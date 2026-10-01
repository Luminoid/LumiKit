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

        button.accessibilityLabel = "Open the debug menu"
        button.isEnabled = true
        #expect(button.accessibilityLabel == "Open the debug menu", "a host label survives state changes")
        button.accessibilityLabel = nil
        #expect(button.accessibilityLabel == "Depuración")
    }

    @Test
    func `Badge content adds, updates, removes the badge, and is the VoiceOver value`() {
        let button = LMKFloatingButton(icon: nil)
        #expect(button.badgeView == nil)
        #expect(button.accessibilityValue == nil)
        button.badge = .count(3)
        #expect(button.badgeView?.accessibilityLabel == "3")
        #expect(button.accessibilityValue == "3")
        button.badge = .dot
        #expect(button.badgeView?.countLabel.text == nil)
        #expect(button.accessibilityValue == LMKBadgeView.Strings().dotAccessibilityLabel)
        button.badge = .count(0)
        #expect(button.accessibilityValue == nil, "a hidden badge says nothing")
        button.badge = nil
        #expect(button.badgeView == nil)
        #expect(button.accessibilityValue == nil)
        #expect(button.subviews.contains { $0 is LMKBadgeView } == false)
    }

    @Test
    func `Hit target: 44pt while enabled, the bounds while disabled, nothing while hidden`() {
        let button = LMKFloatingButton(icon: nil, size: 32)
        button.frame = CGRect(x: 0, y: 0, width: 32, height: 32)
        #expect(button.gestureRecognizers?.count(where: { $0 is UIPanGestureRecognizer }) == 1)
        #expect(button.point(inside: CGPoint(x: -5, y: 16), with: nil))
        button.isEnabled = false
        #expect(button.point(inside: CGPoint(x: 10, y: 10), with: nil), "a disabled button swallows the touch like a disabled UIControl")
        #expect(!button.point(inside: CGPoint(x: -5, y: 16), with: nil), "without the expanded area")
        button.isEnabled = true
        button.isHidden = true
        #expect(!button.point(inside: CGPoint(x: 10, y: 10), with: nil))
    }

    @Test
    func `show installs at the bottom trailing corner inside the safe area and dismiss removes`() async {
        let (window, host) = Self.makeHost()
        defer { window.isHidden = true }
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
        await LMKWait.until { button.superview == nil }
        #expect(button.superview == nil)
        #expect(host.subviews.isEmpty, "the placement sentinel leaves with the button")
    }

    @Test
    func `The button follows a superview resize`() {
        let (window, host) = Self.makeHost()
        defer { window.isHidden = true }
        let button = LMKFloatingButton(icon: nil)
        button.show(in: host)
        host.layoutIfNeeded()
        #expect(button.center.x == 390 - LMKSpacing.large - 28)

        host.frame = CGRect(x: 0, y: 0, width: 844, height: 390)
        host.layoutIfNeeded()
        #expect(button.center.x == 844 - LMKSpacing.large - 28, "a rotation keeps the button at its corner")
        #expect(button.center.y == 390 - host.safeAreaInsets.bottom - LMKSpacing.large - 28)

        button.style.edgeMargin = 40
        #expect(button.center.x == 776, "a new margin moves it too")
        button.style.size = 40
        #expect(button.center.x == 784)
    }

    @Test
    func `The static show helper installs in the given host and replaces an existing button`() async {
        let (window, host) = Self.makeHost()
        defer { window.isHidden = true }
        let first = LMKFloatingButton.show(icon: nil, in: host) {}
        let second = LMKFloatingButton.show(icon: nil, in: host) {}
        await LMKWait.until { first.superview == nil }
        #expect(first.superview == nil)
        #expect(second.superview === host)
    }

    @Test
    func `positionKey persists the corner and moves a shown button`() {
        let key = "test.floatingButton.\(UUID().uuidString)"
        defer { UserDefaults.standard.removeObject(forKey: key) }
        let (window, host) = Self.makeHost()
        defer { window.isHidden = true }
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

        let late = LMKFloatingButton.show(icon: nil, in: host) {}
        #expect(late.center.y == host.bounds.height - host.safeAreaInsets.bottom - LMKSpacing.large - 28)
        late.positionKey = key
        #expect(late.center.y == host.safeAreaInsets.top + LMKSpacing.large + 28, "a key set after show moves the button to the stored corner")

        let keyed = LMKFloatingButton.show(icon: nil, in: host, positionKey: key) {}
        #expect(keyed.center.y == host.safeAreaInsets.top + LMKSpacing.large + 28)
    }

    @Test
    func `Pressed shades the fill, and the state styles apply every field`() {
        let button = LMKFloatingButton(icon: nil, style: LMKFloatingButton.Style(surface: LMKSurfaceStyle(background: .solid(UIColor(white: 0.6, alpha: 1)))))
        let resting = button.backgroundColor
        button.isHighlighted = true
        var brightness: CGFloat = 0
        button.backgroundColor?.resolvedColor(with: button.traitCollection).getHue(nil, saturation: nil, brightness: &brightness, alpha: nil)
        #expect(abs(brightness - 0.6 * 0.85) < 0.01, "a press shades the fill shown")
        #expect(button.alpha == 1)
        button.isHighlighted = false
        #expect(button.backgroundColor == resting)

        let glass = LMKFloatingButton(icon: nil, style: LMKFloatingButton.Style(surface: LMKSurfaceStyle(background: .glass(.regular))))
        glass.isHighlighted = true
        #expect(glass.transform.a < 1, "a fill with no shade to take presses in")
        glass.isHighlighted = false
        #expect(glass.transform == .identity)

        var styled = LMKFloatingButton.Style()
        styled.highlighted = LMKControlStateStyle(foregroundColor: .black, scale: 0.9, shadow: LMKShadowSource.hidden)
        styled.disabled = LMKControlStateStyle(foregroundColor: .gray, border: .solid(.red, width: 2), scale: 0.8, shadow: LMKShadowSource.hidden)
        button.style = styled
        button.isHighlighted = true
        #expect(button.iconView.tintColor == UIColor.black)
        #expect(abs(button.transform.a - 0.9) < 0.001)
        #expect(button.layer.shadowOpacity == 0)
        button.isHighlighted = false
        button.isEnabled = false
        #expect(button.iconView.tintColor == UIColor.gray)
        #expect(button.layer.borderWidth == LMKLayout.pixelAligned(2, for: button))
        #expect(abs(button.transform.a - 0.8) < 0.001)
        #expect(button.layer.shadowOpacity == 0)
        #expect(abs(button.alpha - LMKTheme.current.alpha.disabled) < 0.001, "the disabled alpha still applies")
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
