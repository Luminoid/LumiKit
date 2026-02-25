//
//  LMKCardPanelLayoutTests.swift
//  LumiKit
//
//  Tests for LMKCardPanelLayout constants.
//

import Testing
import UIKit

@testable import LumiKitUI

@Suite("LMKCardPanelLayout")
@MainActor
struct LMKCardPanelLayoutTests {
    @Test("Card max width is positive")
    func cardMaxWidthPositive() {
        #expect(LMKCardPanelLayout.cardMaxWidth > 0)
    }

    @Test("Card horizontal inset is positive")
    func cardHorizontalInsetPositive() {
        #expect(LMKCardPanelLayout.cardHorizontalInset > 0)
    }

    @Test("Card max height ratio is between 0 and 1")
    func cardMaxHeightRatioValid() {
        #expect(LMKCardPanelLayout.cardMaxHeightRatio > 0)
        #expect(LMKCardPanelLayout.cardMaxHeightRatio <= 1.0)
    }

    @Test("Slide offset is positive")
    func slideOffsetPositive() {
        #expect(LMKCardPanelLayout.slideOffset > 0)
    }
}
