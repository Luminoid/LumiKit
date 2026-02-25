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
            color: shadowColor(lightAlpha: config.cellCardLightAlpha, darkAlpha: config.cellCardDarkAlpha),
            offset: config.cellCardOffset,
            radius: config.cellCardRadius,
            opacity: config.cellCardOpacity
        )
    }

    public static func card() -> LMKShadowStyle {
        LMKShadowStyle(
            color: shadowColor(lightAlpha: config.cardLightAlpha, darkAlpha: config.cardDarkAlpha),
            offset: config.cardOffset,
            radius: config.cardRadius,
            opacity: config.cardOpacity
        )
    }

    public static func button() -> LMKShadowStyle {
        LMKShadowStyle(
            color: shadowColor(lightAlpha: config.buttonLightAlpha, darkAlpha: config.buttonDarkAlpha),
            offset: config.buttonOffset,
            radius: config.buttonRadius,
            opacity: config.buttonOpacity
        )
    }

    public static func small() -> LMKShadowStyle {
        LMKShadowStyle(
            color: shadowColor(lightAlpha: config.smallLightAlpha, darkAlpha: config.smallDarkAlpha),
            offset: config.smallOffset,
            radius: config.smallRadius,
            opacity: config.smallOpacity
        )
    }
}
