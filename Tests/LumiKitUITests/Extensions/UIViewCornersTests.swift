//
//  UIViewCornersTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

// MARK: - LMKCornerStyle

struct LMKCornerStyleTests {
    @Test
    func `Presets carry their radius rule and all corners`() {
        #expect(LMKCornerStyle.capsule.radius == .capsule)
        #expect(LMKCornerStyle.circle.radius == .circle)
        #expect(LMKCornerStyle.none.radius == .none)
        #expect(LMKCornerStyle.capsule.maskedCorners == .lmk_all)
        #expect(LMKCornerStyle.capsule.curve == .continuous)
        #expect(LMKCornerStyle.fixed(8, corners: .lmk_top, curve: .circular) == LMKCornerStyle(radius: .fixed(8), maskedCorners: .lmk_top, curve: .circular))
        #expect(LMKCornerStyle.concentric(minimum: 4).radius == .concentric(minimum: 4))
    }

    @Test
    func `resolvedRadius follows the bounds only for capsule and circle`() {
        let bounds = CGRect(x: 0, y: 0, width: 60, height: 20)
        #expect(LMKCornerStyle.none.resolvedRadius(for: bounds) == 0)
        #expect(LMKCornerStyle.fixed(8).resolvedRadius(for: bounds) == 8)
        #expect(LMKCornerStyle.capsule.resolvedRadius(for: bounds) == 10)
        #expect(LMKCornerStyle.circle.resolvedRadius(for: bounds) == 10)
        #expect(LMKCornerStyle.concentric(minimum: 6).resolvedRadius(for: bounds) == 6)
        #expect(LMKCornerStyle.capsule.tracksBounds)
        #expect(!LMKCornerStyle.fixed(8).tracksBounds)
    }

    @Test
    func `Corner masks compose`() {
        #expect(CACornerMask.lmk_top.union(.lmk_bottom) == .lmk_all)
        #expect(CACornerMask.lmk_left.union(.lmk_right) == .lmk_all)
    }
}

// MARK: - UIView

@MainActor
struct UIViewCornersTests {
    @Test
    func `Fixed style sets radius, mask, and curve`() {
        let view = UIView()
        view.lmk_applyCornerStyle(.fixed(8, corners: .lmk_top, curve: .circular))
        #expect(view.layer.cornerRadius == 8)
        #expect(view.layer.maskedCorners == .lmk_top)
        #expect(view.layer.cornerCurve == .circular)
        #expect(view.layer.masksToBounds)
        #expect(view.lmk_cornerStyle == .fixed(8, corners: .lmk_top, curve: .circular))
    }

    @Test
    func `lmk_applyCornerRadius sets radius and masking`() {
        let view = UIView()
        view.lmk_applyCornerRadius(12, masking: false)
        #expect(view.layer.cornerRadius == 12)
        #expect(view.layer.masksToBounds == false)
        #expect(view.layer.cornerCurve == .continuous)
    }

