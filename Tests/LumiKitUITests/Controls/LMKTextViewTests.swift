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
    func `A delegate assigned to the inner text view is forwarded to, never replaces the view`() {
        final class ChangeCounter: NSObject, UITextViewDelegate {
            var changes = 0
            func textViewDidChange(_: UITextView) {
                changes += 1
            }
        }
        let view = LMKTextView()
        let host = ChangeCounter()
        var texts: [String] = []
        view.onTextChange = { texts.append($0) }
        view.textView.delegate = host
        #expect(view.textView.delegate === view, "the wrapper stays the real delegate")
        #expect(view.delegate === host)
        view.textView.text = "Hi"
        view.textView.delegate?.textViewDidChange?(view.textView)
        #expect(texts == ["Hi"], "the wrapper's own handling still runs")
        #expect(host.changes == 1)
        withExtendedLifetime(host) {}
    }

    @Test
    func `Text and placeholder proxy to the text view`() {
        let tv = LMKTextView()
        tv.placeholder = "Notes"
        #expect(tv.placeholderLabel.text == "Notes")
        #expect(tv.textView.accessibilityHint == "Notes", "VoiceOver hears the placeholder a text view cannot show it")
        #expect(!tv.placeholderLabel.isHidden)
        tv.text = "Hello"
        #expect(tv.textView.text == "Hello")
        #expect(tv.placeholderLabel.isHidden)
        tv.helperText = "Helper"
        #expect(tv.textView.accessibilityHint == "Helper")
        tv.validationState = .error("Bad")
        #expect(tv.textView.accessibilityHint == "Bad")
        #expect(tv.textView.accessibilityValue == nil, "never the value VoiceOver reads back")
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
        #expect(!tv.hasAmbiguousLayout, "a scrolling text view still has a definite height")

        tv.text = "Short"
        LMKThemeTesting.fit(tv, width: 300)
        #expect(!tv.textView.isScrollEnabled, "back under the cap, it grows again")
    }

    @Test
    func `Text set before the first layout is measured at the real width, not at zero`() {
        let tv = LMKTextView()
        tv.maximumHeight = 240
        tv.text = (1 ... 6).map { "Line \($0)" }.joined(separator: "\n")
        #expect(!tv.textView.isScrollEnabled, "nothing scrolls before there is a width to wrap at")
        LMKThemeTesting.fit(tv, width: 300)
        #expect(!tv.textView.isScrollEnabled, "six lines fit under a 240pt cap")
        #expect(tv.textView.bounds.height > 100)
        #expect(tv.textView.bounds.height < 240)

        LMKThemeTesting.fit(tv, width: 40)
        #expect(tv.textView.isScrollEnabled, "a narrower width re-measures: the wrapped text no longer fits")
        #expect(tv.textView.bounds.height <= 240)
    }

    @Test
    func `A cap under the floor scrolls only past the floor`() {
        let tv = LMKTextView()
        tv.minimumHeight = 200
        tv.maximumHeight = 60
        tv.text = "Short"
        LMKThemeTesting.fit(tv, width: 300)
        #expect(tv.textView.bounds.height == 200)
        #expect(!tv.textView.isScrollEnabled, "a short text does not scroll inside a 200pt view")
    }

    @Test
    func `The helper line adds height only while it shows`() {
        let tv = LMKTextView()
        LMKThemeTesting.fit(tv, width: 300)
        #expect(tv.bounds.height == tv.textView.bounds.height)
        tv.helperText = "Helper"
        LMKThemeTesting.fit(tv, width: 300)
        #expect(tv.bounds.height > tv.textView.bounds.height + LMKTheme.current.spacing.xs)
    }

    @Test
    func `Character limit stops typing at the limit and counts characters`() {
        let tv = LMKTextView()
        tv.maxCharacterCount = 3
        tv.text = "ab"
        #expect(tv.textView(tv.textView, shouldChangeTextIn: NSRange(location: 2, length: 0), replacementText: "c"))
        #expect(tv.textView(tv.textView, shouldChangeTextIn: NSRange(location: 2, length: 0), replacementText: "👨‍👩‍👧‍👦"), "an emoji is one character")
        tv.text = "abc"
        #expect(!tv.textView(tv.textView, shouldChangeTextIn: NSRange(location: 3, length: 0), replacementText: "d"))
        #expect(tv.textView(tv.textView, shouldChangeTextIn: NSRange(location: 2, length: 1), replacementText: ""))
    }

    @Test
    func `Per-instance strings drive the counter's accessibility label`() {
        let tv = LMKTextView()
        tv.maxCharacterCount = 9
        tv.showsCharacterCount = true
        tv.text = "abc"
        #expect(tv.counterLabel.accessibilityLabel == "3 of 9 characters")
        tv.strings = LMKTextView.Strings(counterAccessibilityLabelFormat: "%lld/%lld")
        #expect(tv.counterLabel.accessibilityLabel == "3/9")
    }

    @Test
    func `An over-limit paste goes through and is trimmed to fit`() {
        let tv = LMKTextView()
        tv.maxCharacterCount = 5
        tv.showsCharacterCount = true
        tv.text = "abc"
        var changes: [String] = []
        tv.onTextChange = { changes.append($0) }
        #expect(tv.textView(tv.textView, shouldChangeTextIn: NSRange(location: 1, length: 0), replacementText: "XYZW"), "two of four characters fit")
        tv.textView.text = "aXYZWbc"
        tv.textViewDidChange(tv.textView)
        #expect(tv.text == "aXYbc", "the paste is cut, the original text kept")
        #expect(tv.textView.selectedRange == NSRange(location: 3, length: 0), "the caret follows the kept part")
        #expect(tv.counterLabel.text == "5/5")
        #expect(changes == ["aXYbc"])
    }

    @Test
    func `Marked text is never cut while an input method composes`() {
        let tv = LMKTextView()
        tv.maxCharacterCount = 3
        tv.text = "ab"
        tv.textView.setMarkedText("nihao", selectedRange: NSRange(location: 5, length: 0))
        #expect(tv.textView.markedTextRange != nil)
        #expect(tv.textView(tv.textView, shouldChangeTextIn: NSRange(location: 7, length: 0), replacementText: "x"), "the limit stays out of a composition")
        tv.textViewDidChange(tv.textView)
        #expect(tv.textView.text == "abnihao", "nothing is trimmed while marked")
        tv.textView.unmarkText()
        tv.textViewDidChange(tv.textView)
        #expect(tv.textView.text == "abn", "the committed text is trimmed to fit once the composition ends")
    }

    @Test
    func `Every delegate call reaches the host, scrolling included`() {
        final class Host: NSObject, UITextViewDelegate {
            var events: [String] = []
            func textViewDidChange(_: UITextView) {
                events.append("change")
            }

            func textViewDidChangeSelection(_: UITextView) {
                events.append("selection")
            }

            func scrollViewDidScroll(_: UIScrollView) {
                events.append("scroll")
            }

            func textView(_: UITextView, shouldChangeTextIn _: NSRange, replacementText _: String) -> Bool {
                events.append("should")
                return false
            }
        }
        let tv = LMKTextView()
        let host = Host()
        tv.delegate = host
        tv.textViewDidChange(tv.textView)
        tv.textViewDidChangeSelection(tv.textView)
        tv.scrollViewDidScroll(tv.textView)
        #expect(!tv.textView(tv.textView, shouldChangeTextIn: NSRange(location: 0, length: 0), replacementText: "a"), "the host's refusal wins")
        #expect(host.events == ["change", "selection", "scroll", "should"])
        withExtendedLifetime(host) {}
    }

    @Test
    func `Disabled views dim, stop editing, and absorb touches`() {
        let tv = LMKTextView()
        LMKThemeTesting.fit(tv, width: 300)
        let inside = CGPoint(x: 20, y: 20)
        #expect(tv.hitTest(inside, with: nil) !== tv, "an enabled view hands the touch to the text view")
        tv.isEnabled = false
        #expect(!tv.textView.isEditable)
        #expect(abs(tv.alpha - LMKTheme.current.alpha.disabled) < 0.001)
        #expect(tv.hitTest(inside, with: nil) === tv)
        tv.style.disabled = LMKControlStateStyle(alpha: 0.3)
        #expect(abs(tv.alpha - 0.3) < 0.001)
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
