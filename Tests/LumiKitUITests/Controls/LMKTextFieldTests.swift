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
        let base = LMKTextInputStyle(states: [.error: LMKControlStateStyle(border: .solid(.red, width: 2))])
        let merged = base.merging(LMKTextInputStyle(states: [.error: LMKControlStateStyle(background: .solid(.yellow)), .success: LMKControlStateStyle(border: .solid(.green))]))
        #expect(merged.states?[.error]?.border?.width == 2)
        #expect(merged.states?[.error]?.background == .solid(.yellow))
        #expect(merged.states?[.success]?.border?.color == UIColor.green)
        #expect(merged.tint(for: .error, defaultBorder: .gray) == UIColor.red)
        #expect(merged.tint(for: .warning, defaultBorder: .gray) === LMKColor.warning)
        #expect(merged.tint(for: .normal, defaultBorder: .gray) == UIColor.gray)
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
        #expect(field.helperLabel.textColor === LMKColor.textTertiary)

        field.validationState = .error("Invalid")
        #expect(Self.borderHex(field) == LMKColor.error.resolvedColor(with: field.traitCollection).lmk_hexString)
        #expect(field.helperLabel.text == "Invalid")
        #expect(field.helperLabel.textColor === LMKColor.error)
        #expect(field.textField.accessibilityValue == "Invalid")

        field.validationState = .warning("Careful")
        #expect(Self.borderHex(field) == LMKColor.warning.resolvedColor(with: field.traitCollection).lmk_hexString)
        #expect(field.helperLabel.text == "Careful")

        field.validationState = .success
        #expect(Self.borderHex(field) == LMKColor.success.resolvedColor(with: field.traitCollection).lmk_hexString)
        #expect(field.helperLabel.text == "Helper")
        #expect(field.textField.accessibilityValue == nil)
    }

    @Test
    func `Editing shows the focused border`() {
        let field = LMKTextField()
        var editing: [Bool] = []
        field.onEditingChange = { editing.append($0) }
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
        #expect(field.textField.clearButtonMode == .never)
        field.trailingAccessoryView = nil
        #expect(unit.superview == nil)
        field.showsClearButton = true
        #expect(field.textField.clearButtonMode == .whileEditing)
    }

    @Test
    func `Character limit rejects overflow and the counter tracks the text`() {
        let field = LMKTextField()
        field.maxCharacterCount = 5
        field.showsCharacterCount = true
        field.text = "abc"
        #expect(field.counterLabel.text == "3/5")
        #expect(!field.counterLabel.isHidden)
        let accepts = field.textField(field.textField, shouldChangeCharactersIn: NSRange(location: 3, length: 0), replacementString: "de")
        let rejects = field.textField(field.textField, shouldChangeCharactersIn: NSRange(location: 3, length: 0), replacementString: "def")
        #expect(accepts)
        #expect(!rejects)
        field.showsCharacterCount = false
        #expect(field.counterLabel.isHidden)
    }

    @Test
    func `Disabled fields dim and stop editing`() {
        let field = LMKTextField()
        field.isEnabled = false
        #expect(!field.textField.isEnabled)
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
