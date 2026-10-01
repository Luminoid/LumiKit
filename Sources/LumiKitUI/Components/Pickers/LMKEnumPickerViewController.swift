//
//  LMKEnumPickerViewController.swift
//  LumiKit
//
//  The enum picker's sheet: a title, an optional search field, a table of
//  action-sheet rows, and a Done button for multi-select.
//

import SnapKit
import UIKit

/// The bottom sheet behind `LMKEnumPicker.present(...)`.
///
/// Options are type-erased into `Item`s here (a generic `UIViewController` subclass
/// would trip the Swift 6.2 WMO crash, swiftlang/swift#82523); the namespace maps
/// committed indices back to values.
public final class LMKEnumPickerViewController: LMKBottomSheetViewController, UITableViewDataSource, UITableViewDelegate {
    /// One row.
    public struct Item: Equatable {
        public var title: String
        public var iconName: String?
        public var isEnabled: Bool

        public init(title: String, iconName: String? = nil, isEnabled: Bool = true) {
            self.title = title
            self.iconName = iconName
            self.isEnabled = isEnabled
        }
    }

    // MARK: - Properties

    public let items: [Item]
    public let isMultiSelect: Bool
    public let showsSearch: Bool
    /// Indices of the selected items (into `items`).
    public private(set) var selectedIndices: Set<Int>
    /// Indices of the items matching the search text, in order.
    public private(set) var visibleIndices: [Int]

    public let titleLabel = UILabel()
    public let searchBar: LMKSearchBar
    public let tableView = UITableView(frame: .zero, style: .plain)
    public let doneButton = LMKButton(style: LMKButton.Style())

    /// The picker style last resolved against the theme.
    public private(set) var resolvedPickerStyle = LMKEnumPicker.Style()

    private let titleText: String
    private let doneTitle: String?
    private let pickerStyle: LMKEnumPicker.Style
    private let pickerStrings: LMKEnumPicker.Strings
    private let onCommit: (Set<Int>) -> Void
    private let onCancel: (() -> Void)?
    private var pendingCommit: Set<Int>?
    private var rowInsets: UIEdgeInsets = .zero
    private var horizontalInsetConstraints: [Constraint] = []
    private var searchTopConstraint: Constraint?
    private var tableTopConstraint: Constraint?
    private var tableBottomConstraint: Constraint?
    private var tableHeightConstraint: Constraint?
    private var appliedTableHeight: CGFloat = 0
    private var contentSizeObservation: NSKeyValueObservation?

    private static let cellIdentifier = "LMKEnumPickerCell"
    private static let estimatedRowHeight: CGFloat = 56

    // MARK: - Initialization

    init(
        title: String,
        items: [Item],
        selectedIndices: Set<Int>,
        isMultiSelect: Bool,
        showsSearch: Bool,
        doneTitle: String?,
        style: LMKEnumPicker.Style,
        strings: LMKEnumPicker.Strings,
        onCommit: @escaping (Set<Int>) -> Void,
        onCancel: (() -> Void)? = nil
    ) {
        self.titleText = title
        self.items = items
        self.selectedIndices = selectedIndices
        self.visibleIndices = Array(items.indices)
        self.isMultiSelect = isMultiSelect
        self.showsSearch = showsSearch
        self.doneTitle = doneTitle
        self.pickerStyle = style
        self.pickerStrings = strings
        self.onCommit = onCommit
        self.onCancel = onCancel
        self.searchBar = LMKSearchBar(style: style.searchBar)
        super.init()
    }

    isolated deinit {
        contentSizeObservation?.invalidate()
    }

    // MARK: - Sheet content

    override public func setupSheetContent() {
        titleLabel.text = titleText
        titleLabel.accessibilityTraits = .header
        // The list is what gives way at the sheet's height cap; at the default priority the
        // title tied with the list's preferred height and lost its top half.
        titleLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        containerView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(contentLayoutGuide.snp.top)
            horizontalInsetConstraints.append(make.leading.trailing.equalTo(contentLayoutGuide).inset(0).constraint)
        }

