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
    func `Text and placeholder proxy to the text view`() {
        let tv = LMKTextView()
        tv.placeholder = "Notes"
        #expect(tv.placeholder == "Notes")
        #expect(tv.placeholderLabel.text == "Notes")
        #expect(!tv.placeholderLabel.isHidden)
        tv.text = "Hello"
        #expect(tv.textView.text == "Hello")
        #expect(tv.text == "Hello")
        #expect(tv.placeholderLabel.isHidden)
    }

    @Test
    func `Default styling uses design tokens`() {
        let tv = LMKTextView()
        #expect(tv.textView.font?.pointSize == LMKTypography.body.pointSize)
        #expect(tv.textView.backgroundColor === LMKColor.backgroundSecondary)
        #expect(tv.textView.layer.cornerRadius == LMKCornerRadius.small)
        #expect(tv.textView.layer.borderWidth == 1)
        #expect(tv.maxCharacterCount == nil)
    }

    @Test
    func `Counter shows only with showsCharacterCount and a limit`() {
        let tv = LMKTextView()
        tv.maxCharacterCount = 100
        tv.text = "Hello"
        #expect(tv.counterLabel.isHidden)
        tv.showsCharacterCount = true
        #expect(!tv.counterLabel.isHidden)
        #expect(tv.counterLabel.text == "5/100")
        tv.text = ""
        #expect(tv.counterLabel.text == "0/100")
        tv.maxCharacterCount = 2000
        tv.text = "abc"
        #expect(tv.counterLabel.text == "3/2,000", "the counter is localized")
        tv.showsCharacterCount = false
        #expect(tv.counterLabel.isHidden)
        tv.showsCharacterCount = true
        tv.maxCharacterCount = nil
        #expect(tv.counterLabel.isHidden)
    }

    @Test
    func `Validation states recolor the border and the helper line`() {
        let tv = LMKTextView()
        tv.helperText = "Helper"
        #expect(tv.helperLabel.text == "Helper")
        tv.validationState = .error("Too short")
        #expect(tv.helperLabel.text == "Too short")
        #expect(tv.helperLabel.textColor === LMKColor.error)
        #expect(tv.textView.layer.borderColor.map { UIColor(cgColor: $0).lmk_hexString } == LMKColor.error.resolvedColor(with: tv.traitCollection).lmk_hexString)
        tv.validationState = .normal
        #expect(tv.helperLabel.text == "Helper")
    }

    @Test
    func `Height floors and caps`() {
        let tv = LMKTextView()
        LMKThemeTesting.fit(tv, width: 300)
        #expect(tv.textView.bounds.height >= 100)
        #expect(!tv.textView.isScrollEnabled)
        tv.minimumHeight = 200
        LMKThemeTesting.fit(tv, width: 300)
        #expect(tv.textView.bounds.height >= 200)

        tv.minimumHeight = 40
        tv.maximumHeight = 60
        tv.text = String(repeating: "A long line of notes that wraps. ", count: 20)
        LMKThemeTesting.fit(tv, width: 300)
        #expect(tv.textView.bounds.height <= 60)
        #expect(tv.textView.isScrollEnabled)
    }

    @Test
    func `Character limit rejects overflow`() {
        let tv = LMKTextView()
        tv.maxCharacterCount = 3
        tv.text = "ab"
        #expect(tv.textView(tv.textView, shouldChangeTextIn: NSRange(location: 2, length: 0), replacementText: "c"))
        #expect(!tv.textView(tv.textView, shouldChangeTextIn: NSRange(location: 2, length: 0), replacementText: "cd"))
    }

    @Test
    func `Disabled views dim and stop editing`() {
        let tv = LMKTextView()
        tv.isEnabled = false
        #expect(!tv.textView.isEditable)
        #expect(abs(tv.alpha - LMKTheme.current.alpha.disabled) < 0.001)
    }

    @Test
    func `theme.textView supplies app-wide defaults`() {
        var theme = LMKTheme()
        theme.textView = LMKTextInputStyle(placeholderColor: .purple, minimumHeight: 30)
        let tv = LMKTextView()
        tv.placeholder = "x"
        let window = LMKThemeTesting.host(tv, theme: theme)
        defer { window.isHidden = true }
        #expect(tv.placeholderLabel.textColor == UIColor.purple)
        LMKThemeTesting.fit(tv, width: 300)
        #expect(tv.textView.bounds.height < 100)
    }
}
