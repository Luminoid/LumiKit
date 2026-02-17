//
//  LMKCardViewTests.swift
//  LumiKit
//

import Testing
import UIKit

@testable import LumiKitUI

// MARK: - LMKCardView

@Suite("LMKCardView")
@MainActor
struct LMKCardViewTests {
    @Test("Default corner radius is LMKCornerRadius.medium")
    func defaultCornerRadius() {
        let card = LMKCardView()
        #expect(card.layer.cornerRadius == LMKCornerRadius.medium)
    }

    @Test("contentView is a subview")
    func contentViewIsSubview() {
        let card = LMKCardView()
        #expect(card.contentView.superview === card)
    }

    @Test("Shadow is applied")
    func shadowApplied() {
        let card = LMKCardView()
        #expect(card.layer.shadowOpacity > 0)
        #expect(!card.layer.masksToBounds)
    }

    @Test("Custom corner radius is applied")
    func customCornerRadius() {
        let card = LMKCardView()
        card.cardCornerRadius = 20
        #expect(card.layer.cornerRadius == 20)
        #expect(card.contentView.layer.cornerRadius == 20)
    }
}
