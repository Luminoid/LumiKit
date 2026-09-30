//
//  LMKThemeTrait.swift
//  LumiKit
//
//  The trait that carries the theme through the view hierarchy. Because it
//  affects color appearance, UIKit re-resolves every dynamic `UIColor` in a
//  window when the theme changes, which is what makes `LMKColor.*`
//  assignments in app code follow `LMKTheme.apply(_:)`.
//

import UIKit

/// Custom trait holding an `LMKThemeReference`.
///
/// `LMKTheme.apply(_:)` stamps every window's `traitOverrides.lmkTheme`; a host can
/// scope a different theme to a subtree (`preview.traitOverrides.lmkTheme = LMKThemeReference(candidate)`).
public nonisolated struct LMKThemeTrait: UITraitDefinition {
    public static let defaultValue = LMKThemeReference.global
    public static let identifier = "com.lumi.lumikit.theme"
    public static let name = "LumiKit Theme"
    public static let affectsColorAppearance = true
}

public nonisolated extension UITraitCollection {
    /// The theme in effect for these traits: the scoped override, or the process-wide theme.
    var lmkTheme: LMKTheme {
        self[LMKThemeTrait.self].theme
    }
}

public nonisolated extension UIMutableTraits {
    /// The theme handle carried by these traits; set it to scope a theme to a subtree.
    ///
    /// On `traitOverrides`, reading requires an override to be present (UIKit traps otherwise);
    /// check `traitOverrides.contains(LMKThemeTrait.self)` first, or read `traitCollection.lmkTheme`.
    var lmkTheme: LMKThemeReference {
        get { self[LMKThemeTrait.self] }
        set { self[LMKThemeTrait.self] = newValue }
    }
}
