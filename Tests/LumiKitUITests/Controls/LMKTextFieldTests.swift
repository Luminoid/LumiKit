//
//  LMKTextFieldTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

// MARK: - LMKValidationState

struct LMKValidationStateTests {
    @Test
    func `Kinds and messages`() {
        #expect(LMKValidationState.normal.kind == .normal)
        #expect(LMKValidationState.warning("w").kind == .warning)
        #expect(LMKValidationState.error("e").kind == .error)
        #expect(LMKValidationState.success.kind == .success)
        #expect(LMKValidationState.error("e").message == "e")
        #expect(LMKValidationState.success.message == nil)
        #expect(LMKValidationState.error("a") != LMKValidationState.error("b"))
    }

    @Test
    func `Style merging layers per-state overrides`() {
        let base = LMKTextInputStyle(states: [.error: LMKControlStateStyle(border: .solid(.red, width: 2))], disabled: LMKControlStateStyle(alpha: 0.2))
        let merged = base.merging(LMKTextInputStyle(states: [.error: LMKControlStateStyle(background: .solid(.yellow)), .success: LMKControlStateStyle(border: .solid(.green))]))
        #expect(merged.states?[.error]?.border?.width == 2)
        #expect(merged.states?[.error]?.background == .solid(.yellow))
        #expect(merged.states?[.success]?.border?.color == UIColor.green)
        #expect(merged.disabled?.alpha == 0.2)
        #expect(merged.tint(for: .error, defaultBorder: .gray) == UIColor.red)
        #expect(merged.tint(for: .warning, defaultBorder: .gray) === LMKColor.warning)
        #expect(merged.tint(for: .normal, defaultBorder: .gray) == UIColor.gray)
    }
}

// MARK: - Character limit

struct LMKTextInputCharacterLimitTests {
    private typealias Limit = LMKTextInputStyle.CharacterLimit

    private func allows(_ current: String, at location: Int, length: Int = 0, _ replacement: String, limit: Int) -> Bool {
        Limit.allowsChange(in: current, ranges: [NSRange(location: location, length: length)], replacement: replacement, limit: limit)
    }

    @Test
    func `Counts Characters, the unit the counter shows`() {
        #expect(allows("abc", at: 3, "👨‍👩‍👧‍👦", limit: 4), "one family emoji is one character, however many UTF-16 units")
        #expect(!allows("abc👨‍👩‍👧‍👦", at: 14, "d", limit: 4), "the field is full at four characters")
        #expect(allows("ab", at: 2, "c", limit: 3))
        #expect(!allows("abc", at: 3, "d", limit: 3))
        #expect(allows("abc", at: 0, length: 3, "xyz", limit: 3), "replacing everything keeps the count")
        #expect(allows("abc", at: 1, length: 1, "", limit: 2), "a deletion always goes through, even from over the limit")
        #expect(allows("ab", at: 9, "c", limit: 2), "a range past the end is left to UIKit")
    }

    @Test
    func `A multi-character insertion goes through when part of it fits, so a paste is trimmed instead of dropped`() {
        #expect(allows("abc", at: 3, "defgh", limit: 5), "two of five characters fit")
        #expect(!allows("abcde", at: 5, "fgh", limit: 5), "nothing fits")
        #expect(allows("ab", at: 0, length: 2, "vwxyz", limit: 3), "the removed text makes room")
    }

    @Test
    func `iOS 26 multi-range edits delete every range and insert at the first`() {
        let ranges = [NSRange(location: 4, length: 1), NSRange(location: 1, length: 1)]
        #expect(Limit.proposed("abcdef", replacing: ranges, with: "XY") == "aXYcdf")
        #expect(Limit.allowsChange(in: "abcdef", ranges: ranges, replacement: "XY", limit: 6))
        #expect(Limit.allowsChange(in: "abcdef", ranges: ranges, replacement: "XYZ", limit: 6), "one of three characters fits after the deletions")
        #expect(!Limit.allowsChange(in: "abcdef", ranges: ranges, replacement: "XYZ", limit: 4), "no room once the deletions are counted")
    }

