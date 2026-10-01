//
//  LMKAlphaTests.swift
//  LumiKit
//

import Testing
@testable import LumiKitUI

// MARK: - LMKAlpha

@MainActor
struct LMKAlphaTests {
    @Test
    func `Alpha values are between 0 and 1`() {
        for value in [LMKAlpha.xxs, LMKAlpha.xs, LMKAlpha.small, LMKAlpha.medium, LMKAlpha.large, LMKAlpha.xl, LMKAlpha.xxl, LMKAlpha.dimming, LMKAlpha.disabled] {
            #expect(value > 0 && value <= 1)
        }
    }

    @Test
    func `Ramp is strictly increasing`() {
        let ramp = [LMKAlpha.xxs, LMKAlpha.xs, LMKAlpha.small, LMKAlpha.medium, LMKAlpha.large, LMKAlpha.xl, LMKAlpha.xxl]
        #expect(ramp == ramp.sorted())
        #expect(Set(ramp).count == ramp.count)
    }
}

// MARK: - LMKAlphaTheme

@MainActor
struct LMKAlphaConfigurationTests {
    @Test
    func `Default alpha keeps the pre 1.0 values`() {
        let config = LMKAlphaTheme()
        #expect(config.xxs == 0.1)
        #expect(config.xs == 0.15)
        #expect(config.small == 0.2)
        #expect(config.medium == 0.3)
        #expect(config.large == 0.5)
        #expect(config.xl == 0.7)
        #expect(config.xxl == 0.8)
        #expect(config.dimming == 0.4)
        #expect(config.disabled == 0.38)
    }

    @Test
    func `Values are clamped to the unit range`() {
        let config = LMKAlphaTheme(xxs: -1, xxl: 4)
        #expect(config.xxs == 0)
        #expect(config.xxl == 1)
    }

    @Test
    func `Custom alpha is applied via proxy`() {
        let original = LMKTheme.current.alpha
        defer { LMKTheme.update { $0.alpha = original } }

        LMKTheme.update { $0.alpha = .init(disabled: 0.3) }
        #expect(LMKAlpha.disabled == 0.3)
        #expect(LMKAlpha.large == 0.5) // unchanged
    }
}
