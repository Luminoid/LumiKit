//
//  LMKPointerStyleTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

// MARK: - LMKPointerStyle

@MainActor
struct LMKPointerStyleTests {
    /// A view hosted in a real window, plus the window keeping it there.
    private func makeHostedView() -> (UIWindow, UIView) {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 375, height: 812))
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 44))
        window.addSubview(view)
        window.makeKeyAndVisible()
        return (window, view)
    }

    // MARK: - preview(for:)

    @Test
    func `preview is nil for a nil view`() {
        #expect(LMKPointerStyle.preview(for: nil) == nil)
    }

    @Test
    func `preview is nil for a view with no window`() {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 44))
        #expect(LMKPointerStyle.preview(for: view) == nil)
    }

    @Test
    func `preview is nil for a view whose superview has no window`() {
        // A recycled cell keeps a superview (reuse pool, detached container) after its
        // window is gone, which is why `superview` is not a usable substitute for `window`.
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 375, height: 812))
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 44))
        container.addSubview(view)
        #expect(view.superview != nil)
        #expect(LMKPointerStyle.preview(for: view) == nil)
    }

    @Test
    func `preview targets a view in a window`() {
        let (window, view) = makeHostedView()
        defer { window.isHidden = true }
        let preview = LMKPointerStyle.preview(for: view)
        #expect(preview != nil)
        #expect(preview?.view === view)
    }

    @Test
    func `preview is nil after the view is removed from the window`() {
        let (window, view) = makeHostedView()
        defer { window.isHidden = true }
        #expect(LMKPointerStyle.preview(for: view) != nil)
        view.removeFromSuperview()
        #expect(LMKPointerStyle.preview(for: view) == nil)
    }

    // MARK: - Effect factories

    @Test
    func `every factory is nil for a nil view`() {
        #expect(LMKPointerStyle.automatic(for: nil) == nil)
        #expect(LMKPointerStyle.highlight(for: nil) == nil)
        #expect(LMKPointerStyle.lift(for: nil) == nil)
        #expect(LMKPointerStyle.hover(for: nil) == nil)
    }

    @Test
    func `every factory is nil for a view with no window`() {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 44))
        #expect(LMKPointerStyle.automatic(for: view) == nil)
        #expect(LMKPointerStyle.highlight(for: view) == nil)
        #expect(LMKPointerStyle.lift(for: view) == nil)
        #expect(LMKPointerStyle.hover(for: view) == nil)
    }

    @Test
    func `every factory returns a style for a view in a window`() {
        let (window, view) = makeHostedView()
        defer { window.isHidden = true }
        #expect(LMKPointerStyle.automatic(for: view) != nil)
        #expect(LMKPointerStyle.highlight(for: view) != nil)
        #expect(LMKPointerStyle.lift(for: view) != nil)
        #expect(LMKPointerStyle.hover(for: view) != nil)
    }

    @Test
    func `hover accepts custom effect parameters`() {
        let (window, view) = makeHostedView()
        defer { window.isHidden = true }
        let style = LMKPointerStyle.hover(
            for: view,
            preferredTintMode: .none,
            prefersShadow: true,
            prefersScaledContent: false
        )
        #expect(style != nil)
    }

    @Test
    func `hover is nil for a windowless view even with custom parameters`() {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 44))
        let style = LMKPointerStyle.hover(
            for: view,
            preferredTintMode: .underlay,
            prefersShadow: true,
            prefersScaledContent: false
        )
        #expect(style == nil)
    }

    // MARK: - Delegate usage

    @Test
    func `a delegate passing interaction view is safe once the view leaves the window`() {
        let (window, view) = makeHostedView()
        defer { window.isHidden = true }
        let interaction = UIPointerInteraction(delegate: nil)
        view.addInteraction(interaction)

        #expect(LMKPointerStyle.lift(for: interaction.view) != nil)

        // The interaction stays attached to the view after it leaves the hierarchy —
        // exactly the state that made the raw initializer abort.
        view.removeFromSuperview()
        #expect(interaction.view != nil)
        #expect(LMKPointerStyle.lift(for: interaction.view) == nil)
    }
}
