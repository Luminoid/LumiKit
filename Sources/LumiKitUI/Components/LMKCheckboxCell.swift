//
//  LMKCheckboxCell.swift
//  LumiKit
//
//  Check-off row for to-dos and checklist items.
//

import SnapKit
import UIKit

// MARK: - Configurable Strings

/// Configurable strings for checkbox cell accessibility.
public nonisolated struct LMKCheckboxCellStrings: Sendable {
    /// Accessibility label for the checkbox button.
    public var checkboxAccessibilityLabel: String
    /// Accessibility value announced when the item is done.
    public var doneAccessibilityValue: String
    /// Accessibility value announced when the item is not done.
    public var notDoneAccessibilityValue: String

    public init(
        checkboxAccessibilityLabel: String = "Toggle done",
        doneAccessibilityValue: String = "Done",
        notDoneAccessibilityValue: String = "Not done"
    ) {
        self.checkboxAccessibilityLabel = checkboxAccessibilityLabel
        self.doneAccessibilityValue = doneAccessibilityValue
        self.notDoneAccessibilityValue = notDoneAccessibilityValue
    }
}

public nonisolated(unsafe) var lmkCheckboxCellStrings = LMKCheckboxCellStrings()

// MARK: - LMKCheckboxCell

/// A reusable check-off row for to-dos and checklist items: a tappable checkbox
/// plus a title that strikes through when done.
///
/// The checkbox's hit area is expanded to the minimum touch target; hosts should
/// also toggle from `tableView(_:didSelectRowAt:)` so the whole row is a target:
/// ```swift
/// cell.configure(title: item.title, isDone: item.isDone)
/// cell.onToggle = { [weak self] in self?.viewModel.toggle(item) }
/// ```
public final class LMKCheckboxCell: UITableViewCell {
    public static let reuseIdentifier = "LMKCheckboxCell"

    // MARK: - Properties

    /// Fired when the checkbox (or the row) requests a toggle.
    public var onToggle: (() -> Void)?

    private let checkbox = LMKExpandedHitAreaButton(type: .system)
    private let titleLabel = UILabel()

    // MARK: - Init

    override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI() {
        backgroundColor = LMKColor.backgroundSecondary
        selectionStyle = .none

        checkbox.tintColor = LMKColor.primary
        checkbox.addTarget(self, action: #selector(toggleTapped), for: .touchUpInside)
        checkbox.setContentHuggingPriority(.required, for: .horizontal)
        checkbox.accessibilityLabel = lmkCheckboxCellStrings.checkboxAccessibilityLabel
        // The rendered glyph is icon-sized; expand the hit area to the minimum
        // touch target so the checkbox alone is a comfortable toggle.
        let hitInset = -max(0, (LMKLayout.minimumTouchTarget - LMKLayout.iconMedium) / 2)
        checkbox.lmk_touchAreaEdgeInsets = UIEdgeInsets(top: hitInset, left: hitInset, bottom: hitInset, right: hitInset)

        titleLabel.font = LMKTypography.body
        titleLabel.textColor = LMKColor.textPrimary
        titleLabel.numberOfLines = 0

        contentView.addSubview(checkbox)
        contentView.addSubview(titleLabel)

        checkbox.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(LMKSpacing.large)
            make.centerY.equalToSuperview()
            make.size.equalTo(LMKLayout.iconMedium)
        }
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(checkbox.snp.trailing).offset(LMKSpacing.medium)
            make.trailing.equalToSuperview().inset(LMKSpacing.large)
            make.top.bottom.equalToSuperview().inset(LMKSpacing.medium)
        }
    }

    // MARK: - Configuration

    public func configure(title: String, isDone: Bool) {
        // Set the checkbox image directly, never via a cross-dissolve. Toggling a
        // row republishes the view model's items, which reloadData()s the whole
        // table and reconfigures every visible cell; a cross-dissolve here animates
        // each recycled cell from whatever image it last held, briefly flashing a
        // checkmark on unrelated rows (the "false check" bug).
        checkbox.setImage(UIImage(systemName: isDone ? "checkmark.circle.fill" : "circle"), for: .normal)
        checkbox.tintColor = isDone ? LMKColor.success : LMKColor.primary

        if isDone {
            titleLabel.attributedText = NSAttributedString(
                string: title,
                attributes: [
                    .strikethroughStyle: NSUnderlineStyle.single.rawValue,
                    .foregroundColor: LMKColor.textTertiary,
                ]
            )
        } else {
            titleLabel.attributedText = nil
            titleLabel.text = title
            titleLabel.textColor = LMKColor.textPrimary
        }

        accessibilityLabel = title
        accessibilityValue = isDone
            ? lmkCheckboxCellStrings.doneAccessibilityValue
            : lmkCheckboxCellStrings.notDoneAccessibilityValue
        accessibilityTraits = isDone ? [.button, .selected] : [.button]
    }

    // MARK: - Actions

    @objc private func toggleTapped() {
        LMKHapticFeedbackHelper.light()
        onToggle?()
    }

    // MARK: - Reuse

    override public func prepareForReuse() {
        super.prepareForReuse()
        onToggle = nil
        titleLabel.attributedText = nil
        titleLabel.text = nil
    }
}

// MARK: - LMKExpandedHitAreaButton

/// `UIButton` honoring `lmk_touchAreaEdgeInsets` so an icon-sized control can
/// still meet the minimum touch target.
private final class LMKExpandedHitAreaButton: UIButton {
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        lmk_pointInside(point, with: event)
    }
}
