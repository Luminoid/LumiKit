//
//  LMKShadowTheme.swift
//  LumiKit
//
//  Shadow configuration for customizing shadow styles.
//

import UIKit

/// Configuration for a single shadow style.
///
/// Groups offset, radius, opacity, and light/dark alpha into one unit.
///
/// Shadows use a **two-level opacity system**:
/// - `opacity` controls `CALayer.shadowOpacity` (overall shadow visibility, 0–1).
/// - `lightAlpha` / `darkAlpha` control the alpha component of `CALayer.shadowColor`,
///   adapting shadow intensity for the current interface style.
///
/// The effective shadow darkness is `opacity × colorAlpha`. For example,
/// `opacity: 0.5, lightAlpha: 0.1` produces an effective alpha of 0.05 in light mode.
/// This separation allows fine-tuning shadow weight independently of color intensity.
public nonisolated struct LMKShadowConfig: Sendable {
    public var offset: CGSize
    public var radius: CGFloat
    /// Layer opacity applied to the shadow (`CALayer.shadowOpacity`).
    /// Acts as a multiplier on the shadow color alpha.
    public var opacity: Float
    /// Shadow color alpha in light mode (`CALayer.shadowColor`).
    public var lightAlpha: CGFloat
    /// Shadow color alpha in dark mode — typically higher for visibility on dark backgrounds.
    public var darkAlpha: CGFloat

    public init(
        offset: CGSize = CGSize(width: 0, height: 2),
        radius: CGFloat = 6,
        opacity: Float = 0.5,
        lightAlpha: CGFloat = 0.1,
        darkAlpha: CGFloat = 0.3
    ) {
        self.offset = offset
        self.radius = radius
        self.opacity = opacity
        self.lightAlpha = lightAlpha
        self.darkAlpha = darkAlpha
    }
}

/// Shadow configuration for the Lumi design system.
///
/// Each shadow category is an `LMKShadowConfig` grouping offset, radius, opacity,
/// and light/dark color alpha. Override at app launch:
/// ```swift
/// LMKThemeManager.shared.apply(shadow: .init(
///     cellCard: .init(radius: 8),
///     card: .init(radius: 12)
/// ))
/// ```
public nonisolated struct LMKShadowTheme: Sendable {
    /// Standard shadow opacity for icon overlays (e.g. category icon on photo).
    public var iconOverlayOpacity: Float

    /// Shadow for table/collection view cell cards.
    public var cellCard: LMKShadowConfig
    /// Shadow for standalone card views and containers.
    public var card: LMKShadowConfig
    /// Shadow for elevated buttons.
    public var button: LMKShadowConfig
    /// Subtle shadow for small elements (chips, badges).
    public var small: LMKShadowConfig
    /// Medium shadow for floating elements (toasts, popovers).
    public var medium: LMKShadowConfig
    /// Large shadow for elevated overlays (modals, dialogs).
    public var large: LMKShadowConfig

    public init(
        iconOverlayOpacity: Float = 0.8,
        cellCard: LMKShadowConfig = .init(
            offset: CGSize(width: 0, height: 2), radius: 6, opacity: 0.5,
            lightAlpha: 0.1, darkAlpha: 0.3
        ),
        card: LMKShadowConfig = .init(
            offset: CGSize(width: 0, height: 2), radius: 8, opacity: 1.0,
            lightAlpha: 0.1, darkAlpha: 0.3
        ),
        button: LMKShadowConfig = .init(
            offset: CGSize(width: 0, height: 2), radius: 4, opacity: 1.0,
            lightAlpha: 0.15, darkAlpha: 0.4
        ),
        small: LMKShadowConfig = .init(
            offset: CGSize(width: 0, height: 1), radius: 2, opacity: 1.0,
            lightAlpha: 0.1, darkAlpha: 0.3
        ),
        medium: LMKShadowConfig = .init(
            offset: CGSize(width: 0, height: 4), radius: 12, opacity: 1.0,
            lightAlpha: 0.1, darkAlpha: 0.3
        ),
        large: LMKShadowConfig = .init(
            offset: CGSize(width: 0, height: 8), radius: 24, opacity: 1.0,
            lightAlpha: 0.12, darkAlpha: 0.4
        )
    ) {
        self.iconOverlayOpacity = iconOverlayOpacity
        self.cellCard = cellCard
        self.card = card
        self.button = button
        self.small = small
        self.medium = medium
        self.large = large
    }
}
