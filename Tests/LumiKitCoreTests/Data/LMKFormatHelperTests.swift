//
//  LMKFormatHelperTests.swift
//  LumiKit
//

import Foundation
import Testing
@testable import LumiKitCore

// MARK: - LMKFormatHelper

struct FormatHelperTests {
    @Test
    func `progressPercent formats 0.75 as 75%`() {
        #expect(LMKFormatHelper.progressPercent(0.75) == "75%")
    }

    @Test
    func `progressPercent formats 0.0 as 0%`() {
        #expect(LMKFormatHelper.progressPercent(0.0) == "0%")
    }

    @Test
    func `progressPercent formats 1.0 as 100%`() {
        #expect(LMKFormatHelper.progressPercent(1.0) == "100%")
    }
}
