//
//  LMKGlassViewTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

// MARK: - LMKGlassView

/// Counts KVO callbacks (the observer closure is `@Sendable`).
private final class EffectAssignmentCounter: @unchecked Sendable {
    private let lock = NSLock()
    private var value = 0

    var count: Int {
        lock.withLock { value }
    }

    var isEmpty: Bool { lock.withLock { value } < 1 }

    func increment() {
        lock.withLock { value += 1 }
    }
}

@MainActor
struct LMKGlassViewTests {
    @Test
    func `isGlass tracks iOS 26 availability`() {
        let view = LMKGlassView()
        if #available(iOS 26, *) {
            #expect(view.isGlass)
            #expect(view.effect is UIGlassEffect)
        } else {
            #expect(!view.isGlass)
            #expect(view.effect is UIBlurEffect)
        }
    }

    @Test
    func `The blur fallback caps its radius at half the shorter side, as glass does`() {
        let button = CGRect(x: 0, y: 0, width: 120, height: 46)
        #expect(LMKGlassView.fallbackCornerRadius(.concentric(minimum: 40), bounds: button) == 23, "a concentric minimum on a short button is a capsule")
        #expect(LMKGlassView.fallbackCornerRadius(.fixed(40), bounds: button) == 23)
        #expect(LMKGlassView.fallbackCornerRadius(.fixed(16), bounds: button) == 16, "a radius that fits is kept")
        #expect(LMKGlassView.fallbackCornerRadius(.capsule, bounds: button) == 23)
        #expect(LMKGlassView.fallbackCornerRadius(.fixed(40), bounds: .zero) == 40, "before layout the radius waits for a size")
    }

    @Test
    func `clear style, tint, and interactivity reach the effect and can change later`() {
        let view = LMKGlassView(variant: .clear, tintColor: .red, isInteractive: true)
        #expect(view.variant == .clear)
        #expect(view.isInteractive)
        if #available(iOS 26, *) {
            let glass = view.effect as? UIGlassEffect
            #expect(glass?.tintColor == .red)
            #expect(glass?.isInteractive == true)
            view.style.tintColor = .blue
            view.isInteractive = false
            let updated = view.effect as? UIGlassEffect
            #expect(updated?.tintColor == .blue)
            #expect(updated?.isInteractive == false)
        } else {
            #expect(view.contentView.backgroundColor != nil)
        }
    }

    @Test
    func `fixed corner radius applies through the version-appropriate path`() {
        let view = LMKGlassView(cornerRadius: 12)
        #expect(!view.usesConcentricCorners)
        #expect(view.cornerRadius == 12)
        if #available(iOS 26, *) {
            #expect(view.cornerConfiguration == .corners(radius: .fixed(12)))
            view.cornerRadius = 20
            #expect(view.cornerConfiguration == .corners(radius: .fixed(20)))
        } else {
            #expect(view.layer.cornerRadius == 12)
            #expect(view.clipsToBounds)
            view.cornerRadius = 20
            #expect(view.layer.cornerRadius == 20)
        }
    }

    @Test
    func `concentric corners use the radius as the floor on iOS 26`() {
        let view = LMKGlassView(cornerRadius: 10, usesConcentricCorners: true)
        #expect(view.usesConcentricCorners)
        if #available(iOS 26, *) {
            #expect(view.cornerConfiguration == .corners(radius: .containerConcentric(minimum: 10)))
            view.usesConcentricCorners = false
            #expect(view.cornerConfiguration == .corners(radius: .fixed(10)))
        } else {
            #expect(view.layer.cornerRadius == 10)
        }
    }

    @Test
    func `Partly rounded corners keep their square corners on iOS 26`() {
        let view = LMKGlassView(style: LMKGlassView.Style(corners: .fixed(16, corners: .lmk_top)))
        if #available(iOS 26, *) {
            #expect(view.cornerConfiguration == .corners(topLeftRadius: .fixed(16), topRightRadius: .fixed(16), bottomLeftRadius: .fixed(0), bottomRightRadius: .fixed(0)))
        } else {
            #expect(view.layer.maskedCorners == .lmk_top)
            #expect(view.layer.cornerRadius == 16)
        }
    }

    @Test
    func `The effect is rebuilt only when its inputs change`() {
        let view = LMKGlassView(variant: .clear, tintColor: .red)
        let assignments = EffectAssignmentCounter()
        let observation = view.observe(\.effect, options: [.new]) { _, _ in assignments.increment() }
        defer { observation.invalidate() }
        view.cornerRadius = 30
        view.applyTheme(LMKTheme())
        #expect(assignments.isEmpty, "a radius or a theme pass leaves the effect alone")
        view.style.tintColor = .blue
        #expect(assignments.count == 1)
        view.variant = .regular
        #expect(assignments.count == 2)
        view.isInteractive = true
        #expect(assignments.count == 3)
    }

    @Test
    func `Capsule corners publish the capsule configuration`() {
        let view = LMKGlassView(style: LMKGlassView.Style(corners: .capsule))
        if #available(iOS 26, *) {
            #expect(view.cornerConfiguration == .capsule())
        } else {
            view.frame = CGRect(x: 0, y: 0, width: 80, height: 30)
            view.layoutIfNeeded()
            #expect(view.layer.cornerRadius == 15)
        }
    }

    @Test
    func `theme.glass supplies app-wide defaults`() {
        var theme = LMKTheme()
        theme.glass = LMKGlassView.Style(variant: .clear, corners: .fixed(3))
        let view = LMKGlassView(style: LMKGlassView.Style())
        let window = LMKThemeTesting.host(view, theme: theme)
        defer { window.isHidden = true }
        #expect(view.variant == .clear)
        #expect(view.cornerRadius == 3)
    }

    @Test
    func `makeContainer returns a typed container hosting glass views`() {
        let container = LMKGlassView.makeContainer(spacing: 12)
        let glass = LMKGlassView()
        container.contentView.addSubview(glass)
        #expect(glass.superview === container.contentView)
        #expect(container.spacing == 12)
        if #available(iOS 26, *) {
            #expect((container.effect as? UIGlassContainerEffect)?.spacing == 12)
            container.spacing = 20
            #expect((container.effect as? UIGlassContainerEffect)?.spacing == 20)
        } else {
            #expect(container.effect == nil)
        }
    }
}
