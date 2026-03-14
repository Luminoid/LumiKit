//
//  LMKTouchExpandedButton.swift
//  LumiKit
//
//  Button subclass that uses the expanded touch area from UIControl+LMKTouchArea.
//

import UIKit

/// Button that automatically applies `lmk_pointInside` for expanded touch areas.
/// Use with `lmk_touchAreaEdgeInsets` on `UIControl+LMKTouchArea` for minimum 44x44pt targets.
final class LMKTouchExpandedButton: UIButton {
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        lmk_pointInside(point, with: event)
    }
}
