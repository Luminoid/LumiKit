//
//  LMKShadowTheme.swift
//  LumiKit
//
//  Shadow configuration: five elevation levels resolved into `LMKShadowStyle`
//  values by `LMKShadow.style(for:)`.
//

import UIKit

public extension LMKShadowTheme {
    /// One elevation level: geometry plus the light/dark alpha of the black shadow color.
    nonisolated struct Shadow: Sendable, Equatable {
        public var offset: CGSize
        public var radius: CGFloat
        public var opacity: Float
        /// Shadow color alpha in light mode.
        public var lightAlpha: CGFloat
        /// Shadow color alpha in dark mode.
        public var darkAlpha: CGFloat

        public init(
            offset: CGSize = CGSize(width: 0, height: 2),
            radius: CGFloat = 6,
            opacity: Float = 0.5,
            lightAlpha: CGFloat = 0.1,
            darkAlpha: CGFloat = 0.3
        ) {
            self.offset = offset
            self.radius = max(0, radius)
            self.opacity = min(max(opacity, 0), 1)
            self.lightAlpha = min(max(lightAlpha, 0), 1)
            self.darkAlpha = min(max(darkAlpha, 0), 1)
        }

        /// The resolved style: a trait-aware black shadow color plus the geometry.
        public var style: LMKShadowStyle {
            let lightAlpha = lightAlpha
            let darkAlpha = darkAlpha
            let color = UIColor { traitCollection in
                UIColor.black.withAlphaComponent(traitCollection.userInterfaceStyle == .dark ? darkAlpha : lightAlpha)
            }
            return LMKShadowStyle(color: color, offset: offset, radius: radius, opacity: opacity)
        }
    }
}

/// Shadow configuration: elevation levels 1 (tightest) to 5 (widest) plus the
/// icon-overlay opacity used by symbol badges over photos.
public nonisolated struct LMKShadowTheme: Sendable, Equatable {
    /// Opacity of icon overlays on photos (see `LMKShadow.iconOverlayOpacity`).
    public var iconOverlayOpacity: Float
    /// Hairline lift: small controls, thumbs.
    public var level1: Shadow
    /// Buttons, list cards.
    public var level2: Shadow
    /// Cards, floating panels.
    public var level3: Shadow
    /// Sheets, popovers.
    public var level4: Shadow
    /// Full-screen overlays, hero cards.
    public var level5: Shadow

    public init(
        iconOverlayOpacity: Float = 0.8,
        level1: Shadow = .init(offset: CGSize(width: 0, height: 1), radius: 2, opacity: 1.0, lightAlpha: 0.1, darkAlpha: 0.3),
        level2: Shadow = .init(offset: CGSize(width: 0, height: 2), radius: 4, opacity: 1.0, lightAlpha: 0.15, darkAlpha: 0.4),
        level3: Shadow = .init(offset: CGSize(width: 0, height: 2), radius: 8, opacity: 1.0, lightAlpha: 0.1, darkAlpha: 0.3),
        level4: Shadow = .init(offset: CGSize(width: 0, height: 4), radius: 12, opacity: 1.0, lightAlpha: 0.1, darkAlpha: 0.3),
        level5: Shadow = .init(offset: CGSize(width: 0, height: 8), radius: 24, opacity: 1.0, lightAlpha: 0.12, darkAlpha: 0.4)
    ) {
        self.iconOverlayOpacity = min(max(iconOverlayOpacity, 0), 1)
        self.level1 = level1
        self.level2 = level2
        self.level3 = level3
        self.level4 = level4
        self.level5 = level5
    }

    /// The configured shadow for `level`; `.none` is an invisible shadow.
    public func shadow(for level: LMKShadow.Level) -> Shadow {
        switch level {
        case .none: Shadow(offset: .zero, radius: 0, opacity: 0, lightAlpha: 0, darkAlpha: 0)
        case .level1: level1
        case .level2: level2
        case .level3: level3
        case .level4: level4
        case .level5: level5
        }
    }
}
