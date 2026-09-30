//
//  LMKTipViewTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

@MainActor
struct LMKTipViewTests {
    @Test
    func `Init keeps the content and builds the bubble`() {
        let icon = UIImage(systemName: "star")
        let tip = LMKTipView(title: "Tip", message: "Message", icon: icon)
        #expect(tip.title == "Tip")
        #expect(tip.message == "Message")
        #expect(tip.icon === icon)
        #expect(tip.titleLabel.text == "Tip")
        #expect(tip.messageLabel.text == "Message")
        #expect(!tip.iconBackgroundView.isHidden)
        #expect(tip.superview == nil)
        #expect(tip.onDismiss == nil)

        let plain = LMKTipView(message: "Hello")
        #expect(plain.titleLabel.isHidden)
        #expect(plain.iconBackgroundView.isHidden)
    }

    @Test
    func `Default bubble surface, dimming, and strings`() {
        let tip = LMKTipView(message: "Test")
        #expect(tip.bubbleView.layer.cornerRadius == LMKCornerRadius.medium)
        #expect(tip.bubbleView.backgroundColor === LMKColor.backgroundSecondary)
        #expect(tip.bubbleView.layer.shadowOpacity > 0)
        #expect(tip.dimmingView.backgroundColor != nil)
        #expect(tip.dismissButton.isHidden, "the dismiss button appears for centered tips at show time")
        #expect(tip.dismissButton.title == "Got it")
        let strings = LMKTipView.Strings()
        #expect(strings.dismissAccessibilityHint == "Tap anywhere to dismiss")
        #expect(strings.dismissButtonTitle == "Got it")
        tip.strings = LMKTipView.Strings(dismissAccessibilityHint: "Toca", dismissButtonTitle: "Entendido")
        #expect(tip.dismissButton.title == "Entendido")
        #expect(tip.dimmingView.accessibilityLabel == "Toca")
    }

    @Test
    func `Accessibility exposes the bubble and the dimming button`() {
        let tip = LMKTipView(title: "Title", message: "Message")
        #expect(!tip.isAccessibilityElement)
        #expect(tip.bubbleView.isAccessibilityElement)
        #expect(tip.bubbleView.accessibilityLabel == "Title. Message")
        #expect(tip.dimmingView.isAccessibilityElement)
        #expect(tip.dimmingView.accessibilityTraits == .button)
        #expect(tip.dimmingView.gestureRecognizers?.contains { $0 is UITapGestureRecognizer } == true)
        #expect(LMKTipView(message: "Just a message").bubbleView.accessibilityLabel == "Just a message")
    }

    @Test
    func `Centered tips show the dismiss button and dismiss through it`() async {
        UIView.setAnimationsEnabled(false)
        defer { UIView.setAnimationsEnabled(true) }
        let host = UIViewController()
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        window.rootViewController = host
        window.isHidden = false
        defer { window.isHidden = true }

        var dismissed = 0
        let tip = LMKTip.show(title: "Hi", message: "There", in: host) { dismissed += 1 }
        #expect(tip.superview === host.view)
        #expect(!tip.dismissButton.isHidden)
        tip.dismissButton.didTap()
        try? await Task.sleep(for: .milliseconds(400))
        #expect(tip.superview == nil)
        #expect(dismissed == 1)
    }

    @Test
    func `Pointed tips draw an arrow toward the source and hide the dismiss button`() async throws {
        UIView.setAnimationsEnabled(false)
        defer { UIView.setAnimationsEnabled(true) }
        let host = UIViewController()
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        window.rootViewController = host
        window.isHidden = false
        defer { window.isHidden = true }
        let source = UIView(frame: CGRect(x: 150, y: 400, width: 60, height: 40))
        host.view.addSubview(source)

        let tip = LMKTipView(message: "Look here")
        tip.show(placement: .pointed(sourceView: source, arrowDirection: .up), in: host)
        host.view.layoutIfNeeded()
        #expect(tip.dismissButton.isHidden)
        #expect(!tip.outlineLayer.isHidden, "a solid bubble and its arrow are one outline")
        #expect(tip.arrowLayer.isHidden)
        let outline = try #require(tip.outlineLayer.path)
        // The arrow reaches above the bubble toward the source.
        #expect(outline.boundingBox.minY < 0)
        #expect(tip.bubbleView.backgroundColor == UIColor.clear, "the outline paints the fill")
        #expect(tip.bubbleView.layer.shadowOpacity == 0)
        #expect(tip.outlineLayer.shadowOpacity > 0)
        #expect(tip.bubbleView.frame.minY > source.frame.maxY)
        #expect(tip.dimmingView.backgroundColor == UIColor.clear)
        tip.dismiss()
        try? await Task.sleep(for: .milliseconds(400))
        #expect(tip.superview == nil)
    }

    private static func showPointed(_ style: LMKTipView.Style, direction: LMKTipView.ArrowDirection = .down) -> (UIWindow, LMKTipView) {
        let host = UIViewController()
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        window.rootViewController = host
        window.isHidden = false
        let source = UIView(frame: CGRect(x: 150, y: 400, width: 60, height: 40))
        host.view.addSubview(source)
        let tip = LMKTipView(title: "Tip", message: "Look here", style: style)
        tip.show(placement: .pointed(sourceView: source, arrowDirection: direction), in: host)
        host.view.layoutIfNeeded()
        return (window, tip)
    }

