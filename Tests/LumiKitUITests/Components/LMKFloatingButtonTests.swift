//
//  LMKFloatingButtonTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

@MainActor
struct LMKFloatingButtonTests {
    private static func makeHost() -> (UIWindow, UIView) {
        UIView.setAnimationsEnabled(false)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        let host = UIView(frame: window.bounds)
        window.addSubview(host)
        window.isHidden = false
        return (window, host)
    }

    @Test
    func `Default size, circle, primary background, and icon`() {
        let button = LMKFloatingButton(icon: UIImage(systemName: "star"))
        button.layoutIfNeeded()
        #expect(button.bounds.size == CGSize(width: 56, height: 56))
        #expect(button.lmk_cornerStyle == .circle)
        #expect(button.backgroundColor === LMKColor.primary)
        #expect(button.iconView.tintColor === LMKColor.onAccent)
        #expect(button.iconView.image != nil)
        #expect(button.layer.shadowOpacity > 0)
        button.icon = UIImage(systemName: "gear")
        #expect(button.iconView.image != nil)
    }

    @Test
    func `Custom size and style`() {
        let sized = LMKFloatingButton(icon: nil, size: 48)
        sized.layoutIfNeeded()
        #expect(sized.bounds.width == 48)
        let styled = LMKFloatingButton(icon: nil, style: LMKFloatingButton.Style(surface: LMKSurfaceStyle(background: .solid(.red)), iconTint: .black, iconSize: 10))
        #expect(styled.backgroundColor == UIColor.red)
        #expect(styled.iconView.tintColor == UIColor.black)
    }

    @Test
    func `Accessibility label, traits, custom actions, and strings`() {
        let button = LMKFloatingButton(icon: nil)
        #expect(button.isAccessibilityElement)
        #expect(button.accessibilityTraits.contains(.button))
        #expect(button.accessibilityLabel == "Floating action button")
        #expect(button.accessibilityCustomActions?.count == 4)
        button.strings = LMKFloatingButton.Strings(accessibilityLabel: "Depuración")
        #expect(button.accessibilityLabel == "Depuración")
        button.isEnabled = false
        #expect(button.accessibilityTraits.contains(.notEnabled))
        #expect(button.alpha < 1)
    }

    @Test
    func `Badge content adds, updates, and removes the badge`() {
        let button = LMKFloatingButton(icon: nil)
        #expect(button.badgeView == nil)
        button.badge = .count(3)
        #expect(button.badgeView?.accessibilityLabel == "3")
        button.badge = .dot
        #expect(button.badgeView?.countLabel.text == nil)
        button.badge = nil
        #expect(button.badgeView == nil)
        #expect(button.subviews.contains { $0 is LMKBadgeView } == false)
    }

    @Test
    func `Gestures and tap handler`() {
        let button = LMKFloatingButton(icon: nil)
        #expect(button.gestureRecognizers?.count(where: { $0 is UIPanGestureRecognizer }) == 1)
        var taps = 0
        button.onTap = { taps += 1 }
        button.sendActions(for: .touchUpInside)
        button.isEnabled = false
        #expect(!button.point(inside: CGPoint(x: 10, y: 10), with: nil))
    }

    @Test
    func `show installs at the bottom trailing corner inside the safe area and dismiss removes`() async {
        let (window, host) = Self.makeHost()
        defer { window.isHidden = true; UIView.setAnimationsEnabled(true) }
        let button = LMKFloatingButton(icon: nil)
        button.show(in: host)
        host.layoutIfNeeded()
        #expect(button.superview === host)
        #expect(button.center.x == host.bounds.width - LMKSpacing.large - 28)
        #expect(button.center.y == host.bounds.height - host.safeAreaInsets.bottom - LMKSpacing.large - 28)

        button.move(to: .topLeading, animated: false)
        #expect(button.center.x == LMKSpacing.large + 28)
        #expect(button.center.y == host.safeAreaInsets.top + LMKSpacing.large + 28)

        button.dismiss()
        try? await Task.sleep(for: .milliseconds(400))
        #expect(button.superview == nil)
    }

    @Test
    func `The static show helper installs in the given host and replaces an existing button`() async {
        let (window, host) = Self.makeHost()
        defer { window.isHidden = true; UIView.setAnimationsEnabled(true) }
        let first = LMKFloatingButton.show(icon: nil, in: host) {}
        let second = LMKFloatingButton.show(icon: nil, in: host) {}
        try? await Task.sleep(for: .milliseconds(400))
        #expect(first.superview == nil)
        #expect(second.superview === host)
    }

    @Test
    func `positionKey persists the corner`() {
        let key = "test.floatingButton.\(UUID().uuidString)"
        defer { UserDefaults.standard.removeObject(forKey: key) }
        let (window, host) = Self.makeHost()
        defer { window.isHidden = true; UIView.setAnimationsEnabled(true) }
        let button = LMKFloatingButton(icon: nil)
        button.positionKey = key
        button.show(in: host)
        button.move(to: .topTrailing, animated: false)
        #expect(UserDefaults.standard.dictionary(forKey: key)?["corner"] as? String == "topTrailing")

        let restored = LMKFloatingButton(icon: nil)
        restored.positionKey = key
        restored.show(in: host)
        #expect(restored.center.y == host.safeAreaInsets.top + LMKSpacing.large + 28)
        #expect(restored.center.x == host.bounds.width - LMKSpacing.large - 28)
    }

    @Test
    func `theme.floatingButton supplies app-wide defaults`() {
        var theme = LMKTheme()
        theme.floatingButton = LMKFloatingButton.Style(size: 40, iconTint: .black)
        let button = LMKFloatingButton(icon: nil)
        let window = LMKThemeTesting.host(button, theme: theme)
        defer { window.isHidden = true }
        button.layoutIfNeeded()
        #expect(button.bounds.width == 40)
        #expect(button.iconView.tintColor == UIColor.black)
    }
}
