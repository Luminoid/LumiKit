//
//  LMKMarkdownRenderer.swift
//  LumiKit
//
//  Renders markdown text as NSAttributedString for display in UILabels and UITextViews.
//  Preserves bold/italic traits while applying a custom base font and color.
//

import UIKit

/// Renders markdown to `NSAttributedString` with configurable base font and color.
///
/// Supports two modes:
/// - **Inline** (default): Bold, italic, code — suitable for labels and single-line text.
/// - **Full**: Headings, lists, bold, italic — suitable for long-form content.
///   Uses inline parsing to guarantee every `\n` is a visible line break, then applies
///   heading styles by detecting `#` prefixes.
///
/// ```swift
/// // Inline (labels, short text)
/// label.attributedText = LMKMarkdownRenderer.render(
///     "This is **bold** and *italic* text",
///     font: LMKTypography.body,
///     color: LMKColor.textPrimary
/// )
///
/// // Full (reports, articles)
/// textView.attributedText = LMKMarkdownRenderer.renderFull(
///     "## Heading\n\nSome **bold** text\n- Item 1\n- Item 2",
///     font: LMKTypography.body,
///     color: LMKColor.textPrimary
/// )
/// ```
public enum LMKMarkdownRenderer {
    /// Render inline markdown (bold, italic, code) as an attributed string.
    /// Falls back to plain text if markdown parsing fails.
    public static func render(
        _ markdown: String,
        font: UIFont = LMKTypography.body,
        color: UIColor = LMKColor.textPrimary
    ) -> NSAttributedString {
        guard let attributedString = try? NSAttributedString(
            markdown: markdown,
            options: AttributedString.MarkdownParsingOptions(
                interpretedSyntax: .inlineOnlyPreservingWhitespace
            )
        ) else {
            return NSAttributedString(string: markdown, attributes: [
                .font: font,
                .foregroundColor: color,
            ])
        }

        return applyBaseFont(to: attributedString, font: font, color: color)
    }

    /// Render long-form markdown as an attributed string with heading styles.
    ///
    /// Uses `.inlineOnlyPreservingWhitespace` to guarantee every `\n` renders as a
    /// visible line break (CommonMark `.full` collapses single `\n`). Headings
    /// (`# ` through `###### `) are stripped from the text and rendered as bold
    /// scaled fonts. `•` and `*` list markers are normalized to `- `.
    public static func renderFull(
        _ markdown: String,
        font: UIFont = LMKTypography.body,
        color: UIColor = LMKColor.textPrimary
    ) -> NSAttributedString {
        let (processed, headingRanges) = preprocessForInline(markdown)

        guard let attributedString = try? NSAttributedString(
            markdown: processed,
            options: AttributedString.MarkdownParsingOptions(
                interpretedSyntax: .inlineOnlyPreservingWhitespace
            )
        ) else {
            return NSAttributedString(string: markdown, attributes: [
                .font: font,
                .foregroundColor: color,
            ])
        }

        let mutable = NSMutableAttributedString(attributedString: applyBaseFont(to: attributedString, font: font, color: color))
        applyHeadingStyles(to: mutable, headingRanges: headingRanges, baseFont: font)
        return mutable
    }

    // MARK: - Inline Text View

    /// Create a pre-configured `UITextView` for inline markdown display.
    ///
    /// The returned view is read-only, non-scrolling, and transparent — designed
    /// to be embedded in a stack view or used inline within a layout.
    /// Links are styled with ``LMKColor/primary``.
    ///
    /// - Parameters:
    ///   - markdown: Markdown string to render.
    ///   - font: Base font for the text. Defaults to ``LMKTypography/body``.
    ///   - color: Base text color. Defaults to ``LMKColor/textPrimary``.
    /// - Returns: A configured `UITextView` with rendered markdown content.
    public static func makeInlineTextView(
        markdown: String,
        font: UIFont = LMKTypography.body,
        color: UIColor = LMKColor.textPrimary
    ) -> UITextView {
        let textView = UITextView()
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.linkTextAttributes = [.foregroundColor: LMKColor.primary]
        textView.attributedText = render(markdown, font: font, color: color)
        return textView
    }

