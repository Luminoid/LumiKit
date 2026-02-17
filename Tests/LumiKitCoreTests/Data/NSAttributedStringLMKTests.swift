//
//  NSAttributedStringLMKTests.swift
//  LumiKit
//

import Foundation
import Testing

@testable import LumiKitCore

// MARK: - NSAttributedString+LMK

@Suite("NSAttributedString+LMK")
struct NSAttributedStringLMKTests {
    @Test("Concatenation operator combines strings")
    func concatenation() {
        let a = NSAttributedString(string: "Hello ")
        let b = NSAttributedString(string: "World")
        let result = a + b
        #expect(result.string == "Hello World")
    }

    @Test("lmk_append adds text")
    func appendText() {
        let result = NSMutableAttributedString()
            .lmk_append("Hello ")
            .lmk_append("World")
        #expect(result.string == "Hello World")
    }

    @Test("lmk_applyToAll applies across full range")
    func applyToAll() {
        let key = NSAttributedString.Key("lmk.test")
        let result = NSMutableAttributedString(string: "Test")
            .lmk_applyToAll([key: 2.0])
        var range = NSRange()
        let attrs = result.attributes(at: 0, longestEffectiveRange: &range, in: NSRange(location: 0, length: result.length))
        #expect(attrs[key] as? Double == 2.0)
        #expect(range.length == 4)
    }

    @Test("lmk_applyToAll on empty string does not crash")
    func applyToAllEmpty() {
        let key = NSAttributedString.Key("lmk.test")
        let result = NSMutableAttributedString()
            .lmk_applyToAll([key: 2.0])
        #expect(result.length == 0)
    }
}
