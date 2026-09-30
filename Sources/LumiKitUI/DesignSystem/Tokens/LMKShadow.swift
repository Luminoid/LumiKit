//
//  LMKShadow.swift
//  LumiKit
//
//  Shadow tokens: elevation levels resolved against the active theme.
//  Proxies to `LMKTheme.current.shadow`.
//

import UIKit

/// A resolved shadow, ready for `UIView.lmk_applyShadow(_:)`.
///
/// `color` is normally a trait-aware dynamic color; the layer helper resolves it
/// against the view's traits and re-stamps it when they change.
public nonisolated struct LMKShadowStyle: Sendable, Equatable {
    public var color: UIColor
    public var offset: CGSize
    public var radius: CGFloat
    public var opacity: Float

    public init(color: UIColor, offset: CGSize, radius: CGFloat, opacity: Float) {
        self.color = color
        self.offset = offset
        self.radius = max(0, radius)
        self.opacity = min(max(opacity, 0), 1)
    }
}

/// Shadow tokens.
///
/// Usage: `card.lmk_applyShadow(.level3)` or `LMKShadow.style(for: .level2)`.
public nonisolated enum LMKShadow {
    /// Elevation levels: 1 is the tightest lift, 5 the widest.
    public nonisolated enum Level: Int, Sendable, Hashable, CaseIterable, Comparable {
        case none = 0
        case level1
        case level2
        case level3
        case level4
        case level5

        public static func < (lhs: Self, rhs: Self) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }

    private static var config: LMKShadowTheme {
        LMKTheme.current.shadow
    }

    /// Opacity for icon overlays on photos (LIVE badges, symbol chips over images).
    public static var iconOverlayOpacity: Float { config.iconOverlayOpacity }

    /// The resolved style for `level`; `.none` resolves to an invisible shadow.
    public static func style(for level: Level) -> LMKShadowStyle {
        config.shadow(for: level).style
    }
}
