//
//  LMKLayout.swift
//  LumiKit
//
//  General layout dimension tokens.
//  Proxies to `LMKThemeManager.shared.layout` for customization.
//

import UIKit

/// General layout dimension tokens for the Lumi design system.
///
/// Customize by applying a layout theme:
/// ```swift
/// LMKThemeManager.shared.apply(layout: .init(iconMedium: 28))
/// ```
public enum LMKLayout {
    private static var config: LMKLayoutTheme {
        LMKThemeManager.shared.layout
    }

    /// Minimum touch target size (44pt per HIG).
    public static var minimumTouchTarget: CGFloat { config.minimumTouchTarget }
    /// Medium icon size — default 24pt.
    public static var iconMedium: CGFloat { config.iconMedium }
    /// Small icon size — default 20pt.
    public static var iconSmall: CGFloat { config.iconSmall }
    /// Extra small icon size (chevrons, compact indicators) — default 16pt.
    public static var iconExtraSmall: CGFloat { config.iconExtraSmall }
    /// Pull-to-refresh threshold; compact preview height — default 80pt.
    public static var pullThreshold: CGFloat { config.pullThreshold }
    /// Minimum cell height; name limit — default 100pt.
    public static var cellHeightMin: CGFloat { config.cellHeightMin }
    /// Search bar container height — default 36pt.
    public static var searchBarHeight: CGFloat { config.searchBarHeight }
    /// Search bar magnifying glass icon size — default 18pt.
    public static var searchBarIconSize: CGFloat { config.searchBarIconSize }
    /// Clear button size — default 22pt.
    public static var clearButtonSize: CGFloat { config.clearButtonSize }
}
