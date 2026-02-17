//
//  LMKThemeManagerTests.swift
//  LumiKit
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
            var imageBorder: UIColor { .separator }
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

// MARK: - LMKThemeManager.configure

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
