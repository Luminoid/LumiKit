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
        )
    ) {
        self.iconOverlayOpacity = iconOverlayOpacity
        self.cellCard = cellCard
        self.card = card
        self.button = button
        self.small = small
    }

    // MARK: - Flat Property Access (backwards compatible)

    public var cellCardOffset: CGSize {
        get { cellCard.offset } set { cellCard.offset = newValue }
    }
    public var cellCardRadius: CGFloat {
        get { cellCard.radius } set { cellCard.radius = newValue }
    }
    public var cellCardOpacity: Float {
        get { cellCard.opacity } set { cellCard.opacity = newValue }
    }
    public var cellCardLightAlpha: CGFloat {
        get { cellCard.lightAlpha } set { cellCard.lightAlpha = newValue }
    }
    public var cellCardDarkAlpha: CGFloat {
        get { cellCard.darkAlpha } set { cellCard.darkAlpha = newValue }
    }
    public var cardOffset: CGSize {
        get { card.offset } set { card.offset = newValue }
    }
    public var cardRadius: CGFloat {
        get { card.radius } set { card.radius = newValue }
    }
    public var cardOpacity: Float {
        get { card.opacity } set { card.opacity = newValue }
    }
    public var cardLightAlpha: CGFloat {
        get { card.lightAlpha } set { card.lightAlpha = newValue }
    }
    public var cardDarkAlpha: CGFloat {
        get { card.darkAlpha } set { card.darkAlpha = newValue }
    }
    public var buttonOffset: CGSize {
        get { button.offset } set { button.offset = newValue }
    }
    public var buttonRadius: CGFloat {
        get { button.radius } set { button.radius = newValue }
    }
    public var buttonOpacity: Float {
        get { button.opacity } set { button.opacity = newValue }
    }
    public var buttonLightAlpha: CGFloat {
        get { button.lightAlpha } set { button.lightAlpha = newValue }
    }
    public var buttonDarkAlpha: CGFloat {
        get { button.darkAlpha } set { button.darkAlpha = newValue }
    }
    public var smallOffset: CGSize {
        get { small.offset } set { small.offset = newValue }
    }
    public var smallRadius: CGFloat {
        get { small.radius } set { small.radius = newValue }
    }
    public var smallOpacity: Float {
        get { small.opacity } set { small.opacity = newValue }
    }
    public var smallLightAlpha: CGFloat {
        get { small.lightAlpha } set { small.lightAlpha = newValue }
    }
    public var smallDarkAlpha: CGFloat {
        get { small.darkAlpha } set { small.darkAlpha = newValue }
    }
}
