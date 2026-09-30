//
//  LMKTextView.swift
//  LumiKit
//
//  Multi-line text input with a placeholder, validation states, a helper or
//  counter line, and auto-growing height between a floor and an optional cap.
//

import SnapKit
import UIKit

/// Multi-line text view with placeholder, validation states, and a helper line.
///
/// ```swift
/// let textView = LMKTextView()
/// textView.placeholder = "Add notes..."
/// textView.maxCharacterCount = 200
/// textView.showsCharacterCount = true
/// textView.validationState = .error("Too short")
/// ```
public final class LMKTextView: UIView, LMKThemeApplying {
    public typealias Style = LMKTextInputStyle

    // MARK: - Properties

    /// The wrapped text view, for keyboard and content configuration.
    public let textView = UITextView()
    public let placeholderLabel = UILabel()
    public let helperLabel: UILabel
    public let counterLabel: UILabel
    private let helperRow = LMKTextInputHelperRow()
    private var minimumHeightConstraint: Constraint?
    private var maximumHeightConstraint: Constraint?
    private var resolved = Style()
    private var isEditingText = false

    /// Delegate forwarding.
    public weak var delegate: (any UITextViewDelegate)?

    public var text: String? {
        get { textView.text }
        set {
            textView.text = newValue
            updatePlaceholderVisibility()
            updateHelperRow()
            updateGrowth()
        }
    }

    /// Placeholder shown while the text view is empty.
    public var placeholder: String? {
        didSet {
            placeholderLabel.lmk_setText(placeholder)
            textView.accessibilityHint = placeholder
        }
    }

    /// Helper text below the text view in the normal and success states.
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

    /// Maximum number of characters; `nil` means unlimited.
    public var maxCharacterCount: Int? {
        didSet { updateHelperRow() }
    }

    /// Shows "n/max" below the text view (needs `maxCharacterCount`).
    public var showsCharacterCount = false {
        didSet { updateHelperRow() }
    }

    /// Height floor; `nil` = the style's `minimumHeight` (100).
    public var minimumHeight: CGFloat? {
        didSet { updateGrowth() }
    }

    /// Growth cap; `nil` = the style's `maximumHeight` (unlimited). Past the cap the view scrolls.
    public var maximumHeight: CGFloat? {
        didSet { updateGrowth() }
    }

    /// Called when text changes via user input.
    public var onTextChange: ((String?) -> Void)?

    /// Called when editing begins (`true`) and ends (`false`).
    public var onEditingChange: ((Bool) -> Void)?

    /// Enables or disables editing and dims the view.
    public var isEnabled = true {
        didSet {
            guard isEnabled != oldValue else { return }
            textView.isEditable = isEnabled
            applyTheme(traitCollection.lmkTheme)
        }
    }

    /// Per-instance style; `nil` fields resolve from `theme.textView`, then the built-in look.
    public var style: Style {
        didSet {
            guard style != oldValue else { return }
            applyTheme(traitCollection.lmkTheme)
        }
    }

    /// Called at the end of every `applyTheme`, for tweaks the style does not cover.
    public var didApplyStyle: ((LMKTextView) -> Void)?

