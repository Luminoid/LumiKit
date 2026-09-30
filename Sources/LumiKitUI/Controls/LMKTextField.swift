//
//  LMKTextField.swift
//  LumiKit
//
//  Text field with a leading icon, an optional trailing accessory, validation
//  states, and helper or counter text below.
//

import SnapKit
import UIKit

/// Text field with icon, validation states, and a helper line.
///
/// ```swift
/// let field = LMKTextField()
/// field.placeholder = "Email"
/// field.leadingIcon = UIImage(systemName: "envelope")
/// field.helperText = "We never share your email."
/// field.validationState = .error("Invalid email format")
/// ```
public final class LMKTextField: UIView, LMKThemeApplying {
    public typealias Style = LMKTextInputStyle

    // MARK: - Properties

    /// The wrapped text field, for keyboard, content type, and return key configuration.
    public let textField = UITextField()
    public let containerView = UIView()
    public let leadingIconView = UIImageView()
    public let helperLabel: UILabel
    public let counterLabel: UILabel
    private let helperRow = LMKTextInputHelperRow()
    private var leadingConstraint: Constraint?
    private var trailingConstraint: Constraint?
    private var iconSizeConstraint: Constraint?
    private var heightConstraint: Constraint?
    private var helperInsetsConstraint: Constraint?
    private var resolved = Style()
    private var isEditingText = false

    /// Delegate forwarding. Calls are forwarded after internal handling (the character limit).
    public weak var delegate: (any UITextFieldDelegate)?

    public var text: String? {
        get { textField.text }
        set {
            textField.text = newValue
            updateHelperRow()
        }
    }

    public var placeholder: String? {
        didSet { applyPlaceholder() }
    }

    /// Leading icon image.
    public var leadingIcon: UIImage? {
        didSet {
            leadingIconView.image = leadingIcon
            leadingIconView.isHidden = leadingIcon == nil
            updateLeadingConstraint()
        }
    }

    /// A trailing accessory (a unit label, a reveal button); replaces the clear button.
    public var trailingAccessoryView: UIView? {
        didSet {
            oldValue?.removeFromSuperview()
            if let trailingAccessoryView {
                containerView.addSubview(trailingAccessoryView)
                trailingAccessoryView.setContentHuggingPriority(.required, for: .horizontal)
                trailingAccessoryView.setContentCompressionResistancePriority(.required, for: .horizontal)
            }
            updateTrailingConstraint()
        }
    }

    /// Shows the system clear button while editing (hidden while a trailing accessory is set).
    public var showsClearButton = false {
        didSet { updateTrailingConstraint() }
    }

    /// Helper text below the field in the normal and success states.
    public var helperText: String? {
        didSet { updateHelperRow() }
    }

    /// Current validation state; entering `.warning` / `.error` announces the message to VoiceOver.
    public var validationState: LMKValidationState = .normal {
        didSet {
            guard validationState != oldValue else { return }
            applyTheme(traitCollection.lmkTheme)
            if let message = validationState.message {
                UIAccessibility.post(notification: .announcement, argument: message)
            }
        }
    }

    /// Called when text changes via user input.
    public var onTextChange: ((String?) -> Void)?

    /// Called when editing begins (`true`) and ends (`false`).
    public var onEditingChange: ((Bool) -> Void)?

    /// Maximum number of characters; `nil` means unlimited. With `showsCharacterCount` a counter appears.
    public var maxCharacterCount: Int? {
        didSet { updateHelperRow() }
    }

    /// Shows "n/max" below the field (needs `maxCharacterCount`).
    public var showsCharacterCount = false {
        didSet { updateHelperRow() }
    }

    /// Enables or disables editing and dims the field.
    public var isEnabled = true {
        didSet {
            guard isEnabled != oldValue else { return }
            textField.isEnabled = isEnabled
            applyTheme(traitCollection.lmkTheme)
        }
    }

    /// Per-instance style; `nil` fields resolve from `theme.textField`, then the built-in look.
    public var style: Style {
        didSet {
            guard style != oldValue else { return }
            applyTheme(traitCollection.lmkTheme)
        }
    }

    /// Called at the end of every `applyTheme`, for tweaks the style does not cover.
    public var didApplyStyle: ((LMKTextField) -> Void)?

