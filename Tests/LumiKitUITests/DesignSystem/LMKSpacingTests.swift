//
//  LMKSpacingTests.swift
//  LumiKit
//

import Testing
import UIKit

@testable import LumiKitUI

// MARK: - LMKSpacing

@Suite("LMKSpacing")
@MainActor
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

// MARK: - LMKSpacingTheme

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