    private static let defaultMinimumHeight: CGFloat = 100
    private static let defaultBorderWidth: CGFloat = 1

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
        textView.lmk_applyFormContentPadding()
        textView.delegate = self
        textView.isScrollEnabled = false
        addSubview(textView)
        textView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            minimumHeightConstraint = make.height.greaterThanOrEqualTo(Self.defaultMinimumHeight).constraint
            maximumHeightConstraint = make.height.lessThanOrEqualTo(10000).constraint
        }
        maximumHeightConstraint?.deactivate()

        placeholderLabel.numberOfLines = 0
        placeholderLabel.isUserInteractionEnabled = false
        textView.addSubview(placeholderLabel)
        updatePlaceholderConstraints()

        addSubview(helperRow)
        helperRow.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(LMKSpacing.xs)
            make.top.equalTo(textView.snp.bottom).offset(LMKSpacing.xs)
            make.bottom.equalToSuperview()
        }
        isAccessibilityElement = false
        accessibilityElements = [textView, helperRow.messageLabel, helperRow.counterLabel]
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        textView.lmk_layoutSurfaceIfNeeded()
    }

    private func updatePlaceholderConstraints() {
        let inset = textView.textContainerInset
        let padding = textView.textContainer.lineFragmentPadding
        placeholderLabel.snp.remakeConstraints { make in
            make.leading.equalToSuperview().offset(inset.left + padding)
            make.top.equalToSuperview().offset(inset.top)
            make.trailing.equalTo(self.snp.trailing).offset(-(inset.right + padding))
        }
    }

    // MARK: - Theme

    public func applyTheme(_ theme: LMKTheme) {
        resolved = theme.textView.merging(style)
        let kind: LMKValidationState.Kind = validationState.kind == .normal && isEditingText ? .focused : validationState.kind
        let stateStyle = resolved.states?[kind]
        let tint = resolved.tint(for: kind, defaultBorder: LMKColor.divider)
        var surface = resolved.surface
        if let background = stateStyle?.background { surface.background = background }
        if surface.border == nil || kind != .normal {
            surface.border = .solid(tint, width: stateStyle?.border?.width ?? surface.border?.width ?? Self.defaultBorderWidth)
        }
        let defaults = LMKSurfaceStyle(
            background: .solid(LMKColor.backgroundSecondary),
            corners: .fixed(theme.cornerRadius.small),
            border: .solid(tint, width: Self.defaultBorderWidth),
            shadow: LMKShadowSource.none
        )
        let applied = textView.lmk_apply(surface: surface, defaults: defaults)
        if let insets = applied.contentInsets {
            textView.textContainerInset = UIEdgeInsets(top: insets.top, left: insets.leading, bottom: insets.bottom, right: insets.trailing)
        } else {
            textView.lmk_applyFormContentPadding()
        }
        updatePlaceholderConstraints()
        textView.lmk_apply(resolved.textStyle ?? .body, color: resolved.textColor ?? LMKColor.textPrimary)
        placeholderLabel.lmk_apply(resolved.textStyle ?? .body, color: resolved.placeholderColor ?? LMKColor.textTertiary)
        alpha = isEnabled ? 1 : theme.alpha.disabled
        updateGrowth()
        updateHelperRow()
        didApplyStyle?(self)
    }

    // MARK: - UI Updates

    private func updatePlaceholderVisibility() {
        placeholderLabel.isHidden = !(textView.text?.isEmpty ?? true)
    }

    private func updateHelperRow() {
        let kind = validationState.kind
        let message = validationState.message ?? helperText
        let messageColor = kind == .warning || kind == .error ? resolved.tint(for: kind, defaultBorder: LMKColor.divider) : (resolved.helperColor ?? LMKColor.textTertiary)
        helperRow.update(
            message: message,
            messageColor: messageColor,
            messageStyle: resolved.helperTextStyle ?? .small,
            count: showsCharacterCount ? (textView.text?.count ?? 0) : nil,
            limit: showsCharacterCount ? maxCharacterCount : nil,
            counterColor: resolved.counterColor ?? LMKColor.textTertiary,
            counterStyle: resolved.counterTextStyle ?? .small
        )
        textView.accessibilityValue = validationState.message
    }

    /// Floors the height, caps it when a maximum is set, and scrolls only past the cap.
    private func updateGrowth() {
        let floor = minimumHeight ?? resolved.minimumHeight ?? Self.defaultMinimumHeight
        minimumHeightConstraint?.update(offset: floor)
        if let cap = maximumHeight ?? resolved.maximumHeight {
            maximumHeightConstraint?.update(offset: max(cap, floor))
            maximumHeightConstraint?.activate()
            let contentHeight = textView.sizeThatFits(CGSize(width: max(textView.bounds.width, 1), height: .greatestFiniteMagnitude)).height
            textView.isScrollEnabled = contentHeight > cap
        } else {
            maximumHeightConstraint?.deactivate()
            textView.isScrollEnabled = false
        }
        invalidateIntrinsicContentSize()
    }

    // MARK: - First Responder

    @discardableResult
    override public func becomeFirstResponder() -> Bool {
        textView.becomeFirstResponder()
    }

    @discardableResult
    override public func resignFirstResponder() -> Bool {
        textView.resignFirstResponder()
    }

    override public var isFirstResponder: Bool { textView.isFirstResponder }
}

// MARK: - UITextViewDelegate

extension LMKTextView: UITextViewDelegate {
    public func textViewDidChange(_ textView: UITextView) {
        updatePlaceholderVisibility()
        updateHelperRow()
        updateGrowth()
        onTextChange?(textView.text)
        delegate?.textViewDidChange?(textView)
    }

    public func textViewDidBeginEditing(_ textView: UITextView) {
        isEditingText = true
        applyTheme(traitCollection.lmkTheme)
        onEditingChange?(true)
        delegate?.textViewDidBeginEditing?(textView)
    }

    public func textViewDidEndEditing(_ textView: UITextView) {
        isEditingText = false
        applyTheme(traitCollection.lmkTheme)
        onEditingChange?(false)
        delegate?.textViewDidEndEditing?(textView)
    }

    public func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        delegate?.textViewShouldBeginEditing?(textView) ?? true
    }

    public func textViewShouldEndEditing(_ textView: UITextView) -> Bool {
        delegate?.textViewShouldEndEditing?(textView) ?? true
    }

    public func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if let maxCharacterCount {
            let currentText = (textView.text ?? "") as NSString
            let newLength = currentText.length + (text as NSString).length - range.length
            if newLength > maxCharacterCount {
                _ = delegate?.textView?(textView, shouldChangeTextIn: range, replacementText: text)
                return false
            }
        }
        return delegate?.textView?(textView, shouldChangeTextIn: range, replacementText: text) ?? true
    }

    public func textViewDidChangeSelection(_ textView: UITextView) {
        delegate?.textViewDidChangeSelection?(textView)
    }
}
