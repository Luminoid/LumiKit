//
//  LMKBadgeThemeTests.swift
//  LumiKit
//

import Testing
import UIKit

@testable import LumiKitUI

// MARK: - LMKBadgeTheme

@Suite("LMKBadgeTheme")
@MainActor
struct LMKBadgeThemeTests {
    @Test("Default badge theme values")
    func defaultValues() {
        let config = LMKBadgeTheme()
        #expect(config.minWidth == 18)
        #expect(config.height == 18)
        #expect(config.horizontalPadding == 5)
        #expect(config.borderWidth == 1.5)
    }

    @Test("Custom badge theme applied via ThemeManager")
    func customTheme() {
        let original = LMKThemeManager.shared.badge
        defer { LMKThemeManager.shared.apply(badge: original) }

        LMKThemeManager.shared.apply(badge: .init(minWidth: 24, height: 24))
        #expect(LMKThemeManager.shared.badge.minWidth == 24)
        #expect(LMKThemeManager.shared.badge.height == 24)
    }
}
