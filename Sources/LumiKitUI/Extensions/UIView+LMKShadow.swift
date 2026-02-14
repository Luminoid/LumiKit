//
//  UIView+LMKShadow.swift
//  LumiKit
//
//  One-call shadow application using LMKShadow design tokens.
//

import UIKit

public extension UIView {
    /// Apply a shadow from an `LMKShadow` token tuple.
    ///
    /// ```swift
    /// cardView.lmk_applyShadow(LMKShadow.card())
    /// headerView.lmk_applyShadow(LMKShadow.small())
    /// ```
    func lmk_applyShadow(_ shadow: (color: CGColor, offset: CGSize, radius: CGFloat, opacity: Float)) {
        layer.shadowColor = shadow.color
        layer.shadowOffset = shadow.offset
        layer.shadowRadius = shadow.radius
        layer.shadowOpacity = shadow.opacity
        layer.masksToBounds = false
    }

    /// Remove shadow from the view.
    func lmk_removeShadow() {
        layer.shadowOpacity = 0
    }
}
