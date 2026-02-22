//
//  LMKShadowTests.swift
//  LumiKit
//

import Testing
import UIKit

@testable import LumiKitUI

// MARK: - LMKShadowTheme

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
