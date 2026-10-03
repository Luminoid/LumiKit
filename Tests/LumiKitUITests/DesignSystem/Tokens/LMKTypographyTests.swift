//
//  LMKTypographyTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

// MARK: - LMKTypography

@MainActor
struct LMKTypographyTests {
    @Test
    func `Heading fonts are larger than body`() {
        #expect(LMKTypography.h1.pointSize > LMKTypography.body.pointSize)
        #expect(LMKTypography.h2.pointSize >= LMKTypography.body.pointSize)
    }

    @Test
    func `Caption fonts are smaller than body`() {
        #expect(LMKTypography.caption.pointSize < LMKTypography.body.pointSize)
        #expect(LMKTypography.small.pointSize < LMKTypography.caption.pointSize)
    }

    @Test
    func `Italic body has italic trait`() {
        let traits = LMKTypography.italicBody.fontDescriptor.symbolicTraits
        #expect(traits.contains(.traitItalic))
    }

    @Test
    func `lineHeight returns positive value`() {
        let height = LMKTypography.lineHeight(for: LMKTypography.body, type: .body)
        #expect(height > 0)
    }

    @Test
    func `letterSpacing for heading is negative`() {
        #expect(LMKTypography.letterSpacing(for: .heading) < 0)
    }

    @Test
    func `lineHeightMultiplier reads the theme per kind`() {
        let theme = LMKThemeTesting.distinct.typography
        #expect(theme.lineHeightMultiplier(for: .heading) == 1.3)
        #expect(theme.lineHeightMultiplier(for: .body) == 1.6)
        #expect(theme.lineHeightMultiplier(for: .caption) == 1.45)
        #expect(theme.lineHeightMultiplier(for: .small) == 1.35)
        #expect(LMKTypography.lineHeightMultiplier(for: .body) == LMKTheme.current.typography.bodyLineHeightMultiplier)
    }
}

// MARK: - LMKTypographyTheme

@MainActor
struct LMKTypographyConfigurationTests {
    @Test
    func `Default typography matches original hardcoded values`() {
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

    @Test
    func `Custom font sizes are applied via proxy`() {
        let original = LMKTheme.current.typography
        defer { LMKTheme.update { $0.typography = original } }

        LMKTheme.update { $0.typography = .init(h1Size: 32, bodySize: 15) }
        #expect(LMKTypography.h1.pointSize == 32)
        #expect(LMKTypography.body.pointSize == 15)
    }

    @Test
    func `Custom font family is applied`() {
        let original = LMKTheme.current.typography
        defer { LMKTheme.update { $0.typography = original } }

        LMKTheme.update { $0.typography = .init(fontFamily: "Helvetica Neue") }
        let font = LMKTypography.h1
        #expect(font.familyName == "Helvetica Neue")
    }

    @Test
    func `Line height multipliers are configurable`() {
        let original = LMKTheme.current.typography
        defer { LMKTheme.update { $0.typography = original } }

        LMKTheme.update { $0.typography = .init(headingLineHeightMultiplier: 1.5) }
        #expect(LMKTypography.headingLineHeightMultiplier == 1.5)
    }

    @Test
    func `Letter spacing is configurable`() {
        let original = LMKTheme.current.typography
        defer { LMKTheme.update { $0.typography = original } }

        LMKTheme.update { $0.typography = .init(headingLetterSpacing: -1.0) }
        #expect(LMKTypography.headingLetterSpacing == -1.0)
        #expect(LMKTypography.letterSpacing(for: .heading) == -1.0)
    }

    @Test
    func `Default font family is system font`() {
        let original = LMKTheme.current.typography
        defer { LMKTheme.update { $0.typography = original } }

        LMKTheme.update { $0.typography = .init() }
        let font = LMKTypography.body
        // System font family varies by platform but should be non-empty
        #expect(!font.familyName.isEmpty)
    }
}

// MARK: - System design

@MainActor
struct LMKTypographySystemDesignTests {
    private func isRounded(_ font: UIFont) -> Bool {
        font.fontName.localizedCaseInsensitiveContains("rounded")
    }

    @Test
    func `Default design is the plain system font`() {
        let theme = LMKTypographyTheme()
        #expect(theme.fontDesign == .default)
        #expect(theme.headingFontDesign == nil)
        #expect(!isRounded(theme.baseFont(for: .h1)))
        #expect(!isRounded(theme.baseFont(for: .body)))
    }

    @Test
    func `Rounded design applies to every step at its size`() {
        let theme = LMKTypographyTheme(fontDesign: .rounded)
        for style in [LMKTextStyle.h1, .h4, .body, .bodyBold, .caption, .extraSmall] {
            #expect(isRounded(theme.baseFont(for: style)))
        }
        #expect(theme.baseFont(for: .body).pointSize == 16)
        #expect(theme.baseFont(for: .h1).pointSize == 28)
    }

    @Test
    func `Heading design overrides the heading steps only`() {
        let theme = LMKTypographyTheme(headingFontDesign: .rounded)
        #expect(isRounded(theme.baseFont(for: .h1)))
        #expect(isRounded(theme.baseFont(for: .h3)))
        #expect(!isRounded(theme.baseFont(for: .body)))
        #expect(!isRounded(theme.baseFont(for: .caption)))
        #expect(theme.systemDesign(for: .heading) == .rounded)
        #expect(theme.systemDesign(for: .body) == .default)
    }

    @Test
    func `Rounded design keeps Dynamic Type scaling`() {
        let theme = LMKTypographyTheme(fontDesign: .rounded)
        let traits = UITraitCollection(preferredContentSizeCategory: .accessibilityLarge)
        let font = theme.font(for: .body, compatibleWith: traits)
        #expect(font.pointSize > 16)
        #expect(isRounded(font))
    }

    @Test
    func `Italic steps stay italic under a design`() {
        let theme = LMKTypographyTheme(fontDesign: .rounded)
        #expect(theme.baseFont(for: .italicBody).fontDescriptor.symbolicTraits.contains(.traitItalic))
        #expect(theme.baseFont(for: .italicCaption).pointSize == 13)
    }

    @Test
    func `A custom family wins over the system design`() {
        let theme = LMKTypographyTheme(fontFamily: "Helvetica Neue", fontDesign: .rounded)
        #expect(theme.baseFont(for: .body).familyName == "Helvetica Neue")
    }
}