    @Test
    func `Trimming cuts only what was inserted and keeps the caret after the kept part`() {
        let pasted = Limit.trimmed("abXYZWVcde", previous: "abcde", limit: 8)
        #expect(pasted?.text == "abXYZcde", "the tail of the original text survives; the paste is cut")
        #expect(pasted?.caretOffset == 5)
        #expect(Limit.trimmed("abcde", previous: "abcde", limit: 3) == nil, "text that was already there is never cut")
        #expect(Limit.trimmed("abc", previous: "", limit: 5) == nil, "nothing to do under the limit")
        let composed = Limit.trimmed("ab你好", previous: "ab", limit: 3)
        #expect(composed?.text == "ab你", "a committed composition is trimmed like a paste")
        #expect(composed?.caretOffset == 3)
        let emoji = Limit.trimmed("a👨‍👩‍👧‍👦👨‍👩‍👧‍👦", previous: "a", limit: 2)
        #expect(emoji?.text == "a👨‍👩‍👧‍👦", "trimming never splits a grapheme cluster")
    }
}

// MARK: - LMKTextField

@MainActor
struct LMKTextFieldTests {
    private static func borderHex(_ field: LMKTextField) -> String? {
        field.containerView.layer.borderColor.map { UIColor(cgColor: $0).lmk_hexString }
    }

    @Test
    func `Default surface and font`() {
        let field = LMKTextField()
        #expect(field.textField.font?.pointSize == LMKTypography.body.pointSize)
        #expect(field.containerView.backgroundColor === LMKColor.backgroundSecondary)
        #expect(field.containerView.layer.cornerRadius == LMKCornerRadius.small)
        #expect(field.containerView.layer.borderWidth == 1)
        #expect(Self.borderHex(field) == LMKColor.divider.resolvedColor(with: field.traitCollection).lmk_hexString)
    }

    @Test
    func `Validation states recolor the border and show the message`() {
        let field = LMKTextField()
        field.helperText = "Helper"
        #expect(field.helperLabel.text == "Helper")
        #expect(field.helperLabel.textColor === LMKColor.textSecondary)

        field.validationState = .error("Invalid")
        #expect(Self.borderHex(field) == LMKColor.error.resolvedColor(with: field.traitCollection).lmk_hexString)
        #expect(field.helperLabel.text == "Invalid")
        #expect(field.helperLabel.textColor === LMKColor.error)
        #expect(field.textField.accessibilityHint == "Invalid", "the message is the hint, never the value VoiceOver reads back")
        #expect(field.textField.accessibilityValue == nil)

        field.validationState = .warning("Careful")
        #expect(Self.borderHex(field) == LMKColor.warning.resolvedColor(with: field.traitCollection).lmk_hexString)
        #expect(field.helperLabel.text == "Careful")

        field.validationState = .success
        #expect(Self.borderHex(field) == LMKColor.success.resolvedColor(with: field.traitCollection).lmk_hexString)
        #expect(field.helperLabel.text == "Helper")
        #expect(field.textField.accessibilityHint == "Helper")
    }

    @Test
    func `The helper line adds height only while it shows`() {
        let field = LMKTextField()
        LMKThemeTesting.fit(field, width: 300)
        #expect(field.bounds.height == field.containerView.bounds.height, "no helper, no gap")
        field.helperText = "Helper"
        LMKThemeTesting.fit(field, width: 300)
        #expect(field.bounds.height > field.containerView.bounds.height + LMKTheme.current.spacing.xs)
    }

