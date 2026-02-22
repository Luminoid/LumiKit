//
//  LMKAnimationThemeTests.swift
//  LumiKit
//

import Testing
import UIKit

@testable import LumiKitUI

// MARK: - LMKAnimationTheme

@Suite("LMKAnimationTheme")
@MainActor
struct LMKAnimationConfigurationTests {
    @Test("Default animation matches original values")
    func defaultAnimation() {
        let config = LMKAnimationTheme()
        #expect(config.screenTransition == 0.35)
        #expect(config.modalPresentation == 0.3)
        #expect(config.actionSheet == 0.25)
        #expect(config.alert == 0.2)
        #expect(config.buttonPress == 0.1)
        #expect(config.springDamping == 0.8)
    }

    @Test("Custom animation is applied via proxy")
    func customAnimation() {
        let original = LMKThemeManager.shared.animation
        defer { LMKThemeManager.shared.apply(animation: original) }

        LMKThemeManager.shared.apply(animation: .init(modalPresentation: 0.25, springDamping: 0.7))
        #expect(LMKAnimationHelper.Duration.modalPresentation == 0.25)
        #expect(LMKAnimationHelper.Spring.damping == 0.7)
        #expect(LMKAnimationHelper.Duration.alert == 0.2) // unchanged
    }
}
