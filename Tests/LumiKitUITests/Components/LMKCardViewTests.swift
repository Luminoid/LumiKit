//
//  LMKCardViewTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

// MARK: - LMKCardView

@MainActor
struct LMKCardViewTests {
    @Test
    func `Default corner radius is LMKCornerRadius.medium`() {
        let card = LMKCardView()
        #expect(card.layer.cornerRadius == LMKCornerRadius.medium)
    }

    @Test
    func `contentView is a subview`() {
        let card = LMKCardView()
        #expect(card.contentView.superview === card)
    }

    @Test
    func `Shadow is applied`() {
        let card = LMKCardView()
        #expect(card.layer.shadowOpacity > 0)
        #expect(!card.layer.masksToBounds)
    }

    @Test
    func `Custom corner radius is applied`() {
        let card = LMKCardView()
        card.cardCornerRadius = 20
        #expect(card.layer.cornerRadius == 20)
        #expect(card.contentView.layer.cornerRadius == 20)
    }
}
