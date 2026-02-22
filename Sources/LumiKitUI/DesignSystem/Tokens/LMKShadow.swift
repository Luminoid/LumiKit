//
//  LMKShadow.swift
//  LumiKit
//
//  Shadow tokens.
//  Proxies to `LMKThemeManager.shared.shadow` for customization.
//

import UIKit

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

    /// Standard shadow opacity for icon overlays (e.g. category icon on photo).
    public static var opacity: Float { config.iconOverlayOpacity }

    /// Shadow color that adapts to light/dark mode (lower opacity in dark mode).
    private static func shadowColor(lightAlpha: CGFloat, darkAlpha: CGFloat) -> UIColor {
        UIColor { traitCollection in
            let alpha = traitCollection.userInterfaceStyle == .dark ? darkAlpha : lightAlpha
            return UIColor.black.withAlphaComponent(alpha)
        }
    }

    public static func cellCard() -> (color: CGColor, offset: CGSize, radius: CGFloat, opacity: Float) {
        (
            color: shadowColor(lightAlpha: config.cellCardLightAlpha, darkAlpha: config.cellCardDarkAlpha).cgColor,
            offset: config.cellCardOffset,
            radius: config.cellCardRadius,
            opacity: config.cellCardOpacity
        )
    }

    public static func card() -> (color: CGColor, offset: CGSize, radius: CGFloat, opacity: Float) {
        (
            color: shadowColor(lightAlpha: config.cardLightAlpha, darkAlpha: config.cardDarkAlpha).cgColor,
            offset: config.cardOffset,
            radius: config.cardRadius,
            opacity: config.cardOpacity
        )
    }

    public static func button() -> (color: CGColor, offset: CGSize, radius: CGFloat, opacity: Float) {
        (
            color: shadowColor(lightAlpha: config.buttonLightAlpha, darkAlpha: config.buttonDarkAlpha).cgColor,
            offset: config.buttonOffset,
            radius: config.buttonRadius,
            opacity: config.buttonOpacity
        )
    }

    public static func small() -> (color: CGColor, offset: CGSize, radius: CGFloat, opacity: Float) {
        (
            color: shadowColor(lightAlpha: config.smallLightAlpha, darkAlpha: config.smallDarkAlpha).cgColor,
            offset: config.smallOffset,
            radius: config.smallRadius,
            opacity: config.smallOpacity
        )
    }
}
