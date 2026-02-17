//
//  LMKDateFormatterHelperTests.swift
//  LumiKit
//

import Foundation
import Testing

@testable import LumiKitCore

// MARK: - LMKDateFormatterHelper

@Suite("LMKDateFormatterHelper", .serialized)
struct DateFormatterHelperTests {
    @Test("Default format is MM/dd/yyyy")
    func defaultFormat() {
        LMKDateFormatterHelper.configure(dateFormat: { "MM/dd/yyyy" })
        let formatter = LMKDateFormatterHelper.dateFormatter()
        #expect(formatter.dateFormat == "MM/dd/yyyy")
    }

    @Test("Configure changes format")
    func configureChangesFormat() {
        LMKDateFormatterHelper.configure(dateFormat: { "yyyy-MM-dd" })
        let formatter = LMKDateFormatterHelper.dateFormatter()
        #expect(formatter.dateFormat == "yyyy-MM-dd")
        // Restore default
        LMKDateFormatterHelper.configure(dateFormat: { "MM/dd/yyyy" })
    }

    @Test("Include time appends HH:mm")
    func includeTimeFormat() {
        LMKDateFormatterHelper.configure(dateFormat: { "MM/dd/yyyy" })
        let formatter = LMKDateFormatterHelper.dateFormatter(includeTime: true)
        #expect(formatter.dateFormat == "MM/dd/yyyy HH:mm")
    }

    @Test("formatDate produces non-empty string")
    func formatDateProducesString() {
        LMKDateFormatterHelper.configure(dateFormat: { "MM/dd/yyyy" })
        let result = LMKDateFormatterHelper.formatDate(Date())
        #expect(!result.isEmpty)
    }

    @Test("formatNumber produces string")
    func formatNumber() {
        let result = LMKDateFormatterHelper.formatNumber(NSNumber(value: 42))
        #expect(!result.isEmpty)
    }
}