        var tableTopAnchor: ConstraintItem = titleLabel.snp.bottom
        if showsSearch {
            searchBar.placeholder = pickerStrings.searchPlaceholder
            searchBar.onTextChange = { [weak self] text in self?.filter(with: text) }
            containerView.addSubview(searchBar)
            searchBar.snp.makeConstraints { make in
                searchTopConstraint = make.top.equalTo(titleLabel.snp.bottom).offset(0).constraint
                horizontalInsetConstraints.append(make.leading.trailing.equalTo(contentLayoutGuide).inset(0).constraint)
            }
            tableTopAnchor = searchBar.snp.bottom
        }

        if isMultiSelect {
            doneButton.title = doneTitle ?? pickerStrings.done
            doneButton.onTap = { [weak self] in self?.doneTapped() }
            containerView.addSubview(doneButton)
            doneButton.snp.makeConstraints { make in
                horizontalInsetConstraints.append(make.leading.trailing.equalTo(contentLayoutGuide).inset(0).constraint)
                make.bottom.equalTo(contentLayoutGuide.snp.bottom)
            }
        }

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(LMKEnumPickerCell.self, forCellReuseIdentifier: Self.cellIdentifier)
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.alwaysBounceVertical = false
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = Self.estimatedRowHeight
        tableView.keyboardDismissMode = .onDrag
        containerView.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            tableTopConstraint = make.top.equalTo(tableTopAnchor).offset(0).constraint
            make.leading.trailing.equalTo(contentLayoutGuide)
            if isMultiSelect {
                tableBottomConstraint = make.bottom.equalTo(doneButton.snp.top).offset(0).constraint
            } else {
                make.bottom.equalTo(contentLayoutGuide.snp.bottom)
            }
            // Preferred height from the content; the sheet's cap wins when taller.
            tableHeightConstraint = make.height.equalTo(Self.estimatedRowHeight * CGFloat(items.count)).priority(.high).constraint
        }
        // Row heights follow Dynamic Type and the row style, so the preferred height tracks
        // the table's own content size once the cells have been measured.
        let refresh: @Sendable (UITableView, Any) -> Void = { [weak self] _, _ in
            MainActor.assumeIsolated {
                self?.updateTableHeight()
            }
        }
        contentSizeObservation = tableView.observe(\.contentSize, options: [.new], changeHandler: refresh)
    }

    // MARK: - Theme

    override public func resolveStyle(for theme: LMKTheme) -> Style {
        theme.bottomSheet.merging(theme.enumPicker.sheet).merging(pickerStyle.sheet).merging(style)
    }

    override public func applyContentTheme(_ theme: LMKTheme) {
        resolvedPickerStyle = theme.enumPicker.merging(pickerStyle)
        titleLabel.lmk_apply(resolvedPickerStyle.titleTextStyle ?? .h3, color: resolvedPickerStyle.titleColor ?? LMKColor.textPrimary)
        doneButton.style = LMKButton.Style(variant: .filled, minimumHeight: Self.defaultButtonHeight).merging(resolvedPickerStyle.doneButton)
        searchBar.style = resolvedPickerStyle.searchBar

        // The sheet's content insets place the title, search field, rows, and Done; the cancel
        // button already follows them through the base class.
        let insets = resolvedStyle.surface.contentInsets
        rowInsets = UIEdgeInsets(top: 0, left: insets?.leading ?? theme.spacing.xl, bottom: 0, right: insets?.trailing ?? theme.spacing.xl)
        horizontalInsetConstraints.forEach { $0.update(inset: rowInsets) }
        searchTopConstraint?.update(offset: theme.spacing.medium)
        tableTopConstraint?.update(offset: theme.spacing.large)
        tableBottomConstraint?.update(offset: -theme.spacing.large)
        for cell in tableView.visibleCells {
            (cell as? LMKEnumPickerCell)?.rowView.style = resolvedPickerStyle.row
        }
        tableView.reloadData()
    }

    // MARK: - Layout

    /// Keeps the table's preferred height at its unfiltered content height, so a picker with a
    /// few options is exactly as tall as its rows (whatever their Dynamic Type size) and a
    /// search that narrows the list does not shrink the sheet under the keyboard.
    private func updateTableHeight() {
        guard visibleIndices.count == items.count else { return }
        let height = tableView.contentSize.height
        guard height > 0, height != appliedTableHeight else { return }
        appliedTableHeight = height
        tableHeightConstraint?.update(offset: height)
    }

    // MARK: - Search

    /// Keeps the rows whose title contains `text` (case- and diacritic-insensitive).
    public func filter(with text: String) {
        let query = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if query.isEmpty {
            visibleIndices = Array(items.indices)
        } else {
            visibleIndices = items.indices.filter { items[$0].title.range(of: query, options: [.caseInsensitive, .diacriticInsensitive]) != nil }
        }
        tableView.reloadData()
    }

    // MARK: - Selection

    /// Toggles (multi) or commits (single) the item at `index` into `items`, as a tap would.
    public func select(itemAt index: Int) {
        guard let item = items[lmk_safe: index], item.isEnabled else { return }
        if isMultiSelect {
            if selectedIndices.contains(index) {
                selectedIndices.remove(index)
            } else {
                selectedIndices.insert(index)
            }
            if let row = visibleIndices.firstIndex(of: index) {
                tableView.reloadRows(at: [IndexPath(row: row, section: 0)], with: .none)
            }
        } else {
            selectedIndices = [index]
            pendingCommit = [index]
            dismiss(reason: .programmatic)
        }
    }

    private func doneTapped() {
        pendingCommit = selectedIndices
        dismiss(reason: .programmatic)
    }

    override public func didDismiss(reason: DismissReason) {
        super.didDismiss(reason: reason)
        if let pendingCommit {
            self.pendingCommit = nil
            onCommit(pendingCommit)
        } else {
            onCancel?()
        }
    }

    // MARK: - UITableViewDataSource

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        visibleIndices.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: Self.cellIdentifier, for: indexPath) as? LMKEnumPickerCell,
              let index = visibleIndices[lmk_safe: indexPath.row], let item = items[lmk_safe: index]
        else {
            return UITableViewCell()
        }
        cell.rowView.style = resolvedPickerStyle.row
        cell.configure(item: item, isSelected: selectedIndices.contains(index), rowSpacing: resolvedPickerStyle.rowSpacing ?? traitCollection.lmkTheme.spacing.xs, horizontalInsets: rowInsets)
        return cell
    }

    // MARK: - UITableViewDelegate

    public func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        guard let index = visibleIndices[lmk_safe: indexPath.row], let item = items[lmk_safe: index] else { return false }
        return item.isEnabled
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let index = visibleIndices[lmk_safe: indexPath.row] else { return }
        select(itemAt: index)
    }
}

