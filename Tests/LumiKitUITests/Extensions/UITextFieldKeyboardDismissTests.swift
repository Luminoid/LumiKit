//
//  UITextFieldKeyboardDismissTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

// MARK: - UITextField (lmk_dismissKeyboardOnReturn)

@MainActor
struct UITextFieldKeyboardDismissTests {
    @Test
    func `Sets the return key to Done`() {
        let field = UITextField()
        field.lmk_dismissKeyboardOnReturn()
        #expect(field.returnKeyType == .done)
    }

    @Test
    func `Resigns first responder on editingDidEndOnExit`() {
        let field = UITextField()
        field.lmk_dismissKeyboardOnReturn()
        let actions = field.actions(forTarget: field, forControlEvent: .editingDidEndOnExit)
        #expect(actions?.contains("resignFirstResponder") == true)
    }

    @Test
    func `LMKTextField forwards to its wrapped text field`() {
        let field = LMKTextField()
        field.lmk_dismissKeyboardOnReturn()
        #expect(field.textField.returnKeyType == .done)
        let actions = field.textField.actions(forTarget: field.textField, forControlEvent: .editingDidEndOnExit)
        #expect(actions?.contains("resignFirstResponder") == true)
    }
}
