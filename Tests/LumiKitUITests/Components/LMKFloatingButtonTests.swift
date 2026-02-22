//
//  LMKFloatingButtonTests.swift
//  LumiKitUITests
//
//  Tests for floating action button component.
//

import Testing
import UIKit

@testable import LumiKitUI

@Suite("LMKFloatingButton")
@MainActor
struct LMKFloatingButtonTests {
    // MARK: - Initialization

    @Test("Init with default size creates correct frame")
    func initDefaultSize() {
        let button = LMKFloatingButton(icon: UIImage(systemName: "star"))

        #expect(button.frame.width == LMKFloatingButtonLayout.defaultSize)
        #expect(button.frame.height == LMKFloatingButtonLayout.defaultSize)
    }

    @Test("Init with custom size creates correct frame")
    func initCustomSize() {
        let button = LMKFloatingButton(icon: nil, size: 48)

        #expect(button.frame.width == 48)
        #expect(button.frame.height == 48)
    }

    // MARK: - Layout Constants

    @Test("Layout constants have expected values")
    func layoutConstants() {
        #expect(LMKFloatingButtonLayout.defaultSize == 56)
        #expect(LMKFloatingButtonLayout.edgeMargin == 16)
        #expect(LMKFloatingButtonLayout.iconSize == 24)
        #expect(LMKFloatingButtonLayout.badgeOffset == -4)
    }

    // MARK: - Shape

    @Test("Button is circular")
    func circularShape() {
        let size: CGFloat = 56
        let button = LMKFloatingButton(icon: nil, size: size)

        #expect(button.layer.cornerRadius == size / 2)
    }

    @Test("Button has primary background color")
    func backgroundColor() {
        let button = LMKFloatingButton(icon: nil)

        #expect(button.backgroundColor == LMKColor.primary)
    }

    // MARK: - Icon

    @Test("Icon view has white tint")
    func iconTint() {
        let button = LMKFloatingButton(icon: UIImage(systemName: "gear"))

        let iconView = button.subviews.compactMap { $0 as? UIImageView }.first
        #expect(iconView?.tintColor == LMKColor.white)
    }

    @Test("Setting icon updates image view")
    func setIcon() {
        let button = LMKFloatingButton(icon: nil)
        let newIcon = UIImage(systemName: "star")
        button.icon = newIcon

        let iconView = button.subviews.compactMap { $0 as? UIImageView }.first
        #expect(iconView?.image != nil)
    }

    // MARK: - Configurable Strings

    @Test("Default strings have expected values")
    func defaultStrings() {
        let strings = LMKFloatingButton.Strings()

        #expect(strings.accessibilityLabel == "Floating action button")
    }

    // MARK: - Accessibility

    @Test("Button has accessibility traits")
    func accessibilityTraits() {
        let button = LMKFloatingButton(icon: nil)

        #expect(button.isAccessibilityElement)
        #expect(button.accessibilityTraits.contains(.button))
    }

    // MARK: - Badge

    @Test("Show badge adds badge view")
    func showBadge() {
        let button = LMKFloatingButton(icon: nil)
        button.showBadge(count: 3)

        let badge = button.subviews.compactMap { $0 as? LMKBadgeView }.first
        #expect(badge != nil)
    }

    @Test("Hide badge removes badge view")
    func hideBadge() {
        let button = LMKFloatingButton(icon: nil)
        button.showBadge(count: 3)
        button.hideBadge()

        let badge = button.subviews.compactMap { $0 as? LMKBadgeView }.first
        #expect(badge == nil)
    }

    @Test("Show dot badge adds badge view")
    func showDotBadge() {
        let button = LMKFloatingButton(icon: nil)
        button.showBadge()

        let badge = button.subviews.compactMap { $0 as? LMKBadgeView }.first
        #expect(badge != nil)
    }

    // MARK: - Gestures

    @Test("Button has tap and pan gesture recognizers")
    func gestures() {
        let button = LMKFloatingButton(icon: nil)

        let tapGestures = button.gestureRecognizers?.filter { $0 is UITapGestureRecognizer }
        let panGestures = button.gestureRecognizers?.filter { $0 is UIPanGestureRecognizer }
        #expect(tapGestures?.count == 1)
        #expect(panGestures?.count == 1)
    }
}
