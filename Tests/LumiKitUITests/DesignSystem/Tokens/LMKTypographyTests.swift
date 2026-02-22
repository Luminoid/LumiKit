//
//  LMKTypographyTests.swift
//  LumiKit
//

import Testing
import UIKit

@testable import LumiKitUI

// MARK: - LMKTypography

@Suite("LMKTypography")
@MainActor
struct LMKTypographyTests {
    @Test("Heading fonts are larger than body")
    func headingLargerThanBody() {
        #expect(LMKTypography.h1.pointSize > LMKTypography.body.pointSize)
        #expect(LMKTypography.h2.pointSize >= LMKTypography.body.pointSize)
    }

    @Test("Caption fonts are smaller than body")
    func captionSmallerThanBody() {
        #expect(LMKTypography.caption.pointSize < LMKTypography.body.pointSize)
        #expect(LMKTypography.small.pointSize < LMKTypography.caption.pointSize)
    }

    @Test("Italic body has italic trait")
    func italicBodyHasItalicTrait() {
        let traits = LMKTypography.italicBody.fontDescriptor.symbolicTraits
        #expect(traits.contains(.traitItalic))
    }

    @Test("lineHeight returns positive value")
    func lineHeightPositive() {
        let height = LMKTypography.lineHeight(for: LMKTypography.body, type: .body)
        #expect(height > 0)
    }

    @Test("letterSpacing for heading is negative")
    func letterSpacingHeading() {
        #expect(LMKTypography.letterSpacing(for: .heading) < 0)
    }
}

// MARK: - LMKTypographyTheme

@Suite("LMKTypographyTheme")
@MainActor
struct LMKTypographyConfigurationTests {
    @Test("Default typography matches original hardcoded values")
    func defaultTypography() {
        let config = LMKTypographyTheme()
        #expect(config.h1Size == 28)
        #expect(config.h2Size == 22)
        #expect(config.h3Size == 18)
        #expect(config.h4Size == 16)
        #expect(config.bodySize == 16)
        #expect(config.subbodySize == 14)
        #expect(config.captionSize == 13)
        #expect(config.smallSize == 12)
        #expect(config.extraSmallSize == 11)
        #expect(config.extraExtraSmallSize == 10)
        #expect(config.fontFamily == nil)
    }

    @Test("Custom font sizes are applied via proxy")
    func customFontSizes() {
        let original = LMKThemeManager.shared.typography
        defer { LMKThemeManager.shared.apply(typography: original) }

        LMKThemeManager.shared.apply(typography: .init(h1Size: 32, bodySize: 15))
        #expect(LMKTypography.h1.pointSize == 32)
        #expect(LMKTypography.body.pointSize == 15)
    }

    @Test("Custom font family is applied")
    func customFontFamily() {
        let original = LMKThemeManager.shared.typography
        defer { LMKThemeManager.shared.apply(typography: original) }

        LMKThemeManager.shared.apply(typography: .init(fontFamily: "Helvetica Neue"))
        let font = LMKTypography.h1
        #expect(font.familyName == "Helvetica Neue")
    }

    @Test("Line height multipliers are configurable")
    func lineHeightMultipliers() {
        let original = LMKThemeManager.shared.typography
        defer { LMKThemeManager.shared.apply(typography: original) }

        LMKThemeManager.shared.apply(typography: .init(headingLineHeightMultiplier: 1.5))
        #expect(LMKTypography.headingLineHeightMultiplier == 1.5)
    }

    @Test("Letter spacing is configurable")
    func letterSpacing() {
        let original = LMKThemeManager.shared.typography
        defer { LMKThemeManager.shared.apply(typography: original) }

        LMKThemeManager.shared.apply(typography: .init(headingLetterSpacing: -1.0))
        #expect(LMKTypography.headingLetterSpacing == -1.0)
        #expect(LMKTypography.letterSpacing(for: .heading) == -1.0)
    }

    @Test("Default font family is system font")
    func defaultIsSystemFont() {
        let original = LMKThemeManager.shared.typography
        defer { LMKThemeManager.shared.apply(typography: original) }

        LMKThemeManager.shared.apply(typography: .init())
        let font = LMKTypography.body
        // System font family varies by platform but should be non-empty
        #expect(!font.familyName.isEmpty)
    }
}
