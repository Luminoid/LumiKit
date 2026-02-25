//
//  UITextFieldFormStyleTests.swift
//  LumiKit
//

import Testing
import UIKit

@testable import LumiKitUI

// MARK: - UITextField+LMKFormStyle

@Suite("UITextField+LMKFormStyle")
@MainActor
struct UITextFieldFormStyleTests {
    @Test("lmk_applyFormContentPadding sets left and right views")
    func applyFormContentPadding() {
        let textField = UITextField()
        textField.lmk_applyFormContentPadding()

        #expect(textField.leftView != nil)
        #expect(textField.leftViewMode == .always)
        #expect(textField.rightView != nil)
        #expect(textField.rightViewMode == .always)
    }

    @Test("lmk_applyFormContentPadding uses spacing token width")
    func formContentPaddingWidth() {
        let textField = UITextField()
        textField.lmk_applyFormContentPadding()

        let expectedWidth = LMKSpacing.xs
        #expect(textField.leftView?.frame.width == expectedWidth)
        #expect(textField.rightView?.frame.width == expectedWidth)
    }

    @Test("lmk_applyFormStyle sets border style and background")
    func applyFormStyle() {
        let textField = UITextField()
        textField.lmk_applyFormStyle()

        #expect(textField.borderStyle == .roundedRect)
        #expect(textField.backgroundColor == LMKColor.backgroundSecondary)
        #expect(textField.leftView != nil)
        #expect(textField.rightView != nil)
    }
}

// MARK: - UITextView+LMKFormStyle

@Suite("UITextView+LMKFormStyle")
@MainActor
struct UITextViewFormStyleTests {
    @Test("lmk_applyFormContentPadding sets text container inset")
    func applyFormContentPadding() {
        let textView = UITextView()
        textView.lmk_applyFormContentPadding()

        #expect(textView.textContainerInset.top == LMKSpacing.textViewPaddingVertical)
        #expect(textView.textContainerInset.left == LMKSpacing.textViewPaddingHorizontal)
        #expect(textView.textContainerInset.bottom == LMKSpacing.textViewPaddingVertical)
        #expect(textView.textContainerInset.right == LMKSpacing.textViewPaddingHorizontal)
    }
}
