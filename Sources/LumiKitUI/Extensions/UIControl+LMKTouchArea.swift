//
//  UIControl+LMKTouchArea.swift
//  LumiKit
//
//  Extension to expand or shrink the touch/hit area of any UIControl via edge insets.
//  Use negative insets to expand the touchable area (e.g. for small buttons).
//

import UIKit

private nonisolated(unsafe) var lmk_touchAreaEdgeInsetsKey: UInt8 = 0

public extension UIControl {
    /// Edge insets applied to the hit-test area. Use negative values to expand the touch area.
    var lmk_touchAreaEdgeInsets: UIEdgeInsets {
        get {
            if let value = objc_getAssociatedObject(self, &lmk_touchAreaEdgeInsetsKey) as? NSValue {
                var edgeInsets = UIEdgeInsets.zero
                value.getValue(&edgeInsets)
                return edgeInsets
            }
            return .zero
        }
        set {
            let value = NSValue(uiEdgeInsets: newValue)
            objc_setAssociatedObject(self, &lmk_touchAreaEdgeInsetsKey, value, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    /// Check if point is inside the expanded touch area.
    /// Call from your `point(inside:with:)` override if you use `lmk_touchAreaEdgeInsets`.
    func lmk_pointInside(_ point: CGPoint, with event: UIEvent?) -> Bool {
        if lmk_touchAreaEdgeInsets == .zero || !isEnabled || isHidden {
            return bounds.contains(point)
        }
        return bounds.inset(by: lmk_touchAreaEdgeInsets).contains(point)
    }
}
