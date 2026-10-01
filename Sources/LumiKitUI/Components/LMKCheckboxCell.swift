//
//  LMKCheckboxCell.swift
//  LumiKit
//
//  Check-off row for to-dos and checklists: an `LMKCheckbox` plus a title
//  that strikes through when done, and an optional subtitle.
//

import SnapKit
import UIKit

/// Check-off row.
///
/// A tap on the checkbox flips the row (`isDone`, the strikethrough, the VoiceOver value) and
/// reports the new value through `onValueChange`. The checkbox has a 44pt hit area; hosts should
/// also toggle from `tableView(_:didSelectRowAt:)` with `setDone(_:animated:)` so the whole
/// row is a target:
/// ```swift
/// cell.configure(title: item.title, subtitle: item.due, isDone: item.isDone)
/// cell.onValueChange = { [weak self] isDone in self?.viewModel.setDone(isDone, for: item) }
/// // didSelectRowAt:
/// cell.setDone(!cell.isDone, animated: true)
/// ```
public final class LMKCheckboxCell: UITableViewCell, LMKThemeApplying {
    // MARK: - Style

    public nonisolated struct Style: Sendable, Equatable, LMKThemeExtension {
        /// Row background; `nil` = `backgroundSecondary`.
        public var background: UIColor?
        /// `nil` = `body`.
        public var titleTextStyle: LMKTextStyle?
        /// `nil` = `caption`.
        public var subtitleTextStyle: LMKTextStyle?
        /// `nil` = `textPrimary`.
        public var titleColor: UIColor?
        /// `nil` = `textSecondary`.
        public var subtitleColor: UIColor?
        /// Title and subtitle color once done; `nil` = `textTertiary`.
        public var doneColor: UIColor?
        /// Strike the title through when done; `nil` = yes.
        public var strikesThroughWhenDone: Bool?
        /// Content insets; `nil` = `medium` / `large`.
        public var contentInsets: NSDirectionalEdgeInsets?
        /// Gap between checkbox and text; `nil` = `medium`.
        public var spacing: CGFloat?
        /// Checkbox style.
        public var checkbox: LMKCheckbox.Style?

        public init(
            background: UIColor? = nil,
            titleTextStyle: LMKTextStyle? = nil,
            subtitleTextStyle: LMKTextStyle? = nil,
            titleColor: UIColor? = nil,
            subtitleColor: UIColor? = nil,
            doneColor: UIColor? = nil,
            strikesThroughWhenDone: Bool? = nil,
            contentInsets: NSDirectionalEdgeInsets? = nil,
            spacing: CGFloat? = nil,
            checkbox: LMKCheckbox.Style? = nil
        ) {
            self.background = background
            self.titleTextStyle = titleTextStyle
            self.subtitleTextStyle = subtitleTextStyle
            self.titleColor = titleColor
            self.subtitleColor = subtitleColor
            self.doneColor = doneColor
            self.strikesThroughWhenDone = strikesThroughWhenDone
            self.contentInsets = contentInsets
            self.spacing = spacing
            self.checkbox = checkbox
        }

        public static let defaultValue = Self()

        /// `other`'s non-nil fields over this style's.
        public func merging(_ other: Self) -> Self {
            Self(
                background: other.background ?? background,
                titleTextStyle: other.titleTextStyle ?? titleTextStyle,
                subtitleTextStyle: other.subtitleTextStyle ?? subtitleTextStyle,
                titleColor: other.titleColor ?? titleColor,
                subtitleColor: other.subtitleColor ?? subtitleColor,
                doneColor: other.doneColor ?? doneColor,
                strikesThroughWhenDone: other.strikesThroughWhenDone ?? strikesThroughWhenDone,
                contentInsets: other.contentInsets ?? contentInsets,
                spacing: other.spacing ?? spacing,
                checkbox: other.checkbox.map { checkbox?.merging($0) ?? $0 } ?? checkbox
            )
        }
    }

    // MARK: - Strings

