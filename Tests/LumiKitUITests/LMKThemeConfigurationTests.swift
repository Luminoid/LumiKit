//
//  LMKThemeConfigurationTests.swift
//  LumiKit
//
//  Tests for the configurable design token system.
//

import Testing
import UIKit

@testable import LumiKitUI

// MARK: - Typography Configuration

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

// MARK: - Spacing Configuration

@Suite("LMKSpacingTheme")
@MainActor
struct LMKSpacingConfigurationTests {
    @Test("Default spacing matches original values")
    func defaultSpacing() {
        let config = LMKSpacingTheme()
        #expect(config.xxs == 2)
        #expect(config.xs == 4)
        #expect(config.small == 8)
        #expect(config.medium == 12)
        #expect(config.large == 16)
        #expect(config.xl == 20)
        #expect(config.xxl == 24)
        #expect(config.buttonPaddingVertical == 12)
        #expect(config.buttonPaddingHorizontal == 16)
    }

    @Test("Custom spacing is applied via proxy")
    func customSpacing() {
        let original = LMKThemeManager.shared.spacing
        defer { LMKThemeManager.shared.apply(spacing: original) }

        LMKThemeManager.shared.apply(spacing: .init(large: 20, xxl: 28))
        #expect(LMKSpacing.large == 20)
        #expect(LMKSpacing.xxl == 28)
        // Other values stay at defaults
        #expect(LMKSpacing.small == 8)
    }
}

// MARK: - Corner Radius Configuration

@Suite("LMKCornerRadiusTheme")
@MainActor
struct LMKCornerRadiusConfigurationTests {
    @Test("Default corner radius matches original values")
    func defaultCornerRadius() {
        let config = LMKCornerRadiusTheme()
        #expect(config.xs == 4)
        #expect(config.small == 8)
        #expect(config.medium == 12)
        #expect(config.large == 16)
        #expect(config.xlarge == 20)
        #expect(config.circular == 999)
    }

    @Test("Custom corner radius is applied via proxy")
    func customCornerRadius() {
        let original = LMKThemeManager.shared.cornerRadius
        defer { LMKThemeManager.shared.apply(cornerRadius: original) }

        LMKThemeManager.shared.apply(cornerRadius: .init(small: 12, medium: 16))
        #expect(LMKCornerRadius.small == 12)
        #expect(LMKCornerRadius.medium == 16)
        #expect(LMKCornerRadius.xs == 4) // unchanged
    }
}

// MARK: - Alpha Configuration

@Suite("LMKAlphaTheme")
@MainActor
struct LMKAlphaConfigurationTests {
    @Test("Default alpha matches original values")
    func defaultAlpha() {
        let config = LMKAlphaTheme()
        #expect(config.overlay == 0.5)
        #expect(config.dimmingOverlay == 0.4)
        #expect(config.disabled == 0.5)
        #expect(config.overlayStrong == 0.7)
        #expect(config.overlayLight == 0.1)
        #expect(config.overlayOpaque == 0.8)
    }

    @Test("Custom alpha is applied via proxy")
    func customAlpha() {
        let original = LMKThemeManager.shared.alpha
        defer { LMKThemeManager.shared.apply(alpha: original) }

        LMKThemeManager.shared.apply(alpha: .init(disabled: 0.3))
        #expect(LMKAlpha.disabled == 0.3)
        #expect(LMKAlpha.overlay == 0.5) // unchanged
    }
}

// MARK: - Shadow Configuration

@Suite("LMKShadowTheme")
@MainActor
struct LMKShadowConfigurationTests {
    @Test("Default shadow matches original values")
    func defaultShadow() {
        let config = LMKShadowTheme()
        #expect(config.cellCardRadius == 6)
        #expect(config.cardRadius == 8)
        #expect(config.buttonRadius == 4)
        #expect(config.smallRadius == 2)
        #expect(config.iconOverlayOpacity == 0.8)
    }

    @Test("Custom shadow is applied via proxy")
    func customShadow() {
        let original = LMKThemeManager.shared.shadow
        defer { LMKThemeManager.shared.apply(shadow: original) }

        LMKThemeManager.shared.apply(shadow: .init(cellCardRadius: 10, cardRadius: 14))
        let cellCard = LMKShadow.cellCard()
        let card = LMKShadow.card()
        #expect(cellCard.radius == 10)
        #expect(card.radius == 14)
    }
}

// MARK: - Layout Configuration

@Suite("LMKLayoutTheme")
@MainActor
struct LMKLayoutConfigurationTests {
    @Test("Default layout matches original values")
    func defaultLayout() {
        let config = LMKLayoutTheme()
        #expect(config.minimumTouchTarget == 44)
        #expect(config.iconMedium == 24)
        #expect(config.iconSmall == 20)
        #expect(config.iconExtraSmall == 16)
        #expect(config.pullThreshold == 80)
        #expect(config.cellHeightMin == 100)
        #expect(config.searchBarHeight == 36)
        #expect(config.searchBarIconSize == 18)
        #expect(config.clearButtonSize == 22)
    }

    @Test("Custom layout is applied via proxy")
    func customLayout() {
        let original = LMKThemeManager.shared.layout
        defer { LMKThemeManager.shared.apply(layout: original) }

        LMKThemeManager.shared.apply(layout: .init(iconMedium: 28))
        #expect(LMKLayout.iconMedium == 28)
        #expect(LMKLayout.iconSmall == 20) // unchanged
    }

