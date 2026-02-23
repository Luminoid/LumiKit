//
//  LMKBottomSheetLayoutTests.swift
//  LumiKit
//

import Testing
import UIKit

@testable import LumiKitUI

// MARK: - LMKBottomSheetLayout

@Suite("LMKBottomSheetLayout")
@MainActor
struct LMKBottomSheetLayoutTests {
    @Test("Drag indicator dimensions are consistent")
    func dragIndicatorDimensions() {
        #expect(LMKBottomSheetLayout.dragIndicatorWidth == 40)
        #expect(LMKBottomSheetLayout.dragIndicatorHeight == 5)
        #expect(LMKBottomSheetLayout.dragIndicatorCornerRadius == 2.5)
    }

    @Test("Row height meets HIG minimum touch target")
    func rowHeightMeetsHIG() {
        #expect(LMKBottomSheetLayout.rowHeight >= 44)
    }

    @Test("Button height meets HIG minimum touch target")
    func buttonHeightMeetsHIG() {
        #expect(LMKBottomSheetLayout.buttonHeight >= 44)
    }

    @Test("maxScreenHeightRatio is less than 1.0")
    func maxHeightRatioValid() {
        #expect(LMKBottomSheetLayout.maxScreenHeightRatio > 0)
        #expect(LMKBottomSheetLayout.maxScreenHeightRatio < 1.0)
    }

    @Test("Back button height meets HIG minimum touch target")
    func backButtonHeightMeetsHIG() {
        #expect(LMKBottomSheetLayout.backButtonHeight >= 44)
    }
}
