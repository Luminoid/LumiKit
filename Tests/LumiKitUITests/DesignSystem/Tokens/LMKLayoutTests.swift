//
//  LMKLayoutTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

// MARK: - LMKLayout

@MainActor
struct LMKLayoutTests {
    @Test
    func `minimumTouchTarget meets Apple HIG`() {
        #expect(LMKLayout.minimumTouchTarget >= 44)
    }

    @Test
    func `Icon sizes are positive and ordered`() {
        #expect(LMKLayout.iconExtraSmall > 0)
        #expect(LMKLayout.iconSmall > LMKLayout.iconExtraSmall)
        #expect(LMKLayout.iconMedium > LMKLayout.iconSmall)
    }

    @Test
    func `Cell height minimum is positive`() {
        #expect(LMKLayout.cellHeightMin > 0)
    }
}

// MARK: - LMKLayoutTheme

@MainActor
struct LMKLayoutConfigurationTests {
    @Test
    func `Default layout matches original values`() {
        let config = LMKLayoutTheme()
        #expect(config.minimumTouchTarget == 44)
        #expect(config.iconMedium == 24)
        #expect(config.iconSmall == 20)
        #expect(config.iconExtraSmall == 16)
        #expect(config.iconCircle == 36)
        #expect(config.pullThreshold == 80)
        #expect(config.cellHeightMin == 100)
        #expect(config.searchBarHeight == 36)
        #expect(config.searchBarIconSize == 18)
        #expect(config.clearButtonSize == 22)
    }

    @Test
    func `Custom layout is applied via proxy`() {
        let original = LMKThemeManager.shared.layout
        defer { LMKThemeManager.shared.apply(layout: original) }

        LMKThemeManager.shared.apply(layout: .init(iconMedium: 28))
        #expect(LMKLayout.iconMedium == 28)
        #expect(LMKLayout.iconSmall == 20) // unchanged
    }

    @Test
    func `New search bar tokens are accessible`() {
        #expect(LMKLayout.searchBarHeight == 36)
        #expect(LMKLayout.searchBarIconSize == 18)
        #expect(LMKLayout.clearButtonSize == 22)
    }

    @Test
    func `Icon circle token is accessible and larger than the icon it wraps`() {
        #expect(LMKLayout.iconCircle == 36)
        #expect(LMKLayout.iconCircle > LMKLayout.iconExtraSmall)
    }
}