    // MARK: - Private

    /// Heading info for post-parse styling.
    private struct HeadingInfo {
        let lineIndex: Int
        let level: Int
    }

    /// Heading scale factors relative to base font size.
    private static let headingScales: [Int: CGFloat] = [
        1: 1.6,
        2: 1.35,
        3: 1.15,
        4: 1.0,
        5: 0.9,
        6: 0.85,
    ]

    /// Pre-processes markdown for inline parsing:
    /// - Strips `# ` prefixes from headings (records their line indices and levels)
    /// - Converts `•` bullets to `-`
    /// - Leaves all `\n` intact so `.inlineOnlyPreservingWhitespace` preserves them
    private static func preprocessForInline(_ markdown: String) -> (String, [HeadingInfo]) {
        let lines = markdown.components(separatedBy: "\n")
        var result: [String] = []
        var headings: [HeadingInfo] = []

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Detect and strip heading prefixes (# through ######)
            if let headingLevel = detectHeadingLevel(trimmed) {
                let prefix = String(repeating: "#", count: headingLevel) + " "
                let content = String(trimmed.dropFirst(prefix.count))
                headings.append(HeadingInfo(lineIndex: result.count, level: headingLevel))
                result.append(content)
                continue
            }

            // Replace • and * list markers with - to avoid * being parsed as italic
            if trimmed.hasPrefix("•") {
                let indent = line.prefix(while: { $0 == " " || $0 == "\t" })
                result.append(indent + "-" + trimmed.dropFirst())
                continue
            }
            if trimmed.hasPrefix("* ") || trimmed.hasPrefix("*\t") {
                let indent = line.prefix(while: { $0 == " " || $0 == "\t" })
                result.append(indent + "-" + trimmed.dropFirst())
                continue
            }

            result.append(line)
        }

        return (result.joined(separator: "\n"), headings)
    }

    /// Returns the heading level (1-6) if the line starts with `# `, or nil.
    private static func detectHeadingLevel(_ trimmed: String) -> Int? {
        for level in (1 ... 6).reversed() {
            let prefix = String(repeating: "#", count: level) + " "
            if trimmed.hasPrefix(prefix) {
                return level
            }
        }
        return nil
    }

    /// Applies heading font styles to specific lines in the attributed string.
    /// Finds each heading line by scanning for `\n` boundaries and applies bold + scaled font.
    private static func applyHeadingStyles(
        to mutable: NSMutableAttributedString,
        headingRanges: [HeadingInfo],
        baseFont: UIFont
    ) {
        guard !headingRanges.isEmpty else { return }
        let string = mutable.string

        // Build a map of line index → NSRange
        var lineStart = string.startIndex
        var lineRanges: [NSRange] = []
        for line in string.split(separator: "\n", omittingEmptySubsequences: false) {
            let start = lineStart
            let end = string.index(start, offsetBy: line.count)
            let nsRange = NSRange(start ..< end, in: string)
            lineRanges.append(nsRange)
            // Advance past the \n
            lineStart = end < string.endIndex ? string.index(after: end) : string.endIndex
        }

        for heading in headingRanges {
            guard heading.lineIndex < lineRanges.count else { continue }
            let range = lineRanges[heading.lineIndex]
            guard range.length > 0 else { continue }

            let scale = headingScales[heading.level] ?? 1.0
            let headingSize = baseFont.pointSize * scale
            let traits: UIFontDescriptor.SymbolicTraits = .traitBold
            if let descriptor = baseFont.fontDescriptor.withSymbolicTraits(traits) {
                mutable.addAttribute(.font, value: UIFont(descriptor: descriptor, size: headingSize), range: range)
            }
        }
    }

    /// Re-applies base font and color while preserving bold/italic traits from markdown parsing.
    private static func applyBaseFont(
        to attributedString: NSAttributedString,
        font: UIFont,
        color: UIColor
    ) -> NSAttributedString {
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
