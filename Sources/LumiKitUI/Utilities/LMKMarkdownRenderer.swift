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
/// - **Full**: Headings, lists, bold, italic, fenced code blocks, and GFM tables — suitable for
///   long-form content such as AI chat responses. Prose uses inline parsing so every `\n` is a
///   visible line break; code and tables render in a monospaced font.
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

    /// Render long-form markdown as an attributed string.
    ///
    /// Block-aware: the text is split into fenced code blocks (```` ``` ````), GitHub-style tables
    /// (`| a | b |` + `|---|`), and normal prose. Code and tables render in a monospaced font (code
    /// gets a subtle background; tables get tab-stop-aligned columns with a full-width header rule)
    /// so an AI response that emits them stays readable instead of collapsing to a run-on line. Normal prose
    /// keeps the inline pipeline: headings (`# ` through `###### `) become bold scaled fonts, `•` / `*`
    /// markers normalize to `- `, and `.inlineOnlyPreservingWhitespace` preserves every `\n`. Input
    /// with no code/table blocks renders identically to the prose-only path.
    public static func renderFull(
        _ markdown: String,
        font: UIFont = LMKTypography.body,
        color: UIColor = LMKColor.textPrimary
    ) -> NSAttributedString {
        let result = NSMutableAttributedString()
        let lines = markdown.components(separatedBy: "\n")
        var index = 0
        var prose: [String] = []

        func flushProse() {
            guard !prose.isEmpty else { return }
            appendBlock(result, renderInlineBlock(prose.joined(separator: "\n"), font: font, color: color))
            prose.removeAll()
        }

        while index < lines.count {
            let line = lines[index]
            if isCodeFence(line) {
                flushProse()
                var code: [String] = []
                index += 1
                while index < lines.count, !isCodeFence(lines[index]) {
                    code.append(lines[index])
                    index += 1
                }
                if index < lines.count { index += 1 } // consume the closing fence
                appendBlock(result, renderCodeBlock(code.joined(separator: "\n"), font: font, color: color))
                continue
            }
            if isTableHeader(lines, at: index) {
                flushProse()
                var table: [String] = []
                while index < lines.count, isTableRow(lines[index]) {
                    table.append(lines[index])
                    index += 1
                }
                appendBlock(result, renderTable(table, font: font, color: color))
                continue
            }
            prose.append(line)
            index += 1
        }
        flushProse()
        return result
    }

    /// Inline pipeline for a prose-only span: headings, list-marker normalization, bold/italic, with
    /// every `\n` preserved. This is the historical `renderFull` body, now one block kind among several.
    private static func renderInlineBlock(
        _ markdown: String,
        font: UIFont,
        color: UIColor
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

    // MARK: - Block assembly

    /// Append a rendered block, inserting a single newline separator when the previous block didn't
    /// already end in one. Keeps code/table blocks visually separated from surrounding prose.
    private static func appendBlock(_ result: NSMutableAttributedString, _ block: NSAttributedString) {
        if result.length > 0, !result.string.hasSuffix("\n") {
            result.append(NSAttributedString(string: "\n"))
        }
        result.append(block)
    }

    private static func isCodeFence(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        return trimmed.hasPrefix("```") || trimmed.hasPrefix("~~~")
    }

    /// Monospaced block with a subtle backing color. `.backgroundColor` paints behind the glyphs only
    /// (a UILabel can't host a full-width rounded box), which still reads clearly as code.
    private static func renderCodeBlock(
        _ code: String,
        font: UIFont,
        color: UIColor
    ) -> NSAttributedString {
        let mono = UIFont.monospacedSystemFont(ofSize: font.pointSize, weight: .regular)
        let paragraph = NSMutableParagraphStyle()
        paragraph.firstLineHeadIndent = 4
        paragraph.headIndent = 4
        paragraph.paragraphSpacingBefore = 2
        paragraph.paragraphSpacing = 2
        return NSAttributedString(string: code, attributes: [
            .font: mono,
            .foregroundColor: color,
            .backgroundColor: LMKColor.backgroundTertiary,
            .paragraphStyle: paragraph,
        ])
    }

    // MARK: - Tables

    /// A header row plus a delimiter row (`|---|:--:|`) immediately below marks a GFM table.
    private static func isTableHeader(_ lines: [String], at index: Int) -> Bool {
        guard index + 1 < lines.count else { return false }
        return isTableRow(lines[index]) && isTableDelimiter(lines[index + 1])
    }

    private static func isTableRow(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        return !trimmed.isEmpty && trimmed.contains("|")
    }

    private static func isTableDelimiter(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard trimmed.contains("-"), trimmed.contains("|") else { return false }
        let allowed = CharacterSet(charactersIn: "-:| \t")
        return trimmed.unicodeScalars.allSatisfy { allowed.contains($0) }
    }

    private static func parseRowCells(_ line: String) -> [String] {
        var trimmed = line.trimmingCharacters(in: .whitespaces)
        if trimmed.hasPrefix("|") { trimmed.removeFirst() }
        if trimmed.hasSuffix("|") { trimmed.removeLast() }
        return trimmed.components(separatedBy: "|").map { $0.trimmingCharacters(in: .whitespaces) }
    }

    /// Render the collected table lines as tab-stop-aligned monospaced columns: a bold header, a
    /// full-width `─` rule, then the body rows. Column positions are `NSTextTab` stops measured in
    /// points from the rendered cell widths, so wide glyphs (CJK) and any per-glyph spacing align
    /// exactly instead of drifting the way character-count padding does. Rows clip rather than wrap
    /// (`.byClipping`) so the grid never breaks mid-row; a table wider than its container is the
    /// caller's cue to host it in a horizontally scrollable text view.
    private static func renderTable(
        _ lines: [String],
        font: UIFont,
        color: UIColor
    ) -> NSAttributedString {
        let rows = lines.filter { !isTableDelimiter($0) }.map(parseRowCells)
        guard !rows.isEmpty else {
            return renderCodeBlock(lines.joined(separator: "\n"), font: font, color: color)
        }
        let columnCount = rows.map(\.count).max() ?? 0
        let mono = UIFont.monospacedSystemFont(ofSize: font.pointSize, weight: .regular)
        let bold = UIFont.monospacedSystemFont(ofSize: font.pointSize, weight: .semibold)

        // Per-column width in points, measured against the font each row will use (header is bold).
        var columnWidths = [CGFloat](repeating: 0, count: columnCount)
        for (rowIndex, row) in rows.enumerated() {
            let rowFont = rowIndex == 0 ? bold : mono
            for (column, cell) in row.enumerated() {
                let width = (cell as NSString).size(withAttributes: [.font: rowFont]).width
                columnWidths[column] = max(columnWidths[column], width)
            }
        }

        // A two-space gap between columns; tab stops sit at the start of columns 1...n-1.
        let gap = ("  " as NSString).size(withAttributes: [.font: mono]).width
        var tabStops: [NSTextTab] = []
        var position: CGFloat = 0
        for column in 0 ..< max(0, columnCount - 1) {
            position += ceil(columnWidths[column]) + gap
            tabStops.append(NSTextTab(textAlignment: .left, location: position, options: [:]))
        }
        let totalWidth = position + ceil(columnWidths.last ?? 0)

        func tableParagraph() -> NSMutableParagraphStyle {
            let paragraph = NSMutableParagraphStyle()
            paragraph.tabStops = tabStops
            paragraph.lineBreakMode = .byClipping
            return paragraph
        }

        let result = NSMutableAttributedString()
        for (rowIndex, row) in rows.enumerated() {
            let line = (0 ..< columnCount)
                .map { column in column < row.count ? row[column] : "" }
                .joined(separator: "\t")
            result.append(NSAttributedString(string: line, attributes: [
                .font: rowIndex == 0 ? bold : mono,
                .foregroundColor: color,
                .paragraphStyle: tableParagraph(),
            ]))
            result.append(NSAttributedString(string: "\n"))
            if rowIndex == 0 {
                let dashWidth = ("─" as NSString).size(withAttributes: [.font: mono]).width
                let dashCount = max(1, Int((totalWidth / dashWidth).rounded()))
                let rulePara = NSMutableParagraphStyle()
                rulePara.lineBreakMode = .byClipping
                result.append(NSAttributedString(string: String(repeating: "─", count: dashCount), attributes: [
                    .font: mono,
                    .foregroundColor: color.withAlphaComponent(0.4),
                    .paragraphStyle: rulePara,
                ]))
                result.append(NSAttributedString(string: "\n"))
            }
        }
        if result.string.hasSuffix("\n") {
            result.deleteCharacters(in: NSRange(location: result.length - 1, length: 1))
        }
        return result
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
    /// - Normalizes unordered bullets (`•`, `*`, `+`, `-`) + trailing whitespace to `- `
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

            // Normalize unordered list markers (•, *, +, -) and their trailing whitespace to a
            // single "- " so every bullet renders with the same marker and gap regardless of the
            // source style. Without collapsing the gap, "*   item" and "- item" would render with
            // different bullet-to-text spacing.
            if let content = unorderedListContent(trimmed) {
                let indent = line.prefix(while: { $0 == " " || $0 == "\t" })
                result.append(indent + "- " + content)
                continue
            }

            result.append(line)
        }

        return (result.joined(separator: "\n"), headings)
    }

    /// If `trimmed` is an unordered list item, returns the content after the marker and its
    /// trailing whitespace; otherwise `nil`. `•` is treated as a bullet even without a following
    /// space (it's never an inline-formatting character); `*`, `+`, and `-` require following
    /// whitespace so `**bold**`, `*italic*`, and `---` are not mistaken for bullets.
    private static func unorderedListContent(_ trimmed: String) -> String? {
        guard let first = trimmed.first else { return nil }
        if first == "•" {
            return String(trimmed.dropFirst().drop(while: { $0 == " " || $0 == "\t" }))
        }
        guard first == "*" || first == "+" || first == "-" else { return nil }
        let afterMarker = trimmed.dropFirst()
        guard let next = afterMarker.first, next == " " || next == "\t" else { return nil }
        return String(afterMarker.drop(while: { $0 == " " || $0 == "\t" }))
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
