//
//  LMKColorTheme.swift
//  LumiKit
//
//  Semantic color roles. Every role has a default, so an app theme names only
//  the colors that differ (usually the brand accents and surfaces).
//

import UIKit

/// The color roles of a theme.
///
/// ```swift
/// extension LMKTheme {
///     static let petfolio = LMKTheme(colors: LMKColorTheme(
///         primary: .lmk_dynamic(lightHex: 0xD4875A, darkHex: 0xBB7146),
///         secondary: .lmk_dynamic(lightHex: 0x7CC7BD, darkHex: 0x7EBBB3)
///     ))
/// }
/// ```
///
/// Dynamic colors (`UIColor { traits in … }`, `lmk_dynamic`) keep light and dark
/// variants; `LMKColor.*` wraps each role in a trait-aware provider so views
/// re-render when the theme, the interface style, or the contrast setting changes.
public nonisolated struct LMKColorTheme: Sendable {
    // MARK: Accents

    /// Brand accent: filled buttons, selected segments, links by default.
    public var primary: UIColor
    /// A shade of `primary` for pressed and selected states.
    public var primaryVariant: UIColor
    public var secondary: UIColor
    public var tertiary: UIColor
    public var success: UIColor
    public var warning: UIColor
    public var error: UIColor
    public var info: UIColor
    /// Foreground on any filled accent (button titles, badge text).
    public var onAccent: UIColor

    // MARK: Text

    public var textPrimary: UIColor
    public var textSecondary: UIColor
    public var textTertiary: UIColor
    /// Tappable text; defaults to `primary`.
    public var link: UIColor

    // MARK: Surfaces

    public var backgroundPrimary: UIColor
    public var backgroundSecondary: UIColor
    public var backgroundTertiary: UIColor

    // MARK: Lines and fills

    public var divider: UIColor
    /// Borders around images, cards, and outlined controls; defaults to a translucent `divider`.
    public var outline: UIColor
    /// Inactive fills: slider tracks, switch off-track.
    public var fill: UIColor
    /// Stronger inactive fill: inactive page dots, neutral chips.
    public var fillStrong: UIColor

    // MARK: Overlays

    /// Base of dimming views behind sheets and panels (applied with `LMKAlpha.dimming`).
    public var scrim: UIColor
    /// Highlight wash over pressed rows and cards.
    public var pressedOverlay: UIColor
    /// Background of selected rows and segments; defaults to a translucent `primary`.
    public var selection: UIColor

    /// Brightness delta applied to accent roles under Increase Contrast (`0` disables the policy).
    public var highContrastBoost: CGFloat

    public init(
        primary: UIColor = .systemGreen,
        primaryVariant: UIColor? = nil,
        secondary: UIColor = .systemGray,
        tertiary: UIColor = .systemBrown,
        success: UIColor = .systemGreen,
        warning: UIColor = .systemOrange,
        error: UIColor = .systemRed,
        info: UIColor = .systemBlue,
        onAccent: UIColor = UIColor(white: 0.98, alpha: 1),
        textPrimary: UIColor = .label,
        textSecondary: UIColor = .secondaryLabel,
        textTertiary: UIColor = .tertiaryLabel,
        link: UIColor? = nil,
        backgroundPrimary: UIColor = .systemBackground,
        backgroundSecondary: UIColor = .secondarySystemBackground,
        backgroundTertiary: UIColor = .tertiarySystemBackground,
        divider: UIColor = .separator,
        outline: UIColor? = nil,
        fill: UIColor = .lmk_dynamic(light: UIColor(white: 0.85, alpha: 1), dark: UIColor(white: 0.25, alpha: 1)),
        fillStrong: UIColor = .lmk_dynamic(light: UIColor(white: 0.75, alpha: 1), dark: UIColor(white: 0.35, alpha: 1)),
        scrim: UIColor = .black,
        pressedOverlay: UIColor? = nil,
        selection: UIColor? = nil,
        highContrastBoost: CGFloat = 0.12
    ) {
        self.primary = primary
        self.primaryVariant = primaryVariant ?? UIColor { traits in
            primary.resolvedColor(with: traits).lmk_adjustedBrightness(by: 0.85)
        }
        self.secondary = secondary
        self.tertiary = tertiary
        self.success = success
        self.warning = warning
        self.error = error
        self.info = info
        self.onAccent = onAccent
        self.textPrimary = textPrimary
        self.textSecondary = textSecondary
        self.textTertiary = textTertiary
        self.link = link ?? primary
        self.backgroundPrimary = backgroundPrimary
        self.backgroundSecondary = backgroundSecondary
        self.backgroundTertiary = backgroundTertiary
        self.divider = divider
        self.outline = outline ?? divider.withAlphaComponent(0.5)
        self.fill = fill
        self.fillStrong = fillStrong
        self.scrim = scrim
        self.pressedOverlay = pressedOverlay ?? .lmk_dynamic(
            light: UIColor.black.withAlphaComponent(0.1),
            dark: UIColor.white.withAlphaComponent(0.2)
        )
        self.selection = selection ?? primary.withAlphaComponent(0.15)
        self.highContrastBoost = max(0, highContrastBoost)
    }
}

nonisolated extension LMKColorTheme: Equatable {
    /// Every color role, in declaration order.
    public static let roles: [KeyPath<LMKColorTheme, UIColor> & Sendable] = [
        \.primary, \.primaryVariant, \.secondary, \.tertiary, \.success, \.warning, \.error, \.info, \.onAccent,
        \.textPrimary, \.textSecondary, \.textTertiary, \.link,
        \.backgroundPrimary, \.backgroundSecondary, \.backgroundTertiary,
        \.divider, \.outline, \.fill, \.fillStrong,
        \.scrim, \.pressedOverlay, \.selection,
    ]

    /// Colors compare by their resolved light and dark values (see `lmk_isVisuallyEqual`).
    public static func == (lhs: Self, rhs: Self) -> Bool {
        guard lhs.highContrastBoost == rhs.highContrastBoost else { return false }
        return roles.allSatisfy { lhs[keyPath: $0].lmk_isVisuallyEqual(to: rhs[keyPath: $0]) }
    }
}
