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

    // MARK: - Strings

    public nonisolated struct Strings: Sendable, Equatable {
        /// VoiceOver label of the counter: `%lld of %lld characters` (the count, then the limit).
        public var counterAccessibilityLabelFormat: String

        public init(counterAccessibilityLabelFormat: String = LMKLocalized("textInput.counter.accessibilityLabel")) {
            self.counterAccessibilityLabelFormat = counterAccessibilityLabelFormat
        }
    }

    /// Process-wide defaults; set at app launch to override.
    public nonisolated(unsafe) static var strings = Strings()

    /// Per-instance strings (default `Self.strings`).
    public var strings: Strings = LMKTextView.strings {
        didSet { updateHelperRow() }
    }

    // MARK: - Properties

    /// The wrapped text view, for keyboard and content configuration. A delegate assigned to it
    /// (`view.textView.delegate = self`) becomes this view's `delegate`, so the view's own handling
    /// (focus border, growth, editing callbacks, character limit) keeps running.
    public let textView: UITextView = LMKWrappedTextView()
    public let placeholderLabel = UILabel()
    public let helperLabel: UILabel
    public let counterLabel: UILabel
    private let helperRow = LMKTextInputHelperRow()
    private var minimumHeightConstraint: Constraint?
    private var maximumHeightConstraint: Constraint?
    private var scrollingHeightConstraint: Constraint?
    private var helperInsetsConstraint: Constraint?
    private var helperTopConstraint: Constraint?
    private var resolved = Style()
    private var isEditingText = false
    /// The width the growth was last measured at; a new width re-measures in `layoutSubviews`.
    private var growthWidth: CGFloat = 0
    /// The text as of the last change outside an input method's composition; what a trim keeps.
    private var committedText = ""

    /// Delegate forwarding: every `UITextViewDelegate` method, scroll view methods included, is
    /// forwarded after the view's own handling (the character limit runs after the host's answer).
    public weak var delegate: (any UITextViewDelegate)?

    public var text: String? {
        get { textView.text }
        set {
            textView.text = newValue
            committedText = newValue ?? ""
            updatePlaceholderVisibility()
            updateHelperRow()
            updateGrowth()
        }
    }

    /// Placeholder shown while the text view is empty; VoiceOver reads it as the hint while no
    /// helper or validation message shows.
    public var placeholder: String? {
        didSet {
            placeholderLabel.lmk_setText(placeholder)
            updateHelperRow()
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

    /// Maximum number of characters (`Character`s, the unit the counter shows); `nil` means
    /// unlimited. Typing stops at the limit, a longer paste is trimmed to fit, and an input
    /// method's composition is never interrupted.
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

    /// Called with the new text when it changes through user input.
    public var onTextChange: ((String) -> Void)?

    /// Called when editing begins.
    public var onBeginEditing: (() -> Void)?

    /// Called when editing ends.
    public var onEndEditing: (() -> Void)?

    /// Enables or disables editing and dims the view; a disabled view absorbs touches.
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
        (textView as? LMKWrappedTextView)?.wrapper = self
        textView.delegate = self
        textView.isScrollEnabled = false
        addSubview(textView)
        textView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            minimumHeightConstraint = make.height.greaterThanOrEqualTo(Self.defaultMinimumHeight).constraint
            maximumHeightConstraint = make.height.lessThanOrEqualTo(Self.defaultMinimumHeight).constraint
            // A scrolling text view has no intrinsic height; this pins it to the cap meanwhile.
            scrollingHeightConstraint = make.height.equalTo(Self.defaultMinimumHeight).priority(.high).constraint
        }
        maximumHeightConstraint?.deactivate()
        scrollingHeightConstraint?.deactivate()

        placeholderLabel.numberOfLines = 0
        placeholderLabel.isUserInteractionEnabled = false
        textView.addSubview(placeholderLabel)
        updatePlaceholderConstraints()

        addSubview(helperRow)
        helperRow.snp.makeConstraints { make in
            helperInsetsConstraint = make.leading.trailing.equalToSuperview().inset(0).constraint
            helperTopConstraint = make.top.equalTo(textView.snp.bottom).offset(0).constraint
            make.bottom.equalToSuperview()
        }
        isAccessibilityElement = false
        accessibilityElements = [textView, helperRow.messageLabel, helperRow.counterLabel]
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        textView.lmk_layoutSurfaceIfNeeded()
        // The scroll-at-cap decision depends on the wrapping width; re-run it when that changes.
        if textView.bounds.width != growthWidth {
            updateGrowth()
        }
    }

    /// A disabled view absorbs a touch inside its bounds, like a disabled control.
    override public func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        return view != nil && !isEnabled ? self : view
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
            shadow: LMKShadowSource.hidden
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
        helperInsetsConstraint?.update(inset: theme.spacing.xs)
        helperRow.spacing = theme.spacing.small
        alpha = isEnabled ? 1 : (resolved.disabled?.alpha ?? theme.alpha.disabled)
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
        let messageColor = kind == .warning || kind == .error ? resolved.tint(for: kind, defaultBorder: LMKColor.divider) : (resolved.helperColor ?? LMKColor.textSecondary)
        helperRow.update(
            message: message,
            messageColor: messageColor,
            messageStyle: resolved.helperTextStyle ?? .small,
            count: showsCharacterCount ? (textView.text?.count ?? 0) : nil,
            limit: showsCharacterCount ? maxCharacterCount : nil,
            counterColor: resolved.counterColor ?? LMKColor.textSecondary,
            counterStyle: resolved.counterTextStyle ?? .small,
            counterAccessibilityLabelFormat: strings.counterAccessibilityLabelFormat
        )
        // The helper line's gap exists only while the line shows.
        helperTopConstraint?.update(offset: helperRow.isHidden ? 0 : traitCollection.lmkTheme.spacing.xs)
        // The message (else the placeholder) reads as the hint; the value stays what was typed.
        textView.accessibilityHint = message ?? placeholder
    }

    /// Floors the height, caps it when a maximum is set, and scrolls only past the cap. The
    /// content is measured at the current width; before the first layout nothing scrolls, and
    /// `layoutSubviews` re-measures at every new width.
    private func updateGrowth() {
        let floor = minimumHeight ?? resolved.minimumHeight ?? Self.defaultMinimumHeight
        minimumHeightConstraint?.update(offset: floor)
        let width = textView.bounds.width
        growthWidth = width
        guard let cap = maximumHeight ?? resolved.maximumHeight else {
            maximumHeightConstraint?.deactivate()
            scrollingHeightConstraint?.deactivate()
            textView.isScrollEnabled = false
            invalidateIntrinsicContentSize()
            return
        }
        let limit = max(cap, floor)
        maximumHeightConstraint?.update(offset: limit)
        maximumHeightConstraint?.activate()
        var scrolls = false
        if width > 0 {
            let contentHeight = textView.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude)).height
            scrolls = contentHeight > limit
        }
        textView.isScrollEnabled = scrolls
        // Scrolling removes the intrinsic height; the cap holds it until the text fits again.
        if scrolls {
            scrollingHeightConstraint?.update(offset: limit)
            scrollingHeightConstraint?.activate()
        } else {
            scrollingHeightConstraint?.deactivate()
        }
        invalidateIntrinsicContentSize()
    }

    /// Trims what an over-limit change inserted (a paste, a committed composition) so the text
    /// fits, keeping the caret after the kept part. Waits while marked text is composing.
    private func enforceCharacterLimit() {
        guard textView.markedTextRange == nil else { return }
        let current = textView.text ?? ""
        if let limit = maxCharacterCount, let trimmed = Style.CharacterLimit.trimmed(current, previous: committedText, limit: limit) {
            textView.text = trimmed.text
            textView.selectedRange = NSRange(location: trimmed.caretOffset, length: 0)
        }
        committedText = textView.text ?? ""
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
        enforceCharacterLimit()
        updatePlaceholderVisibility()
        updateHelperRow()
        updateGrowth()
        onTextChange?(textView.text ?? "")
        delegate?.textViewDidChange?(textView)
    }

    public func textViewDidBeginEditing(_ textView: UITextView) {
        isEditingText = true
        committedText = textView.text ?? ""
        applyTheme(traitCollection.lmkTheme)
        onBeginEditing?()
        delegate?.textViewDidBeginEditing?(textView)
    }

    public func textViewDidEndEditing(_ textView: UITextView) {
        isEditingText = false
        applyTheme(traitCollection.lmkTheme)
        onEndEditing?()
        delegate?.textViewDidEndEditing?(textView)
    }

    public func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        delegate?.textViewShouldBeginEditing?(textView) ?? true
    }

    public func textViewShouldEndEditing(_ textView: UITextView) -> Bool {
        delegate?.textViewShouldEndEditing?(textView) ?? true
    }

    public func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        shouldChange(ranges: [range], replacement: text) {
            delegate?.textView?(textView, shouldChangeTextIn: range, replacementText: text)
        }
    }

    @available(iOS 26, *)
    public func textView(_ textView: UITextView, shouldChangeTextInRanges ranges: [NSValue], replacementText text: String) -> Bool {
        let nsRanges = ranges.map(\.rangeValue)
        return shouldChange(ranges: nsRanges, replacement: text) {
            if let answer = delegate?.textView?(textView, shouldChangeTextInRanges: ranges, replacementText: text) { return answer }
            return delegate?.textView?(textView, shouldChangeTextIn: Self.union(of: nsRanges), replacementText: text)
        }
    }

    /// The host's answer first (`nil` = not implemented), then the character limit outside a composition.
    private func shouldChange(ranges: [NSRange], replacement: String, host: () -> Bool?) -> Bool {
        guard host() ?? true else { return false }
        guard let limit = maxCharacterCount, textView.markedTextRange == nil else { return true }
        return Style.CharacterLimit.allowsChange(in: textView.text ?? "", ranges: ranges, replacement: replacement, limit: limit)
    }

    private static func union(of ranges: [NSRange]) -> NSRange {
        ranges.dropFirst().reduce(ranges.first ?? NSRange(location: 0, length: 0)) { NSUnionRange($0, $1) }
    }

    public func textViewDidChangeSelection(_ textView: UITextView) {
        delegate?.textViewDidChangeSelection?(textView)
    }

    // MARK: Edit menu

    public func textView(_ textView: UITextView, editMenuForTextIn range: NSRange, suggestedActions: [UIMenuElement]) -> UIMenu? {
        delegate?.textView?(textView, editMenuForTextIn: range, suggestedActions: suggestedActions)
    }

    @available(iOS 26, *)
    public func textView(_ textView: UITextView, editMenuForTextInRanges ranges: [NSValue], suggestedActions: [UIMenuElement]) -> UIMenu? {
        if let menu = delegate?.textView?(textView, editMenuForTextInRanges: ranges, suggestedActions: suggestedActions) { return menu }
        return delegate?.textView?(textView, editMenuForTextIn: Self.union(of: ranges.map(\.rangeValue)), suggestedActions: suggestedActions)
    }

    public func textView(_ textView: UITextView, willPresentEditMenuWith animator: any UIEditMenuInteractionAnimating) {
        delegate?.textView?(textView, willPresentEditMenuWith: animator)
    }

    public func textView(_ textView: UITextView, willDismissEditMenuWith animator: any UIEditMenuInteractionAnimating) {
        delegate?.textView?(textView, willDismissEditMenuWith: animator)
    }

    // MARK: Text items

    public func textView(_ textView: UITextView, primaryActionFor textItem: UITextItem, defaultAction: UIAction) -> UIAction? {
        guard let delegate, delegate.responds(to: #selector(UITextViewDelegate.textView(_:primaryActionFor:defaultAction:))) else { return defaultAction }
        return delegate.textView?(textView, primaryActionFor: textItem, defaultAction: defaultAction)
    }

    public func textView(_ textView: UITextView, menuConfigurationFor textItem: UITextItem, defaultMenu: UIMenu) -> UITextItem.MenuConfiguration? {
        guard let delegate, delegate.responds(to: #selector(UITextViewDelegate.textView(_:menuConfigurationFor:defaultMenu:))) else { return .init(menu: defaultMenu) }
        return delegate.textView?(textView, menuConfigurationFor: textItem, defaultMenu: defaultMenu)
    }

    public func textView(_ textView: UITextView, textItemMenuWillDisplayFor textItem: UITextItem, animator: any UIContextMenuInteractionAnimating) {
        delegate?.textView?(textView, textItemMenuWillDisplayFor: textItem, animator: animator)
    }

    public func textView(_ textView: UITextView, textItemMenuWillEndFor textItem: UITextItem, animator: any UIContextMenuInteractionAnimating) {
        delegate?.textView?(textView, textItemMenuWillEndFor: textItem, animator: animator)
    }

    // MARK: Writing Tools and formatting

    public func textViewWritingToolsWillBegin(_ textView: UITextView) {
        delegate?.textViewWritingToolsWillBegin?(textView)
    }

    public func textViewWritingToolsDidEnd(_ textView: UITextView) {
        delegate?.textViewWritingToolsDidEnd?(textView)
    }

    public func textView(_ textView: UITextView, writingToolsIgnoredRangesInEnclosingRange enclosingRange: NSRange) -> [NSValue] {
        delegate?.textView?(textView, writingToolsIgnoredRangesInEnclosingRange: enclosingRange) ?? []
    }

    #if !targetEnvironment(macCatalyst)
        public func textView(_ textView: UITextView, willBeginFormattingWith viewController: UITextFormattingViewController) {
            delegate?.textView?(textView, willBeginFormattingWith: viewController)
        }

        public func textView(_ textView: UITextView, didBeginFormattingWith viewController: UITextFormattingViewController) {
            delegate?.textView?(textView, didBeginFormattingWith: viewController)
        }

        public func textView(_ textView: UITextView, willEndFormattingWith viewController: UITextFormattingViewController) {
            delegate?.textView?(textView, willEndFormattingWith: viewController)
        }

        public func textView(_ textView: UITextView, didEndFormattingWith viewController: UITextFormattingViewController) {
            delegate?.textView?(textView, didEndFormattingWith: viewController)
        }

        @available(iOS 18.4, *)
        public func textView(_ textView: UITextView, insertInputSuggestion inputSuggestion: UIInputSuggestion) {
            delegate?.textView?(textView, insertInputSuggestion: inputSuggestion)
        }
    #endif

    // MARK: Scrolling

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        delegate?.scrollViewDidScroll?(scrollView)
    }

    public func scrollViewDidZoom(_ scrollView: UIScrollView) {
        delegate?.scrollViewDidZoom?(scrollView)
    }

    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        delegate?.scrollViewWillBeginDragging?(scrollView)
    }

    public func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        delegate?.scrollViewWillEndDragging?(scrollView, withVelocity: velocity, targetContentOffset: targetContentOffset)
    }

    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        delegate?.scrollViewDidEndDragging?(scrollView, willDecelerate: decelerate)
    }

    public func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        delegate?.scrollViewWillBeginDecelerating?(scrollView)
    }

    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        delegate?.scrollViewDidEndDecelerating?(scrollView)
    }

    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        delegate?.scrollViewDidEndScrollingAnimation?(scrollView)
    }

    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        delegate?.viewForZooming?(in: scrollView)
    }

    public func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        delegate?.scrollViewWillBeginZooming?(scrollView, with: view)
    }

    public func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        delegate?.scrollViewDidEndZooming?(scrollView, with: view, atScale: scale)
    }

    public func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        delegate?.scrollViewShouldScrollToTop?(scrollView) ?? true
    }

    public func scrollViewDidScrollToTop(_ scrollView: UIScrollView) {
        delegate?.scrollViewDidScrollToTop?(scrollView)
    }

    public func scrollViewDidChangeAdjustedContentInset(_ scrollView: UIScrollView) {
        delegate?.scrollViewDidChangeAdjustedContentInset?(scrollView)
    }
}

// MARK: - Wrapped text view

/// The text view inside `LMKTextView`: the wrapper stays its real delegate, and a delegate assigned
/// from outside is forwarded to through the wrapper's `delegate` instead of replacing it.
final class LMKWrappedTextView: UITextView {
    weak var wrapper: LMKTextView?

    override var delegate: (any UITextViewDelegate)? {
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
