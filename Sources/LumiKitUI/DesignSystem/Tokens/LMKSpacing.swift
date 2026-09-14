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

    // MARK: - Expanded-Canvas Breakpoints

    // Three tiers keyed on the shortest side of the key window (the portrait
    // width, so rotation never flips the tier) whenever the window is regular
    // in both size classes. Size classes, not the device idiom: an iPad in
    // Slide Over is compact and gets phone padding; an iPhone Duo's inner
    // display (669pt, regular × regular) gets the compact iPad tier; a
    // resizable iPad window moves between tiers as it is resized.

    /// iPad mini (744pt) and older 9.7" / 10.2" iPads (768pt).
    private static let compactCanvasMaxWidth: CGFloat = 768
    /// iPad 10th gen / iPad Air 11" (820pt) and iPad Pro 11" (834pt).
    private static let regularCanvasMaxWidth: CGFloat = 834

    /// Canvas tier for the key window, `nil` when the window is not regular
    /// in both dimensions (phones, Slide Over, narrow windows, Mac Catalyst).
    private enum CanvasTier {
        case compact, regular, large
    }

    /// Content horizontal padding for headers, list content, cards.
    /// Scales with the canvas (phone-class -> iPad tiers -> Mac Catalyst).
    /// All per-tier values are theme-configurable via `LMKSpacingTheme`;
    /// phone-class canvases fall through to `config.large` from the theme.
    ///
    /// Tiers (regular × regular windows, by shortest window side):
    /// - Compact (≤768pt): iPad mini, iPad 9th gen, iPhone Duo inner display
    /// - Regular (≤834pt): iPad 10th gen, iPad Air 11", iPad Pro 11"
    /// - Large (>834pt): iPad Air 13", iPad Pro 13"
    public static var cardPadding: CGFloat {
        #if targetEnvironment(macCatalyst)
            return config.cardPaddingMac
        #elseif os(iOS)
            switch canvasTier {
            case .compact: return config.cardPaddingIPadCompact
            case .regular: return config.cardPaddingIPadRegular
            case .large: return config.cardPaddingIPadLarge
            case nil: return config.large
            }
        #else
            return config.large
        #endif
    }

    /// Cell vertical padding (larger on bigger canvases).
    /// All per-tier values are theme-configurable via `LMKSpacingTheme`;
    /// phone-class canvases fall through to `config.small` from the theme.
    ///
    /// Same tiers as ``cardPadding``.
    public static var cellPaddingVertical: CGFloat {
        #if targetEnvironment(macCatalyst)
            return config.cellPaddingVerticalMac
        #elseif os(iOS)
            switch canvasTier {
            case .compact: return config.cellPaddingVerticalIPadCompact
            case .regular: return config.cellPaddingVerticalIPadRegular
            case .large: return config.cellPaddingVerticalIPadLarge
            case nil: return config.small
            }
        #else
            return config.medium
        #endif
    }

    /// Tier of the key window when it is regular in both size classes.
    ///
    /// Without a key window (early launch) an iPad idiom is assumed to be a
    /// full-screen regular-tier canvas so first-pass layouts are not phone-sized.
    private static var canvasTier: CanvasTier? {
        guard let window = LMKSceneUtil.getKeyWindow() else {
            return UIDevice.current.userInterfaceIdiom == .pad ? .regular : nil
        }
        let traits = window.traitCollection
        guard traits.horizontalSizeClass == .regular, traits.verticalSizeClass == .regular else {
            return nil
        }
        let shortestSide = min(window.bounds.width, window.bounds.height)
        if shortestSide <= compactCanvasMaxWidth {
            return .compact
        } else if shortestSide <= regularCanvasMaxWidth {
            return .regular
        } else {
            return .large
        }
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