    // MARK: - Initialization

    public init(style: Style = Style()) {
        self.style = style
        helperLabel = helperRow.messageLabel
        counterLabel = helperRow.counterLabel
        super.init(frame: .zero)
        setupUI()
        lmk_startApplyingTheme()
    }

    override public convenience init(frame: CGRect) {
        self.init(style: Style())
        self.frame = frame
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI() {
        addSubview(containerView)
        leadingIconView.contentMode = .scaleAspectFit
        leadingIconView.isHidden = true
        containerView.addSubview(leadingIconView)
        textField.lmk_applyFormContentPadding()
        textField.delegate = self
        containerView.addSubview(textField)
        addSubview(helperRow)

        containerView.snp.makeConstraints { make in
            make.leading.trailing.top.equalToSuperview()
            heightConstraint = make.height.greaterThanOrEqualTo(0).constraint
        }
        leadingIconView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(0)
            make.centerY.equalToSuperview()
            iconSizeConstraint = make.width.height.equalTo(0).constraint
        }
        textField.snp.makeConstraints { make in
            leadingConstraint = make.leading.equalToSuperview().offset(0).constraint
            trailingConstraint = make.trailing.equalToSuperview().offset(0).constraint
            make.top.bottom.equalToSuperview()
        }
        helperRow.snp.makeConstraints { make in
            helperInsetsConstraint = make.leading.trailing.equalToSuperview().inset(0).constraint
            make.top.equalTo(containerView.snp.bottom).offset(0)
            make.bottom.equalToSuperview()
        }
        textField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        isAccessibilityElement = false
        accessibilityElements = [textField, helperRow.messageLabel, helperRow.counterLabel]
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        containerView.lmk_layoutSurfaceIfNeeded()
    }

    // MARK: - Theme

    public func applyTheme(_ theme: LMKTheme) {
        resolved = theme.textField.merging(style)
        let kind: LMKValidationState.Kind = validationState.kind == .normal && isEditingText ? .focused : validationState.kind
        let stateStyle = resolved.states?[kind]
        let tint = resolved.tint(for: kind, defaultBorder: LMKColor.divider)
        var surface = resolved.surface
        if let background = stateStyle?.background { surface.background = background }
        let defaults = LMKSurfaceStyle(
            background: .solid(LMKColor.backgroundSecondary),
            corners: .fixed(theme.cornerRadius.small),
            border: .solid(tint, width: stateStyle?.border?.width ?? Self.defaultBorderWidth),
            shadow: LMKShadowSource.none,
            contentInsets: .lmk_symmetric(vertical: 0, horizontal: theme.spacing.medium)
        )
        if surface.border == nil || kind != .normal {
            surface.border = .solid(tint, width: stateStyle?.border?.width ?? surface.border?.width ?? Self.defaultBorderWidth)
        }
        let applied = containerView.lmk_apply(surface: surface, defaults: defaults)
        let insets = applied.contentInsets ?? .lmk_symmetric(vertical: 0, horizontal: theme.spacing.medium)
        leadingIconView.snp.updateConstraints { $0.leading.equalToSuperview().offset(insets.leading) }
        iconSizeConstraint?.update(offset: resolved.iconSize ?? theme.layout.iconSmall)
        leadingIconView.tintColor = resolved.iconTint ?? LMKColor.textTertiary
        updateLeadingConstraint()
        updateTrailingConstraint()

        textField.lmk_apply(resolved.textStyle ?? .body, color: resolved.textColor ?? LMKColor.textPrimary)
        applyPlaceholder()
        let lineHeight = ceil(theme.typography.font(for: resolved.textStyle ?? .body, compatibleWith: traitCollection).lineHeight) + theme.spacing.small * 2
        heightConstraint?.update(offset: max(resolved.minimumHeight ?? theme.layout.minimumTouchTarget, lineHeight))
        helperInsetsConstraint?.update(inset: theme.spacing.xs)
        helperRow.snp.updateConstraints { $0.top.equalTo(containerView.snp.bottom).offset(theme.spacing.xs) }
        alpha = isEnabled ? 1 : theme.alpha.disabled
        updateHelperRow()
        didApplyStyle?(self)
    }

    private static let defaultBorderWidth: CGFloat = 1