    @Test
    func `A pointed tip's color and border wrap the bubble and the arrow as one shape`() throws {
        UIView.setAnimationsEnabled(false)
        defer { UIView.setAnimationsEnabled(true) }
        let style = LMKTipView.Style(surface: LMKSurfaceStyle(
            background: .solid(.systemIndigo),
            corners: .fixed(20),
            border: .solid(.white, width: 2),
            shadow: .level(.level4)
        ))
        let (window, tip) = Self.showPointed(style)
        defer { window.isHidden = true }
        let traits = tip.traitCollection

        #expect(!tip.outlineLayer.isHidden)
        #expect(tip.outlineLayer.fillColor == UIColor.systemIndigo.resolvedColor(with: traits).cgColor)
        #expect(tip.outlineLayer.strokeColor == UIColor.white.resolvedColor(with: traits).cgColor)
        #expect(tip.outlineLayer.lineWidth == 2)
        #expect(tip.bubbleView.layer.borderWidth == 0, "one stroke, not a second one on the bubble's layer")

        let outline = try #require(tip.outlineLayer.path)
        let bounds = tip.bubbleView.bounds
        let arrowHeight = LMKTipView.defaultArrowHeight
        // The border sits inside the bubble; only the arrow leaves it, below the bottom edge.
        #expect(abs(outline.boundingBox.minY - 1) < 0.5)
        #expect(abs(outline.boundingBox.maxY - (bounds.maxY - 1 + arrowHeight)) < 0.5)
        #expect(abs(outline.boundingBox.width - (bounds.width - 2)) < 0.5)
        // A point on the arrow's flank is part of the same filled shape.
        let sourceMidX = 180 - tip.bubbleView.frame.minX
        #expect(outline.contains(CGPoint(x: sourceMidX, y: bounds.maxY + 2)))
    }

    @Test
    func `The outline follows the arrow direction and the corner style`() {
        let arrow = LMKTipView.Arrow(pointsUp: true, centerX: 100, width: 16, height: 8, tipRadius: 2)
        let rect = CGRect(x: 0, y: 0, width: 200, height: 80)
        let up = LMKTipView.outlinePath(in: rect, cornerRadius: 12, maskedCorners: .lmk_all, arrow: arrow)
        // The control point of the rounded tip marks the full arrow height.
        #expect(up.cgPath.boundingBox.minY == -8)
        #expect(up.cgPath.boundingBox.maxY == 80)
        #expect(up.contains(CGPoint(x: 100, y: -4)))
        #expect(!up.contains(CGPoint(x: 80, y: -4)))
        #expect(!up.contains(CGPoint(x: 1, y: 1)), "the corner is rounded")

        var down = arrow
        down.pointsUp = false
        let below = LMKTipView.outlinePath(in: rect, cornerRadius: 12, maskedCorners: [.layerMinXMinYCorner], arrow: down)
        #expect(below.cgPath.boundingBox.minY == 0)
        #expect(below.cgPath.boundingBox.maxY == 88)
        #expect(below.contains(CGPoint(x: 100, y: 84)))
        #expect(below.contains(CGPoint(x: 199, y: 79)), "an unmasked corner stays square")
        #expect(!below.contains(CGPoint(x: 1, y: 1)))
    }

    @Test
    func `A gradient bubble keeps its own surface and a plain arrow in arrowColor`() {
        UIView.setAnimationsEnabled(false)
        defer { UIView.setAnimationsEnabled(true) }
        let style = LMKTipView.Style(
            surface: LMKSurfaceStyle(background: .gradient(colors: [.systemPink, .systemOrange], direction: .leftToRight)),
            arrowColor: .systemOrange
        )
        let (window, tip) = Self.showPointed(style, direction: .up)
        defer { window.isHidden = true }
        #expect(tip.outlineLayer.isHidden)
        #expect(!tip.arrowLayer.isHidden)
        #expect(tip.arrowLayer.fillColor == UIColor.systemOrange.resolvedColor(with: tip.traitCollection).cgColor)
        #expect(tip.bubbleView.lmk_surfaceBackgroundView != nil)
    }

    @Test
    func `A centered tip keeps the border on the bubble itself`() {
        UIView.setAnimationsEnabled(false)
        defer { UIView.setAnimationsEnabled(true) }
        let host = UIViewController()
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        window.rootViewController = host
        window.isHidden = false
        defer { window.isHidden = true }
        let tip = LMKTipView(message: "Welcome", style: LMKTipView.Style(surface: LMKSurfaceStyle(background: .solid(.systemTeal), border: .solid(.black, width: 1))))
        tip.show(placement: .center, in: host)
        #expect(tip.outlineLayer.isHidden)
        #expect(tip.bubbleView.backgroundColor == UIColor.systemTeal)
        #expect(tip.bubbleView.layer.borderWidth == 1)
    }

    @Test
    func `Style overrides apply per instance and through the theme`() {
        let tip = LMKTipView(message: "Test", style: LMKTipView.Style(surface: LMKSurfaceStyle(background: .solid(.red)), messageColor: .white, iconBackgroundSize: 50))
        #expect(tip.bubbleView.backgroundColor == UIColor.red)
        #expect(tip.messageLabel.textColor == UIColor.white)

        var theme = LMKTheme()
        theme.tip = LMKTipView.Style(surface: LMKSurfaceStyle(corners: .fixed(2)), dimmingColor: .clear)
        let themed = LMKTipView(message: "Test")
        let window = LMKThemeTesting.host(themed, theme: theme)
        defer { window.isHidden = true }
        #expect(themed.bubbleView.layer.cornerRadius == 2)
        #expect(themed.dimmingView.backgroundColor == UIColor.clear)
    }
}
