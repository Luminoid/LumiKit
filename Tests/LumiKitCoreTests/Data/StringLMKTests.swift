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
        #expect(value.lmk_nonEmpty == "hello")
    }

    @Test
    func `nonEmpty returns nil for empty string`() {
        let value: String? = ""
        #expect(value.lmk_nonEmpty == nil)
    }

    @Test
    func `nonEmpty returns nil for nil`() {
        let value: String? = nil
        #expect(value.lmk_nonEmpty == nil)
    }

    @Test
    func `trimmedOrNil trims and keeps content`() {
        #expect("  hello \n".lmk_trimmedOrNil == "hello")
        #expect("hello".lmk_trimmedOrNil == "hello")
    }

    @Test
    func `trimmedOrNil returns nil for blank input`() {
        #expect("".lmk_trimmedOrNil == nil)
        #expect("   \n\t".lmk_trimmedOrNil == nil)
    }

    @Test
    func `trimmedOrNil on optionals handles nil and blanks`() {
        let missing: String? = nil
        let blank: String? = "  "
        let present: String? = " x "
        #expect(missing.lmk_trimmedOrNil == nil)
        #expect(blank.lmk_trimmedOrNil == nil)
        #expect(present.lmk_trimmedOrNil == "x")
    }
}
