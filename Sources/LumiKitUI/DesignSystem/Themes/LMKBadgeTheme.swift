//
//  LMKBadgeTheme.swift
//  LumiKit
//
//  Badge configuration for customizing badge appearance.
//

import UIKit

/// Badge configuration for the Lumi design system.
///
/// Override at app launch to customize badge appearance:
/// ```swift
/// LMKThemeManager.shared.apply(badge: .init(minWidth: 20, height: 20))
/// ```
public nonisolated struct LMKBadgeTheme: Sendable {
    /// Minimum badge width.
    public var minWidth: CGFloat
    /// Badge height.
    public var height: CGFloat
    /// Horizontal padding inside badge.
    public var horizontalPadding: CGFloat
    /// Border width around badge (0 for no border).
    public var borderWidth: CGFloat
    /// Ratio of dot badge size to badge height.
    public var dotSizeRatio: CGFloat
    /// Badge background color. `nil` uses `LMKColor.error` default.
    public var backgroundColor: UIColor?
    /// Badge text color. `nil` uses `LMKColor.white` default.
    public var textColor: UIColor?
    /// Badge border color. `nil` uses `LMKColor.backgroundPrimary` default.
    public var borderColor: UIColor?

    public init(
        minWidth: CGFloat = 18,
        height: CGFloat = 18,
        horizontalPadding: CGFloat = 6,
        borderWidth: CGFloat = 1.5,
        dotSizeRatio: CGFloat = 0.55,
        backgroundColor: UIColor? = nil,
        textColor: UIColor? = nil,
        borderColor: UIColor? = nil
    ) {
        self.minWidth = minWidth
        self.height = height
        self.horizontalPadding = horizontalPadding
        self.borderWidth = borderWidth
        self.dotSizeRatio = dotSizeRatio
        self.backgroundColor = backgroundColor
        self.textColor = textColor
        self.borderColor = borderColor
    }
}

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
