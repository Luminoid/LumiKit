//
//  LMKColor.swift
//  LumiKit
//
//  Color tokens. Each is a dynamic color that resolves against the theme
//  carried by the view's traits, so a `label.textColor = LMKColor.primary`
//  follows `LMKTheme.apply(_:)`, dark mode, and Increase Contrast.
//

import UIKit

/// Theme color tokens.
///
/// Usage: `view.backgroundColor = LMKColor.backgroundPrimary`
///
/// Every token is a trait-aware `UIColor`: it reads the theme from the resolving
/// trait collection (`traits.lmkTheme`), so it follows theme switches, the
/// interface style, and, for accent roles, Increase Contrast. Cached as
/// `static let`s so identity comparisons keep working.
public nonisolated enum LMKColor {
    // MARK: - Accents

    public static let primary = accent(\.primary)
    public static let primaryVariant = accent(\.primaryVariant)
    public static let secondary = accent(\.secondary)
    public static let tertiary = accent(\.tertiary)
    public static let success = accent(\.success)
    public static let warning = accent(\.warning)
    public static let error = accent(\.error)
    public static let info = accent(\.info)
    /// Foreground on any filled accent.
    public static let onAccent = plain(\.onAccent)

    // MARK: - Text

    public static let textPrimary = plain(\.textPrimary)
    public static let textSecondary = plain(\.textSecondary)
    public static let textTertiary = plain(\.textTertiary)
    public static let link = accent(\.link)

    // MARK: - Surfaces

    public static let backgroundPrimary = plain(\.backgroundPrimary)
    public static let backgroundSecondary = plain(\.backgroundSecondary)
    public static let backgroundTertiary = plain(\.backgroundTertiary)

    // MARK: - Lines and fills

    public static let divider = plain(\.divider)
    public static let outline = plain(\.outline)
    public static let fill = plain(\.fill)
    public static let fillStrong = plain(\.fillStrong)

    // MARK: - Overlays

    public static let scrim = plain(\.scrim)
    public static let pressedOverlay = plain(\.pressedOverlay)
    public static let selection = plain(\.selection)

    // MARK: - Resolution

    /// Resolves `role` in the theme carried by `traits`, without the contrast policy.
    public static func resolved(_ role: KeyPath<LMKColorTheme, UIColor> & Sendable, with traits: UITraitCollection) -> UIColor {
        traits.lmkTheme.colors[keyPath: role].resolvedColor(with: traits)
    }

    private static func plain(_ role: KeyPath<LMKColorTheme, UIColor> & Sendable) -> UIColor {
        UIColor { traits in
            resolved(role, with: traits)
        }
    }

    /// Accent roles get the theme's Increase Contrast boost: darker in light mode, lighter in dark mode.
    private static func accent(_ role: KeyPath<LMKColorTheme, UIColor> & Sendable) -> UIColor {
        UIColor { traits in
            let colors = traits.lmkTheme.colors
            let base = colors[keyPath: role].resolvedColor(with: traits)
            guard traits.accessibilityContrast == .high, colors.highContrastBoost > 0 else { return base }
            // `lmk_adjustedBrightness(by:)` multiplies brightness: lighter on a dark background, darker on a light one.
            let factor = traits.userInterfaceStyle == .dark ? 1 + colors.highContrastBoost : 1 - colors.highContrastBoost
            return base.lmk_adjustedBrightness(by: factor)
        }
    }

    /// The text color for content on a tinted fill: `preferred` (usually `onAccent`) normally;
    /// under Increase Contrast, black or white by the fill's luminance, so a light accent (or one
    /// the boost lightened in Dark Mode) never carries white text. Filled buttons, chips, and badges use it.
    public static func onFill(_ fill: UIColor, preferred: UIColor) -> UIColor {
        UIColor { traits in
            guard traits.accessibilityContrast == .high else { return preferred.resolvedColor(with: traits) }
            return fill.resolvedColor(with: traits).lmk_contrastingTextColor
        }
    }
}
