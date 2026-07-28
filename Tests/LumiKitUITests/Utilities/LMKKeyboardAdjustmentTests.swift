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

    // MARK: - Focus changes while the keyboard is already up

    /// Records reveal requests. A headless xctest has no display link, so an
    /// animated `scrollRectToVisible` never advances `contentOffset` — asserting on
    /// the request is what actually distinguishes "asked to reveal" from "did nothing".
    private final class RecordingScrollView: UIScrollView {
        var revealedRects: [CGRect] = []

        override func scrollRectToVisible(_ rect: CGRect, animated: Bool) {
            revealedRects.append(rect)
            super.scrollRectToVisible(rect, animated: animated)
        }
    }

    /// Builds a windowed scroll view whose only field sits far below the fold.
    private func makeHostedScrollView() -> (window: UIWindow, scrollView: RecordingScrollView, field: UITextField) {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 375, height: 812))
        let scrollView = RecordingScrollView(frame: window.bounds)
        scrollView.contentInsetAdjustmentBehavior = .never
        let content = UIView(frame: CGRect(x: 0, y: 0, width: 375, height: 2000))
        let field = UITextField(frame: CGRect(x: 0, y: 1900, width: 375, height: 44))
        content.addSubview(field)
        scrollView.addSubview(content)
        scrollView.contentSize = content.bounds.size
        window.addSubview(scrollView)
        window.makeKeyAndVisible()
        window.layoutIfNeeded()
        scrollView.lmk_enableKeyboardAdjustment()
        return (window, scrollView, field)
    }

    @Test
    func `Begin editing reveals the newly focused field`() {
        let (window, scrollView, field) = makeHostedScrollView()
        defer { window.isHidden = true }

        NotificationCenter.default.post(name: UITextField.textDidBeginEditingNotification, object: field)

        #expect(scrollView.revealedRects.count == 1)
        // The field's rect, padded vertically so it doesn't sit flush against the edge.
        let revealed = try? #require(scrollView.revealedRects.first)
        #expect(revealed?.minY == 1900 - LMKSpacing.medium)
        #expect(revealed?.maxY == 1944 + LMKSpacing.medium)
    }

    @Test
    func `Begin editing on a field outside the scroll view is ignored`() {
        let (window, scrollView, _) = makeHostedScrollView()
        defer { window.isHidden = true }

        let outsider = UITextField(frame: CGRect(x: 0, y: 0, width: 100, height: 44))
        window.addSubview(outsider)
        NotificationCenter.default.post(name: UITextField.textDidBeginEditingNotification, object: outsider)

        #expect(scrollView.revealedRects.isEmpty)
    }

    @Test
    func `Begin editing on a text view is handled too`() {
        let (window, scrollView, field) = makeHostedScrollView()
        defer { window.isHidden = true }

        let textView = UITextView(frame: CGRect(x: 0, y: 1700, width: 375, height: 100))
        field.superview?.addSubview(textView)
        NotificationCenter.default.post(name: UITextView.textDidBeginEditingNotification, object: textView)

        #expect(scrollView.revealedRects.count == 1)
    }

    @Test
    func `Keyboard did-change grows the bottom inset`() {
        let (window, scrollView, field) = makeHostedScrollView()
        defer { window.isHidden = true }
        field.becomeFirstResponder()

        NotificationCenter.default.post(
            name: UIResponder.keyboardDidChangeFrameNotification,
            object: nil,
            userInfo: [
                UIResponder.keyboardFrameEndUserInfoKey: NSValue(cgRect: CGRect(x: 0, y: 512, width: 375, height: 300)),
                UIResponder.keyboardAnimationDurationUserInfoKey: 0.0,
            ]
        )

        #expect(scrollView.contentInset.bottom == 300)
    }
}
