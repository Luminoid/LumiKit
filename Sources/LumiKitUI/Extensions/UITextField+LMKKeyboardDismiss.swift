//
//  UITextField+LMKKeyboardDismiss.swift
//  LumiKit
//
//  Return-key keyboard dismissal for single-line text fields.
//

import UIKit

public extension UITextField {
    /// One-line fields have nothing to insert on Return, so Return dismisses the
    /// keyboard: sets the return key to Done and resigns first responder on
    /// `.editingDidEndOnExit`. Fields that commit on Return instead wire
    /// `.editingDidEndOnExit` to their own action and skip this.
    func lmk_dismissKeyboardOnReturn() {
        returnKeyType = .done
        addTarget(self, action: #selector(UIResponder.resignFirstResponder), for: .editingDidEndOnExit)
    }
}

public extension LMKTextField {
    /// Forwards `lmk_dismissKeyboardOnReturn()` to the wrapped `UITextField`.
    func lmk_dismissKeyboardOnReturn() {
        textField.lmk_dismissKeyboardOnReturn()
    }
}
