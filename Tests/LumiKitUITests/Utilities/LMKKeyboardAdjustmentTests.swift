//
//  LMKKeyboardAdjustmentTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

// MARK: - UIScrollView.lmk_enableKeyboardAdjustment

@MainActor
struct LMKKeyboardAdjustmentTests {
    @Test
    func `enable does not crash`() {
        let scrollView = UIScrollView()
        scrollView.lmk_enableKeyboardAdjustment()
    }

    @Test
    func `enable twice is safe`() {
        let scrollView = UIScrollView()
        scrollView.lmk_enableKeyboardAdjustment()
        scrollView.lmk_enableKeyboardAdjustment()
    }

    @Test
    func `Adjuster does not retain the scroll view`() {
        weak var weakScrollView: UIScrollView?
        autoreleasepool {
            let scrollView = UIScrollView()
            scrollView.lmk_enableKeyboardAdjustment()
            weakScrollView = scrollView
        }
        #expect(weakScrollView == nil)
    }

    @Test
    func `Keyboard change without a window leaves insets unchanged`() {
        let scrollView = UIScrollView(frame: CGRect(x: 0, y: 0, width: 375, height: 812))
        scrollView.contentInset.bottom = 10
        scrollView.lmk_enableKeyboardAdjustment()

        NotificationCenter.default.post(
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil,
            userInfo: [
                UIResponder.keyboardFrameEndUserInfoKey: NSValue(cgRect: CGRect(x: 0, y: 512, width: 375, height: 300)),
                UIResponder.keyboardAnimationDurationUserInfoKey: 0.0,
            ]
        )

        #expect(scrollView.contentInset.bottom == 10)
    }

    @Test
    func `Hide without prior adjustment leaves insets unchanged`() {
        let scrollView = UIScrollView(frame: CGRect(x: 0, y: 0, width: 375, height: 812))
        scrollView.contentInset.bottom = 24
        scrollView.lmk_enableKeyboardAdjustment()

        NotificationCenter.default.post(
            name: UIResponder.keyboardWillHideNotification,
            object: nil,
            userInfo: [UIResponder.keyboardAnimationDurationUserInfoKey: 0.0]
        )

        #expect(scrollView.contentInset.bottom == 24)
    }
}
