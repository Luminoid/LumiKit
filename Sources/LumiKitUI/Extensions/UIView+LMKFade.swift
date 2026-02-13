//
//  UIView+LMKFade.swift
//  LumiKit
//
//  Fade in/out extensions for UIView.
//

import UIKit

extension UIView {
    /// Fade in to a given alpha.
    public func lmk_fadeIn(_ alpha: CGFloat = 1.0, duration: Double = 0.2, completion: ((Bool) -> Void)? = nil) {
        if duration == 0.0 {
            self.alpha = alpha
            completion?(true)
        } else {
            UIView.animate(withDuration: duration, animations: { self.alpha = alpha }, completion: completion)
        }
    }

    /// Fade out to a given alpha.
    public func lmk_fadeOut(_ alpha: CGFloat = 0.0, duration: Double = 0.2, completion: ((Bool) -> Void)? = nil) {
        if duration == 0.0 {
            self.alpha = alpha
            completion?(true)
        } else {
            UIView.animate(withDuration: duration, animations: { self.alpha = alpha }, completion: completion)
        }
    }
}
