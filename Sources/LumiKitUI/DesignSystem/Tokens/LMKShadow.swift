//
//  LMKShadow.swift
//  LumiKit
//
//  Shadow tokens.
//  Proxies to `LMKThemeManager.shared.shadow` for customization.
//

import UIKit

/// Encapsulates shadow configuration for consistent application.
public struct LMKShadowStyle {
    /// Shadow color (dynamic UIColor that adapts to dark mode).
    public let color: UIColor
    /// Shadow offset.
    public let offset: CGSize
    /// Shadow blur radius.
    public let radius: CGFloat
    /// Shadow opacity.
    public let opacity: Float
}

/// Shadow tokens for the Lumi design system.
///
/// Customize by applying a shadow theme:
/// ```swift
/// LMKThemeManager.shared.apply(shadow: .init(cellCardRadius: 8, cardRadius: 12))
/// ```
public enum LMKShadow {
    private static var config: LMKShadowTheme {
        LMKThemeManager.shared.shadow
    }

    /// Shadow opacity for icon overlays (e.g. category icon on photo).
    /// For general-purpose shadow opacity, use the individual shadow functions (`cellCard()`, `card()`, etc.).
    public static var opacity: Float { config.iconOverlayOpacity }

    /// Shadow color that adapts to light/dark mode (lower opacity in dark mode).
    private static func shadowColor(lightAlpha: CGFloat, darkAlpha: CGFloat) -> UIColor {
        UIColor { traitCollection in
            let alpha = traitCollection.userInterfaceStyle == .dark ? darkAlpha : lightAlpha
            return UIColor.black.withAlphaComponent(alpha)
        }
    }

    public static func cellCard() -> LMKShadowStyle {
        LMKShadowStyle(
            color: shadowColor(lightAlpha: config.cellCard.lightAlpha, darkAlpha: config.cellCard.darkAlpha),
            offset: config.cellCard.offset,
            radius: config.cellCard.radius,
            opacity: config.cellCard.opacity
        )
    }

    public static func card() -> LMKShadowStyle {
        LMKShadowStyle(
            color: shadowColor(lightAlpha: config.card.lightAlpha, darkAlpha: config.card.darkAlpha),
            offset: config.card.offset,
            radius: config.card.radius,
            opacity: config.card.opacity
        )
    }

    public static func button() -> LMKShadowStyle {
        LMKShadowStyle(
            color: shadowColor(lightAlpha: config.button.lightAlpha, darkAlpha: config.button.darkAlpha),
            offset: config.button.offset,
            radius: config.button.radius,
            opacity: config.button.opacity
        )
    }

    public static func small() -> LMKShadowStyle {
        LMKShadowStyle(
            color: shadowColor(lightAlpha: config.small.lightAlpha, darkAlpha: config.small.darkAlpha),
            offset: config.small.offset,
            radius: config.small.radius,
            opacity: config.small.opacity
        )
    }

    public static func medium() -> LMKShadowStyle {
        LMKShadowStyle(
            color: shadowColor(lightAlpha: config.medium.lightAlpha, darkAlpha: config.medium.darkAlpha),
            offset: config.medium.offset,
            radius: config.medium.radius,
            opacity: config.medium.opacity
        )
    }

    public static func large() -> LMKShadowStyle {
        LMKShadowStyle(
            color: shadowColor(lightAlpha: config.large.lightAlpha, darkAlpha: config.large.darkAlpha),
            offset: config.large.offset,
            radius: config.large.radius,
            opacity: config.large.opacity
        )
    }
}
