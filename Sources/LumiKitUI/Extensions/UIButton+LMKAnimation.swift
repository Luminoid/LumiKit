//
//  UIButton+LMKAnimation.swift
//  LumiKit
//
//  Button press animation and haptic feedback extension.
//

import UIKit

public extension UIButton {
    @objc func lmk_animatePress() {
        LMKAnimationHelper.animateButtonPress(self)
        LMKHapticFeedbackHelper.medium()
    }

    @objc func lmk_animateRelease() {
        // Release animation handled by LMKAnimationHelper's spring return.
    }
}