    @Test
    func `Capsule tracks the bounds in a window`() {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 80, height: 30))
        let window = LMKThemeTesting.host(view)
        defer { window.isHidden = true }
        view.lmk_applyCornerStyle(.capsule)
        view.lmk_layoutCornersIfNeeded()
        window.layoutIfNeeded()
        #expect(view.layer.cornerRadius == 15)
        #expect(view.layer.masksToBounds)

        view.frame = CGRect(x: 0, y: 0, width: 80, height: 50)
        view.lmk_layoutCornersIfNeeded()
        window.layoutIfNeeded()
        #expect(view.layer.cornerRadius == 25)
    }

    @Test
    func `A capsule follows the view's size without a layout call`() {
        let view = UIView()
        let window = LMKThemeTesting.host(view)
        defer { window.isHidden = true }
        view.lmk_applyCornerStyle(.capsule)

        view.frame = CGRect(x: 0, y: 0, width: 120, height: 36)
        window.layoutIfNeeded()
        #expect(view.layer.cornerRadius == 18)

        view.frame = CGRect(x: 0, y: 0, width: 120, height: 60)
        window.layoutIfNeeded()
        #expect(view.layer.cornerRadius == 30)
    }

    @Test
    func `The view that follows a capsule's size stays out of the way`() throws {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 80, height: 30))
        view.lmk_applyCornerStyle(.capsule)
        let tracker = try #require(view.subviews.first)
        #expect(tracker.isHidden)
        #expect(!tracker.isUserInteractionEnabled)
        #expect(view.subviews.count == 1)

        // Applying again does not stack another one; a host that cleared its subviews gets it back.
        view.lmk_applyCornerStyle(.capsule)
        #expect(view.subviews.count == 1)
        tracker.removeFromSuperview()
        view.lmk_applyCornerStyle(.capsule)
        #expect(view.subviews.count == 1)

        // A fixed radius needs none.
        view.lmk_applyCornerStyle(.fixed(8))
        #expect(view.subviews.isEmpty)
    }

    @Test
    func `An effect view follows its capsule from its content view`() {
        let effectView = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
        effectView.frame = CGRect(x: 0, y: 0, width: 80, height: 30)
        effectView.lmk_applyCornerStyle(.capsule)
        #expect(effectView.contentView.subviews.count == 1)
        #expect(effectView.layer.cornerRadius == 15)
    }

    @Test
    func `A capsule is drawn on the layer, not through a corner configuration`() {
        guard #available(iOS 26, *) else { return }
        // A published configuration clips subviews along a tighter curve than the border follows.
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 80, height: 30))
        view.lmk_applyCornerStyle(.capsule)
        #expect(view.cornerConfiguration != .capsule())
        #expect(view.layer.cornerRadius == 15)

        let circle = UIView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        circle.lmk_makeCircular()
        #expect(circle.cornerConfiguration != .capsule())
        #expect(circle.layer.cornerRadius == 20)
    }

    @Test
    func `A clipping container with a border does not publish its radius`() {
        guard #available(iOS 26, *) else { return }
        let bordered = UIView()
        bordered.lmk_applyBorder(color: .black)
        bordered.lmk_applyCornerRadius(10, asConcentricContainer: true)
        #expect(bordered.cornerConfiguration != .corners(radius: .fixed(10)))
        #expect(bordered.layer.cornerRadius == 10)

        // Without clipping the border is safe, and so is the configuration.
        let unclipped = UIView()
        unclipped.lmk_applyBorder(color: .black)
        unclipped.lmk_applyCornerRadius(10, masking: false, asConcentricContainer: true)
        #expect(unclipped.cornerConfiguration == .corners(radius: .fixed(10)))

        // Once the border goes, the container publishes.
        bordered.lmk_removeBorder()
        #expect(bordered.cornerConfiguration == .corners(radius: .fixed(10)))
    }

    @Test
    func `lmk_makeCircular halves the shorter side`() {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        let window = LMKThemeTesting.host(view)
        defer { window.isHidden = true }
        view.lmk_makeCircular()
        window.layoutIfNeeded()
        #expect(view.layer.cornerRadius == 20)
        #expect(view.lmk_cornerStyle == .circle)
    }

    @Test
    func `Concentric corners floor at the minimum radius and mask`() {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        view.lmk_applyConcentricCorners(minimumRadius: 6)
        #expect(view.layer.masksToBounds)
        if #available(iOS 26, *) {
            #expect(view.cornerConfiguration == .corners(radius: .containerConcentric(minimum: 6)))
        } else {
            #expect(view.layer.cornerRadius == 6)
        }
    }

    @Test
    func `A fixed radius publishes a container configuration only when asked`() {
        guard #available(iOS 26, *) else { return }
        let plain = UIView()
        plain.lmk_applyCornerRadius(10)
        #expect(plain.cornerConfiguration != .corners(radius: .fixed(10)))

        let container = UIView()
        container.lmk_applyCornerRadius(10, asConcentricContainer: true)
        #expect(container.cornerConfiguration == .corners(radius: .fixed(10)))

        // Once published, a later fixed radius keeps the configuration consistent.
        container.lmk_applyCornerRadius(14)
        #expect(container.cornerConfiguration == .corners(radius: .fixed(14)))
    }

    @Test
    func `A partially masked container publishes per-corner radii`() {
        guard #available(iOS 26, *) else { return }
        let sheet = UIView()
        sheet.lmk_applyCornerStyle(.fixed(16, corners: .lmk_top), asConcentricContainer: true)
        let expected = UICornerConfiguration.corners(topLeftRadius: .fixed(16), topRightRadius: .fixed(16), bottomLeftRadius: .fixed(0), bottomRightRadius: .fixed(0))
        #expect(sheet.cornerConfiguration == expected)
        #expect(sheet.layer.maskedCorners == .lmk_top)
    }
}
