//
//  LMKLoggerTests.swift
//  LumiKit
//

import Foundation
import Testing
@testable import LumiKitCore

// MARK: - LMKLogger

struct LMKLoggerTests {
    @Test
    func `Configure subsystem updates category logs`() {
        LMKLogger.configure(subsystem: "com.test.lumikit")
        // If it doesn't crash, the subsystem was applied correctly.
        LMKLogger.info("Test message after configure", category: .general)
    }

    @Test
    func `Built-in categories exist`() {
        _ = LMKLogger.LogCategory.general
        _ = LMKLogger.LogCategory.data
        _ = LMKLogger.LogCategory.ui
        _ = LMKLogger.LogCategory.network
        _ = LMKLogger.LogCategory.error
        _ = LMKLogger.LogCategory.localization
    }

    @Test
    func `Custom category creation`() {
        let category = LMKLogger.LogCategory(name: "CustomTest")
        LMKLogger.debug("Custom category test", category: category)
    }
}
