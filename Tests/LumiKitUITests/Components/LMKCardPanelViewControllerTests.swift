//
//  LMKCardPanelViewControllerTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

@Suite(.serialized)
@MainActor
struct LMKCardPanelViewControllerTests {
    private func makeHost() -> (UIViewController, UIWindow) {
        let host = UIViewController()
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 375, height: 812))
        window.rootViewController = host
        window.makeKeyAndVisible()
        return (host, window)
    }

    private func overlayWindow(for panel: LMKCardPanelViewController, in window: UIWindow) -> LMKCardPanelOverlayWindow? {
        window.windowScene?.windows.compactMap { $0 as? LMKCardPanelOverlayWindow }.first { $0.rootViewController === panel }
    }

    @Test
    func `Embeds the root in a bar-less navigation controller and forwards the status bar`() {
        let root = UIViewController()
        let panel = LMKCardPanelViewController(rootViewController: root)
        #expect(panel.embeddedNavigationController.viewControllers.first === root)
        #expect(panel.embeddedNavigationController.isNavigationBarHidden)
        #expect(panel.childForStatusBarStyle === panel.embeddedNavigationController)
        #expect(panel.modalPresentationCapturesStatusBarAppearance)
        #expect(panel.dismissesOnBackgroundTap)
        #expect(panel.presentation == .overlayWindow)
        #expect(!panel.isPresented)
        panel.loadViewIfNeeded()
        #expect(panel.embeddedNavigationController.view.superview === panel.cardView)
        #expect(panel.embeddedNavigationController.interactivePopGestureRecognizer?.isEnabled == false)
        #expect(panel.cardView.backgroundColor === LMKColor.backgroundPrimary)
        #expect(panel.cardView.layer.cornerRadius == LMKCornerRadius.large)
        #expect(panel.cardView.layer.shadowOpacity > 0)
        #expect(panel.cardView.alpha == 0, "hidden until animated in")
        #expect(panel.cardView.transform.ty == -20, "resting above its place by the default slide offset")
        #expect(panel.view.accessibilityViewIsModal)
    }

    @Test
    func `Overlay presentation makes a window, dims, restores the key window, and releases on dismiss`() async {
        let (host, window) = makeHost()
        defer { window.isHidden = true }
        let panel = LMKCardPanelViewController(rootViewController: UIViewController())
        var dismissed = 0
        panel.onDismiss = { dismissed += 1 }
        panel.present(from: host)
        #expect(panel.isPresented)
        let overlay = overlayWindow(for: panel, in: window)
        #expect(overlay != nil)
        #expect(overlay?.isKeyWindow == true)
        #expect(overlay?.passthroughEnabled == false)
        #expect(overlay?.windowLevel == .normal + 1)
        await LMKWait.until { panel.cardView.alpha == 1 }
        #expect(panel.cardView.alpha == 1)
        #expect(panel.view.backgroundColor != UIColor.clear)

        panel.dismiss()
        panel.dismiss()
        await LMKWait.until { !panel.isPresented }
        #expect(!panel.isPresented)
        #expect(dismissed == 1, "a second dismiss during the slide-out is ignored")
        #expect(overlay?.isHidden == true)
        #expect(overlay?.rootViewController == nil)
        #expect(window.isKeyWindow)

        panel.present(from: host)
        #expect(panel.isPresented, "a dismissed panel presents again")
        panel.dismiss()
        await LMKWait.until { !panel.isPresented }
        #expect(dismissed == 2)
    }

    @Test
    func `dismissesOnBackgroundTap false passes touches through and skips the dimming`() async {
        let (host, window) = makeHost()
        defer { window.isHidden = true }
        let panel = LMKCardPanelViewController(rootViewController: UIViewController())
        panel.dismissesOnBackgroundTap = false
        panel.present(from: host)
        let overlay = overlayWindow(for: panel, in: window)
        #expect(overlay?.passthroughEnabled == true)
        await LMKWait.until { panel.cardView.alpha == 1 }
        #expect(panel.view.backgroundColor == UIColor.clear)
        overlay?.layoutIfNeeded()
        #expect(overlay?.hitTest(CGPoint(x: 2, y: 2), with: nil) == nil, "a touch outside the card falls through")

        let alert = UIViewController()
        panel.present(alert, animated: false)
        #expect(panel.presentedViewController === alert)
        #expect(overlay?.hitTest(CGPoint(x: 2, y: 2), with: nil) != nil, "a controller presented from the panel keeps every touch")
        panel.dismiss(animated: false)
        await LMKWait.until { panel.presentedViewController == nil }
        #expect(panel.isPresented, "dismissing what the panel presented leaves the panel up")

        panel.dismissesOnBackgroundTap = true
        #expect(overlay?.passthroughEnabled == false)
        panel.dismiss()
        await LMKWait.until { !panel.isPresented }
    }

    @Test
    func `Modal presentation presents over the host and dismisses it`() async {
        let (host, window) = makeHost()
        defer { window.isHidden = true }
        let panel = LMKCardPanelViewController(rootViewController: UIViewController())
        panel.presentation = .modal
        panel.present(from: host)
        await LMKWait.until { host.presentedViewController === panel && panel.cardView.alpha == 1 }
        #expect(host.presentedViewController === panel)
        #expect(panel.modalPresentationStyle == .overFullScreen)
        #expect(overlayWindow(for: panel, in: window) == nil)
        var dismissed = 0
        panel.onDismiss = { dismissed += 1 }
        panel.dismiss()
        // UIKit does not process a modal dismissal inside the test host, so the panel's own
        // state is the observable outcome here.
        await LMKWait.until { !panel.isPresented }
        #expect(!panel.isPresented)
        #expect(dismissed == 1)
    }

    @Test
    func `A UIKit dismissal of the modal ends in the panel's own state`() async {
        let (host, window) = makeHost()
        defer { window.isHidden = true }
        let panel = LMKCardPanelViewController(rootViewController: UIViewController())
        panel.presentation = .modal
        var dismissed = 0
        panel.onDismiss = { dismissed += 1 }
        panel.present(from: host)
        await LMKWait.until { host.presentedViewController === panel && panel.cardView.alpha == 1 }

        // A page closing its panel through UIKit: the panel's own teardown runs.
        panel.dismiss(animated: true)
        await LMKWait.until { !panel.isPresented }
        #expect(!panel.isPresented)
        #expect(dismissed == 1)
        panel.dismiss(animated: true)
        #expect(dismissed == 1, "nothing left to dismiss")
    }

    @Test
    func `A host that cannot present leaves the panel unpresented`() async {
        let (host, window) = makeHost()
        defer { window.isHidden = true }
        let other = UIViewController()
        host.present(other, animated: false)
        await LMKWait.until { host.presentedViewController === other }
        let panel = LMKCardPanelViewController(rootViewController: UIViewController())
        panel.presentation = .modal
        panel.present(from: host)
        #expect(!panel.isPresented, "a refused presentation does not leave isPresented stuck")
        host.dismiss(animated: false)
    }

    @Test
    func `Pages reach the panel and the root page's back item dismisses it`() async {
        let (host, window) = makeHost()
        defer { window.isHidden = true }
        let page = LMKCardPageViewController(title: "Root")
        let panel = LMKCardPanelViewController(rootViewController: page)
        #expect(page.lmk_cardPanel === panel)
        #expect(panel.embeddedNavigationController.lmk_cardPanel === panel)
        #expect(UIViewController().lmk_cardPanel == nil)
        panel.present(from: host)
        await LMKWait.until { panel.cardView.alpha == 1 }
        page.leadingButton.didTap()
        await LMKWait.until { !panel.isPresented }
        #expect(!panel.isPresented)
    }

    @Test
    func `The panel is a VoiceOver modal with an escape and key commands`() async {
        let (host, window) = makeHost()
        defer { window.isHidden = true }
        let panel = LMKCardPanelViewController(rootViewController: UIViewController())
        #expect(!panel.accessibilityPerformEscape(), "nothing to escape while not presented")
        let inputs = panel.keyCommands?.map(\.input) ?? []
        #expect(inputs.contains(UIKeyCommand.inputEscape))
        #expect(inputs.contains("w"))
        #expect(panel.keyCommands?.first { $0.input == "w" }?.modifierFlags == .command)
        #expect(panel.canBecomeFirstResponder)
        panel.present(from: host)
        await LMKWait.until { panel.cardView.alpha == 1 }
        #expect(panel.accessibilityPerformEscape())
        await LMKWait.until { !panel.isPresented }
        #expect(!panel.isPresented)
    }

    @Test
    func `Style sizes the card and theme.cardPanel supplies defaults`() {
        let panel = LMKCardPanelViewController(rootViewController: UIViewController(), style: LMKCardPanelViewController.Style(
            surface: LMKSurfaceStyle(background: .solid(.red), shadow: LMKShadowSource.hidden),
            maxWidth: 300,
            horizontalInset: 10,
            heightRatio: 0.5,
            slideOffset: 40
        ))
        panel.view.frame = CGRect(x: 0, y: 0, width: 375, height: 800)
        panel.view.layoutIfNeeded()
        #expect(panel.cardView.backgroundColor == UIColor.red)
        #expect(panel.cardView.frame.width == 300)
        #expect(abs(panel.cardView.frame.height - 400) < 1)
        #expect(panel.cardView.layer.shadowOpacity == 0)
        #expect(panel.cardView.transform.ty == -40, "the first slide-in travels the style's offset")
        panel.style.maxWidth = 500
        panel.view.layoutIfNeeded()
        #expect(panel.cardView.frame.width == 355, "the inset wins once the cap is wider than the host")

        var theme = LMKTheme()
        theme.cardPanel = LMKCardPanelViewController.Style(surface: LMKSurfaceStyle(background: .solid(.magenta)))
        let themed = LMKCardPanelViewController(rootViewController: UIViewController())
        let window = LMKThemeTesting.host(themed.view, theme: theme)
        defer { window.isHidden = true }
        themed.applyTheme(theme)
        #expect(themed.cardView.backgroundColor == UIColor.magenta)
    }

    @Test
    func `applyContentTheme runs on every apply, before didApplyStyle`() {
        final class Panel: LMKCardPanelViewController {
            var calls: [String] = []
            override func applyContentTheme(_ theme: LMKTheme) {
                calls.append("content")
            }
        }
        let panel = Panel(rootViewController: UIViewController())
        panel.didApplyStyle = { ($0 as? Panel)?.calls.append("style") }
        panel.loadViewIfNeeded()
        #expect(panel.calls == ["content", "style"])
        panel.style.maxWidth = 100
        #expect(panel.calls == ["content", "style", "content", "style"])
    }
}
