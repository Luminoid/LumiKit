//
//  LMKCardPanelControllerTests.swift
//  LumiKit
//
//  Tests for LMKCardPanelController: card view setup, embedded navigation,
//  overlay window, layout configuration, and dismissal.
//

import SnapKit
import Testing
import UIKit
@testable import LumiKitUI

// MARK: - LMKCardPanelController

@MainActor
struct LMKCardPanelControllerTests {
    // MARK: - Initialization

    @Test
    func `Root view controller is embedded in navigation controller`() {
        let rootVC = UIViewController()
        let panel = LMKCardPanelController(rootViewController: rootVC)
        panel.loadViewIfNeeded()

        #expect(panel.embeddedNavigationController.viewControllers.first === rootVC)
    }

    @Test
    func `Embedded navigation bar is hidden`() {
        let panel = LMKCardPanelController(rootViewController: UIViewController())
        panel.loadViewIfNeeded()

        #expect(panel.embeddedNavigationController.isNavigationBarHidden)
    }

    // MARK: - Card View

    @Test
    func `Card view has backgroundPrimary color`() {
        let panel = LMKCardPanelController(rootViewController: UIViewController())
        panel.loadViewIfNeeded()

        #expect(panel.cardView.backgroundColor == LMKColor.backgroundPrimary)
    }

    @Test
    func `Card view has large corner radius`() {
        let panel = LMKCardPanelController(rootViewController: UIViewController())
        panel.loadViewIfNeeded()

        #expect(panel.cardView.layer.cornerRadius == LMKCornerRadius.large)
    }

    @Test
    func `Card view has shadow applied`() {
        let panel = LMKCardPanelController(rootViewController: UIViewController())
        panel.loadViewIfNeeded()

        #expect(panel.cardView.layer.shadowOpacity > 0)
        #expect(panel.cardView.layer.shadowRadius > 0)
    }

    @Test
    func `Embedded nav view clips to bounds`() {
        let panel = LMKCardPanelController(rootViewController: UIViewController())
        panel.loadViewIfNeeded()

        #expect(panel.embeddedNavigationController.view.clipsToBounds)
    }

    @Test
    func `Embedded nav view has large corner radius`() {
        let panel = LMKCardPanelController(rootViewController: UIViewController())
        panel.loadViewIfNeeded()

        #expect(panel.embeddedNavigationController.view.layer.cornerRadius == LMKCornerRadius.large)
    }

    // MARK: - View & Touch Handling

    @Test
    func `View background is clear`() {
        let panel = LMKCardPanelController(rootViewController: UIViewController())
        panel.loadViewIfNeeded()

        #expect(panel.view.backgroundColor == .clear)
    }

    @Test
    func `Hit test returns the view itself for touches outside card — no passthrough`() {
        let panel = LMKCardPanelController(rootViewController: UIViewController())
        panel.loadViewIfNeeded()
        panel.view.frame = CGRect(x: 0, y: 0, width: 375, height: 812)
        panel.view.layoutIfNeeded()

        // Touch at the very edge of the view (outside the centered card)
        let result = panel.view.hitTest(CGPoint(x: 0, y: 0), with: nil)
        #expect(result === panel.view)
    }

    @Test
    func `Hit test returns subview for touches on card after animate-in`() {
        let panel = LMKCardPanelController(rootViewController: UIViewController())
        panel.loadViewIfNeeded()
        panel.view.frame = CGRect(x: 0, y: 0, width: 375, height: 812)
        panel.view.layoutIfNeeded()

        // Card starts at alpha 0 — animate in so hit testing works
        UIView.setAnimationsEnabled(false)
        panel.animateIn()
        UIView.setAnimationsEnabled(true)

        let cardCenter = panel.cardView.center
        let result = panel.view.hitTest(cardCenter, with: nil)
        #expect(result != nil)
    }

    // MARK: - Configuration

    @Test
    func `dismissesOnBackgroundTap defaults to true`() {
        let panel = LMKCardPanelController(rootViewController: UIViewController())
        #expect(panel.dismissesOnBackgroundTap)
    }

    @Test
    func `Subclass can disable background tap dismissal`() {
        let panel = NoDismissCardPanel(rootViewController: UIViewController())
        #expect(!panel.dismissesOnBackgroundTap)
    }

    // MARK: - Card starts hidden

    @Test
    func `Card starts with zero alpha for animate-in`() {
        let panel = LMKCardPanelController(rootViewController: UIViewController())
        panel.loadViewIfNeeded()

        #expect(panel.cardView.alpha == 0)
    }

    @Test
    func `Card starts with upward transform for animate-in`() {
        let panel = LMKCardPanelController(rootViewController: UIViewController())
        panel.loadViewIfNeeded()

        #expect(panel.cardView.transform != .identity)
        #expect(panel.cardView.transform.ty < 0)
    }

    // MARK: - Animate In

    @Test
    func `animateIn sets card alpha to 1 and identity transform`() {
        let panel = LMKCardPanelController(rootViewController: UIViewController())
        panel.loadViewIfNeeded()

        // Disable animation for instant result
        UIView.setAnimationsEnabled(false)
        panel.animateIn()
        UIView.setAnimationsEnabled(true)

        #expect(panel.cardView.alpha == 1)
        #expect(panel.cardView.transform == .identity)
    }

    // MARK: - Configuration

    @Test
    func `Default card max width matches layout constant`() {
        let panel = LMKCardPanelController(rootViewController: UIViewController())
        #expect(panel.cardMaxWidth == LMKCardPanelLayout.cardMaxWidth)
    }

    @Test
    func `Default card horizontal inset matches layout constant`() {
        let panel = LMKCardPanelController(rootViewController: UIViewController())
        #expect(panel.cardHorizontalInset == LMKCardPanelLayout.cardHorizontalInset)
    }

    @Test
    func `Default card max height ratio matches layout constant`() {
        let panel = LMKCardPanelController(rootViewController: UIViewController())
        #expect(panel.cardMaxHeightRatio == LMKCardPanelLayout.cardMaxHeightRatio)
    }

    @Test
    func `Custom subclass can override card max width`() {
        let panel = WideCardPanel(rootViewController: UIViewController())
        #expect(panel.cardMaxWidth == 600)
    }

    // MARK: - Works with LMKCardPageController

    @Test
    func `Card panel can host LMKCardPageController`() {
        let page = LMKCardPageController(title: "Settings")
        let panel = LMKCardPanelController(rootViewController: page)
        panel.loadViewIfNeeded()

        let rootVC = panel.embeddedNavigationController.viewControllers.first
        #expect(rootVC === page)
    }

    // MARK: - Child VC containment

    @Test
    func `Embedded nav is a child of the panel`() {
        let panel = LMKCardPanelController(rootViewController: UIViewController())
        panel.loadViewIfNeeded()

        #expect(panel.children.contains(panel.embeddedNavigationController))
    }
}

// MARK: - Test Helpers

private final class WideCardPanel: LMKCardPanelController {
    override var cardMaxWidth: CGFloat { 600 }
}

private final class NoDismissCardPanel: LMKCardPanelController {
    override var dismissesOnBackgroundTap: Bool { false }
}