    private func applyPlaceholder() {
        textField.attributedPlaceholder = placeholder.map {
            NSAttributedString(string: $0, attributes: [.foregroundColor: resolved.placeholderColor ?? LMKColor.textTertiary])
        }
    }

    private func updateLeadingConstraint() {
        let theme = traitCollection.lmkTheme
        let inset = containerView.lmk_resolvedSurface?.contentInsets?.leading ?? theme.spacing.medium
        let iconSize = resolved.iconSize ?? theme.layout.iconSmall
        leadingConstraint?.update(offset: leadingIcon != nil ? inset + iconSize + theme.spacing.small : inset)
    }

    private func updateTrailingConstraint() {
        let theme = traitCollection.lmkTheme
        let inset = containerView.lmk_resolvedSurface?.contentInsets?.trailing ?? theme.spacing.medium
        if let trailingAccessoryView {
            trailingAccessoryView.snp.remakeConstraints { make in
                make.trailing.equalToSuperview().inset(inset)
                make.centerY.equalToSuperview()
            }
            trailingConstraint?.deactivate()
            textField.snp.makeConstraints { make in
                trailingConstraint = make.trailing.equalTo(trailingAccessoryView.snp.leading).offset(-theme.spacing.small).constraint
            }
            textField.clearButtonMode = .never
        } else {
            trailingConstraint?.deactivate()
            textField.snp.makeConstraints { make in
                trailingConstraint = make.trailing.equalToSuperview().offset(-inset).constraint
            }
            textField.clearButtonMode = showsClearButton ? .whileEditing : .never
        }
    }

    private func updateHelperRow() {
        let theme = traitCollection.lmkTheme
        let kind = validationState.kind
        let message = validationState.message ?? helperText
        let messageColor = kind == .warning || kind == .error ? resolved.tint(for: kind, defaultBorder: LMKColor.divider) : (resolved.helperColor ?? LMKColor.textTertiary)
        helperRow.update(
            message: message,
            messageColor: messageColor,
            messageStyle: resolved.helperTextStyle ?? .small,
            count: showsCharacterCount ? (textField.text?.count ?? 0) : nil,
            limit: showsCharacterCount ? maxCharacterCount : nil,
            counterColor: resolved.counterColor ?? LMKColor.textTertiary,
            counterStyle: resolved.counterTextStyle ?? .small
        )
        textField.accessibilityValue = validationState.message
        _ = theme
    }

    @objc private func textFieldDidChange() {
        updateHelperRow()
        onTextChange?(textField.text)
    }

    // MARK: - First Responder

    @discardableResult
    override public func becomeFirstResponder() -> Bool {
        textField.becomeFirstResponder()
    }

    @discardableResult
    override public func resignFirstResponder() -> Bool {
        textField.resignFirstResponder()
    }

    override public var isFirstResponder: Bool { textField.isFirstResponder }
}

// MARK: - UITextFieldDelegate

extension LMKTextField: UITextFieldDelegate {
    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if let maxCharacterCount {
            let currentText = (textField.text ?? "") as NSString
            let newLength = currentText.length + (string as NSString).length - range.length
            if newLength > maxCharacterCount {
                // The host still hears about the rejected edit.
                _ = delegate?.textField?(textField, shouldChangeCharactersIn: range, replacementString: string)
                return false
            }
        }
        return delegate?.textField?(textField, shouldChangeCharactersIn: range, replacementString: string) ?? true
    }

    public func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        delegate?.textFieldShouldBeginEditing?(textField) ?? true
    }

    public func textFieldDidBeginEditing(_ textField: UITextField) {
        isEditingText = true
        applyTheme(traitCollection.lmkTheme)
        onEditingChange?(true)
        delegate?.textFieldDidBeginEditing?(textField)
    }

    public func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        delegate?.textFieldShouldEndEditing?(textField) ?? true
    }

    public func textFieldDidEndEditing(_ textField: UITextField) {
        isEditingText = false
        applyTheme(traitCollection.lmkTheme)
        onEditingChange?(false)
        delegate?.textFieldDidEndEditing?(textField)
    }

    public func textFieldShouldClear(_ textField: UITextField) -> Bool {
        delegate?.textFieldShouldClear?(textField) ?? true
    }

    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        delegate?.textFieldShouldReturn?(textField) ?? true
    }
}
