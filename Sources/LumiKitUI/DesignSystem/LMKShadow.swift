//
//  LMKShadow.swift
//  LumiKit
//
//  Shadow tokens.
//

import UIKit

/// Shadow tokens for the Lumi design system.
/// Uses `UIColor.black` directly (not theme-dependent).
public enum LMKShadow {
    /// Standard shadow opacity for icon overlays (e.g. category icon on photo).
    public static let opacity: Float = 0.8

    /// Shadow color that adapts to light/dark mode (lower opacity in dark mode).
    private static func shadowColor(lightAlpha: CGFloat, darkAlpha: CGFloat) -> UIColor {
        UIColor { traitCollection in
            let alpha = traitCollection.userInterfaceStyle == .dark ? darkAlpha : lightAlpha
            return UIColor.black.withAlphaComponent(alpha)
        }
    }

    public static func cellCard() -> (color: CGColor, offset: CGSize, radius: CGFloat, opacity: Float) {
        (color: shadowColor(lightAlpha: 0.1, darkAlpha: 0.3).cgColor, offset: CGSize(width: 0, height: 2), radius: 6, opacity: 0.5)
    }

    public static func card() -> (color: CGColor, offset: CGSize, radius: CGFloat, opacity: Float) {
        (color: shadowColor(lightAlpha: 0.1, darkAlpha: 0.3).cgColor, offset: CGSize(width: 0, height: 2), radius: 8, opacity: 1.0)
    }

    public static func button() -> (color: CGColor, offset: CGSize, radius: CGFloat, opacity: Float) {
        (color: shadowColor(lightAlpha: 0.15, darkAlpha: 0.4).cgColor, offset: CGSize(width: 0, height: 2), radius: 4, opacity: 1.0)
    }

    public static func small() -> (color: CGColor, offset: CGSize, radius: CGFloat, opacity: Float) {
        (color: shadowColor(lightAlpha: 0.1, darkAlpha: 0.3).cgColor, offset: CGSize(width: 0, height: 1), radius: 2, opacity: 1.0)
    }
}
