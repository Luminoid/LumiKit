//
//  LMKMarkdownRendererTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

// MARK: - LMKMarkdownRenderer

@MainActor
struct LMKMarkdownRendererTests {
    @Test
    func `renders plain text without markdown`() {
        let result = LMKMarkdownRenderer.render("Hello world")
        #expect(result.string == "Hello world")
    }

    @Test
    func `strips bold markdown syntax from output text`() {
        let result = LMKMarkdownRenderer.render("This is **bold** text")
        #expect(result.string == "This is bold text")
    }

    @Test
    func `strips italic markdown syntax from output text`() {
        let result = LMKMarkdownRenderer.render("This is *italic* text")
        #expect(result.string == "This is italic text")
    }

    @Test
    func `applies custom font`() {
        let customFont = UIFont.systemFont(ofSize: 20)
        let result = LMKMarkdownRenderer.render("Hello", font: customFont)

        let font = result.attribute(.font, at: 0, effectiveRange: nil) as? UIFont
        #expect(font?.pointSize == 20)
    }

    @Test
    func `applies custom color across full range`() {
        let result = LMKMarkdownRenderer.render("**bold** and plain", color: .red)

        let fullRange = NSRange(location: 0, length: result.length)
        result.enumerateAttribute(.foregroundColor, in: fullRange) { value, _, _ in
            #expect(value as? UIColor == .red)
        }
    }

    @Test
    func `falls back to plain text for empty string`() {
        let result = LMKMarkdownRenderer.render("")
        #expect(result.string == "")
    }

    @Test
    func `handles mixed bold and italic`() {
        let result = LMKMarkdownRenderer.render("**bold** and *italic*")
        #expect(result.string == "bold and italic")
    }
}

// MARK: - LMKMarkdownRenderer (renderFull blocks)

@MainActor
struct LMKMarkdownRendererFullBlockTests {
    @Test
    func `prose-only renderFull matches the inline heading path`() {
        let markdown = "# Title\n\nSome **bold** text\n- one\n- two"
        let result = LMKMarkdownRenderer.renderFull(markdown)
        // Heading marker stripped, bold marker stripped, bullets normalized, newlines preserved.
        #expect(result.string == "Title\n\nSome bold text\n- one\n- two")
    }

    @Test
    func `fenced code block preserves content verbatim`() {
        let markdown = "Here:\n```swift\nlet x = 1\n```"
        let result = LMKMarkdownRenderer.renderFull(markdown)
        #expect(result.string.contains("let x = 1"))
    }

    @Test
    func `markdown inside a code block is not parsed`() {
        let markdown = "```\n**not bold**\n```"
        let result = LMKMarkdownRenderer.renderFull(markdown)
        // The literal asterisks survive because code blocks bypass the inline parser.
        #expect(result.string.contains("**not bold**"))
    }

    @Test
    func `code block uses a monospaced font`() {
        let markdown = "```\ncode\n```"
        let result = LMKMarkdownRenderer.renderFull(markdown)
        let index = (result.string as NSString).range(of: "code").location
        let font = result.attribute(.font, at: index, effectiveRange: nil) as? UIFont
        #expect(font?.fontDescriptor.symbolicTraits.contains(.traitMonoSpace) == true)
    }

    @Test
    func `table cells are rendered and pipe delimiters removed`() {
        let markdown = "| Name | Age |\n| --- | --- |\n| Ann | 30 |"
        let result = LMKMarkdownRenderer.renderFull(markdown)
        #expect(result.string.contains("Name"))
        #expect(result.string.contains("Ann"))
        #expect(result.string.contains("30"))
        // The raw markdown pipe-and-dash delimiter row should not appear literally.
        #expect(!result.string.contains("---"))
    }

    @Test
    func `table header row is bold and monospaced`() {
        let markdown = "| Name | Age |\n| --- | --- |\n| Ann | 30 |"
        let result = LMKMarkdownRenderer.renderFull(markdown)
        let index = (result.string as NSString).range(of: "Name").location
        let font = result.attribute(.font, at: index, effectiveRange: nil) as? UIFont
        #expect(font?.fontDescriptor.symbolicTraits.contains(.traitMonoSpace) == true)
        #expect(font?.fontDescriptor.symbolicTraits.contains(.traitBold) == true)
    }

    @Test
    func `prose around a code block is still parsed`() {
        let markdown = "Intro **bold**\n```\ncode\n```\nOutro"
        let result = LMKMarkdownRenderer.renderFull(markdown)
        #expect(result.string.contains("Intro bold")) // bold marker stripped in prose
        #expect(result.string.contains("code")) // code retained
        #expect(result.string.contains("Outro"))
    }
}

// MARK: - LMKMarkdownRenderer (makeInlineTextView)

@MainActor
struct LMKMarkdownRendererInlineTextViewTests {
    @Test
    func `isEditable is false`() {
        let tv = LMKMarkdownRenderer.makeInlineTextView(markdown: "Hello")
        #expect(!tv.isEditable)
    }

    @Test
    func `isScrollEnabled is false`() {
        let tv = LMKMarkdownRenderer.makeInlineTextView(markdown: "Hello")
        #expect(!tv.isScrollEnabled)
    }

    @Test
    func `backgroundColor is clear`() {
        let tv = LMKMarkdownRenderer.makeInlineTextView(markdown: "Hello")
        #expect(tv.backgroundColor == .clear)
    }

    @Test
    func `textContainerInset is zero`() {
        let tv = LMKMarkdownRenderer.makeInlineTextView(markdown: "Hello")
        #expect(tv.textContainerInset == .zero)
    }

    @Test
    func `lineFragmentPadding is zero`() {
        let tv = LMKMarkdownRenderer.makeInlineTextView(markdown: "Hello")
        #expect(tv.textContainer.lineFragmentPadding == 0)
    }

    @Test
    func `link color is LMKColor.primary`() {
        let tv = LMKMarkdownRenderer.makeInlineTextView(markdown: "[link](https://example.com)")
        #expect(tv.linkTextAttributes[.foregroundColor] as? UIColor == LMKColor.primary)
    }

    @Test
    func `attributedText is not nil`() {
        let tv = LMKMarkdownRenderer.makeInlineTextView(markdown: "**bold** text")
        #expect(tv.attributedText != nil)
        #expect(tv.attributedText.string == "bold text")
    }
}
