//
//  UIView+LMKFade.swift
//  LumiKit
//
//  Fade in/out extensions for UIView.
//

import UIKit

public extension UIView {
    /// Fade in to a given alpha. Respects Reduce Motion accessibility setting.
    func lmk_fadeIn(_ alpha: CGFloat = 1.0, duration: Double = LMKAnimationHelper.Duration.alert, completion: ((Bool) -> Void)? = nil) {
        let effectiveDuration = LMKAnimationHelper.shouldAnimate ? duration : 0
        if effectiveDuration == 0 {
            self.alpha = alpha
            completion?(true)
        } else {
            UIView.animate(withDuration: effectiveDuration, animations: { self.alpha = alpha }, completion: completion)
        }
    }

    /// Fade out to a given alpha. Respects Reduce Motion accessibility setting.
    func lmk_fadeOut(_ alpha: CGFloat = 0.0, duration: Double = LMKAnimationHelper.Duration.alert, completion: ((Bool) -> Void)? = nil) {
        let effectiveDuration = LMKAnimationHelper.shouldAnimate ? duration : 0
        if effectiveDuration == 0 {
            self.alpha = alpha
            completion?(true)
        } else {
            UIView.animate(withDuration: effectiveDuration, animations: { self.alpha = alpha }, completion: completion)
        }
    }
}
