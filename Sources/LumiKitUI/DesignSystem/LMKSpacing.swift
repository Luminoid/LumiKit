//
//  LMKSpacing.swift
//  LumiKit
//
//  Spacing tokens (4pt base unit).
//  Proxies to `LMKThemeManager.shared.spacing` for customization.
//

import UIKit

/// General spacing tokens for the Lumi design system.
///
/// Customize by applying a spacing theme:
/// ```swift
/// LMKThemeManager.shared.apply(spacing: .init(large: 20, xxl: 28))
/// ```
public enum LMKSpacing {
    private static var config: LMKSpacingTheme {
        LMKThemeManager.shared.spacing
    }

    /// Very tight spacing (stacked labels) — default 2pt.
    public static var xxs: CGFloat { config.xxs }
    /// Tight spacing (icon to text) — default 4pt.
    public static var xs: CGFloat { config.xs }
    /// Standard spacing (elements in cards) — default 8pt.
    public static var small: CGFloat { config.small }
    /// Comfortable spacing (between sections) — default 12pt.
    public static var medium: CGFloat { config.medium }
    /// Section spacing (card padding) — default 16pt.
    public static var large: CGFloat { config.large }
    /// Large spacing (between major sections) — default 20pt.
    public static var xl: CGFloat { config.xl }
    /// Screen margins, large gaps — default 24pt.
    public static var xxl: CGFloat { config.xxl }

    /// Content horizontal padding for headers, list content, cards.
    /// Scales based on device size (iPhone -> iPad -> Mac Catalyst).
    /// iPad and Mac Catalyst values are intentionally hardcoded per screen size;
    /// iPhone falls through to `config.large` from the theme.
    public static var cardPadding: CGFloat {
        #if targetEnvironment(macCatalyst)
            return 48
        #elseif os(iOS)
            if UIDevice.current.userInterfaceIdiom == .pad {
                let screenSize = longestScreenSide
                if screenSize <= 768 { return 24 } else if screenSize <= 820 { return 28 } else if screenSize <= 834 { return 32 } else if screenSize <= 1024 { return 36 } else { return 40 }
            }
            return config.large
        #else
            return config.large
        #endif
    }

    /// Cell vertical padding (larger on bigger screens).
    /// iPad and Mac Catalyst values are intentionally hardcoded per screen size;
    /// iPhone falls through to `config.small` from the theme.
    public static var cellPaddingVertical: CGFloat {
        #if targetEnvironment(macCatalyst)
            return 16
        #elseif os(iOS)
            if UIDevice.current.userInterfaceIdiom == .pad {
                let screenSize = longestScreenSide
                if screenSize <= 768 { return 12 }
                if screenSize <= 834 { return 14 }
                return 16
            }
            return config.small
        #else
            return config.medium
        #endif
    }

    /// Longest side of the current screen, resolved via the key window scene.
    private static var longestScreenSide: CGFloat {
        let bounds = LMKSceneUtil.getKeyWindow()?.windowScene?.screen.bounds
            ?? CGRect(x: 0, y: 0, width: 1024, height: 1366)
        return max(bounds.width, bounds.height)
    }

    public static var buttonPaddingVertical: CGFloat { config.buttonPaddingVertical }
    public static var buttonPaddingHorizontal: CGFloat { config.buttonPaddingHorizontal }
    /// Between icons — default 6pt.
    public static var iconSpacing: CGFloat { config.iconSpacing }
    /// Icon to text — default 8pt.
    public static var iconToText: CGFloat { config.iconToText }
}