/// A table cell hosting one `LMKActionSheetRowView`.
final class LMKEnumPickerCell: UITableViewCell {
    let rowView = LMKActionSheetRowView()
    private var insetsConstraint: Constraint?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none
        rowView.isUserInteractionEnabled = false
        contentView.addSubview(rowView)
        rowView.snp.makeConstraints { make in
            insetsConstraint = make.edges.equalToSuperview().inset(0).constraint
        }
        isAccessibilityElement = true
        accessibilityTraits = .button
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Binds `item`; `rowSpacing` is split above and below the row (the table draws no
    /// separators) and `horizontalInsets` are the sheet's content insets.
    func configure(item: LMKEnumPickerViewController.Item, isSelected: Bool, rowSpacing: CGFloat, horizontalInsets: UIEdgeInsets) {
        let icon = item.iconName.flatMap { UIImage(named: $0) ?? UIImage(systemName: $0) }
        rowView.configure(LMKActionSheetRowView.Content(title: item.title, icon: icon, isSelected: isSelected, isEnabled: item.isEnabled))
        insetsConstraint?.update(inset: UIEdgeInsets(top: rowSpacing / 2, left: horizontalInsets.left, bottom: rowSpacing / 2, right: horizontalInsets.right))
        accessibilityLabel = item.title
        var traits: UIAccessibilityTraits = .button
        if isSelected { traits.insert(.selected) }
        if !item.isEnabled { traits.insert(.notEnabled) }
        accessibilityTraits = traits
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        rowView.isHighlighted = highlighted
    }
}
