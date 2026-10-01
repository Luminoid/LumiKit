//
//  UIView+LMKTextStyle.swift
//  LumiKit
//
//  `lmk_apply(_:)` for labels, text fields, and text views: resolves an
//  `LMKTextStyle` against the view's own traits and theme, and re-applies it
//  whenever Dynamic Type or the theme changes.
//

import UIKit

private nonisolated(unsafe) var lmk_textStyleStateKey: UInt8 = 0

/// What `lmk_apply` remembers per view so it can re-run on trait changes.
@MainActor
private final class LMKTextStyleState {
    var style: LMKTextStyle
    var color: UIColor?
    var lineMetrics: Bool
    /// The edge a `.natural` label was last resolved to (attributed text resolves `.natural` by
    /// the content's direction, not the view's, so the label carries an explicit edge instead).
    var naturalAlignmentEdge: NSTextAlignment?
    var registration: (any UITraitChangeRegistration)?

    init(style: LMKTextStyle, color: UIColor?, lineMetrics: Bool) {
        self.style = style
        self.color = color
        self.lineMetrics = lineMetrics
    }
}

private extension UIView {
    var lmk_textStyleState: LMKTextStyleState? {
        get { objc_getAssociatedObject(self, &lmk_textStyleStateKey) as? LMKTextStyleState }
        set { objc_setAssociatedObject(self, &lmk_textStyleStateKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    /// Stores the style and registers the one trait handler that re-applies it.
    func lmk_storeTextStyle(_ style: LMKTextStyle, color: UIColor?, lineMetrics: Bool, reapply: @escaping @MainActor (UIView) -> Void) {
        if let state = lmk_textStyleState {
            state.style = style
            state.color = color
            state.lineMetrics = lineMetrics
            return
        }
        let state = LMKTextStyleState(style: style, color: color, lineMetrics: lineMetrics)
        state.registration = registerForTraitChanges([UITraitPreferredContentSizeCategory.self, UITraitLayoutDirection.self, LMKThemeTrait.self]) { (view: Self, _) in
            reapply(view)
        }
        lmk_textStyleState = state
    }
}

// MARK: - UILabel

public extension UILabel {
    /// The text style last applied with `lmk_apply(_:color:lineMetrics:)`, if any.
    var lmk_textStyle: LMKTextStyle? {
        lmk_textStyleState?.style
    }

    /// Applies `style`: a per-view Dynamic Type font from the traits' theme,
    /// `adjustsFontForContentSizeCategory`, and `color` when given. Re-applied
    /// automatically when the content size category or the theme changes.
    ///
    /// With `lineMetrics`, the label renders its text as an attributed string with
    /// the theme's line height and tracking; set text through `lmk_setText(_:)` (or
    /// call `lmk_apply` again) so the metrics survive, since `text =` drops attributes.
    func lmk_apply(_ style: LMKTextStyle, color: UIColor? = nil, lineMetrics: Bool = false) {
        lmk_storeTextStyle(style, color: color, lineMetrics: lineMetrics) { view in
            (view as? UILabel)?.lmk_reapplyTextStyle()
        }
        lmk_reapplyTextStyle()
    }

    /// Sets `text` and, when line metrics are on, re-renders the attributed string.
    func lmk_setText(_ text: String?) {
        self.text = text
        if lmk_textStyleState?.lineMetrics == true {
            lmk_reapplyTextStyle()
        }
    }

    /// A label with `style` applied (line metrics on), `text`, and `color`
    /// (the style's default when `nil`), wrapping by default.
    static func lmk_make(_ style: LMKTextStyle, text: String? = nil, color: UIColor? = nil, numberOfLines: Int = 0) -> UILabel {
        let label = UILabel()
        label.numberOfLines = numberOfLines
        label.text = text
        label.lmk_apply(style, color: color ?? style.defaultColor, lineMetrics: true)
        return label
    }

    private func lmk_reapplyTextStyle() {
        guard let state = lmk_textStyleState else { return }
        let theme = traitCollection.lmkTheme
        let resolvedFont = theme.typography.font(for: state.style, compatibleWith: traitCollection)
        font = resolvedFont
        adjustsFontForContentSizeCategory = true
        if let color = state.color {
            textColor = color
        }
        if state.lineMetrics, let text, !text.isEmpty {
            let attributes = theme.typography.attributes(for: state.style, font: resolvedFont, color: textColor ?? LMKColor.textPrimary)
            // An attributed string with a paragraph style resets both to the paragraph's
            // (natural alignment, word wrapping); the label's own settings win.
            var alignment = textAlignment
            if let edge = state.naturalAlignmentEdge, alignment == edge {
                alignment = .natural
            }
            let lineBreak = lineBreakMode
            attributedText = NSAttributedString(string: text, attributes: attributes)
            // A paragraph's `.natural` follows the text's own direction (English stays left in a
            // right-to-left layout); a plain label's follows the view's. Keep the plain behavior.
            if alignment == .natural {
                let edge: NSTextAlignment = effectiveUserInterfaceLayoutDirection == .rightToLeft ? .right : .left
                textAlignment = edge
                state.naturalAlignmentEdge = edge
            } else {
                textAlignment = alignment
                state.naturalAlignmentEdge = nil
            }
            lineBreakMode = lineBreak
        }
        invalidateIntrinsicContentSize()
    }
}

// MARK: - UITextField

public extension UITextField {
    /// Applies `style` (font, `adjustsFontForContentSizeCategory`, optional `color`),
    /// re-applied on Dynamic Type and theme changes.
    func lmk_apply(_ style: LMKTextStyle, color: UIColor? = nil) {
        lmk_storeTextStyle(style, color: color, lineMetrics: false) { view in
            (view as? UITextField)?.lmk_reapplyTextStyle()
        }
        lmk_reapplyTextStyle()
    }

    private func lmk_reapplyTextStyle() {
        guard let state = lmk_textStyleState else { return }
        font = traitCollection.lmkTheme.typography.font(for: state.style, compatibleWith: traitCollection)
        adjustsFontForContentSizeCategory = true
        if let color = state.color {
            textColor = color
        }
    }
}

// MARK: - UITextView

public extension UITextView {
    /// Applies `style` (font, `adjustsFontForContentSizeCategory`, optional `color`),
    /// re-applied on Dynamic Type and theme changes.
    func lmk_apply(_ style: LMKTextStyle, color: UIColor? = nil) {
        lmk_storeTextStyle(style, color: color, lineMetrics: false) { view in
            (view as? UITextView)?.lmk_reapplyTextStyle()
        }
        lmk_reapplyTextStyle()
    }

    private func lmk_reapplyTextStyle() {
        guard let state = lmk_textStyleState else { return }
        font = traitCollection.lmkTheme.typography.font(for: state.style, compatibleWith: traitCollection)
        adjustsFontForContentSizeCategory = true
        if let color = state.color {
            textColor = color
        }
    }
}
