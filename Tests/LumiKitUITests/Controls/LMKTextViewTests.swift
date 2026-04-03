//
//  LMKTextViewTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

// MARK: - LMKTextView

@MainActor
struct LMKTextViewTests {
    @Test
    func `Text property proxies to textView`() {
        let tv = LMKTextView()
        tv.text = "Hello"
        #expect(tv.textView.text == "Hello")
        #expect(tv.text == "Hello")
    }

    @Test
    func `Placeholder is set`() {
        let tv = LMKTextView()
        tv.placeholder = "Notes"
        #expect(tv.placeholder == "Notes")
    }

    @Test
    func `Default max character count is nil (unlimited)`() {
        let tv = LMKTextView()
        #expect(tv.maxCharacterCount == nil)
    }

    @Test
    func `Default styling uses design tokens`() {
        let tv = LMKTextView()
        #expect(tv.textView.font == LMKTypography.body)
        #expect(tv.textView.backgroundColor == LMKColor.backgroundSecondary)
    }
}
