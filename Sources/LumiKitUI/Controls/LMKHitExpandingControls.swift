//
//  LMKHitExpandingControls.swift
//  LumiKit
//
//  System controls the kit wraps at a visual height under the minimum touch
//  target (a 34pt slider track, a 36pt search field), given the kit-wide
//  `point(inside:with:)` expansion so the whole row responds.
//

import UIKit

/// A bare `UIControl` (a tappable row region) whose hit area is at least the minimum touch target tall.
final class LMKHitExpandingControl: UIControl {
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        guard isEnabled, !isHidden else { return false }
        return lmk_hitTestBounds(minimumSide: traitCollection.lmkTheme.layout.minimumTouchTarget).contains(point)
    }
}

/// A `UISlider` whose hit area is at least the minimum touch target tall.
final class LMKHitExpandingSlider: UISlider {
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        guard isEnabled, !isHidden else { return false }
        return lmk_hitTestBounds(minimumSide: traitCollection.lmkTheme.layout.minimumTouchTarget).contains(point)
    }
}

/// A `UITextField` whose hit area is at least the minimum touch target tall.
final class LMKHitExpandingTextField: UITextField {
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        guard isEnabled, !isHidden else { return false }
        return lmk_hitTestBounds(minimumSide: traitCollection.lmkTheme.layout.minimumTouchTarget).contains(point)
    }
}
