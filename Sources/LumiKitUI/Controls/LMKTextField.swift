//
//  LMKTextField.swift
//  LumiKit
//
//  Text field with a leading icon, an optional trailing accessory or clear
//  button, validation states, and helper or counter text below.
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

    // MARK: - Strings

    public nonisolated struct Strings: Sendable, Equatable {
        /// VoiceOver label of the clear button.
        public var clearAccessibilityLabel: String
        /// VoiceOver label of the counter: `%lld of %lld characters` (the count, then the limit).
        public var counterAccessibilityLabelFormat: String

        public init(
            clearAccessibilityLabel: String = LMKLocalized("textField.clear.accessibilityLabel"),
            counterAccessibilityLabelFormat: String = LMKLocalized("textInput.counter.accessibilityLabel")
        ) {
            self.clearAccessibilityLabel = clearAccessibilityLabel
            self.counterAccessibilityLabelFormat = counterAccessibilityLabelFormat
        }
    }

    /// Process-wide defaults; set at app launch to override.
    public nonisolated(unsafe) static var strings = Strings()

    /// Per-instance strings (default `Self.strings`).
    public var strings: Strings = LMKTextField.strings {
        didSet {
            clearButton.accessibilityLabel = strings.clearAccessibilityLabel
            updateHelperRow()
        }
    }

    // MARK: - Properties

    /// The wrapped text field, for keyboard, content type, and return key configuration. A
    /// delegate assigned to it (`field.textField.delegate = self`) becomes this view's `delegate`,
    /// so the field's own handling (focus border, editing callbacks, character limit) keeps running.
    public let textField: UITextField = LMKWrappedTextField()
    public let containerView = UIView()
    public let leadingIconView = UIImageView()
    /// The kit's clear button (shown by `showsClearButton` while editing with text); clearing
    /// reports through `onTextChange`.
    public let clearButton = LMKButton(style: .iconOnly(.neutral).size(.small))
    public let helperLabel: UILabel
    public let counterLabel: UILabel
    private let helperRow = LMKTextInputHelperRow()
    private var leadingConstraint: Constraint?
    private var trailingConstraint: Constraint?
    private var iconSizeConstraint: Constraint?
    private var heightConstraint: Constraint?
    private var helperInsetsConstraint: Constraint?
    private var helperTopConstraint: Constraint?
    private var clearHiddenWidthConstraint: Constraint?
    private var resolved = Style()
    private var isEditingText = false
    /// The text as of the last change outside an input method's composition; what a trim keeps.
    private var committedText = ""
    /// Bumped on every text change the field handles; tells `clear()` whether UIKit delivered
    /// the change event it sent.
    private var handledChangeCount = 0

    /// Delegate forwarding: every `UITextFieldDelegate` method is forwarded after the
    /// field's own handling (the character limit runs after the host's answer).
    public weak var delegate: (any UITextFieldDelegate)?

    public var text: String? {
        get { textField.text }
        set {
            textField.text = newValue
            committedText = newValue ?? ""
            updateHelperRow()
            updateClearButtonVisibility()
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
            updateClearButtonVisibility()
            updateAccessibilityElements()
        }
    }

    /// Shows the clear button while editing with text (hidden while a trailing accessory is set).
    public var showsClearButton = false {
        didSet {
            updateTrailingConstraint()
            updateClearButtonVisibility()
        }
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

    /// Called with the new text when it changes through user input.
    public var onTextChange: ((String) -> Void)?

    /// Called when editing begins.
    public var onBeginEditing: (() -> Void)?

    /// Called when editing ends.
    public var onEndEditing: (() -> Void)?

    /// Maximum number of characters (`Character`s, the unit the counter shows); `nil` means
    /// unlimited. Typing stops at the limit, a longer paste is trimmed to fit, and an input
    /// method's composition is never interrupted. With `showsCharacterCount` a counter appears.
    public var maxCharacterCount: Int? {
        didSet { updateHelperRow() }
    }

    /// Shows "n/max" below the field (needs `maxCharacterCount`).
    public var showsCharacterCount = false {
        didSet { updateHelperRow() }
    }

    /// Enables or disables editing and dims the field; a disabled field absorbs touches, accessory included.
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
        textField.clearButtonMode = .never
        (textField as? LMKWrappedTextField)?.wrapper = self
        textField.delegate = self
        containerView.addSubview(textField)
        clearButton.setSymbol("xmark.circle.fill")
        clearButton.isHidden = true
        clearButton.accessibilityLabel = strings.clearAccessibilityLabel
        clearButton.setContentHuggingPriority(.required, for: .horizontal)
        clearButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        clearButton.onTap = { [weak self] in self?.clear() }
        containerView.addSubview(clearButton)
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
        clearButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(0)
            make.centerY.equalToSuperview()
            clearHiddenWidthConstraint = make.width.equalTo(0).constraint
        }
        helperRow.snp.makeConstraints { make in
            helperInsetsConstraint = make.leading.trailing.equalToSuperview().inset(0).constraint
            helperTopConstraint = make.top.equalTo(containerView.snp.bottom).offset(0).constraint
            make.bottom.equalToSuperview()
        }
        textField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        isAccessibilityElement = false
        updateAccessibilityElements()
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        containerView.lmk_layoutSurfaceIfNeeded()
    }

    /// A disabled field absorbs a touch inside its bounds, like a disabled control, accessory included.
    override public func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        return view != nil && !isEnabled ? self : view
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
            shadow: LMKShadowSource.hidden,
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

        let textStyle = resolved.textStyle ?? .body
        textField.lmk_apply(textStyle, color: resolved.textColor ?? LMKColor.textPrimary)
        applyPlaceholder()
        let font = theme.typography.font(for: textStyle, compatibleWith: traitCollection)
        // The clear glyph follows the text size, so it scales with Dynamic Type.
        clearButton.style = LMKButton.Style.iconOnly(.neutral).size(.small).tint(resolved.clearButtonTint ?? LMKColor.textTertiary)
        clearButton.style.symbolPointSize = font.pointSize
        clearButton.snp.updateConstraints { $0.trailing.equalToSuperview().offset(-insets.trailing + theme.spacing.xs) }
        let lineHeight = ceil(font.lineHeight) + theme.spacing.small * 2
        heightConstraint?.update(offset: max(resolved.minimumHeight ?? theme.layout.minimumTouchTarget, lineHeight))
        helperInsetsConstraint?.update(inset: theme.spacing.xs)
        helperRow.spacing = theme.spacing.small
        alpha = isEnabled ? 1 : (resolved.disabled?.alpha ?? theme.alpha.disabled)
        updateHelperRow()
        updateClearButtonVisibility()
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

    private var usesClearButton: Bool { showsClearButton && trailingAccessoryView == nil }

    private func updateTrailingConstraint() {
        let theme = traitCollection.lmkTheme
        let inset = containerView.lmk_resolvedSurface?.contentInsets?.trailing ?? theme.spacing.medium
        trailingConstraint?.deactivate()
        if let trailingAccessoryView {
            trailingAccessoryView.snp.remakeConstraints { make in
                make.trailing.equalToSuperview().inset(inset)
                make.centerY.equalToSuperview()
            }
            textField.snp.makeConstraints { make in
                trailingConstraint = make.trailing.equalTo(trailingAccessoryView.snp.leading).offset(-theme.spacing.small).constraint
            }
        } else if usesClearButton {
            textField.snp.makeConstraints { make in
                trailingConstraint = make.trailing.equalTo(clearButton.snp.leading).offset(0).constraint
            }
        } else {
            textField.snp.makeConstraints { make in
                trailingConstraint = make.trailing.equalToSuperview().offset(-inset).constraint
            }
        }
    }

    /// The clear button takes width only while it shows: editing, with text, and no accessory.
    private func updateClearButtonVisibility() {
        let visible = usesClearButton && isEditingText && !(textField.text?.isEmpty ?? true)
        clearButton.isHidden = !visible
        if visible {
            clearHiddenWidthConstraint?.deactivate()
        } else {
            clearHiddenWidthConstraint?.activate()
        }
        if usesClearButton {
            trailingConstraint?.update(offset: visible ? -traitCollection.lmkTheme.spacing.xs : 0)
        }
    }

    private func updateAccessibilityElements() {
        accessibilityElements = [textField, clearButton, trailingAccessoryView, helperRow.messageLabel, helperRow.counterLabel].compactMap(\.self)
    }

    private func updateHelperRow() {
        let kind = validationState.kind
        let message = validationState.message ?? helperText
        let messageColor = kind == .warning || kind == .error ? resolved.tint(for: kind, defaultBorder: LMKColor.divider) : (resolved.helperColor ?? LMKColor.textSecondary)
        helperRow.update(
            message: message,
            messageColor: messageColor,
            messageStyle: resolved.helperTextStyle ?? .small,
            count: showsCharacterCount ? (textField.text?.count ?? 0) : nil,
            limit: showsCharacterCount ? maxCharacterCount : nil,
            counterColor: resolved.counterColor ?? LMKColor.textSecondary,
            counterStyle: resolved.counterTextStyle ?? .small,
            counterAccessibilityLabelFormat: strings.counterAccessibilityLabelFormat
        )
        // The helper line's gap exists only while the line shows.
        helperTopConstraint?.update(offset: helperRow.isHidden ? 0 : traitCollection.lmkTheme.spacing.xs)
        // The message reads as the field's hint; the value stays what was typed.
        textField.accessibilityHint = message
    }

    @objc private func textFieldDidChange() {
        handledChangeCount += 1
        enforceCharacterLimit()
        updateHelperRow()
        updateClearButtonVisibility()
        onTextChange?(textField.text ?? "")
    }

    /// Trims what an over-limit change inserted (a paste, a committed composition) so the text
    /// fits, keeping the caret after the kept part. Waits while marked text is composing.
    private func enforceCharacterLimit() {
        guard textField.markedTextRange == nil else { return }
        let current = textField.text ?? ""
        if let limit = maxCharacterCount, let trimmed = Style.CharacterLimit.trimmed(current, previous: committedText, limit: limit) {
            textField.text = trimmed.text
            if let caret = textField.position(from: textField.beginningOfDocument, offset: trimmed.caretOffset) {
                textField.selectedTextRange = textField.textRange(from: caret, to: caret)
            }
        }
        committedText = textField.text ?? ""
    }

    /// The clear button's action: asks the host's `textFieldShouldClear`, then empties the field.
    private func clear() {
        guard delegate?.textFieldShouldClear?(textField) ?? true else { return }
        textField.text = nil
        // The events UIKit's own clear button sends, so every observer of `textField` hears it.
        let count = handledChangeCount
        textField.sendActions(for: .editingChanged)
        if handledChangeCount == count {
            textFieldDidChange()
        }
        NotificationCenter.default.post(name: UITextField.textDidChangeNotification, object: textField)
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
    public func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        delegate?.textFieldShouldBeginEditing?(textField) ?? true
    }

    public func textFieldDidBeginEditing(_ textField: UITextField) {
        isEditingText = true
        committedText = textField.text ?? ""
        applyTheme(traitCollection.lmkTheme)
        onBeginEditing?()
        delegate?.textFieldDidBeginEditing?(textField)
    }

    public func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        delegate?.textFieldShouldEndEditing?(textField) ?? true
    }

    public func textFieldDidEndEditing(_ textField: UITextField) {
        finishEditing(reason: nil)
    }

    public func textFieldDidEndEditing(_ textField: UITextField, reason: UITextField.DidEndEditingReason) {
        finishEditing(reason: reason)
    }

    /// UIKit calls the `reason` variant in place of the plain one when both exist; the host
    /// gets whichever it implements.
    private func finishEditing(reason: UITextField.DidEndEditingReason?) {
        isEditingText = false
        applyTheme(traitCollection.lmkTheme)
        onEndEditing?()
        if let reason, delegate?.textFieldDidEndEditing?(textField, reason: reason) != nil { return }
        delegate?.textFieldDidEndEditing?(textField)
    }

    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        shouldChange(ranges: [range], replacement: string) {
            delegate?.textField?(textField, shouldChangeCharactersIn: range, replacementString: string)
        }
    }

    @available(iOS 26, *)
    public func textField(_ textField: UITextField, shouldChangeCharactersInRanges ranges: [NSValue], replacementString string: String) -> Bool {
        let nsRanges = ranges.map(\.rangeValue)
        return shouldChange(ranges: nsRanges, replacement: string) {
            if let answer = delegate?.textField?(textField, shouldChangeCharactersInRanges: ranges, replacementString: string) { return answer }
            return delegate?.textField?(textField, shouldChangeCharactersIn: Self.union(of: nsRanges), replacementString: string)
        }
    }

    /// The host's answer first (`nil` = not implemented), then the character limit outside a composition.
    private func shouldChange(ranges: [NSRange], replacement: String, host: () -> Bool?) -> Bool {
        guard host() ?? true else { return false }
        guard let limit = maxCharacterCount, textField.markedTextRange == nil else { return true }
        return Style.CharacterLimit.allowsChange(in: textField.text ?? "", ranges: ranges, replacement: replacement, limit: limit)
    }

    private static func union(of ranges: [NSRange]) -> NSRange {
        ranges.dropFirst().reduce(ranges.first ?? NSRange(location: 0, length: 0)) { NSUnionRange($0, $1) }
    }

    public func textFieldDidChangeSelection(_ textField: UITextField) {
        delegate?.textFieldDidChangeSelection?(textField)
    }

    public func textFieldShouldClear(_ textField: UITextField) -> Bool {
        delegate?.textFieldShouldClear?(textField) ?? true
    }

    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        delegate?.textFieldShouldReturn?(textField) ?? true
    }

    public func textField(_ textField: UITextField, editMenuForCharactersIn range: NSRange, suggestedActions: [UIMenuElement]) -> UIMenu? {
        delegate?.textField?(textField, editMenuForCharactersIn: range, suggestedActions: suggestedActions)
    }

    @available(iOS 26, *)
    public func textField(_ textField: UITextField, editMenuForCharactersInRanges ranges: [NSValue], suggestedActions: [UIMenuElement]) -> UIMenu? {
        if let menu = delegate?.textField?(textField, editMenuForCharactersInRanges: ranges, suggestedActions: suggestedActions) { return menu }
        return delegate?.textField?(textField, editMenuForCharactersIn: Self.union(of: ranges.map(\.rangeValue)), suggestedActions: suggestedActions)
    }

    public func textField(_ textField: UITextField, willPresentEditMenuWith animator: any UIEditMenuInteractionAnimating) {
        delegate?.textField?(textField, willPresentEditMenuWith: animator)
    }

    public func textField(_ textField: UITextField, willDismissEditMenuWith animator: any UIEditMenuInteractionAnimating) {
        delegate?.textField?(textField, willDismissEditMenuWith: animator)
    }

    #if !targetEnvironment(macCatalyst)
        @available(iOS 18.4, *)
        public func textField(_ textField: UITextField, insertInputSuggestion inputSuggestion: UIInputSuggestion) {
            delegate?.textField?(textField, insertInputSuggestion: inputSuggestion)
        }
    #endif
}

// MARK: - Wrapped field

/// The field inside `LMKTextField`: the wrapper stays its real delegate, and a delegate assigned
/// from outside is forwarded to through the wrapper's `delegate` instead of replacing it.
final class LMKWrappedTextField: UITextField {
    weak var wrapper: LMKTextField?

    override var delegate: (any UITextFieldDelegate)? {
        get { super.delegate }
        set {
            guard let wrapper, newValue !== wrapper else {
                super.delegate = newValue
                return
            }
            wrapper.delegate = newValue
        }
    }
}
