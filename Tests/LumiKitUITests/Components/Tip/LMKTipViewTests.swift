//
//  LMKTipViewTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

@MainActor
struct LMKTipViewTests {
    /// A visible window with a hosted controller; keep it for the test's duration.
    private static func makeWindow(theme: LMKTheme? = nil) -> (UIWindow, UIViewController) {
        let host = UIViewController()
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        if let theme {
            window.traitOverrides.lmkTheme = LMKThemeReference(theme)
        }
        window.rootViewController = host
        window.isHidden = false
        host.view.layoutIfNeeded()
        return (window, host)
    }

    private static func showPointed(_ style: LMKTipView.Style, direction: LMKTipView.ArrowDirection = .down) -> (UIWindow, LMKTipView) {
        let (window, host) = makeWindow()
        let source = UIView(frame: CGRect(x: 150, y: 400, width: 60, height: 40))
        host.view.addSubview(source)
        let tip = LMKTipView(title: "Tip", message: "Look here", style: style)
        tip.show(placement: .pointed(sourceView: source, arrowDirection: direction), in: host)
        host.view.layoutIfNeeded()
        return (window, tip)
    }

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
        #expect(tip.dimmingView.accessibilityLabel == "Entendido")
        #expect(tip.dimmingView.accessibilityHint == "Toca")
    }

    @Test
    func `The tip is a VoiceOver modal: bubble content first, then the dismiss area, escape dismisses`() async {
        let tip = LMKTipView(title: "Title", message: "Message")
        #expect(!tip.isAccessibilityElement)
        #expect(tip.accessibilityViewIsModal)
        #expect((tip.accessibilityElements as? [UIView]) == [tip.bubbleView, tip.dimmingView])
        #expect(!tip.bubbleView.isAccessibilityElement, "a container, so the button inside is reachable")
        #expect((tip.bubbleView.accessibilityElements as? [UIView]) == [tip.titleLabel, tip.messageLabel])
        #expect(tip.titleLabel.accessibilityTraits.contains(.header))
        #expect(tip.dimmingView.isAccessibilityElement)
        #expect(tip.dimmingView.accessibilityTraits == .button)
        #expect(tip.dimmingView.gestureRecognizers?.contains { $0 is UITapGestureRecognizer } == true)
        #expect((LMKTipView(message: "Just a message").bubbleView.accessibilityElements as? [UIView])?.count == 1)

        let (window, host) = Self.makeWindow()
        defer { window.isHidden = true }
        var dismissed = 0
        tip.onDismiss = { dismissed += 1 }
        tip.show(placement: .center, in: host)
        #expect((tip.bubbleView.accessibilityElements as? [UIView]) == [tip.titleLabel, tip.messageLabel, tip.dismissButton], "the centered tip's button joins the bubble")
        #expect(tip.accessibilityPerformEscape())
        #expect(tip.accessibilityPerformEscape(), "escape answers even while the fade runs")
        await LMKWait.until { tip.superview == nil }
        #expect(tip.superview == nil)
        #expect(dismissed == 1)
    }

    @Test
    func `Centered tips show the dismiss button and dismiss through it, once`() async {
        let (window, host) = Self.makeWindow()
        defer { window.isHidden = true }

        var dismissed = 0
        let tip = LMKTip.show(title: "Hi", message: "There", in: host) { dismissed += 1 }
        #expect(tip.superview === host.view)
        #expect(!tip.dismissButton.isHidden)
        #expect(tip.dimmingView.backgroundColor != UIColor.clear)
        tip.dismissButton.didTap()
        tip.dismissButton.didTap()
        tip.dismiss()
        await LMKWait.until { tip.superview == nil }
        #expect(tip.superview == nil)
        #expect(dismissed == 1, "three dismissals, one callback")
        tip.dismiss()
        #expect(dismissed == 1, "a dismissed tip stays dismissed")
    }

    @Test
    func `A dismissed tip shows again, visible and with fresh constraints`() async {
        let (window, host) = Self.makeWindow()
        defer { window.isHidden = true }
        var dismissed = 0
        let tip = LMKTipView(message: "Again")
        tip.onDismiss = { dismissed += 1 }
        tip.show(placement: .center, in: host)
        tip.dismiss()
        await LMKWait.until { tip.superview == nil }
        #expect(dismissed == 1)

        tip.show(placement: .center, in: host)
        host.view.layoutIfNeeded()
        #expect(tip.superview === host.view)
        #expect(tip.alpha == 1)
        #expect(tip.frame == host.view.bounds)
        #expect(host.view.constraints.count(where: { $0.firstItem === tip || $0.secondItem === tip }) == 4, "edges only, not stacked from the first show")
        tip.dismiss()
        await LMKWait.until { tip.superview == nil }
        #expect(dismissed == 2, "onDismiss fires once per show")
    }

    @Test
    func `Pointed tips draw an arrow toward the source, hide the button, and never dim`() async throws {
        let (window, host) = Self.makeWindow()
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
        #expect(tip.bubbleView.frame.minY == source.frame.maxY + LMKTipView.defaultArrowHeight + LMKSpacing.xs)
        #expect(abs(tip.bubbleView.frame.midX - source.frame.midX) < 0.5)
        #expect(tip.dimmingView.backgroundColor == UIColor.clear)
        tip.applyTheme(tip.traitCollection.lmkTheme)
        #expect(tip.dimmingView.backgroundColor == UIColor.clear, "a theme pass keeps a pointed tip undimmed")
        tip.dismiss()
        await LMKWait.until { tip.superview == nil }
        #expect(tip.superview == nil)
    }

    @Test
    func `A pointed tip stays undimmed under a stamped theme`() {
        var theme = LMKTheme()
        theme.tip = LMKTipView.Style(dimmingColor: .red)
        let (window, host) = Self.makeWindow(theme: theme)
        defer { window.isHidden = true }
        let source = UIView(frame: CGRect(x: 150, y: 400, width: 60, height: 40))
        host.view.addSubview(source)
        let tip = LMKTipView(message: "Look here")
        tip.show(placement: .pointed(sourceView: source, arrowDirection: .up), in: host)
        tip.updateTraitsIfNeeded()
        host.view.layoutIfNeeded()
        #expect(tip.dimmingView.backgroundColor == UIColor.clear, "the theme trait's re-apply must not bring the scrim back")

        let centered = LMKTipView(message: "Center")
        centered.show(placement: .center, in: host)
        centered.updateTraitsIfNeeded()
        #expect(centered.dimmingView.backgroundColor == UIColor.red)
    }

    @Test
    func `A pointed tip follows its source when the host resizes`() {
        let (window, host) = Self.makeWindow()
        defer { window.isHidden = true }
        let source = UIView()
        host.view.addSubview(source)
        source.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            source.centerXAnchor.constraint(equalTo: host.view.centerXAnchor),
            source.centerYAnchor.constraint(equalTo: host.view.centerYAnchor),
            source.widthAnchor.constraint(equalToConstant: 60),
            source.heightAnchor.constraint(equalToConstant: 40),
        ])
        host.view.layoutIfNeeded()
        let tip = LMKTipView(message: "Look here")
        tip.show(placement: .pointed(sourceView: source, arrowDirection: .down), in: host)
        host.view.layoutIfNeeded()
        let gap = LMKTipView.defaultArrowHeight + LMKSpacing.xs
        #expect(tip.bubbleView.frame.maxY == source.frame.minY - gap)
        #expect(abs(tip.bubbleView.frame.midX - 195) < 0.5)

        window.frame = CGRect(x: 0, y: 0, width: 844, height: 390)
        host.view.frame = window.bounds
        host.view.layoutIfNeeded()
        #expect(source.frame.midX == 422)
        #expect(tip.bubbleView.frame.maxY == source.frame.minY - gap, "the bubble moved with the source")
        #expect(abs(tip.bubbleView.frame.midX - 422) < 0.5)
        #expect((tip.outlineLayer.path?.boundingBox.maxY ?? 0) > tip.bubbleView.bounds.maxY, "the arrow was redrawn toward the source")
    }

    @Test
    func `A pointed tip leaves its source's size and position alone`() {
        let (window, host) = Self.makeWindow()
        defer { window.isHidden = true }
        // A label near the leading edge whose width only its hugging (250) holds, beside a spacer:
        // a bubble constrained to the label at .high stretched it to center over it.
        let source = UILabel()
        source.text = "Target"
        let row = UIStackView(arrangedSubviews: [source, UIView()])
        row.translatesAutoresizingMaskIntoConstraints = false
        host.view.addSubview(row)
        NSLayoutConstraint.activate([
            row.leadingAnchor.constraint(equalTo: host.view.leadingAnchor, constant: 16),
            row.trailingAnchor.constraint(equalTo: host.view.trailingAnchor, constant: -16),
            row.topAnchor.constraint(equalTo: host.view.topAnchor, constant: 300),
        ])
        host.view.layoutIfNeeded()
        let before = source.convert(source.bounds, to: host.view)

        let tip = LMKTipView(title: "Pointed tip", message: "The arrow follows the target view.")
        tip.show(placement: .pointed(sourceView: source, arrowDirection: .up), in: host)
        host.view.layoutIfNeeded()
        #expect(source.convert(source.bounds, to: host.view) == before, "the source kept its frame")
        #expect(tip.bubbleView.frame.minX == LMKSpacing.large, "the bubble is clamped at the margin instead")
        #expect(tip.bubbleView.frame.minY == before.maxY + LMKTipView.defaultArrowHeight + LMKSpacing.xs)
        #expect(tip.outlineLayer.path?.boundingBox.minY ?? 0 < 0, "the arrow still points up at the source")
    }

    @Test
    func `The bubble stays inside the safe area`() {
        let (window, host) = Self.makeWindow()
        defer { window.isHidden = true }
        host.additionalSafeAreaInsets = UIEdgeInsets(top: 0, left: 50, bottom: 0, right: 0)
        let source = UIView(frame: CGRect(x: 0, y: 400, width: 20, height: 20))
        host.view.addSubview(source)
        let tip = LMKTipView(message: "A tip that is wide enough to need clamping at the edge")
        tip.show(placement: .pointed(sourceView: source, arrowDirection: .up), in: host)
        host.view.layoutIfNeeded()
        #expect(tip.bubbleView.frame.minX == 50 + LMKSpacing.large, "leading edge clamped to the safe area plus the margin")
        #expect(tip.bubbleView.frame.width <= LMKTipView.defaultMaxWidth)
    }

    @Test
    func `Automatic direction measures the bubble against the room on both sides`() {
        let (window, host) = Self.makeWindow()
        defer { window.isHidden = true }
        let nearTop = UIView(frame: CGRect(x: 150, y: 20, width: 60, height: 40))
        let nearBottom = UIView(frame: CGRect(x: 150, y: 780, width: 60, height: 40))
        host.view.addSubview(nearTop)
        host.view.addSubview(nearBottom)
        let below = LMKTipView(message: "Below")
        below.show(placement: .pointed(sourceView: nearTop), in: host)
        #expect(below.pointedDirection == .up, "no room above: the bubble goes below")
        let above = LMKTipView(message: "Above")
        above.show(placement: .pointed(sourceView: nearBottom), in: host)
        #expect(above.pointedDirection == .down)
    }

    @Test
    func `A pointed tip's color and border wrap the bubble and the arrow as one shape`() throws {
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
    func `Arrow, margin, spacing, and width fields shape a pointed tip`() throws {
        let style = LMKTipView.Style(arrowWidth: 30, arrowHeight: 14, arrowTipRadius: 0, maxWidth: 120, minMargin: 40, sourceSpacing: 10)
        let (window, tip) = Self.showPointed(style, direction: .up)
        defer { window.isHidden = true }
        let outline = try #require(tip.outlineLayer.path)
        #expect(abs(outline.boundingBox.minY + 14) < 0.5, "the arrow's height")
        #expect(tip.bubbleView.frame.minY == 464, "source bottom (440) + arrow (14) + spacing (10)")
        #expect(tip.bubbleView.frame.width <= 120)
        #expect(tip.bubbleView.frame.minX >= 40)
        // The arrow's base spans its width at the bubble's top edge.
        #expect(outline.contains(CGPoint(x: tip.bubbleView.bounds.width / 2 + 13, y: -1)))
        #expect(!outline.contains(CGPoint(x: tip.bubbleView.bounds.width / 2 + 16, y: -1)))
    }

    @Test
    func `A centered tip keeps the border on the bubble itself`() {
        let (window, host) = Self.makeWindow()
        defer { window.isHidden = true }
        let tip = LMKTipView(message: "Welcome", style: LMKTipView.Style(surface: LMKSurfaceStyle(background: .solid(.systemTeal), border: .solid(.black, width: 1))))
        tip.show(placement: .center, in: host)
        #expect(tip.outlineLayer.isHidden)
        #expect(tip.bubbleView.backgroundColor == UIColor.systemTeal)
        #expect(tip.bubbleView.layer.borderWidth == 1)
    }

    @Test
    func `Style overrides apply per instance and through the theme`() {
        let tip = LMKTipView(message: "Test", style: LMKTipView.Style(surface: LMKSurfaceStyle(background: .solid(.red)), messageTextStyle: .caption, messageColor: .white, iconBackgroundSize: 50))
        #expect(tip.bubbleView.backgroundColor == UIColor.red)
        #expect(tip.messageLabel.textColor == UIColor.white)
        #expect(tip.messageLabel.lmk_textStyle == .caption)
        #expect(LMKTipView.Style(haptics: false).merging(LMKTipView.Style()).haptics == false)
        #expect(LMKTipView.Style().merging(LMKTipView.Style(haptics: false)).haptics == false)

        var theme = LMKTheme()
        theme.tip = LMKTipView.Style(surface: LMKSurfaceStyle(corners: .fixed(2)), dimmingColor: .clear)
        let themed = LMKTipView(message: "Test")
        let window = LMKThemeTesting.host(themed, theme: theme)
        defer { window.isHidden = true }
        #expect(themed.bubbleView.layer.cornerRadius == 2)
        #expect(themed.dimmingView.backgroundColor == UIColor.clear)
    }
}
