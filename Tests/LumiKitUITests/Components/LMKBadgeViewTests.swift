//
//  LMKBadgeViewTests.swift
//  LumiKit
//

import Testing
import UIKit

@testable import LumiKitUI

// MARK: - LMKBadgeView

@Suite("LMKBadgeView")
@MainActor
struct LMKBadgeViewTests {
    @Test("Configure count hides for 0")
    func countHidesForZero() {
        let badge = LMKBadgeView()
        badge.configure(count: 0)
        #expect(badge.isHidden)
    }

    @Test("Configure count shows for positive")
    func countShowsForPositive() {
        let badge = LMKBadgeView()
        badge.configure(count: 5)
        #expect(!badge.isHidden)
    }

    @Test("Configure count shows 99+ for large values")
    func countCapsAt99() {
        let badge = LMKBadgeView()
        badge.configure(count: 150)
        #expect(badge.accessibilityLabel == "150")
    }

    @Test("Configure text sets accessibility")
    func textSetsAccessibility() {
        let badge = LMKBadgeView()
        badge.configure(text: "New")
        #expect(badge.accessibilityLabel == "New")
        #expect(!badge.isHidden)
    }

    @Test("Dot badge has smaller intrinsic size")
    func dotBadge() {
        let badge = LMKBadgeView()
        badge.configure()
        let dotSize = badge.intrinsicContentSize
        badge.configure(count: 5)
        let countSize = badge.intrinsicContentSize
        #expect(dotSize.width < countSize.width)
    }
}
