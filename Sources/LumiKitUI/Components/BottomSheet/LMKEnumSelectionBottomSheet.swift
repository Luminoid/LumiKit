//
//  LMKEnumSelectionBottomSheet.swift
//  LumiKit
//
//  Generic bottom sheet for selecting enum values with icons.
//

import SnapKit
import UIKit

/// Protocol for types that can be displayed in a selection bottom sheet.
public nonisolated protocol LMKEnumSelectable {
    var displayName: String { get }
    var iconName: String { get }
}

/// Bottom sheet for selecting from a list of `LMKEnumSelectable` options.
///
/// Uses type-erased storage internally to avoid a Swift compiler crash
/// with generic UIViewController subclasses under whole-module optimization
/// (swiftlang/swift#82523).
///
/// Usage:
/// ```swift
/// LMKEnumSelectionBottomSheet.present(
///     in: self,
///     title: "Sort By",
///     options: SortOption.allCases,
///     currentSelection: viewModel.sortOption,
///     onSelect: { option in viewModel.sortOption = option }
/// )
/// ```
public final class LMKEnumSelectionBottomSheet: LMKBottomSheetController, UITableViewDataSource, UITableViewDelegate {
    // MARK: - Properties

    private let titleText: String
    private let optionNames: [String]
    private let optionIcons: [String]
    private var selectedIndices: Set<Int>
    private let isMultiSelect: Bool
    private let doneTitle: String
    private let onCommitIndices: (Set<Int>) -> Void
    private let showIcons: Bool

