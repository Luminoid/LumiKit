//
//  LMKCardPanelControllerTests.swift
//  LumiKit
//
//  Tests for LMKCardPanelController: card view setup, embedded navigation,
//  passthrough touches, layout configuration, and dismissal.
//

import SnapKit
import Testing
import UIKit

@testable import LumiKitUI

// MARK: - LMKCardPanelController

@Suite("LMKCardPanelController")
@MainActor
struct LMKCardPanelControllerTests {
    // MARK: - Initialization

    @Test("Root view controller is embedded in navigation controller")
    func rootVCEmbedded() {
        let rootVC = UIViewController()
        let panel = LMKCardPanelController(rootViewController: rootVC)
        panel.loadViewIfNeeded()

        #expect(panel.embeddedNavigationController.viewControllers.first === rootVC)
    }

    @Test("Embedded navigation bar is hidden")
    func navBarHidden() {
        let panel = LMKCardPanelController(rootViewController: UIViewController())
        panel.loadViewIfNeeded()

        #expect(panel.embeddedNavigationController.isNavigationBarHidden)
    }

    // MARK: - Card View

    @Test("Card view has backgroundPrimary color")
    func cardViewBackground() {
        let panel = LMKCardPanelController(rootViewController: UIViewController())
        panel.loadViewIfNeeded()

        #expect(panel.cardView.backgroundColor == LMKColor.backgroundPrimary)
    }

    @Test("Card view has large corner radius")
    func cardViewCornerRadius() {
        let panel = LMKCardPanelController(rootViewController: UIViewController())
        panel.loadViewIfNeeded()

        #expect(panel.cardView.layer.cornerRadius == LMKCornerRadius.large)
    }

    @Test("Card view has shadow applied")
    func cardViewShadow() {
        let panel = LMKCardPanelController(rootViewController: UIViewController())
        panel.loadViewIfNeeded()

        #expect(panel.cardView.layer.shadowOpacity > 0)
        #expect(panel.cardView.layer.shadowRadius > 0)
    }

    @Test("Embedded nav view clips to bounds")
    func embeddedNavClipsToBounds() {
        let panel = LMKCardPanelController(rootViewController: UIViewController())
        panel.loadViewIfNeeded()

        #expect(panel.embeddedNavigationController.view.clipsToBounds)
    }

    @Test("Embedded nav view has large corner radius")
    func embeddedNavCornerRadius() {
        let panel = LMKCardPanelController(rootViewController: UIViewController())
        panel.loadViewIfNeeded()

        #expect(panel.embeddedNavigationController.view.layer.cornerRadius == LMKCornerRadius.large)
    }

    // MARK: - Passthrough View

    @Test("View background is clear")
    func viewBackgroundClear() {
        let panel = LMKCardPanelController(rootViewController: UIViewController())
        panel.loadViewIfNeeded()

        #expect(panel.view.backgroundColor == .clear)
    }

    @Test("Hit test returns nil for touches outside card")
    func passthroughOutsideCard() {
        let panel = LMKCardPanelController(rootViewController: UIViewController())
        panel.loadViewIfNeeded()
        panel.view.frame = CGRect(x: 0, y: 0, width: 375, height: 812)
        panel.view.layoutIfNeeded()

        // Touch at the very edge of the view (outside the centered card)
        let result = panel.view.hitTest(CGPoint(x: 0, y: 0), with: nil)
        #expect(result == nil)
    }

    @Test("Hit test returns subview for touches on card after animate-in")
    func passthroughOnCard() {
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

    // MARK: - Card starts hidden

    @Test("Card starts with zero alpha for animate-in")
    func cardStartsHidden() {
        let panel = LMKCardPanelController(rootViewController: UIViewController())
        panel.loadViewIfNeeded()

        #expect(panel.cardView.alpha == 0)
    }

    @Test("Card starts with upward transform for animate-in")
    func cardStartsTransformed() {
        let panel = LMKCardPanelController(rootViewController: UIViewController())
        panel.loadViewIfNeeded()

        #expect(panel.cardView.transform != .identity)
        #expect(panel.cardView.transform.ty < 0)
    }

    // MARK: - Animate In

    @Test("animateIn sets card alpha to 1 and identity transform")
    func animateInSetsVisible() {
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

    @Test("Default card max width matches layout constant")
    func defaultCardMaxWidth() {
        let panel = LMKCardPanelController(rootViewController: UIViewController())
        #expect(panel.cardMaxWidth == LMKCardPanelLayout.cardMaxWidth)
    }

    @Test("Default card horizontal inset matches layout constant")
    func defaultCardHorizontalInset() {
        let panel = LMKCardPanelController(rootViewController: UIViewController())
        #expect(panel.cardHorizontalInset == LMKCardPanelLayout.cardHorizontalInset)
    }

    @Test("Default card max height ratio matches layout constant")
    func defaultCardMaxHeightRatio() {
        let panel = LMKCardPanelController(rootViewController: UIViewController())
        #expect(panel.cardMaxHeightRatio == LMKCardPanelLayout.cardMaxHeightRatio)
    }

    @Test("Custom subclass can override card max width")
    func customCardMaxWidth() {
        let panel = WideCardPanel(rootViewController: UIViewController())
        #expect(panel.cardMaxWidth == 600)
    }

    // MARK: - Works with LMKCardPageController

    @Test("Card panel can host LMKCardPageController")
    func hostsCardPage() {
        let page = LMKCardPageController(title: "Settings")
        let panel = LMKCardPanelController(rootViewController: page)
        panel.loadViewIfNeeded()

        let rootVC = panel.embeddedNavigationController.viewControllers.first
        #expect(rootVC === page)
    }

    // MARK: - Child VC containment

    @Test("Embedded nav is a child of the panel")
    func embeddedNavIsChild() {
        let panel = LMKCardPanelController(rootViewController: UIViewController())
        panel.loadViewIfNeeded()

        #expect(panel.children.contains(panel.embeddedNavigationController))
    }
}

// MARK: - Test Helpers

private final class WideCardPanel: LMKCardPanelController {
    override var cardMaxWidth: CGFloat { 600 }
}