    public nonisolated struct Strings: Sendable, Equatable {
        /// Accessibility label for the checkbox.
        public var checkboxAccessibilityLabel: String
        /// Accessibility value of a done row.
        public var doneAccessibilityValue: String
        /// Accessibility value of a pending row.
        public var notDoneAccessibilityValue: String

        public init(
            checkboxAccessibilityLabel: String = LMKLocalized("checkboxCell.checkbox.accessibilityLabel"),
            doneAccessibilityValue: String = LMKLocalized("checkboxCell.done.accessibilityValue"),
            notDoneAccessibilityValue: String = LMKLocalized("checkboxCell.notDone.accessibilityValue")
        ) {
            self.checkboxAccessibilityLabel = checkboxAccessibilityLabel
            self.doneAccessibilityValue = doneAccessibilityValue
            self.notDoneAccessibilityValue = notDoneAccessibilityValue
        }
    }

    /// Process-wide defaults; set at app launch to override.
    public nonisolated(unsafe) static var strings = Strings()

    /// Per-instance strings (default `Self.strings`).
    public var strings: Strings = LMKCheckboxCell.strings {
        didSet { updateAccessibility() }
    }

    public static let reuseIdentifier = "LMKCheckboxCell"

    // MARK: - Properties

    /// Fired with the new `isDone` after a tap on the checkbox (or a VoiceOver activation of
    /// the row) flipped it. `setDone(_:animated:)` and `configure` are silent.
    public var onValueChange: ((Bool) -> Void)?

    public let checkbox = LMKCheckbox()
    public let titleLabel = UILabel()
    public let subtitleLabel = UILabel()
    private let textStack = UIStackView()

    /// Per-instance style; `nil` fields resolve from `theme.checkboxCell`, then the built-in look.
    public var style: Style {
        didSet {
            guard style != oldValue else { return }
            applyTheme(traitCollection.lmkTheme)
        }
    }

    /// Called at the end of every `applyTheme`, for tweaks the style does not cover.
    public var didApplyStyle: ((LMKCheckboxCell) -> Void)?

    public private(set) var title: String?
    public private(set) var subtitle: String?
    public private(set) var isDone = false

    private var resolved = Style()
    private var insetsConstraint: Constraint?
    private var spacingConstraint: Constraint?

    // MARK: - Init

    override public init(style cellStyle: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        style = Style()
        super.init(style: cellStyle, reuseIdentifier: reuseIdentifier)
        setupUI()
        lmk_startApplyingTheme()
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI() {
        selectionStyle = .none
        isAccessibilityElement = true
        accessibilityTraits = .button
        checkbox.onValueChange = { [weak self] isChecked in self?.didToggle(to: isChecked) }
        checkbox.setContentHuggingPriority(.required, for: .horizontal)

        titleLabel.numberOfLines = 0
        subtitleLabel.numberOfLines = 0
        subtitleLabel.isHidden = true
        textStack.axis = .vertical
        textStack.addArrangedSubview(titleLabel)
        textStack.addArrangedSubview(subtitleLabel)

        contentView.addSubview(checkbox)
        contentView.addSubview(textStack)
        checkbox.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(0)
            make.centerY.equalToSuperview()
        }
        textStack.snp.makeConstraints { make in
            spacingConstraint = make.leading.equalTo(checkbox.snp.trailing).offset(0).constraint
            // Below required: the table sizes the cell with a temporary encapsulated height, and a
            // required edge would be the constraint UIKit breaks, leaving a wrapped title clipped.
            insetsConstraint = make.top.bottom.trailing.equalToSuperview().inset(0).priority(999).constraint
        }
        updateAccessibility()
    }

    /// The table sizes the row before the label knows its column width; feeding it back makes
    /// the second fitting pass wrap a borderline title instead of truncating it.
    override public func layoutSubviews() {
        super.layoutSubviews()
        let width = textStack.bounds.width
        guard width > 0 else { return }
        var changed = false
        for label in [titleLabel, subtitleLabel] where label.preferredMaxLayoutWidth != width {
            label.preferredMaxLayoutWidth = width
            changed = true
        }
        if changed {
            super.layoutSubviews()
        }
    }

    // MARK: - Configuration

    public func configure(title: String, subtitle: String? = nil, isDone: Bool) {
        self.title = title
        self.subtitle = subtitle
        self.isDone = isDone
        checkbox.isChecked = isDone
        applyContent()
        updateAccessibility()
    }

    /// Sets the done state (the checkbox animates when `animated`) without firing `onValueChange`:
    /// the row-tap path, where the host already knows the new value.
    public func setDone(_ isDone: Bool, animated: Bool) {
        self.isDone = isDone
        checkbox.setChecked(isDone, animated: animated)
        applyContent()
        updateAccessibility()
    }

