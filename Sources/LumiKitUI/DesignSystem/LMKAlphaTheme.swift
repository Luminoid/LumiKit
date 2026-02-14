//
//  LMKAlphaTheme.swift
//  LumiKit
//
//  Alpha/opacity configuration for customizing transparency values.
//

import UIKit

/// Alpha/opacity configuration for the Lumi design system.
///
/// Override at app launch to customize opacity:
/// ```swift
/// LMKThemeManager.shared.apply(alpha: .init(disabled: 0.4))
/// ```
public nonisolated struct LMKAlphaTheme: Sendable {
    /// Semi-transparent overlay.
    public var overlay: CGFloat
    /// Dimming overlay for modal bottom sheets.
    public var dimmingOverlay: CGFloat
    /// Disabled state alpha.
    public var disabled: CGFloat
    /// Semi-transparent background.
    public var semiTransparent: CGFloat
    /// Strong overlay for dark backgrounds (e.g. photo overlay buttons).
    public var overlayStrong: CGFloat
    /// Light mode highlight overlay.
    public var overlayLight: CGFloat
    /// Dark mode highlight overlay.
    public var overlayDark: CGFloat
    /// Medium overlay for selection highlight.
    public var overlayMedium: CGFloat
    /// Opaque overlay for loading/shimmer backgrounds.
    public var overlayOpaque: CGFloat

    public init(
        overlay: CGFloat = 0.5,
        dimmingOverlay: CGFloat = 0.4,
        disabled: CGFloat = 0.5,
        semiTransparent: CGFloat = 0.5,
        overlayStrong: CGFloat = 0.7,
        overlayLight: CGFloat = 0.1,
        overlayDark: CGFloat = 0.2,
        overlayMedium: CGFloat = 0.15,
        overlayOpaque: CGFloat = 0.8
    ) {
        self.overlay = overlay
        self.dimmingOverlay = dimmingOverlay
        self.disabled = disabled
        self.semiTransparent = semiTransparent
        self.overlayStrong = overlayStrong
        self.overlayLight = overlayLight
        self.overlayDark = overlayDark
        self.overlayMedium = overlayMedium
        self.overlayOpaque = overlayOpaque
    }
}
