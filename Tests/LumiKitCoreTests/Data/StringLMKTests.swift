//
//  StringLMKTests.swift
//  LumiKit
//

import Foundation
import Testing
@testable import LumiKitCore

// MARK: - String+LMK

struct StringLMKTests {
    @Test
    func `nonEmpty returns value for non-empty string`() {
        let value: String? = "hello"
        #expect(value.nonEmpty == "hello")
    }

    @Test
    func `nonEmpty returns nil for empty string`() {
        let value: String? = ""
        #expect(value.nonEmpty == nil)
    }

    @Test
    func `nonEmpty returns nil for nil`() {
        let value: String? = nil
        #expect(value.nonEmpty == nil)
    }
}
