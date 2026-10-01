//
//  ExampleTheme.swift
//  LumiKitExample
//
//  Demonstrates how to declare an app theme for LumiKit: name only the colors
//  that differ from the defaults and register it once at launch. A second
//  theme exists so the Theme Switcher page (and the sweep) can prove that
//  every component re-renders when the theme changes.
//

import LumiKitUI
import UIKit

extension LMKTheme {
    /// The catalog's brand theme; applied once from the AppDelegate, before any scene connects.
    static let example = LMKTheme(
        colors: LMKColorTheme(
            primary: UIColor(red: 0.29, green: 0.69, blue: 0.49, alpha: 1.0), // #4CAF7D
            primaryVariant: UIColor(red: 0.24, green: 0.59, blue: 0.42, alpha: 1.0),
            secondary: UIColor(red: 0.35, green: 0.55, blue: 0.75, alpha: 1.0) // #598CBF
        )
    )

    /// A contrasting theme: indigo and teal accents on a cool tinted background, with a
    /// rounder corner scale, so a switch is visible on every page.
    static let ocean = LMKTheme(
        colors: LMKColorTheme(
            primary: UIColor(red: 0.30, green: 0.36, blue: 0.85, alpha: 1.0),
            secondary: UIColor(red: 0.10, green: 0.62, blue: 0.66, alpha: 1.0),
            tertiary: UIColor(red: 0.85, green: 0.45, blue: 0.30, alpha: 1.0),
            backgroundPrimary: .lmk_dynamic(light: UIColor(red: 0.96, green: 0.97, blue: 1.0, alpha: 1), dark: UIColor(red: 0.06, green: 0.07, blue: 0.11, alpha: 1)),
            backgroundSecondary: .lmk_dynamic(light: UIColor(red: 0.91, green: 0.93, blue: 0.98, alpha: 1), dark: UIColor(red: 0.11, green: 0.12, blue: 0.18, alpha: 1))
        ),
        cornerRadius: LMKCornerRadiusTheme(xs: 6, small: 12, medium: 18, large: 24, xl: 28, xxl: 36)
    )
}

/// The themes the switcher and the sweep can apply, by name.
enum ExampleThemes {
    static let names = ["example", "ocean", "default"]

    /// `nil` for a name that is not in `names`, so a typo in `-lmk-theme` is reported, not swallowed.
    static func theme(named name: String) -> LMKTheme? {
        switch name.lowercased() {
        case "example": .example
        case "ocean": .ocean
        case "default": .default
        default: nil
        }
    }
}
