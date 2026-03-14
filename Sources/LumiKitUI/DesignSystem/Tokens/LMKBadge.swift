//
//  LMKBadge.swift
//  LumiKit
//
//  Badge dimension tokens.
//  Proxies to `LMKThemeManager.shared.badge` for customization.
//

import UIKit

/// Badge dimension tokens for the Lumi design system.
///
/// Proxies to `LMKThemeManager.shared.badge` for customization.
public enum LMKBadge {
    private static var config: LMKBadgeTheme {
        LMKThemeManager.shared.badge
    }

    /// Minimum badge width.
    public static var minWidth: CGFloat { config.minWidth }
    /// Badge height.
    public static var height: CGFloat { config.height }
    /// Horizontal padding inside badge.
    public static var horizontalPadding: CGFloat { config.horizontalPadding }
    /// Border width around badge.
    public static var borderWidth: CGFloat { config.borderWidth }
    /// Ratio of dot badge size to badge height.
    public static var dotSizeRatio: CGFloat { config.dotSizeRatio }
    /// Badge background color (falls back to `LMKColor.error`).
    public static var backgroundColor: UIColor { config.backgroundColor ?? LMKColor.error }
    /// Badge text color (falls back to `LMKColor.white`).
    public static var textColor: UIColor { config.textColor ?? LMKColor.white }
    /// Badge border color (falls back to `LMKColor.backgroundPrimary`).
    public static var borderColor: UIColor { config.borderColor ?? LMKColor.backgroundPrimary }
}
