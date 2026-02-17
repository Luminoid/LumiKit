//
//  LMKAnimationHelperTests.swift
//  LumiKit
//

import Testing
import UIKit

@testable import LumiKitUI

// MARK: - LMKAnimationHelper

@Suite("LMKAnimationHelper")
@MainActor
struct LMKAnimationHelperTests {
    @Test("Duration values are positive")
    func durationsPositive() {
        #expect(LMKAnimationHelper.Duration.screenTransition > 0)
        #expect(LMKAnimationHelper.Duration.modalPresentation > 0)
        #expect(LMKAnimationHelper.Duration.buttonPress > 0)
        #expect(LMKAnimationHelper.Duration.errorShake > 0)
        #expect(LMKAnimationHelper.Duration.photoLoad > 0)
    }

    @Test("Spring damping is in valid range")
    func springDampingRange() {
        let damping = LMKAnimationHelper.Spring.damping
        #expect(damping > 0 && damping <= 1)
    }

    @Test("tableViewRowAnimation returns valid value")
    func tableViewRowAnimation() {
        let animation = LMKAnimationHelper.tableViewRowAnimation
        // Should be either .automatic or .none depending on Reduce Motion
        #expect(animation == .automatic || animation == .none)
    }
}
