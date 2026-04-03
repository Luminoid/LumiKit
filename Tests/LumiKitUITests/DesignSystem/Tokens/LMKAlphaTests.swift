//
//  LMKAlphaTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

// MARK: - LMKAlpha

@MainActor
struct LMKAlphaTests {
    @Test
    func `Alpha values are between 0 and 1`() {
        #expect(LMKAlpha.overlay > 0 && LMKAlpha.overlay <= 1)
        #expect(LMKAlpha.overlayStrong > 0 && LMKAlpha.overlayStrong <= 1)
        #expect(LMKAlpha.overlayOpaque > 0 && LMKAlpha.overlayOpaque <= 1)
    }

    @Test
    func `Alpha values are ordered by intensity`() {
        #expect(LMKAlpha.overlay < LMKAlpha.overlayStrong)
        #expect(LMKAlpha.overlayStrong < LMKAlpha.overlayOpaque)
    }
}

// MARK: - LMKAlphaTheme

@MainActor
struct LMKAlphaConfigurationTests {
    @Test
    func `Default alpha matches original values`() {
        let config = LMKAlphaTheme()
        #expect(config.overlay == 0.5)
        #expect(config.dimmingOverlay == 0.4)
        #expect(config.disabled == 0.38)
        #expect(config.overlayStrong == 0.7)
        #expect(config.overlayLight == 0.1)
        #expect(config.overlayOpaque == 0.8)
    }

    @Test
    func `Custom alpha is applied via proxy`() {
        let original = LMKThemeManager.shared.alpha
        defer { LMKThemeManager.shared.apply(alpha: original) }

        LMKThemeManager.shared.apply(alpha: .init(disabled: 0.3))
        #expect(LMKAlpha.disabled == 0.3)
        #expect(LMKAlpha.overlay == 0.5) // unchanged
    }
}
