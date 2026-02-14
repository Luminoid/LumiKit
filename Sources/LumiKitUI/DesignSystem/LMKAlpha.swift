//
//  LMKAlpha.swift
//  LumiKit
//
//  Alpha/opacity tokens.
//  Proxies to `LMKThemeManager.shared.alpha` for customization.
//

import UIKit

/// Alpha/opacity tokens for the Lumi design system.
///
/// Customize by applying an alpha theme:
/// ```swift
/// LMKThemeManager.shared.apply(alpha: .init(disabled: 0.4))
/// ```
public enum LMKAlpha {
    private static var config: LMKAlphaTheme {
        LMKThemeManager.shared.alpha
    }

    /// Semi-transparent overlay (default 0.5).
    public static var overlay: CGFloat { config.overlay }
    /// Dimming overlay for modal bottom sheets (default 0.4).
    public static var dimmingOverlay: CGFloat { config.dimmingOverlay }
    /// Disabled state alpha (default 0.5).
    public static var disabled: CGFloat { config.disabled }
    /// Semi-transparent background (default 0.5).
    public static var semiTransparent: CGFloat { config.semiTransparent }
    /// Strong overlay for dark backgrounds (e.g. photo overlay buttons) (default 0.7).
    public static var overlayStrong: CGFloat { config.overlayStrong }
    /// Light mode highlight overlay (default 0.1).
    public static var overlayLight: CGFloat { config.overlayLight }
    /// Dark mode highlight overlay (default 0.2).
    public static var overlayDark: CGFloat { config.overlayDark }
    /// Medium overlay for selection highlight (default 0.15).
    public static var overlayMedium: CGFloat { config.overlayMedium }
    /// Opaque overlay for loading/shimmer backgrounds (default 0.8).
    public static var overlayOpaque: CGFloat { config.overlayOpaque }
}