    @Test
    func `A delegate assigned to the inner field is forwarded to, never replaces the field`() {
        final class ReturnCounter: NSObject, UITextFieldDelegate {
            var returns: [UITextField] = []
            func textFieldShouldReturn(_ textField: UITextField) -> Bool {
                returns.append(textField)
                return false
            }
        }
        let field = LMKTextField()
        let host = ReturnCounter()
        var began = 0
        field.onBeginEditing = { began += 1 }
        field.textField.delegate = host
        #expect(field.textField.delegate === field, "the wrapper stays the real delegate")
        #expect(field.delegate === host)
        field.textField.delegate?.textFieldDidBeginEditing?(field.textField)
        #expect(began == 1, "the wrapper's own handling still runs")
        #expect(field.textField.delegate?.textFieldShouldReturn?(field.textField) == false)
        #expect(host.returns.first === field.textField, "the host hears the inner field, as before")
        withExtendedLifetime(host) {}
    }

    @Test
    func `Editing shows the focused border`() {
        let field = LMKTextField()
        var editing: [Bool] = []
        field.onBeginEditing = { editing.append(true) }
        field.onEndEditing = { editing.append(false) }
        field.textFieldDidBeginEditing(field.textField)
        #expect(Self.borderHex(field) == LMKColor.primary.resolvedColor(with: field.traitCollection).lmk_hexString)
        field.textFieldDidEndEditing(field.textField)
        #expect(Self.borderHex(field) == LMKColor.divider.resolvedColor(with: field.traitCollection).lmk_hexString)
        #expect(editing == [true, false])
    }

    @Test
    func `Per-state style overrides win`() {
        var style = LMKTextInputStyle()
        style.states = [.error: LMKControlStateStyle(background: .solid(.yellow), border: .solid(.purple, width: 3))]
        let field = LMKTextField(style: style)
        field.validationState = .error("x")
        #expect(field.containerView.backgroundColor == UIColor.yellow)
        #expect(field.containerView.layer.borderWidth == 3)
        #expect(Self.borderHex(field) == UIColor.purple.lmk_hexString)
    }

    @Test
    func `Placeholder, text, icon, and accessory`() {
        let field = LMKTextField()
        field.placeholder = "Email"
        #expect(field.textField.attributedPlaceholder?.string == "Email")
        field.text = "Hello"
        #expect(field.textField.text == "Hello")
        #expect(field.text == "Hello")
        field.leadingIcon = UIImage(systemName: "envelope")
        #expect(!field.leadingIconView.isHidden)
        let unit = UILabel()
        field.trailingAccessoryView = unit
        #expect(unit.superview === field.containerView)
        #expect(field.accessibilityElements?.count == 5, "VoiceOver reaches the accessory")
        #expect(field.accessibilityElements?[2] as? UIView === unit)
        field.trailingAccessoryView = nil
        #expect(unit.superview == nil)
        #expect(field.accessibilityElements?.count == 4)
    }