    /// The checkbox flipped itself: the row follows, then the host hears the new value.
    private func didToggle(to isDone: Bool) {
        self.isDone = isDone
        applyContent()
        updateAccessibility()
        onValueChange?(isDone)
    }

    /// VoiceOver's double tap on the row toggles it, as a tap on the checkbox does; a row whose
    /// checkbox is disabled does nothing.
    override public func accessibilityActivate() -> Bool {
        guard checkbox.isEnabled else { return false }
        setDone(!isDone, animated: true)
        onValueChange?(isDone)
        return true
    }

    /// A button, selected when done, and not enabled while the checkbox is disabled (read live, so
    /// a host that disables `checkbox` needs nothing else).
    override public var accessibilityTraits: UIAccessibilityTraits {
        get {
            var traits = super.accessibilityTraits
            if isDone { traits.insert(.selected) }
            if !checkbox.isEnabled { traits.insert(.notEnabled) }
            return traits
        }
        set { super.accessibilityTraits = newValue }
    }

    private func applyContent() {
        let doneColor = resolved.doneColor ?? LMKColor.textTertiary
        titleLabel.lmk_apply(resolved.titleTextStyle ?? .body, color: isDone ? doneColor : (resolved.titleColor ?? LMKColor.textPrimary))
        if isDone, resolved.strikesThroughWhenDone ?? true, let title {
            titleLabel.attributedText = NSAttributedString(string: title, attributes: [
                .strikethroughStyle: NSUnderlineStyle.single.rawValue,
                .foregroundColor: doneColor,
                .font: titleLabel.font ?? UIFont.preferredFont(forTextStyle: .body),
            ])
        } else {
            titleLabel.attributedText = nil
            titleLabel.lmk_setText(title)
        }
        subtitleLabel.lmk_apply(resolved.subtitleTextStyle ?? .caption, color: isDone ? doneColor : (resolved.subtitleColor ?? LMKColor.textSecondary))
        subtitleLabel.lmk_setText(subtitle)
        subtitleLabel.isHidden = subtitle?.isEmpty ?? true
    }

    // MARK: - Theme

    public func applyTheme(_ theme: LMKTheme) {
        resolved = theme.checkboxCell.merging(style)
        backgroundColor = resolved.background ?? LMKColor.backgroundSecondary
        checkbox.style = resolved.checkbox ?? LMKCheckbox.Style()
        let insets = resolved.contentInsets ?? .lmk_symmetric(vertical: theme.spacing.medium, horizontal: theme.spacing.large)
        checkbox.snp.updateConstraints { $0.leading.equalToSuperview().inset(insets.leading) }
        insetsConstraint?.update(inset: UIEdgeInsets(top: insets.top, left: 0, bottom: insets.bottom, right: insets.trailing))
        spacingConstraint?.update(offset: resolved.spacing ?? theme.spacing.medium)
        textStack.spacing = theme.spacing.xxs
        applyContent()
        didApplyStyle?(self)
    }

    // MARK: - Accessibility

    private func updateAccessibility() {
        checkbox.accessibilityLabel = strings.checkboxAccessibilityLabel
        accessibilityLabel = [title, subtitle].compactMap(\.self).filter { !$0.isEmpty }.joined(separator: ". ")
        accessibilityValue = isDone ? strings.doneAccessibilityValue : strings.notDoneAccessibilityValue
    }

    // MARK: - Reuse

    override public func prepareForReuse() {
        super.prepareForReuse()
        onValueChange = nil
        title = nil
        subtitle = nil
        isDone = false
        checkbox.isChecked = false
        titleLabel.attributedText = nil
        titleLabel.text = nil
        subtitleLabel.text = nil
        subtitleLabel.isHidden = true
        accessibilityLabel = nil
        accessibilityValue = strings.notDoneAccessibilityValue
        accessibilityTraits = [.button]
        // What a host sets on a disabled row must not ride along to the next one.
        checkbox.isEnabled = true
        isUserInteractionEnabled = true
        alpha = 1
    }
}

public nonisolated extension LMKTheme {
    /// App-wide default style for `LMKCheckboxCell`.
    var checkboxCell: LMKCheckboxCell.Style {
        get { self[LMKCheckboxCell.Style.self] }
        set { self[LMKCheckboxCell.Style.self] = newValue }
    }
}
