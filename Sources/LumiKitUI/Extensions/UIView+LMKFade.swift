//
//  UIView+LMKFade.swift
//  LumiKit
//
//  Fade in/out extensions for UIView.
//

import UIKit

public extension UIView {
    /// Fade in to a given alpha. Respects Reduce Motion accessibility setting.
    func lmk_fadeIn(_ alpha: CGFloat = 1.0, duration: Double = LMKAnimationHelper.Duration.alert, delay: Double = 0, completion: ((Bool) -> Void)? = nil) {
        lmk_fade(to: alpha, duration: duration, delay: delay, completion: completion)
    }

    /// Fade out to a given alpha. Respects Reduce Motion accessibility setting.
    func lmk_fadeOut(_ alpha: CGFloat = 0.0, duration: Double = LMKAnimationHelper.Duration.alert, delay: Double = 0, completion: ((Bool) -> Void)? = nil) {
        lmk_fade(to: alpha, duration: duration, delay: delay, completion: completion)
    }

    private func lmk_fade(to alpha: CGFloat, duration: Double, delay: Double, completion: ((Bool) -> Void)?) {
        let effectiveDuration = LMKAnimationHelper.shouldAnimate ? duration : 0
        if effectiveDuration == 0 && delay == 0 {
            self.alpha = alpha
            completion?(true)
        } else {
            UIView.animate(withDuration: effectiveDuration, delay: delay, options: [.beginFromCurrentState], animations: { self.alpha = alpha }, completion: completion)
        }
    }
}
