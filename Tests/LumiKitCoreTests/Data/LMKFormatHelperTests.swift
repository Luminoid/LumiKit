//
//  LMKFormatHelperTests.swift
//  LumiKit
//

import Foundation
import Testing

@testable import LumiKitCore

// MARK: - LMKFormatHelper

@Suite("LMKFormatHelper")
struct FormatHelperTests {
    @Test("progressPercent formats 0.75 as 75%")
    func progressPercent75() {
        #expect(LMKFormatHelper.progressPercent(0.75) == "75%")
    }

    @Test("progressPercent formats 0.0 as 0%")
    func progressPercentZero() {
        #expect(LMKFormatHelper.progressPercent(0.0) == "0%")
    }

    @Test("progressPercent formats 1.0 as 100%")
    func progressPercentFull() {
        #expect(LMKFormatHelper.progressPercent(1.0) == "100%")
    }
}
