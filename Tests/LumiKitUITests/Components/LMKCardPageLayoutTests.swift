//
//  LMKCardPageLayoutTests.swift
//  LumiKit
//
//  Tests for LMKCardPageLayout constants.
//

import Testing
import UIKit

@testable import LumiKitUI

@Suite("LMKCardPageLayout")
@MainActor
struct LMKCardPageLayoutTests {
    @Test("Header height meets minimum touch target")
    func headerHeightMeetsHIG() {
        #expect(LMKCardPageLayout.headerHeight >= LMKLayout.minimumTouchTarget)
    }

    @Test("Symbol point size is positive")
    func symbolPointSizePositive() {
        #expect(LMKCardPageLayout.symbolPointSize > 0)
    }

    @Test("Separator height is sub-point hairline")
    func separatorHeightIsHairline() {
        #expect(LMKCardPageLayout.separatorHeight > 0)
        #expect(LMKCardPageLayout.separatorHeight <= 1.0)
    }
}