    @Test
    func `The kit's clear button shows while editing with text, honors the tint, and clears`() {
        let field = LMKTextField()
        field.showsClearButton = true
        #expect(field.textField.clearButtonMode == .never, "UIKit's own button is never used")
        #expect(field.clearButton.isHidden, "not editing")
        field.text = "Hello"
        field.textFieldDidBeginEditing(field.textField)
        #expect(!field.clearButton.isHidden)
        #expect(field.clearButton.accessibilityLabel == LMKTextField.Strings().clearAccessibilityLabel)
        #expect(field.clearButton.style.tintColor === LMKColor.textTertiary)
        field.style.clearButtonTint = .red
        #expect(field.clearButton.style.tintColor == UIColor.red)
        #expect(field.clearButton.style.symbolPointSize == field.textField.font?.pointSize, "the glyph follows the text size")
        LMKThemeTesting.fit(field, width: 300)
        #expect(field.clearButton.bounds.width > 0)
        #expect(field.textField.frame.maxX <= field.clearButton.frame.minX)

        var changes: [String] = []
        field.onTextChange = { changes.append($0) }
        let observer = NotificationCounter()
        NotificationCenter.default.addObserver(observer, selector: #selector(NotificationCounter.count(_:)), name: UITextField.textDidChangeNotification, object: field.textField)
        defer { NotificationCenter.default.removeObserver(observer) }
        field.clearButton.didTap()
        #expect(field.text?.isEmpty == true)
        #expect(changes == [""], "one change, however UIKit delivers the editing-changed event")
        #expect(observer.received == 1, "observers of the field hear the clear, as with UIKit's own button")
        #expect(field.clearButton.isHidden, "empty again")

        field.text = "More"
        let accessory = UILabel()
        field.trailingAccessoryView = accessory
        #expect(field.clearButton.isHidden, "an accessory replaces the clear button")
        field.trailingAccessoryView = nil
        #expect(!field.clearButton.isHidden)
        field.textFieldDidEndEditing(field.textField)
        #expect(field.clearButton.isHidden)
    }

    @Test
    func `The clear button asks the host's textFieldShouldClear first`() {
        final class RefusingDelegate: NSObject, UITextFieldDelegate {
            func textFieldShouldClear(_: UITextField) -> Bool {
                false
            }
        }
        let field = LMKTextField()
        let host = RefusingDelegate()
        field.delegate = host
        field.text = "Keep"
        field.clearButton.didTap()
        #expect(field.text == "Keep")
        withExtendedLifetime(host) {}
    }

    @Test
    func `Character limit counts characters, stops typing at the limit, and the counter tracks the text`() {
        let field = LMKTextField()
        field.maxCharacterCount = 5
        field.showsCharacterCount = true
        field.text = "abc"
        #expect(field.counterLabel.text == "3/5")
        #expect(field.counterLabel.accessibilityLabel == "3 of 5 characters")
        #expect(!field.counterLabel.isHidden)
        #expect(field.textField(field.textField, shouldChangeCharactersIn: NSRange(location: 3, length: 0), replacementString: "de"))
        #expect(field.textField(field.textField, shouldChangeCharactersIn: NSRange(location: 3, length: 0), replacementString: "👨‍👩‍👧‍👦"), "an emoji is one character")
        field.text = "abcde"
        #expect(!field.textField(field.textField, shouldChangeCharactersIn: NSRange(location: 5, length: 0), replacementString: "f"), "full")
        #expect(field.textField(field.textField, shouldChangeCharactersIn: NSRange(location: 4, length: 1), replacementString: ""), "deleting is always allowed")
        field.showsCharacterCount = false
        #expect(field.counterLabel.isHidden)
    }

    @Test
    func `Per-instance strings rename the clear button and the counter`() {
        let field = LMKTextField()
        field.strings = LMKTextField.Strings(clearAccessibilityLabel: "Borrar", counterAccessibilityLabelFormat: "%lld/%lld")
        field.maxCharacterCount = 9
        field.showsCharacterCount = true
        field.text = "abc"
        #expect(field.clearButton.accessibilityLabel == "Borrar")
        #expect(field.counterLabel.accessibilityLabel == "3/9")
    }

    @Test
    func `An over-limit paste is trimmed to fit instead of rejected`() {
        let field = LMKTextField()
        field.maxCharacterCount = 5
        field.text = "abc"
        var changes: [String] = []
        field.onTextChange = { changes.append($0) }
        // The paste partly fits, so the delegate lets it through...
        #expect(field.textField(field.textField, shouldChangeCharactersIn: NSRange(location: 3, length: 0), replacementString: "defgh"))
        // ...and the change pass trims what does not fit.
        field.textField.text = "abcdefgh"
        field.perform(NSSelectorFromString("textFieldDidChange"))
        #expect(field.text == "abcde")
        #expect(changes == ["abcde"])
    }

    @Test
    func `Marked text is never cut while an input method composes`() {
        let field = LMKTextField()
        field.maxCharacterCount = 3
        field.text = "ab"
        field.textField.setMarkedText("nihao", selectedRange: NSRange(location: 5, length: 0))
        #expect(field.textField.markedTextRange != nil)
        #expect(field.textField.text == "nihaoab")
        #expect(field.textField(field.textField, shouldChangeCharactersIn: NSRange(location: 5, length: 0), replacementString: "x"), "the limit stays out of a composition")
        field.perform(NSSelectorFromString("textFieldDidChange"))
        #expect(field.textField.text == "nihaoab", "nothing is trimmed while marked")
        field.textField.unmarkText()
        field.perform(NSSelectorFromString("textFieldDidChange"))
        #expect(field.textField.text == "nab", "the committed text is trimmed to fit once the composition ends; the text that was there stays")
    }

    @Test
    func `The host delegate is consulted and its refusal wins`() {
        final class CountingDelegate: NSObject, UITextFieldDelegate {
            var asked = 0
            var answer = true
            var endReasons: [UITextField.DidEndEditingReason] = []
            var selectionChanges = 0
            func textField(_: UITextField, shouldChangeCharactersIn _: NSRange, replacementString _: String) -> Bool {
                asked += 1
                return answer
            }

            func textFieldDidEndEditing(_: UITextField, reason: UITextField.DidEndEditingReason) {
                endReasons.append(reason)
            }

            func textFieldDidChangeSelection(_: UITextField) {
                selectionChanges += 1
            }
        }
        let field = LMKTextField()
        let host = CountingDelegate()
        field.delegate = host
        field.maxCharacterCount = 3
        field.text = "abc"
        #expect(!field.textField(field.textField, shouldChangeCharactersIn: NSRange(location: 3, length: 0), replacementString: "d"))
        #expect(host.asked == 1, "the host hears about the edit the limit refuses")
        host.answer = false
        #expect(!field.textField(field.textField, shouldChangeCharactersIn: NSRange(location: 0, length: 1), replacementString: ""))
        #expect(host.asked == 2, "the host's refusal wins over an edit the limit would allow")

        field.textFieldDidEndEditing(field.textField, reason: .committed)
        #expect(host.endReasons == [.committed], "the reason variant reaches a host that implements it")
        field.textFieldDidChangeSelection(field.textField)
        #expect(host.selectionChanges == 1)
        withExtendedLifetime(host) {}
    }

    @Test
    func `Disabled fields dim, stop editing, and absorb touches`() {
        let field = LMKTextField()
        field.style.disabled = LMKControlStateStyle(alpha: 0.25)
        let reveal = UIButton(configuration: .plain())
        reveal.configuration?.title = "Show"
        field.trailingAccessoryView = reveal
        LMKThemeTesting.fit(field, width: 300)
        let onAccessory = field.convert(CGPoint(x: reveal.bounds.midX, y: reveal.bounds.midY), from: reveal)
        #expect(field.hitTest(onAccessory, with: nil) === reveal)
        field.isEnabled = false
        #expect(!field.textField.isEnabled)
        #expect(abs(field.alpha - 0.25) < 0.001, "the disabled style's alpha applies")
        #expect(field.hitTest(onAccessory, with: nil) === field, "a disabled field takes the touch, accessory included")
        field.style.disabled = nil
        #expect(abs(field.alpha - LMKTheme.current.alpha.disabled) < 0.001)
    }

    @Test
    func `theme.textField supplies app-wide defaults`() {
        var theme = LMKTheme()
        theme.textField = LMKTextInputStyle(surface: LMKSurfaceStyle(corners: .fixed(2)), textColor: .purple)
        let field = LMKTextField()
        let window = LMKThemeTesting.host(field, theme: theme)
        defer { window.isHidden = true }
        #expect(field.containerView.layer.cornerRadius == 2)
        #expect(field.textField.textColor == UIColor.purple)
    }
}

/// Counts the notifications it is registered for.
private final class NotificationCounter: NSObject {
    private(set) var received = 0

    @objc func count(_: Notification) {
        received += 1
    }
}
