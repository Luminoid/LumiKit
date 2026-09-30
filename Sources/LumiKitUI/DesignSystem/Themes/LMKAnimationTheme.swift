//
//  LMKAnimationTheme.swift
//  LumiKit
//
//  Motion configuration: seven duration steps, springs, the press scale, and
//  the default curve. Proxied by `LMKAnimation.Duration`, `LMKAnimation.spring`, …
//

import UIKit

/// Motion configuration. Durations are in seconds; negative values are clamped to 0.
public nonisolated struct LMKAnimationTheme: Sendable, Equatable {
    /// Press feedback (default 0.10).
    public var instant: TimeInterval
    /// Short UI changes, photo fades (default 0.15).
    public var fast: TimeInterval
    /// Alerts, action sheets (default 0.25).
    public var normal: TimeInterval
    /// Modal presentation, list updates, card expansion (default 0.30).
    public var moderate: TimeInterval
    /// Screen transitions, error shake (default 0.35).
    public var slow: TimeInterval
    /// Success feedback (default 0.50).
    public var emphasis: TimeInterval
    /// One shimmer sweep of a skeleton (default 1.8).
    public var shimmer: TimeInterval
    /// Spring for sheet and indicator motion.
    public var spring: LMKAnimation.Spring
    /// Spring for control press feedback.
    public var pressSpring: LMKAnimation.Spring
    /// Scale applied to a pressed control (default 0.96).
    public var pressScale: CGFloat
    /// Curve used when a call site does not pick one.
    public var defaultCurve: LMKAnimation.Curve

    public init(
        instant: TimeInterval = 0.1,
        fast: TimeInterval = 0.15,
        normal: TimeInterval = 0.25,
        moderate: TimeInterval = 0.3,
        slow: TimeInterval = 0.35,
        emphasis: TimeInterval = 0.5,
        shimmer: TimeInterval = 1.8,
        spring: LMKAnimation.Spring = .init(damping: 0.8),
        pressSpring: LMKAnimation.Spring = .init(damping: 0.6),
        pressScale: CGFloat = 0.96,
        defaultCurve: LMKAnimation.Curve = .easeInOut
    ) {
        self.instant = max(0, instant)
        self.fast = max(0, fast)
        self.normal = max(0, normal)
        self.moderate = max(0, moderate)
        self.slow = max(0, slow)
        self.emphasis = max(0, emphasis)
        self.shimmer = max(0, shimmer)
        self.spring = spring
        self.pressSpring = pressSpring
        self.pressScale = min(max(pressScale, 0.1), 1)
        self.defaultCurve = defaultCurve
    }
}
