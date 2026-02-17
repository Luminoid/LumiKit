//
//  StringLMKTests.swift
//  LumiKit
//

import Foundation
import Testing

@testable import LumiKitCore

// MARK: - String+LMK

@Suite("String+LMK")
struct StringLMKTests {
    @Test("nonEmpty returns value for non-empty string")
    func nonEmptyReturnsValue() {
        let value: String? = "hello"
        #expect(value.nonEmpty == "hello")
    }

    @Test("nonEmpty returns nil for empty string")
    func nonEmptyReturnsNilForEmpty() {
        let value: String? = ""
        #expect(value.nonEmpty == nil)
    }

    @Test("nonEmpty returns nil for nil")
    func nonEmptyReturnsNilForNil() {
        let value: String? = nil
        #expect(value.nonEmpty == nil)
    }
}
