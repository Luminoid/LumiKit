//
//  LMKCardPanelLayoutTests.swift
//  LumiKit
//
//  Tests for LMKCardPanelLayout constants.
//

import Testing
import UIKit
@testable import LumiKitUI

@MainActor
struct LMKCardPanelLayoutTests {
    @Test
    func `Card max width is positive`() {
        #expect(LMKCardPanelLayout.cardMaxWidth > 0)
    }

    @Test
    func `Card horizontal inset is positive`() {
        #expect(LMKCardPanelLayout.cardHorizontalInset > 0)
    }

    @Test
    func `Card max height ratio is between 0 and 1`() {
        #expect(LMKCardPanelLayout.cardMaxHeightRatio > 0)
        #expect(LMKCardPanelLayout.cardMaxHeightRatio <= 1.0)
    }

    @Test
    func `Slide offset is positive`() {
        #expect(LMKCardPanelLayout.slideOffset > 0)
    }
}
