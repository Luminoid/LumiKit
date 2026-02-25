//
//  LMKTextViewTests.swift
//  LumiKit
//

import Testing
import UIKit

@testable import LumiKitUI

// MARK: - LMKTextView

@Suite("LMKTextView")
@MainActor
struct LMKTextViewTests {
    @Test("Text property proxies to textView")
    func textProxy() {
        let tv = LMKTextView()
        tv.text = "Hello"
        #expect(tv.textView.text == "Hello")
        #expect(tv.text == "Hello")
    }

    @Test("Placeholder is set")
    func placeholderSet() {
        let tv = LMKTextView()
        tv.placeholder = "Notes"
        #expect(tv.placeholder == "Notes")
    }

    @Test("Default max character count is nil (unlimited)")
    func defaultMaxCount() {
        let tv = LMKTextView()
        #expect(tv.maxCharacterCount == nil)
    }

    @Test("Default styling uses design tokens")
    func defaultStyling() {
        let tv = LMKTextView()
        #expect(tv.textView.font == LMKTypography.body)
        #expect(tv.textView.backgroundColor == LMKColor.backgroundSecondary)
    }
}
