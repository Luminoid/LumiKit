//
//  UIButton+LMKAnimation.swift
//  LumiKit
//
//  Button press animation and haptic feedback extension.
//

import UIKit

extension UIButton {
    @objc public func lmk_animatePress() {
        LMKAnimationHelper.animateButtonPress(self)
        LMKHapticFeedbackHelper.medium()
    }

    @objc public func lmk_animateRelease() {
        // Release animation handled by LMKAnimationHelper's spring return.
    }
}
