//
//  LMKThemeApplying.swift
//  LumiKit
//
//  The one hook every component implements to resolve its Style against the
//  theme, re-run on theme and Dynamic Type changes.
//

import UIKit

/// Adopted by views and view controllers whose appearance derives from the theme.
///
/// `applyTheme(_:)` must be idempotent: it re-resolves every Style field against
/// `theme` and re-applies text styles. It is called once from
/// `lmk_startApplyingTheme()` and again whenever the `lmkTheme` trait or the
/// preferred content size category changes. Colors assigned from `LMKColor.*`
/// re-resolve on their own and need no re-assignment here.
@MainActor
public protocol LMKThemeApplying: AnyObject {
    func applyTheme(_ theme: LMKTheme)
}

public extension LMKThemeApplying where Self: UIView {
    /// Registers for theme and content-size-category changes and applies the theme once.
    /// Call it as the last line of `init`.
    func lmk_startApplyingTheme() {
        registerForTraitChanges([LMKThemeTrait.self, UITraitPreferredContentSizeCategory.self]) { (view: Self, _: UITraitCollection) in
            view.applyTheme(view.traitCollection.lmkTheme)
        }
        applyTheme(traitCollection.lmkTheme)
    }
}

public extension LMKThemeApplying where Self: UIViewController {
    /// Registers for theme and content-size-category changes and applies the theme once.
    /// Call it from `viewDidLoad` after the view hierarchy exists.
    func lmk_startApplyingTheme() {
        registerForTraitChanges([LMKThemeTrait.self, UITraitPreferredContentSizeCategory.self]) { (controller: Self, _: UITraitCollection) in
            controller.applyTheme(controller.traitCollection.lmkTheme)
        }
        applyTheme(traitCollection.lmkTheme)
    }
}
