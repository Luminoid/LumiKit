//
//  LMKCardFactoryTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

// MARK: - LMKCardFactory

@MainActor
struct LMKCardFactoryTests {
    @Test
    func `cardView has secondary background color`() {
        let card = LMKCardFactory.cardView()
        #expect(card.backgroundColor == LMKColor.backgroundSecondary)
    }

    @Test
    func `cardView has medium corner radius`() {
        let card = LMKCardFactory.cardView()
        #expect(card.layer.cornerRadius == LMKCornerRadius.medium)
    }

    @Test
    func `cardView has shadow applied`() {
        let card = LMKCardFactory.cardView()
        #expect(card.layer.shadowOpacity > 0)
        #expect(!card.layer.masksToBounds)
    }

    @Test
    func `cardView shadow matches cellCard configuration`() {
        let card = LMKCardFactory.cardView()
        let expected = LMKShadow.cellCard()
        #expect(card.layer.shadowColor == expected.color.cgColor)
        #expect(card.layer.shadowOffset == expected.offset)
        #expect(card.layer.shadowRadius == expected.radius)
        #expect(card.layer.shadowOpacity == expected.opacity)
    }
}
