//
//  LMKBottomSheetLayoutTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

// MARK: - LMKBottomSheetLayout

@MainActor
struct LMKBottomSheetLayoutTests {
    @Test
    func `Drag indicator dimensions are consistent`() {
        #expect(LMKBottomSheetLayout.dragIndicatorWidth == 40)
        #expect(LMKBottomSheetLayout.dragIndicatorHeight == 5)
        #expect(LMKBottomSheetLayout.dragIndicatorCornerRadius == 2.5)
    }

    @Test
    func `Row height meets HIG minimum touch target`() {
        #expect(LMKBottomSheetLayout.rowHeight >= 44)
    }

    @Test
    func `Button height meets HIG minimum touch target`() {
        #expect(LMKBottomSheetLayout.buttonHeight >= 44)
    }

    @Test
    func `maxScreenHeightRatio is less than 1.0`() {
        #expect(LMKBottomSheetLayout.maxScreenHeightRatio > 0)
        #expect(LMKBottomSheetLayout.maxScreenHeightRatio < 1.0)
    }

    @Test
    func `Back button height meets HIG minimum touch target`() {
        #expect(LMKBottomSheetLayout.backButtonHeight >= 44)
    }
}
