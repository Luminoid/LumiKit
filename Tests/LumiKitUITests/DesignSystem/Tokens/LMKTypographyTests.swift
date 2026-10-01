//
//  LMKTypographyTests.swift
//  LumiKit
//

import Testing
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