    @Test("New search bar tokens are accessible")
    func searchBarTokens() {
        #expect(LMKLayout.searchBarHeight == 36)
        #expect(LMKLayout.searchBarIconSize == 18)
        #expect(LMKLayout.clearButtonSize == 22)
    }
}

// MARK: - Animation Configuration

@Suite("LMKAnimationTheme")
@MainActor
struct LMKAnimationConfigurationTests {
    @Test("Default animation matches original values")
    func defaultAnimation() {
        let config = LMKAnimationTheme()
        #expect(config.screenTransition == 0.35)
        #expect(config.modalPresentation == 0.3)
        #expect(config.actionSheet == 0.25)
        #expect(config.alert == 0.2)
        #expect(config.buttonPress == 0.1)
        #expect(config.springDamping == 0.8)
    }

    @Test("Custom animation is applied via proxy")
    func customAnimation() {
        let original = LMKThemeManager.shared.animation
        defer { LMKThemeManager.shared.apply(animation: original) }

        LMKThemeManager.shared.apply(animation: .init(modalPresentation: 0.25, springDamping: 0.7))
        #expect(LMKAnimationHelper.Duration.modalPresentation == 0.25)
        #expect(LMKAnimationHelper.Spring.damping == 0.7)
        #expect(LMKAnimationHelper.Duration.alert == 0.2) // unchanged
    }
}

// MARK: - ThemeManager Configure All-in-One

@Suite("LMKThemeManager.configure")
@MainActor
struct LMKThemeManagerConfigureTests {
    @Test("Configure applies multiple categories at once")
    func configureMultipleCategories() {
        let originalTypography = LMKThemeManager.shared.typography
        let originalSpacing = LMKThemeManager.shared.spacing
        defer {
            LMKThemeManager.shared.apply(typography: originalTypography)
            LMKThemeManager.shared.apply(spacing: originalSpacing)
        }

        LMKThemeManager.shared.configure(
            typography: .init(h1Size: 30),
            spacing: .init(large: 18)
        )
        #expect(LMKTypography.h1.pointSize == 30)
        #expect(LMKSpacing.large == 18)
    }

    @Test("Configure only applies provided categories")
    func configurePartial() {
        let originalSpacing = LMKThemeManager.shared.spacing
        defer { LMKThemeManager.shared.apply(spacing: originalSpacing) }

        LMKThemeManager.shared.configure(spacing: .init(xxl: 32))
        #expect(LMKSpacing.xxl == 32)
        // Typography should be unchanged (default)
        #expect(LMKThemeManager.shared.typography.h1Size == 28)
    }
}

// MARK: - Configuration Structs Sendable

@Suite("Sendable compliance")
struct SendableComplianceTests {
    @Test("All configuration structs are Sendable")
    func sendableStructs() {
        func checkSendable<T: Sendable>(_ value: T) { _ = value }

        checkSendable(LMKTypographyTheme())
        checkSendable(LMKSpacingTheme())
        checkSendable(LMKCornerRadiusTheme())
        checkSendable(LMKAlphaTheme())
        checkSendable(LMKShadowTheme())
        checkSendable(LMKLayoutTheme())
        checkSendable(LMKAnimationTheme())
    }
}

// MARK: - ErrorHandler

@Suite("LMKErrorHandler")
@MainActor
struct LMKErrorHandlerTests {
    @Test("Default error handler strings are English")
    func defaultStrings() {
        let strings = LMKErrorHandler.Strings()
        #expect(strings.errorTitle == "Error")
        #expect(strings.retry == "Retry")
        #expect(strings.ok == "OK")
        #expect(strings.warningTitle == "Warning")
        #expect(strings.infoTitle == "Info")
    }

    @Test("Custom error handler strings are preserved")
    func customStrings() {
        let strings = LMKErrorHandler.Strings(errorTitle: "Oops", retry: "Again", ok: "Done")
        #expect(strings.errorTitle == "Oops")
        #expect(strings.retry == "Again")
        #expect(strings.ok == "Done")
    }

    @Test("Severity enum has all expected cases")
    func severityCases() {
        let cases: [LMKErrorHandler.Severity] = [.info, .warning, .error, .critical]
        #expect(cases.count == 4)
    }

    @Test("Static strings can be overridden")
    func overrideStaticStrings() {
        let original = LMKErrorHandler.strings
        defer { LMKErrorHandler.strings = original }

        LMKErrorHandler.strings = .init(errorTitle: "Fallo", retry: "Reintentar", ok: "Aceptar", warningTitle: "Aviso", infoTitle: "Info")
        #expect(LMKErrorHandler.strings.errorTitle == "Fallo")
        #expect(LMKErrorHandler.strings.retry == "Reintentar")
    }
}

// MARK: - Component Configuration

@Suite("Component token usage")
@MainActor
struct ComponentTokenTests {
    @Test("LMKToastView creates with correct type")
    func toastViewCreation() {
        let toast = LMKToastView(type: .success, message: "Test")
        #expect(toast.superview == nil) // Not added to any view yet
    }

    @Test("LMKEmptyStateView can be configured")
    func emptyStateViewConfiguration() {
        let emptyState = LMKEmptyStateView()
        emptyState.configure(
            message: "No items found",
            icon: "tray",
            style: .fullScreen
        )
        // Just verify it doesn't crash with the configuration
        #expect(emptyState.frame.size == .zero) // Not laid out yet
    }

    @Test("LMKButton handlers work")
    func buttonHandlers() {
        var tapped = false
        let button = LMKButton()
        button.didTapHandler = { _ in tapped = true }
        button.didTap()
        #expect(tapped)
    }
}
