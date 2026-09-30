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
    var lmk_hitTestInsets: UIEdgeInsets {
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
    ///
    /// Wire this up in your `UIControl` subclass:
    /// ```swift
    /// override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
    ///     lmk_point(inside: point, with: event)
    /// }
    /// ```
    func lmk_point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        if lmk_hitTestInsets == .zero || !isEnabled || isHidden {
            return bounds.contains(point)
        }
        return bounds.inset(by: lmk_hitTestInsets).contains(point)
    }
}

public extension UIView {
    /// `bounds` grown symmetrically until each side is at least `minimumSide`, then adjusted by
    /// `insets` (negative values grow it further). LumiKit controls use it from `point(inside:with:)`
    /// so small chips, dots, and glyph buttons keep a 44pt target.
    func lmk_hitTestBounds(minimumSide: CGFloat, insets: UIEdgeInsets = .zero) -> CGRect {
        let dx = max(0, (minimumSide - bounds.width) / 2)
        let dy = max(0, (minimumSide - bounds.height) / 2)
        return bounds.insetBy(dx: -dx, dy: -dy).inset(by: insets)
    }
}
