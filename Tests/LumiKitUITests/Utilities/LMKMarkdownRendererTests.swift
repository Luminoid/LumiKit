//
//  LMKMarkdownRendererTests.swift
//  LumiKit
//

import Testing
import UIKit

@testable import LumiKitUI

// MARK: - LMKMarkdownRenderer

@Suite("LMKMarkdownRenderer")
@MainActor
struct LMKMarkdownRendererTests {
    @Test("renders plain text without markdown")
    func plainText() {
        let result = LMKMarkdownRenderer.render("Hello world")
        #expect(result.string == "Hello world")
    }

    @Test("strips bold markdown syntax from output text")
    func boldStripsMarkdown() {
        let result = LMKMarkdownRenderer.render("This is **bold** text")
        #expect(result.string == "This is bold text")
    }

    @Test("strips italic markdown syntax from output text")
    func italicStripsMarkdown() {
        let result = LMKMarkdownRenderer.render("This is *italic* text")
        #expect(result.string == "This is italic text")
    }

    @Test("applies custom font")
    func customFont() {
        let customFont = UIFont.systemFont(ofSize: 20)
        let result = LMKMarkdownRenderer.render("Hello", font: customFont)

        let font = result.attribute(.font, at: 0, effectiveRange: nil) as? UIFont
        #expect(font?.pointSize == 20)
    }

    @Test("applies custom color across full range")
    func customColor() {
        let result = LMKMarkdownRenderer.render("**bold** and plain", color: .red)

        let fullRange = NSRange(location: 0, length: result.length)
        result.enumerateAttribute(.foregroundColor, in: fullRange) { value, _, _ in
            #expect(value as? UIColor == .red)
        }
    }

    @Test("falls back to plain text for empty string")
    func emptyString() {
        let result = LMKMarkdownRenderer.render("")
        #expect(result.string == "")
    }

    @Test("handles mixed bold and italic")
    func mixedFormatting() {
        let result = LMKMarkdownRenderer.render("**bold** and *italic*")
        #expect(result.string == "bold and italic")
    }
}
