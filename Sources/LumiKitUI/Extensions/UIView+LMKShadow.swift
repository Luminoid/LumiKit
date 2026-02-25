//
//  UIView+LMKShadow.swift
//  LumiKit
//
//  One-call shadow application using LMKShadow design tokens.
//

import UIKit

public extension UIView {
    /// Apply a shadow from an `LMKShadowStyle`.
    ///
    /// ```swift
    /// cardView.lmk_applyShadow(LMKShadow.card())
    /// headerView.lmk_applyShadow(LMKShadow.small())
    /// ```
    ///
    /// - Important: `CALayer.shadowColor` stores a `CGColor` snapshot — it does **not**
    ///   auto-update on dark mode changes. If your shadow color differs between light and
    ///   dark mode, re-call this method inside a `registerForTraitChanges` handler:
    ///   ```swift
    ///   _ = registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: MyView, _) in
    ///       self.lmk_applyShadow(LMKShadow.card())
    ///   }
    ///   ```
    func lmk_applyShadow(_ shadow: LMKShadowStyle) {
        layer.shadowColor = shadow.color.cgColor
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
