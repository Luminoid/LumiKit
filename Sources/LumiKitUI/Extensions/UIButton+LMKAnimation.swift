//
//  UIButton+LMKAnimation.swift
//  LumiKit
//
//  Button press animation and haptic feedback extension.
//

import UIKit

public extension UIButton {
    /// Animate a button press with scale-down + spring return and medium haptic.
    @objc func lmk_animatePress() {
        LMKAnimationHelper.animateButtonPress(self)
        LMKHapticFeedbackHelper.medium()
    }
}
