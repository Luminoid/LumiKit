//
//  LMKDateFormatterHelperTests.swift
//  LumiKit
//

import Foundation
import Testing
@testable import LumiKitCore

// MARK: - LMKDateFormatterHelper

@Suite(.serialized)
struct DateFormatterHelperTests {
    @Test
    func `Default format is MM/dd/yyyy`() {
        LMKDateFormatterHelper.configure(dateFormat: { "MM/dd/yyyy" })
        let formatter = LMKDateFormatterHelper.dateFormatter()
        #expect(formatter.dateFormat == "MM/dd/yyyy")
    }

    @Test
    func `Configure changes format`() {
        LMKDateFormatterHelper.configure(dateFormat: { "yyyy-MM-dd" })
        let formatter = LMKDateFormatterHelper.dateFormatter()
        #expect(formatter.dateFormat == "yyyy-MM-dd")
        // Restore default
        LMKDateFormatterHelper.configure(dateFormat: { "MM/dd/yyyy" })
    }

    @Test
    func `Include time appends HH:mm`() {
        LMKDateFormatterHelper.configure(dateFormat: { "MM/dd/yyyy" })
        let formatter = LMKDateFormatterHelper.dateFormatter(includeTime: true)
        #expect(formatter.dateFormat == "MM/dd/yyyy HH:mm")
    }

    @Test
    func `formatDate produces non-empty string`() {
        LMKDateFormatterHelper.configure(dateFormat: { "MM/dd/yyyy" })
        let result = LMKDateFormatterHelper.formatDate(Date())
        #expect(!result.isEmpty)
    }

    @Test
    func `formatNumber produces string`() {
        let result = LMKDateFormatterHelper.formatNumber(NSNumber(value: 42))
        #expect(!result.isEmpty)
    }
}
