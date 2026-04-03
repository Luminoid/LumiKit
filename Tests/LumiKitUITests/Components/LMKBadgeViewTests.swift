//
//  LMKBadgeViewTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

// MARK: - LMKBadgeView

@MainActor
struct LMKBadgeViewTests {
    @Test
    func `Configure count hides for 0`() {
        let badge = LMKBadgeView()
        badge.configure(count: 0)
        #expect(badge.isHidden)
    }

    @Test
    func `Configure count shows for positive`() {
        let badge = LMKBadgeView()
        badge.configure(count: 5)
        #expect(!badge.isHidden)
    }

    @Test
    func `Configure count shows 99+ for large values`() {
        let badge = LMKBadgeView()
        badge.configure(count: 150)
        #expect(badge.accessibilityLabel == "150")
    }

    @Test
    func `Configure text sets accessibility`() {
        let badge = LMKBadgeView()
        badge.configure(text: "New")
        #expect(badge.accessibilityLabel == "New")
        #expect(!badge.isHidden)
    }

    @Test
    func `Dot badge has smaller intrinsic size`() {
        let badge = LMKBadgeView()
        badge.configure()
        let dotSize = badge.intrinsicContentSize
        badge.configure(count: 5)
        let countSize = badge.intrinsicContentSize
        #expect(dotSize.width < countSize.width)
    }
}
