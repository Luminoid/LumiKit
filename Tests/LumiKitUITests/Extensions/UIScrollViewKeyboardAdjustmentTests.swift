//
//  UIScrollViewKeyboardAdjustmentTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

// MARK: - UIScrollView.lmk_enableKeyboardAdjustment

@MainActor
struct UIScrollViewKeyboardAdjustmentTests {
    @Test
    func `enable installs once and disable removes it`() {
        let scrollView = UIScrollView()
        scrollView.lmk_disableKeyboardAdjustment()
        scrollView.lmk_enableKeyboardAdjustment()
        scrollView.lmk_enableKeyboardAdjustment()
        #expect(scrollView.lmk_hasKeyboardAdjustment)
        scrollView.lmk_disableKeyboardAdjustment()
        #expect(!scrollView.lmk_hasKeyboardAdjustment)
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

    /// Records scroll requests and applies them without animation. A headless
    /// xctest has no display link, so an animated `setContentOffset` never
    /// advances `contentOffset` — recording the request and applying it
    /// immediately is what lets assertions read the final offset.
    private final class RecordingScrollView: UIScrollView {
        var requestedOffsets: [CGPoint] = []

        override func setContentOffset(_ contentOffset: CGPoint, animated: Bool) {
            requestedOffsets.append(contentOffset)
            super.setContentOffset(contentOffset, animated: false)
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

        #expect(scrollView.requestedOffsets.count == 1)
        // Field bottom (1944) + padding lands flush on the visible bottom edge:
        // 1944 + 12 - 812 = 1144.
        #expect(scrollView.contentOffset.y == 1944 + LMKSpacing.medium - 812)
    }

    @Test
    func `Begin editing on a field outside the scroll view is ignored`() {
        let (window, scrollView, _) = makeHostedScrollView()
        defer { window.isHidden = true }

        let outsider = UITextField(frame: CGRect(x: 0, y: 0, width: 100, height: 44))
        window.addSubview(outsider)
        NotificationCenter.default.post(name: UITextField.textDidBeginEditingNotification, object: outsider)

        #expect(scrollView.requestedOffsets.isEmpty)
    }

    @Test
    func `Begin editing on a text view is handled too`() {
        let (window, scrollView, field) = makeHostedScrollView()
        defer { window.isHidden = true }

        let textView = UITextView(frame: CGRect(x: 0, y: 1700, width: 375, height: 100))
        field.superview?.addSubview(textView)
        NotificationCenter.default.post(name: UITextView.textDidBeginEditingNotification, object: textView)

        #expect(scrollView.requestedOffsets.count == 1)
    }

    /// The regression that motivated dropping `scrollRectToVisible`: a field on
    /// screen but underneath the keyboard is inside the raw bounds, so a
    /// bounds-based visibility test treats it as already visible and never
    /// scrolls. The keyboard band math must move it above the grown inset.
    @Test
    func `Field under the keyboard scrolls above it`() {
        let (window, scrollView, field) = makeHostedScrollView()
        defer { window.isHidden = true }

        // On screen (within 812pt bounds), but under a 300pt keyboard.
        let covered = UITextField(frame: CGRect(x: 0, y: 700, width: 375, height: 44))
        field.superview?.addSubview(covered)
        covered.becomeFirstResponder()
        scrollView.requestedOffsets.removeAll()

        NotificationCenter.default.post(
            name: UIResponder.keyboardDidChangeFrameNotification,
            object: nil,
            userInfo: [
                UIResponder.keyboardFrameEndUserInfoKey: NSValue(cgRect: CGRect(x: 0, y: 512, width: 375, height: 300)),
                UIResponder.keyboardAnimationDurationUserInfoKey: 0.0,
            ]
        )
        NotificationCenter.default.post(name: UITextField.textDidBeginEditingNotification, object: covered)

        #expect(scrollView.contentInset.bottom == 300)
        // Field bottom (744) + padding must clear the keyboard top (visible
        // height 512): 744 + 12 - 512 = 244.
        #expect(scrollView.contentOffset.y == 744 + LMKSpacing.medium - 512)
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

    /// The regression: the keyboard overlap was added on top of the safe-area inset UIKit
    /// already applies, leaving blank travel above the keyboard.
    @Test
    func `The grown inset excludes what UIKit already adds below the content`() {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 375, height: 812))
        let host = UIViewController()
        host.additionalSafeAreaInsets.bottom = 34
        window.rootViewController = host
        let scrollView = UIScrollView(frame: window.bounds)
        scrollView.contentInsetAdjustmentBehavior = .always
        let field = UITextField(frame: CGRect(x: 0, y: 100, width: 375, height: 44))
        scrollView.addSubview(field)
        scrollView.contentSize = CGSize(width: 375, height: 2000)
        host.view.addSubview(scrollView)
        window.makeKeyAndVisible()
        window.layoutIfNeeded()
        defer { window.isHidden = true }
        #expect(scrollView.adjustedContentInset.bottom == 34)
        scrollView.lmk_enableKeyboardAdjustment()
        field.becomeFirstResponder()

        NotificationCenter.default.post(
            name: UIResponder.keyboardDidChangeFrameNotification,
            object: nil,
            userInfo: [
                UIResponder.keyboardFrameEndUserInfoKey: NSValue(cgRect: CGRect(x: 0, y: 512, width: 375, height: 300)),
                UIResponder.keyboardAnimationDurationUserInfoKey: 0.0,
            ]
        )

        #expect(scrollView.contentInset.bottom == 266, "300 of overlap less the 34 UIKit already adds")
        #expect(scrollView.adjustedContentInset.bottom == 300, "the band above the keyboard is exactly the overlap")

        NotificationCenter.default.post(
            name: UIResponder.keyboardWillHideNotification,
            object: nil,
            userInfo: [UIResponder.keyboardAnimationDurationUserInfoKey: 0.0]
        )
        #expect(scrollView.contentInset.bottom == 0)
    }

    /// The regression: a scrolling text view is its own first responder, and treating it as
    /// the field to reveal moved the offset by the padding on every focus and edit.
    @Test
    func `A text view that is the scroll view itself is never scrolled toward its own bounds`() {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 375, height: 812))
        let textView = RecordingTextView(frame: CGRect(x: 0, y: 0, width: 375, height: 300))
        textView.text = Array(repeating: "line", count: 400).joined(separator: "\n")
        window.addSubview(textView)
        window.makeKeyAndVisible()
        window.layoutIfNeeded()
        defer { window.isHidden = true }
        textView.lmk_enableKeyboardAdjustment()
        textView.contentOffset = CGPoint(x: 0, y: 100)

        NotificationCenter.default.post(name: UITextView.textDidBeginEditingNotification, object: textView)

        #expect(textView.requestedOffsets.isEmpty)
        #expect(textView.contentOffset.y == 100)
    }

    private final class RecordingTextView: UITextView {
        var requestedOffsets: [CGPoint] = []

        override func setContentOffset(_ contentOffset: CGPoint, animated: Bool) {
            requestedOffsets.append(contentOffset)
            super.setContentOffset(contentOffset, animated: false)
        }
    }
}
