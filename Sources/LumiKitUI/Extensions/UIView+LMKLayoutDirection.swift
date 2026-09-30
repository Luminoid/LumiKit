//
//  UIView+LMKLayoutDirection.swift
//  LumiKit
//
//  Forcing a layout direction on a subtree (RTL previews, tests) so that
//  natural text alignment follows it too, through the iOS 26 trait.
//

import UIKit

public extension UIView {
    /// Forces the layout direction of this view: `semanticContentAttribute` plus, on iOS 26,
    /// `resolvesNaturalAlignmentWithBaseWritingDirection`, so labels with `.natural` alignment
    /// in the subtree follow the forced direction instead of the user's language (before 26
    /// only the layout flips; text alignment stays with the language).
    ///
    /// `semanticContentAttribute` is not inherited by subviews that leave theirs `.unspecified`,
    /// so for a whole-screen RTL preview pair this with
    /// `UIView.appearance().semanticContentAttribute = .forceRightToLeft` before the views are
    /// created (the Example app's `-lmk-rtl` launch argument does exactly that). Shipping apps
    /// leave the direction to the locale. `nil` restores the inherited direction.
    func lmk_forceLayoutDirection(_ direction: UIUserInterfaceLayoutDirection?) {
        switch direction {
        case .leftToRight: semanticContentAttribute = .forceLeftToRight
        case .rightToLeft: semanticContentAttribute = .forceRightToLeft
        case nil: semanticContentAttribute = .unspecified
        @unknown default: semanticContentAttribute = .unspecified
        }
        if #available(iOS 26, *) {
            if direction == nil {
                traitOverrides.remove(UITraitResolvesNaturalAlignmentWithBaseWritingDirection.self)
            } else {
                traitOverrides.resolvesNaturalAlignmentWithBaseWritingDirection = true
            }
        }
    }

    /// The direction forced by `lmk_forceLayoutDirection(_:)`, `nil` when inherited.
    var lmk_forcedLayoutDirection: UIUserInterfaceLayoutDirection? {
        switch semanticContentAttribute {
        case .forceLeftToRight: .leftToRight
        case .forceRightToLeft: .rightToLeft
        default: nil
        }
    }
}
