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
    private let selectedIndex: Int?
    private let onSelectIndex: (Int) -> Void
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

    // MARK: - Initialization

    private init(title: String, optionNames: [String], optionIcons: [String], selectedIndex: Int?, showIcons: Bool, onSelectIndex: @escaping (Int) -> Void) {
        self.titleText = title
        self.optionNames = optionNames
        self.optionIcons = optionIcons
        self.selectedIndex = selectedIndex
        self.showIcons = showIcons
        self.onSelectIndex = onSelectIndex
        super.init()
    }

    // MARK: - Sheet Content

    override public func setupSheetContent() {
        containerView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(dragIndicator.snp.bottom).offset(LMKSpacing.large)
            make.leading.trailing.equalToSuperview().inset(LMKSpacing.xl)
        }

        containerView.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(LMKSpacing.large)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(cancelButton.snp.top).offset(-LMKSpacing.large)
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
        tableView.reloadData()
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
            isSelected: row == selectedIndex,
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
        let handler = onSelectIndex
        let index = indexPath.row
        dismissSheet()
        handler(index)
    }

    // MARK: - Static Convenience

    /// Present an enum selection bottom sheet.
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
        let selectedIndex = options.firstIndex(of: currentSelection)
        let sheet = LMKEnumSelectionBottomSheet(
            title: title,
            optionNames: optionNames,
            optionIcons: optionIcons,
            selectedIndex: selectedIndex,
            showIcons: showIcons,
            onSelectIndex: { index in onSelect(options[index]) }
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
