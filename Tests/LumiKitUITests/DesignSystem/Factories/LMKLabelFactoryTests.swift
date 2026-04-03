//
//  LMKLabelFactoryTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

// MARK: - LMKLabelFactory

@MainActor
struct LMKLabelFactoryTests {
    @Test
    func `heading creates label with h1 font by default`() {
        let label = LMKLabelFactory.heading(text: "Title")
        #expect(label.attributedText != nil)
        let font = label.attributedText?.attribute(.font, at: 0, effectiveRange: nil) as? UIFont
        #expect(font == LMKTypography.h1)
    }

    @Test
    func `heading level 2 uses h2 font`() {
        let label = LMKLabelFactory.heading(text: "Subtitle", level: 2)
        let font = label.attributedText?.attribute(.font, at: 0, effectiveRange: nil) as? UIFont
        #expect(font == LMKTypography.h2)
    }

    @Test
    func `heading level 3 uses h3 font`() {
        let label = LMKLabelFactory.heading(text: "Section", level: 3)
        let font = label.attributedText?.attribute(.font, at: 0, effectiveRange: nil) as? UIFont
        #expect(font == LMKTypography.h3)
    }

    @Test
    func `heading unknown level falls back to h4`() {
        let label = LMKLabelFactory.heading(text: "Small", level: 99)
        let font = label.attributedText?.attribute(.font, at: 0, effectiveRange: nil) as? UIFont
        #expect(font == LMKTypography.h4)
    }

    @Test
    func `body creates label with body font`() {
        let label = LMKLabelFactory.body(text: "Content")
        let font = label.attributedText?.attribute(.font, at: 0, effectiveRange: nil) as? UIFont
        #expect(font == LMKTypography.body)
    }

    @Test
    func `caption creates label with caption font`() {
        let label = LMKLabelFactory.caption(text: "Note")
        let font = label.attributedText?.attribute(.font, at: 0, effectiveRange: nil) as? UIFont
        #expect(font == LMKTypography.caption)
    }

    @Test
    func `small creates label with small font`() {
        let label = LMKLabelFactory.small(text: "Fine print")
        let font = label.attributedText?.attribute(.font, at: 0, effectiveRange: nil) as? UIFont
        #expect(font == LMKTypography.small)
    }

    @Test
    func `scientificName creates italic label with info color`() {
        let label = LMKLabelFactory.scientificName(text: "Monstera deliciosa")
        let font = label.attributedText?.attribute(.font, at: 0, effectiveRange: nil) as? UIFont
        #expect(font == LMKTypography.italicBody)
        let color = label.attributedText?.attribute(.foregroundColor, at: 0, effectiveRange: nil) as? UIColor
        #expect(color == LMKColor.info)
    }

    @Test
    func `Labels have numberOfLines set to 0`() {
        let label = LMKLabelFactory.body(text: "Multi-line")
        #expect(label.numberOfLines == 0)
    }

    @Test
    func `attributedString includes line height and letter spacing`() throws {
        let attrString = LMKLabelFactory.attributedString(
            text: "Test",
            font: LMKTypography.body,
            color: LMKColor.textPrimary,
            type: .body
        )
        let paragraphStyle = attrString.attribute(.paragraphStyle, at: 0, effectiveRange: nil) as? NSParagraphStyle
        #expect(paragraphStyle != nil)
        #expect(try #require(paragraphStyle?.minimumLineHeight) > 0)
        let kern = attrString.attribute(.kern, at: 0, effectiveRange: nil) as? CGFloat
        #expect(kern != nil)
    }
}
