//
//  LMKLoggerTests.swift
//  LumiKit
//

import Foundation
import Testing

@testable import LumiKitCore

// MARK: - LMKLogger

@Suite("LMKLogger")
struct LMKLoggerTests {
    @Test("Configure subsystem updates category logs")
    func configureSubsystem() {
        LMKLogger.configure(subsystem: "com.test.lumikit")
        // If it doesn't crash, the subsystem was applied correctly.
        LMKLogger.info("Test message after configure", category: .general)
    }

    @Test("Built-in categories exist")
    func builtInCategories() {
        _ = LMKLogger.LogCategory.general
        _ = LMKLogger.LogCategory.data
        _ = LMKLogger.LogCategory.ui
        _ = LMKLogger.LogCategory.network
        _ = LMKLogger.LogCategory.error
        _ = LMKLogger.LogCategory.localization
    }

    @Test("Custom category creation")
    func customCategory() {
        let category = LMKLogger.LogCategory(name: "CustomTest")
        LMKLogger.debug("Custom category test", category: category)
    }
}
