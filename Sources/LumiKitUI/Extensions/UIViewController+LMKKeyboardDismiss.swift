//
//  UIViewController+LMKKeyboardDismiss.swift
//  LumiKit
//
//  Tap-anywhere keyboard dismissal for form screens.
//

import UIKit

public extension UIViewController {
    /// Installs a tap recognizer on the root view so tapping anywhere outside a
    /// field dismisses the keyboard. `cancelsTouchesInView = false` so taps still
    /// reach buttons and controls; complements `scrollView.keyboardDismissMode`.
    func lmk_dismissKeyboardOnTap() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(lmk_endEditingFromTap))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    @objc private func lmk_endEditingFromTap() {
        view.endEditing(true)
    }
}
