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

    // MARK: - iPad Breakpoints

    /// iPad mini / iPad 9th gen (longest side 1024pt, shortest 768pt).
    private static let iPadCompactBreakpoint: CGFloat = 768
    /// iPad Air 11" / iPad Pro 11" (longest side 1194pt, shortest 834pt).
    private static let iPadRegularBreakpoint: CGFloat = 834
    /// iPad Pro 12.9" / iPad Pro 13" (longest side 1366pt, shortest 1024pt).
    private static let iPadLargeBreakpoint: CGFloat = 1024

    /// Content horizontal padding for headers, list content, cards.
    /// Scales based on device size (iPhone -> iPad -> Mac Catalyst).
    /// All per-device values are theme-configurable via `LMKSpacingTheme`;
    /// iPhone falls through to `config.large` from the theme.
    ///
    /// iPad breakpoints (by longest screen side):
    /// - Compact (≤768pt): iPad mini, iPad 9th gen
    /// - Regular (≤1024pt): iPad Air, iPad Pro 11"
    /// - Large (>1024pt): iPad Pro 12.9"/13"
    public static var cardPadding: CGFloat {
        #if targetEnvironment(macCatalyst)
            return config.cardPaddingMac
        #elseif os(iOS)
            if UIDevice.current.userInterfaceIdiom == .pad {
                let screenSize = longestScreenSide
                if screenSize <= iPadCompactBreakpoint { return config.cardPaddingIPadCompact }
                else if screenSize <= iPadLargeBreakpoint { return config.cardPaddingIPadRegular }
                else { return config.cardPaddingIPadLarge }
            }
            return config.large
        #else
            return config.large
        #endif
    }

    /// Cell vertical padding (larger on bigger screens).
    /// All per-device values are theme-configurable via `LMKSpacingTheme`;
    /// iPhone falls through to `config.small` from the theme.
    ///
    /// iPad breakpoints (by longest screen side):
    /// - Compact (≤768pt): iPad mini, iPad 9th gen
    /// - Regular (≤834pt): iPad Air 11", iPad Pro 11"
    /// - Large (>834pt): iPad Pro 12.9"/13"
    public static var cellPaddingVertical: CGFloat {
        #if targetEnvironment(macCatalyst)
            return config.cellPaddingVerticalMac
        #elseif os(iOS)
            if UIDevice.current.userInterfaceIdiom == .pad {
                let screenSize = longestScreenSide
                if screenSize <= iPadCompactBreakpoint { return config.cellPaddingVerticalIPadCompact }
                else if screenSize <= iPadRegularBreakpoint { return config.cellPaddingVerticalIPadRegular }
                else { return config.cellPaddingVerticalIPadLarge }
            }
            return config.small
        #else
            return config.medium
        #endif
    }

    /// Longest side of the current screen, resolved via the key window scene.
    private static var longestScreenSide: CGFloat {
        let bounds = LMKSceneUtil.getKeyWindow()?.windowScene?.screen.bounds
            ?? UIScreen.main.bounds
        return max(bounds.width, bounds.height)
    }

    public static var buttonPaddingVertical: CGFloat { config.buttonPaddingVertical }
    public static var buttonPaddingHorizontal: CGFloat { config.buttonPaddingHorizontal }
    /// Between icons — default 6pt.
    public static var iconSpacing: CGFloat { config.iconSpacing }
    /// Icon to text — default 8pt.
    public static var iconToText: CGFloat { config.iconToText }
    /// Text view vertical content inset — default 8pt.
    public static var textViewPaddingVertical: CGFloat { config.textViewPaddingVertical }
    /// Text view horizontal content inset — default 12pt.
    public static var textViewPaddingHorizontal: CGFloat { config.textViewPaddingHorizontal }
}
