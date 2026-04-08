//
//  LMKKeyboardInsetHelperTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

// MARK: - LMKKeyboardInsetHelper

@MainActor
struct LMKKeyboardInsetHelperTests {
    @Test
    func `Init does not crash`() {
        let scrollView = UIScrollView()
        let rootView = UIView()
        let helper = LMKKeyboardInsetHelper(scrollView: scrollView, rootView: rootView)
        _ = helper
    }

    @Test
    func `startObserving and stopObserving don't crash`() {
        let scrollView = UIScrollView()
        let rootView = UIView()
        let helper = LMKKeyboardInsetHelper(scrollView: scrollView, rootView: rootView)
        helper.startObserving()
        helper.stopObserving()
    }

    @Test
    func `startObserving twice is safe`() {
        let scrollView = UIScrollView()
        let rootView = UIView()
        let helper = LMKKeyboardInsetHelper(scrollView: scrollView, rootView: rootView)
        helper.startObserving()
        helper.startObserving()
        helper.stopObserving()
    }

    @Test
    func `stopObserving without start is safe`() {
        let scrollView = UIScrollView()
        let rootView = UIView()
        let helper = LMKKeyboardInsetHelper(scrollView: scrollView, rootView: rootView)
        helper.stopObserving()
    }

    @Test
    func `Hide notification resets bottom inset`() {
        let scrollView = UIScrollView(frame: CGRect(x: 0, y: 0, width: 375, height: 812))
        let rootView = UIView(frame: CGRect(x: 0, y: 0, width: 375, height: 812))
        rootView.addSubview(scrollView)

        let helper = LMKKeyboardInsetHelper(scrollView: scrollView, rootView: rootView)
        helper.startObserving()

        // Simulate hide
        NotificationCenter.default.post(
            name: UIResponder.keyboardWillHideNotification,
            object: nil,
            userInfo: [
                UIResponder.keyboardFrameEndUserInfoKey: NSValue(cgRect: .zero),
                UIResponder.keyboardAnimationDurationUserInfoKey: 0.0,
                UIResponder.keyboardAnimationCurveUserInfoKey: UInt(7),
            ]
        )

        #expect(scrollView.contentInset.bottom == 0)
        helper.stopObserving()
    }

    @Test
    func `Weak references don't retain scroll view`() throws {
        var scrollView: UIScrollView? = UIScrollView()
        let rootView = UIView()
        let helper = try LMKKeyboardInsetHelper(scrollView: #require(scrollView), rootView: rootView)
        helper.startObserving()
        scrollView = nil

        // Should not crash when notification fires after scroll view is deallocated
        NotificationCenter.default.post(
            name: UIResponder.keyboardWillHideNotification,
            object: nil,
            userInfo: [
                UIResponder.keyboardFrameEndUserInfoKey: NSValue(cgRect: .zero),
                UIResponder.keyboardAnimationDurationUserInfoKey: 0.0,
                UIResponder.keyboardAnimationCurveUserInfoKey: UInt(7),
            ]
        )
        helper.stopObserving()
    }
}
