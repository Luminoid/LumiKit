//
//  LMKCardPageLayoutTests.swift
//  LumiKit
//
//  Tests for LMKCardPageLayout constants.
//

import Testing
import UIKit
@testable import LumiKitUI

@MainActor
struct LMKCardPageLayoutTests {
    @Test
    func `Header height meets minimum touch target`() {
        #expect(LMKCardPageLayout.headerHeight >= LMKLayout.minimumTouchTarget)
    }

    @Test
    func `Symbol point size is positive`() {
        #expect(LMKCardPageLayout.symbolPointSize > 0)
    }

    @Test
    func `Separator height is sub-point hairline`() {
        #expect(LMKCardPageLayout.separatorHeight > 0)
        #expect(LMKCardPageLayout.separatorHeight <= 1.0)
    }
}
