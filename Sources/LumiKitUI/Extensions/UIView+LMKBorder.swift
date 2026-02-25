//
//  UIView+LMKBorder.swift
//  LumiKit
//
//  Border and corner radius application using design tokens.
//

import UIKit

public extension UIView {
    /// Apply border with color and width, optionally setting corner radius.
    ///
    /// - Parameters:
    ///   - color: Border color.
    ///   - width: Border width (default 1pt).
    ///   - cornerRadius: Optional corner radius. When provided, also sets `masksToBounds`.
    ///   - clipsToBounds: Whether to clip to bounds when `cornerRadius` is provided (default `true`).
    ///     Set to `false` when you need both a border with corner radius and a shadow.
    ///
    /// ```swift
    /// view.lmk_applyBorder(color: LMKColor.divider, width: 1, cornerRadius: LMKCornerRadius.small)
    /// ```
    func lmk_applyBorder(color: UIColor, width: CGFloat = 1, cornerRadius: CGFloat? = nil, clipsToBounds: Bool = true) {
        layer.borderColor = color.cgColor
        layer.borderWidth = width
        if let cornerRadius {
            layer.cornerRadius = cornerRadius
            layer.masksToBounds = clipsToBounds
        }
    }

    /// Remove border from the view.
    func lmk_removeBorder() {
        layer.borderWidth = 0
        layer.borderColor = nil
    }

    /// Apply corner radius using design tokens.
    ///
    /// ```swift
    /// view.lmk_applyCornerRadius(LMKCornerRadius.medium)
    /// ```
    func lmk_applyCornerRadius(_ radius: CGFloat, masking: Bool = true) {
        layer.cornerRadius = radius
        layer.masksToBounds = masking
    }

    /// Make the view circular (uses half of the smallest dimension).
    /// Call after the view has been laid out (e.g., in `layoutSubviews`).
    func lmk_makeCircular() {
        let minDimension = min(bounds.width, bounds.height)
        layer.cornerRadius = minDimension / 2
        layer.masksToBounds = true
    }
}
