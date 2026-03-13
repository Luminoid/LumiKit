//
//  LMKMarkdownRenderer.swift
//  LumiKit
//
//  Renders markdown text as NSAttributedString for display in UILabels.
//  Preserves bold/italic traits while applying a custom base font and color.
//

import UIKit

/// Renders inline markdown to `NSAttributedString` with configurable base font and color.
///
/// Uses `NSAttributedString(markdown:)` under the hood with inline-only parsing.
/// Bold and italic traits from the markdown are merged onto the base font so the
/// caller's typography choices are preserved.
///
/// ```swift
/// label.attributedText = LMKMarkdownRenderer.render(
///     "This is **bold** and *italic* text",
///     font: LMKTypography.body,
///     color: LMKColor.textPrimary
/// )
/// ```
public enum LMKMarkdownRenderer {
    /// Render a markdown string as an attributed string with the given base font and color.
    /// Falls back to plain text if markdown parsing fails.
    public static func render(
        _ markdown: String,
        font: UIFont = LMKTypography.body,
        color: UIColor = LMKColor.textPrimary
    ) -> NSAttributedString {
        let baseAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color,
        ]

        guard let attributedString = try? NSAttributedString(
            markdown: markdown,
            options: AttributedString.MarkdownParsingOptions(
                interpretedSyntax: .inlineOnlyPreservingWhitespace
            )
        ) else {
            return NSAttributedString(string: markdown, attributes: baseAttributes)
        }

        // Re-apply base font/color while keeping markdown attributes (bold, italic, etc.)
        let mutable = NSMutableAttributedString(attributedString: attributedString)
        let fullRange = NSRange(location: 0, length: mutable.length)
        mutable.addAttribute(.foregroundColor, value: color, range: fullRange)

        mutable.enumerateAttribute(.font, in: fullRange) { value, range, _ in
            guard let existingFont = value as? UIFont else {
                mutable.addAttribute(.font, value: font, range: range)
                return
            }
            let traits = existingFont.fontDescriptor.symbolicTraits
            if let descriptor = font.fontDescriptor.withSymbolicTraits(traits) {
                mutable.addAttribute(.font, value: UIFont(descriptor: descriptor, size: font.pointSize), range: range)
            } else {
                mutable.addAttribute(.font, value: font, range: range)
            }
        }

        return mutable
    }
}
