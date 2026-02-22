//
//  LMKLayoutTests.swift
//  LumiKit
//

import Testing
import UIKit

@testable import LumiKitUI

// MARK: - LMKLayout

@Suite("LMKLayout")
@MainActor
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

// MARK: - LMKLayoutTheme

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
