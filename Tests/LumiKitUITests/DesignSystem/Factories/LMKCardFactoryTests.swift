//
//  LMKCardFactoryTests.swift
//  LumiKit
//

import Testing
import UIKit

@testable import LumiKitUI

// MARK: - LMKCardFactory

@Suite("LMKCardFactory")
@MainActor
struct LMKCardFactoryTests {
    @Test("cardView has secondary background color")
    func cardBackground() {
        let card = LMKCardFactory.cardView()
        #expect(card.backgroundColor == LMKColor.backgroundSecondary)
    }

    @Test("cardView has medium corner radius")
    func cardCornerRadius() {
        let card = LMKCardFactory.cardView()
        #expect(card.layer.cornerRadius == LMKCornerRadius.medium)
    }

    @Test("cardView has shadow applied")
    func cardShadow() {
        let card = LMKCardFactory.cardView()
        #expect(card.layer.shadowOpacity > 0)
        #expect(!card.layer.masksToBounds)
    }

    @Test("cardView shadow matches cellCard configuration")
    func cardShadowMatchesCellCard() {
        let card = LMKCardFactory.cardView()
        let expected = LMKShadow.cellCard()
        #expect(card.layer.shadowColor == expected.color.cgColor)
        #expect(card.layer.shadowOffset == expected.offset)
        #expect(card.layer.shadowRadius == expected.radius)
        #expect(card.layer.shadowOpacity == expected.opacity)
    }
}
