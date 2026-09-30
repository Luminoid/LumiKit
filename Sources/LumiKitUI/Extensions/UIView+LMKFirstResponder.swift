//
//  UIView+LMKFirstResponder.swift
//  LumiKit
//
//  Shared first-responder lookup for the keyboard helpers.
//

import UIKit

extension UIView {
    /// Walks the view hierarchy to find the current first responder.
    func lmk_findFirstResponder() -> UIView? {
        if isFirstResponder { return self }
        for subview in subviews {
            if let found = subview.lmk_findFirstResponder() {
                return found
            }
        }
        return nil
    }
}
