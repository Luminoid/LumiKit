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
    /// Semi-transparent overlay for dimming content behind modals or popovers.
    public var overlay: CGFloat
    /// Dimming overlay for modal bottom sheets.
    public var dimmingOverlay: CGFloat
    /// Disabled state alpha for non-interactive controls (buttons, toggles).
    public var disabled: CGFloat
    /// Semi-transparent background for subtle overlays (highlight effects, hover states).
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
        self.overlay = min(max(overlay, 0), 1)
        self.dimmingOverlay = min(max(dimmingOverlay, 0), 1)
        self.disabled = min(max(disabled, 0), 1)
        self.semiTransparent = min(max(semiTransparent, 0), 1)
        self.overlayStrong = min(max(overlayStrong, 0), 1)
        self.overlayLight = min(max(overlayLight, 0), 1)
        self.overlayDark = min(max(overlayDark, 0), 1)
        self.overlayMedium = min(max(overlayMedium, 0), 1)
        self.overlayOpaque = min(max(overlayOpaque, 0), 1)
    }
}
