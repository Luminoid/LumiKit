//
//  LumiKitUITests.swift
//  LumiKit
//
//  Tests for LumiKitUI: ThemeManager, Color, AlertPresenter,
//  Spacing, CornerRadius, Alpha, Typography, Layout, CropAspectRatio.
//

import Testing
import UIKit

@testable import LumiKitUI

// MARK: - LMKThemeManager

@Suite("LMKThemeManager")
@MainActor
struct LMKThemeManagerTests {
    @Test("Default theme is LMKDefaultTheme")
    func defaultTheme() {
        let theme = LMKThemeManager.shared.current
        // Default theme returns systemGreen for primary
        #expect(theme.primary == UIColor.systemGreen)
    }

    @Test("Apply custom theme changes current")
    func applyCustomTheme() {
        struct TestTheme: LMKTheme {
            var primary: UIColor { .systemPurple }
            var primaryDark: UIColor { .systemPurple }
            var secondary: UIColor { .systemGray }
            var tertiary: UIColor { .systemBrown }
            var success: UIColor { .systemGreen }
            var warning: UIColor { .systemOrange }
            var error: UIColor { .systemRed }
            var info: UIColor { .systemBlue }
            var textPrimary: UIColor { .label }
            var textSecondary: UIColor { .secondaryLabel }
            var textTertiary: UIColor { .tertiaryLabel }
            var backgroundPrimary: UIColor { .systemBackground }
            var backgroundSecondary: UIColor { .secondarySystemBackground }
            var backgroundTertiary: UIColor { .tertiarySystemBackground }
            var divider: UIColor { .separator }
            var graySoft: UIColor { .systemGray4 }
            var grayMuted: UIColor { .systemGray5 }
            var white: UIColor { .white }
            var black: UIColor { .black }
        }

        LMKThemeManager.shared.apply(TestTheme())
        #expect(LMKThemeManager.shared.current.primary == UIColor.systemPurple)

        // Restore default
        LMKThemeManager.shared.apply(LMKDefaultTheme())
    }
}

// MARK: - LMKColor

@Suite("LMKColor")
@MainActor
struct LMKColorTests {
    @Test("LMKColor proxies to active theme")
    func colorProxiesToTheme() {
        LMKThemeManager.shared.apply(LMKDefaultTheme())
        #expect(LMKColor.primary == LMKThemeManager.shared.current.primary)
        #expect(LMKColor.error == LMKThemeManager.shared.current.error)
        #expect(LMKColor.textPrimary == LMKThemeManager.shared.current.textPrimary)
    }

    @Test("LMKColor.clear is UIColor.clear")
    func clearColor() {
        #expect(LMKColor.clear == UIColor.clear)
    }
}

// MARK: - LMKAlertPresenter

@Suite("LMKAlertPresenter")
struct LMKAlertPresenterTests {
    @Test("Default strings are English")
    func defaultStrings() {
        let strings = LMKAlertPresenter.Strings()
        #expect(strings.ok == "OK")
        #expect(strings.cancel == "Cancel")
    }

    @Test("Custom strings are preserved")
    func customStrings() {
        let strings = LMKAlertPresenter.Strings(ok: "Aceptar", cancel: "Cancelar")
        #expect(strings.ok == "Aceptar")
        #expect(strings.cancel == "Cancelar")
    }

    @Test("Static strings can be overridden")
    func overrideStaticStrings() {
        let original = LMKAlertPresenter.strings
        LMKAlertPresenter.strings = .init(ok: "OK!", cancel: "Nah")
        #expect(LMKAlertPresenter.strings.ok == "OK!")
        #expect(LMKAlertPresenter.strings.cancel == "Nah")
        // Restore
        LMKAlertPresenter.strings = original
    }
}

// MARK: - LMKSpacing

@Suite("LMKSpacing")
struct LMKSpacingTests {
    @Test("Spacing values follow 4pt grid")
    func spacingGrid() {
        #expect(LMKSpacing.xxs == 2)
        #expect(LMKSpacing.xs == 4)
        #expect(LMKSpacing.small == 8)
        #expect(LMKSpacing.medium == 12)
        #expect(LMKSpacing.large == 16)
        #expect(LMKSpacing.xl == 20)
        #expect(LMKSpacing.xxl == 24)
    }
}

// MARK: - LMKCornerRadius

@Suite("LMKCornerRadius")
struct LMKCornerRadiusTests {
    @Test("Corner radii are positive and ordered")
    func cornerRadiiOrdered() {
        #expect(LMKCornerRadius.xs > 0)
        #expect(LMKCornerRadius.small > LMKCornerRadius.xs)
        #expect(LMKCornerRadius.medium > LMKCornerRadius.small)
        #expect(LMKCornerRadius.large > LMKCornerRadius.medium)
        #expect(LMKCornerRadius.xlarge > LMKCornerRadius.large)
    }
}

// MARK: - LMKAlpha

@Suite("LMKAlpha")
struct LMKAlphaTests {
    @Test("Alpha values are between 0 and 1")
    func alphaRange() {
        #expect(LMKAlpha.overlay > 0 && LMKAlpha.overlay <= 1)
        #expect(LMKAlpha.overlayStrong > 0 && LMKAlpha.overlayStrong <= 1)
        #expect(LMKAlpha.overlayOpaque > 0 && LMKAlpha.overlayOpaque <= 1)
    }

    @Test("Alpha values are ordered by intensity")
    func alphaOrdered() {
        #expect(LMKAlpha.overlay < LMKAlpha.overlayStrong)
        #expect(LMKAlpha.overlayStrong < LMKAlpha.overlayOpaque)
    }
}

// MARK: - LMKTypography

@Suite("LMKTypography")
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

// MARK: - LMKLayout

@Suite("LMKLayout")
struct LMKLayoutTests {
    @Test("minimumTouchTarget meets Apple HIG")
    func minimumTouchTarget() {
        #expect(LMKLayout.minimumTouchTarget >= 44)
    }

    @Test("Icon sizes are positive and ordered")
    func iconSizes() {
        #expect(LMKLayout.iconExtraSmall > 0)
        #expect(LMKLayout.iconSmall > LMKLayout.iconExtraSmall)
        #expect(LMKLayout.iconMedium > LMKLayout.iconSmall)
    }

    @Test("Cell height minimum is positive")
    func cellHeightMin() {
        #expect(LMKLayout.cellHeightMin > 0)
    }
}

// MARK: - LMKCropAspectRatio

@Suite("LMKCropAspectRatio")
struct CropAspectRatioTests {
    @Test("Square ratio is 1.0")
    func squareRatio() {
        #expect(LMKCropAspectRatio.square.ratio == 1.0)
    }

    @Test("Free ratio is nil")
    func freeRatio() {
        #expect(LMKCropAspectRatio.free.ratio == nil)
    }

    @Test("All cases have display names")
    func allCasesHaveDisplayNames() {
        for ratio in LMKCropAspectRatio.allCases {
            #expect(!ratio.displayName.isEmpty)
        }
    }

    @Test("4:3 ratio is approximately 1.33")
    func fourThreeRatio() {
        let ratio = LMKCropAspectRatio.fourThree.ratio!
        #expect(abs(ratio - 4.0 / 3.0) < 0.001)
    }
}
