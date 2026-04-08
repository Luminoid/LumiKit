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

    // MARK: - Character Counter

    @Test
    func `Counter hidden by default even with maxCharacterCount`() {
        let tv = LMKTextView()
        tv.maxCharacterCount = 100
        tv.text = "Hello"

        let counter = findCounterLabel(in: tv)
        #expect(counter?.isHidden == true)
    }

    @Test
    func `Counter shows when showsCharacterCount enabled`() {
        let tv = LMKTextView()
        tv.maxCharacterCount = 100
        tv.showsCharacterCount = true
        tv.text = "Hello"

        let counter = findCounterLabel(in: tv)
        #expect(counter?.isHidden == false)
        #expect(counter?.text == "5/100")
    }

    @Test
    func `Counter updates on programmatic text set`() {
        let tv = LMKTextView()
        tv.maxCharacterCount = 200
        tv.showsCharacterCount = true
        tv.text = "This is pre-filled text"

        let counter = findCounterLabel(in: tv)
        #expect(counter?.text == "23/200")
    }

    @Test
    func `Counter shows zero when text is empty`() {
        let tv = LMKTextView()
        tv.maxCharacterCount = 50
        tv.showsCharacterCount = true

        let counter = findCounterLabel(in: tv)
        #expect(counter?.text == "0/50")
    }

    @Test
    func `Counter hides when showsCharacterCount disabled`() {
        let tv = LMKTextView()
        tv.maxCharacterCount = 100
        tv.showsCharacterCount = true
        tv.text = "Hello"
        tv.showsCharacterCount = false

        let counter = findCounterLabel(in: tv)
        #expect(counter?.isHidden == true)
    }

    @Test
    func `Counter hides when maxCharacterCount cleared`() {
        let tv = LMKTextView()
        tv.maxCharacterCount = 100
        tv.showsCharacterCount = true
        tv.text = "Hello"
        tv.maxCharacterCount = nil

        let counter = findCounterLabel(in: tv)
        #expect(counter?.isHidden == true)
    }

    // MARK: - Minimum Height

    @Test
    func `Default minimum height is 100`() {
        let tv = LMKTextView()
        #expect(tv.minimumHeight == 100)
    }

    @Test
    func `Custom minimum height`() {
        let tv = LMKTextView()
        tv.minimumHeight = 200
        #expect(tv.minimumHeight == 200)
    }

    // MARK: - Helpers

    private func findCounterLabel(in view: UIView) -> UILabel? {
        view.subviews.compactMap { $0 as? UILabel }
            .first { $0.textAlignment == .right }
    }
}
