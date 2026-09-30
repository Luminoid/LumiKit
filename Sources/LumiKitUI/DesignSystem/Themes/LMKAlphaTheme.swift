//
//  LMKAlphaTheme.swift
//  LumiKit
//
//  Opacity configuration: a seven-step ramp (the same steps as spacing and
//  corner radius) plus two semantic values. Proxied by `LMKAlpha`.
//

import UIKit

/// Configuration for the opacity tokens. Every value is clamped to `0...1`.
///
/// The ramp steps are named like the spacing and corner-radius scales so a
/// theme can retune a step without the name lying about its value.
public nonisolated struct LMKAlphaTheme: Sendable, Equatable {
    /// Faintest wash (default 0.10): highlight tints, subtle fills.
    public var xxs: CGFloat
    /// Default 0.15: selection backgrounds, pressed states.
    public var xs: CGFloat
    /// Default 0.20: light overlays, separators over content.
    public var small: CGFloat
    /// Default 0.30: semi-transparent chrome.
    public var medium: CGFloat
    /// Default 0.50: standard overlays.
    public var large: CGFloat
    /// Default 0.70: strong overlays.
    public var xl: CGFloat
    /// Default 0.80: near-opaque overlays (loading scrims over content).
    public var xxl: CGFloat
    /// Dimming view behind sheets and panels (default 0.40).
    public var dimming: CGFloat
    /// Disabled controls (default 0.38).
    public var disabled: CGFloat

    public init(
        xxs: CGFloat = 0.1,
        xs: CGFloat = 0.15,
        small: CGFloat = 0.2,
        medium: CGFloat = 0.3,
        large: CGFloat = 0.5,
        xl: CGFloat = 0.7,
        xxl: CGFloat = 0.8,
        dimming: CGFloat = 0.4,
        disabled: CGFloat = 0.38
    ) {
        self.xxs = min(max(xxs, 0), 1)
        self.xs = min(max(xs, 0), 1)
        self.small = min(max(small, 0), 1)
        self.medium = min(max(medium, 0), 1)
        self.large = min(max(large, 0), 1)
        self.xl = min(max(xl, 0), 1)
        self.xxl = min(max(xxl, 0), 1)
        self.dimming = min(max(dimming, 0), 1)
        self.disabled = min(max(disabled, 0), 1)
    }
}