    // MARK: - Lazy Views

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = titleText
        label.font = LMKTypography.h3
        label.textColor = LMKColor.textPrimary
        return label
    }()

    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.delegate = self
        tv.dataSource = self
        tv.register(LMKEnumSelectionCell.self, forCellReuseIdentifier: "LMKEnumSelectionCell")
        tv.separatorStyle = .none
        tv.backgroundColor = .clear
        tv.showsVerticalScrollIndicator = true
        tv.alwaysBounceVertical = false
        return tv
    }()

    private lazy var doneButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(doneTitle, for: .normal)
        button.titleLabel?.font = LMKTypography.bodyMedium
        button.setTitleColor(LMKColor.white, for: .normal)
        button.backgroundColor = LMKColor.primary
        button.layer.cornerRadius = LMKCornerRadius.medium
        button.addTarget(self, action: #selector(doneTapped), for: .touchUpInside)
        return button
    }()

    // MARK: - Initialization

    private init(
        title: String,
        optionNames: [String],
        optionIcons: [String],
        selectedIndices: Set<Int>,
        isMultiSelect: Bool,
        showIcons: Bool,
        doneTitle: String,
        onCommitIndices: @escaping (Set<Int>) -> Void
    ) {
        self.titleText = title
        self.optionNames = optionNames
        self.optionIcons = optionIcons
        self.selectedIndices = selectedIndices
        self.isMultiSelect = isMultiSelect
        self.showIcons = showIcons
        self.doneTitle = doneTitle
        self.onCommitIndices = onCommitIndices
        super.init()
    }

    // MARK: - Sheet Content

    override public func setupSheetContent() {
        containerView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(dragIndicator.snp.bottom).offset(LMKSpacing.large)
            make.leading.trailing.equalToSuperview().inset(LMKSpacing.xl)
        }

        if isMultiSelect {
            containerView.addSubview(doneButton)
            doneButton.snp.makeConstraints { make in
                make.leading.trailing.equalToSuperview().inset(LMKSpacing.xl)
                make.bottom.equalTo(cancelButton.snp.top).offset(-LMKSpacing.medium)
                make.height.equalTo(LMKBottomSheetLayout.buttonHeight)
            }
        }

        containerView.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(LMKSpacing.large)
            make.leading.trailing.equalToSuperview()
            if isMultiSelect {
                make.bottom.equalTo(doneButton.snp.top).offset(-LMKSpacing.large)
            } else {
                make.bottom.equalTo(cancelButton.snp.top).offset(-LMKSpacing.large)
            }
        }

        // Preferred table height based on content; shrinks if capped by max height.
        let tableHeight = LMKBottomSheetLayout.rowHeight * CGFloat(optionNames.count)
        tableView.snp.makeConstraints { make in
            make.height.equalTo(tableHeight).priority(.high)
        }
    }

    // MARK: - Dynamic Colors

    override public func refreshSheetColors() {
        titleLabel.textColor = LMKColor.textPrimary
        if isMultiSelect {
            doneButton.setTitleColor(LMKColor.white, for: .normal)
            doneButton.backgroundColor = LMKColor.primary
        }
        tableView.reloadData()
    }

    // MARK: - Actions

    @objc private func doneTapped() {
        let indices = selectedIndices
        dismissSheet()
        onCommitIndices(indices)
    }

    // MARK: - UITableViewDataSource

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        optionNames.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "LMKEnumSelectionCell", for: indexPath) as? LMKEnumSelectionCell else {
            return UITableViewCell()
        }
        let row = indexPath.row
        cell.configure(
            displayName: optionNames[row],
            iconName: optionIcons[row],
            isSelected: selectedIndices.contains(row),
            showIcon: showIcons
        )
        return cell
    }

    // MARK: - UITableViewDelegate

    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        LMKBottomSheetLayout.rowHeight
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let row = indexPath.row
        if isMultiSelect {
            if selectedIndices.contains(row) {
                selectedIndices.remove(row)
            } else {
                selectedIndices.insert(row)
            }
            tableView.reloadRows(at: [indexPath], with: .none)
        } else {
            let indices: Set<Int> = [row]
            dismissSheet()
            onCommitIndices(indices)
        }
    }

    // MARK: - Static Convenience

    /// Present a single-selection bottom sheet. Tapping a row commits and dismisses immediately.
    public static func present<T: Equatable & LMKEnumSelectable>(
        in viewController: UIViewController,
        title: String,
        options: [T],
        currentSelection: T,
        showIcons: Bool = false,
        onSelect: @escaping (T) -> Void
    ) {
        let optionNames = options.map(\.displayName)
        let optionIcons = options.map(\.iconName)
        let initialIndices: Set<Int> = options.firstIndex(of: currentSelection).map { [$0] } ?? []
        let sheet = LMKEnumSelectionBottomSheet(
            title: title,
            optionNames: optionNames,
            optionIcons: optionIcons,
            selectedIndices: initialIndices,
            isMultiSelect: false,
            showIcons: showIcons,
            doneTitle: LMKAlertPresenter.strings.ok,
            onCommitIndices: { indices in
                if let first = indices.first {
                    onSelect(options[first])
                }
            }
        )
        addAsChild(sheet, in: viewController)
    }

    /// Present a multi-selection bottom sheet. Tapping a row toggles selection without dismissing.
    /// Selections are committed via the Done button; Cancel discards them.
    public static func presentMultiSelect<T: Hashable & LMKEnumSelectable>(
        in viewController: UIViewController,
        title: String,
        options: [T],
        currentSelection: Set<T>,
        showIcons: Bool = false,
        doneTitle: String? = nil,
        onSelect: @escaping (Set<T>) -> Void
    ) {
        let optionNames = options.map(\.displayName)
        let optionIcons = options.map(\.iconName)
        let initialIndices: Set<Int> = Set(currentSelection.compactMap { options.firstIndex(of: $0) })
        let sheet = LMKEnumSelectionBottomSheet(
            title: title,
            optionNames: optionNames,
            optionIcons: optionIcons,
            selectedIndices: initialIndices,
            isMultiSelect: true,
            showIcons: showIcons,
            doneTitle: doneTitle ?? LMKAlertPresenter.strings.ok,
            onCommitIndices: { indices in
                let selected = Set(indices.map { options[$0] })
                onSelect(selected)
            }
        )
        addAsChild(sheet, in: viewController)
    }
}

