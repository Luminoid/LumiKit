//
//  LMKFloatingButtonTests.swift
//  LumiKitUITests
//
//  Tests for floating action button component.
//

import Testing
import UIKit
@testable import LumiKitUI

@MainActor
struct LMKFloatingButtonTests {
    // MARK: - Initialization

    @Test
    func `Init with default size creates correct frame`() {
        let button = LMKFloatingButton(icon: UIImage(systemName: "star"))

        #expect(button.frame.width == LMKFloatingButtonLayout.defaultSize)
        #expect(button.frame.height == LMKFloatingButtonLayout.defaultSize)
    }

    @Test
    func `Init with custom size creates correct frame`() {
        let button = LMKFloatingButton(icon: nil, size: 48)

        #expect(button.frame.width == 48)
        #expect(button.frame.height == 48)
    }

    // MARK: - Layout Constants

    @Test
    func `Layout constants have expected values`() {
        #expect(LMKFloatingButtonLayout.defaultSize == 56)
        #expect(LMKFloatingButtonLayout.edgeMargin == 16)
        #expect(LMKFloatingButtonLayout.iconSize == 24)
        #expect(LMKFloatingButtonLayout.badgeOffset == -4)
    }

    // MARK: - Shape

    @Test
    func `Button is circular`() {
        let size: CGFloat = 56
        let button = LMKFloatingButton(icon: nil, size: size)

        #expect(button.layer.cornerRadius == size / 2)
    }

    @Test
    func `Button has primary background color`() {
        let button = LMKFloatingButton(icon: nil)

        #expect(button.backgroundColor == LMKColor.primary)
    }

    // MARK: - Icon

    @Test
    func `Icon view has white tint`() {
        let button = LMKFloatingButton(icon: UIImage(systemName: "gear"))

        let iconView = button.subviews.compactMap { $0 as? UIImageView }.first
        #expect(iconView?.tintColor == LMKColor.white)
    }

    @Test
    func `Setting icon updates image view`() {
        let button = LMKFloatingButton(icon: nil)
        let newIcon = UIImage(systemName: "star")
        button.icon = newIcon

        let iconView = button.subviews.compactMap { $0 as? UIImageView }.first
        #expect(iconView?.image != nil)
    }

    // MARK: - Configurable Strings

    @Test
    func `Default strings have expected values`() {
        let strings = LMKFloatingButton.Strings()

        #expect(strings.accessibilityLabel == "Floating action button")
    }

    // MARK: - Accessibility

    @Test
    func `Button has accessibility traits`() {
        let button = LMKFloatingButton(icon: nil)

        #expect(button.isAccessibilityElement)
        #expect(button.accessibilityTraits.contains(.button))
    }

    // MARK: - Badge

    @Test
    func `Show badge adds badge view`() {
        let button = LMKFloatingButton(icon: nil)
        button.showBadge(count: 3)

        let badge = button.subviews.compactMap { $0 as? LMKBadgeView }.first
        #expect(badge != nil)
    }

    @Test
    func `Hide badge removes badge view`() {
        let button = LMKFloatingButton(icon: nil)
        button.showBadge(count: 3)
        button.hideBadge()

        let badge = button.subviews.compactMap { $0 as? LMKBadgeView }.first
        #expect(badge == nil)
    }

    @Test
    func `Show dot badge adds badge view`() {
        let button = LMKFloatingButton(icon: nil)
        button.showBadge()

        let badge = button.subviews.compactMap { $0 as? LMKBadgeView }.first
        #expect(badge != nil)
    }

    // MARK: - Gestures

    @Test
    func `Button has tap and pan gesture recognizers`() {
        let button = LMKFloatingButton(icon: nil)

        let tapGestures = button.gestureRecognizers?.filter { $0 is UITapGestureRecognizer }
        let panGestures = button.gestureRecognizers?.filter { $0 is UIPanGestureRecognizer }
        #expect(tapGestures?.count == 1)
        #expect(panGestures?.count == 1)
    }
}
