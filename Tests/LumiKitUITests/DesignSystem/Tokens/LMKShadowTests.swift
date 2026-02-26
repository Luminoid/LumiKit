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
        #expect(config.cellCard.radius == 6)
        #expect(config.card.radius == 8)
        #expect(config.button.radius == 4)
        #expect(config.small.radius == 2)
        #expect(config.medium.radius == 12)
        #expect(config.large.radius == 24)
        #expect(config.iconOverlayOpacity == 0.8)
    }

    @Test("Custom shadow is applied via proxy")
    func customShadow() {
        let original = LMKThemeManager.shared.shadow
        defer { LMKThemeManager.shared.apply(shadow: original) }

        LMKThemeManager.shared.apply(shadow: .init(
            cellCard: .init(radius: 10),
            card: .init(radius: 14),
            medium: .init(radius: 16),
            large: .init(radius: 30)
        ))
        let cellCard = LMKShadow.cellCard()
        let card = LMKShadow.card()
        let medium = LMKShadow.medium()
        let large = LMKShadow.large()
        #expect(cellCard.radius == 10)
        #expect(card.radius == 14)
        #expect(medium.radius == 16)
        #expect(large.radius == 30)
    }
}