// MARK: - Selection Cell

final class LMKEnumSelectionCell: UITableViewCell {
    private lazy var iconImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.tintColor = LMKColor.primary
        return iv
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = LMKTypography.body
        label.textColor = LMKColor.textPrimary
        return label
    }()

    private lazy var checkmarkImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "checkmark")
        iv.tintColor = LMKColor.primary
        iv.contentMode = .scaleAspectFit
        iv.isHidden = true
        return iv
    }()

    private lazy var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = LMKColor.backgroundSecondary
        view.layer.cornerRadius = LMKCornerRadius.small
        return view
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(containerView)
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: LMKSpacing.xs, left: LMKSpacing.xl, bottom: LMKSpacing.xs, right: LMKSpacing.xl))
        }

        containerView.addSubview(iconImageView)
        iconImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(LMKSpacing.large)
            make.centerY.equalToSuperview()
            make.height.equalTo(LMKLayout.iconMedium)
            make.width.equalTo(LMKLayout.iconMedium)
        }

        containerView.addSubview(checkmarkImageView)
        checkmarkImageView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(LMKSpacing.large)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(LMKLayout.iconSmall)
        }

        containerView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconImageView.snp.trailing).offset(LMKSpacing.medium)
            make.centerY.equalToSuperview()
            make.trailing.lessThanOrEqualTo(checkmarkImageView.snp.leading).offset(-LMKSpacing.medium)
        }

        iconImageView.isHidden = true
    }

    func configure(displayName: String, iconName: String, isSelected: Bool, showIcon: Bool = false) {
        titleLabel.text = displayName
        iconImageView.isHidden = !showIcon

        if showIcon {
            if let assetImage = UIImage(named: iconName) {
                iconImageView.image = assetImage
            } else if let sfSymbol = UIImage(systemName: iconName) {
                iconImageView.image = sfSymbol
            } else {
                iconImageView.image = UIImage(systemName: "circle.fill")
            }
            iconImageView.tintColor = LMKColor.primary
            iconImageView.snp.updateConstraints { make in make.width.equalTo(LMKLayout.iconMedium) }
            titleLabel.snp.remakeConstraints { make in
                make.leading.equalTo(iconImageView.snp.trailing).offset(LMKSpacing.medium)
                make.centerY.equalToSuperview()
                make.trailing.lessThanOrEqualTo(checkmarkImageView.snp.leading).offset(-LMKSpacing.medium)
            }
        } else {
            iconImageView.snp.updateConstraints { make in make.width.equalTo(0) }
            titleLabel.snp.remakeConstraints { make in
                make.leading.equalToSuperview().offset(LMKSpacing.large)
                make.centerY.equalToSuperview()
                make.trailing.lessThanOrEqualTo(checkmarkImageView.snp.leading).offset(-LMKSpacing.medium)
            }
        }

        checkmarkImageView.isHidden = !isSelected
        accessibilityTraits = isSelected ? [.button, .selected] : .button
        if isSelected {
            containerView.backgroundColor = LMKColor.primary.withAlphaComponent(LMKAlpha.overlayLight)
            titleLabel.font = LMKTypography.bodyMedium
        } else {
            containerView.backgroundColor = LMKColor.backgroundSecondary
            titleLabel.font = LMKTypography.body
        }
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        let duration = (animated && LMKAnimationHelper.shouldAnimate) ? LMKAnimationHelper.Duration.uiShort : 0
        UIView.animate(withDuration: duration) {
            if highlighted {
                self.containerView.backgroundColor = LMKColor.primary.withAlphaComponent(LMKAlpha.overlayMedium)
            } else {
                self.containerView.backgroundColor = self.checkmarkImageView.isHidden
                    ? LMKColor.backgroundSecondary
                    : LMKColor.primary.withAlphaComponent(LMKAlpha.overlayLight)
            }
        }
    }
}
