//
//  LMKAnimationThemeTests.swift
//  LumiKit
//

import Testing
@testable import LumiKitUI

// MARK: - LMKAnimationTheme

@MainActor
struct LMKAnimationConfigurationTests {
    @Test
    func `Default motion steps are ordered`() {
        let config = LMKAnimationTheme()
        #expect(config.instant == 0.1)
        #expect(config.fast == 0.15)
        #expect(config.normal == 0.25)
        #expect(config.moderate == 0.3)
        #expect(config.slow == 0.35)
        #expect(config.emphasis == 0.5)
        #expect(config.shimmer == 1.8)
        let steps = [config.instant, config.fast, config.normal, config.moderate, config.slow, config.emphasis]
        #expect(steps == steps.sorted())
        #expect(config.spring.damping == 0.8)
        #expect(config.pressSpring.damping == 0.6)
        #expect(config.pressScale == 0.96)
        #expect(config.defaultCurve == .easeInOut)
    }

    @Test
    func `Negative durations and out of range springs are clamped`() {
        let config = LMKAnimationTheme(instant: -1, spring: .init(damping: 2), pressScale: 5)
        #expect(config.instant == 0)
        #expect(config.spring.damping == 1)
        #expect(config.pressScale == 1)
    }

    @Test
    func `Curves map to animation options and timing functions`() {
        #expect(LMKAnimation.Curve.easeIn.options == .curveEaseIn)
        #expect(LMKAnimation.Curve.easeOut.options == .curveEaseOut)
        #expect(LMKAnimation.Curve.easeInOut.options == .curveEaseInOut)
        #expect(LMKAnimation.Curve.linear.options == .curveLinear)
        #expect(LMKAnimation.Curve.allCases.count == 4)
        _ = LMKAnimation.Curve.easeInOut.timingFunction
    }

    @Test
    func `Custom animation is applied via proxy`() {
        let original = LMKTheme.current.animation
        defer { LMKTheme.update { $0.animation = original } }

        LMKTheme.update { $0.animation = .init(moderate: 0.25, spring: .init(damping: 0.7)) }
        #expect(LMKAnimation.Duration.moderate == 0.25)
        #expect(LMKAnimation.spring.damping == 0.7)
        #expect(LMKAnimation.Duration.normal == 0.25) // unchanged default
        #expect(LMKAnimation.pressScale == 0.96)
    }
}
