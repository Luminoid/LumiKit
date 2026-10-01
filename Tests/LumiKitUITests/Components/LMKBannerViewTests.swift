//
//  LMKBannerViewTests.swift
//  LumiKit
//

import SnapKit
import Testing
import UIKit
@testable import LumiKitUI

// MARK: - LMKBannerView

@MainActor
struct LMKBannerViewTests {
    @Test
    func `Banner tints an opaque background with the status color`() throws {
        let banner = LMKBannerView(status: .warning, message: "Test")
        let traits = banner.traitCollection
        let expected = LMKColor.warning.lmk_composited(over: LMKColor.backgroundPrimary, alpha: LMKTheme.current.alpha.xs)
        let background = try #require(banner.backgroundColor?.resolvedColor(with: traits))
        #expect(background.lmk_hexString == expected.resolvedColor(with: traits).lmk_hexString)
        #expect(background.cgColor.alpha == 1, "content under a floating banner must not show through")
        #expect(banner.layer.cornerRadius == LMKCornerRadius.medium)
        #expect(banner.layer.borderWidth > 0)
        #expect(banner.iconView.tintColor === LMKColor.warning)
        #expect(banner.messageLabel.text == "Test")
    }

    @Test
    func `The dismiss glyph is small and the banner is one touch target tall`() {
        let banner = LMKBannerView(status: .info, message: "Saved")
        LMKThemeTesting.fit(banner, width: 320)
        #expect(banner.bounds.height == LMKLayout.minimumTouchTarget)
        #expect(banner.dismissButton.bounds.width < 28)
        #expect(banner.dismissButton.point(inside: CGPoint(x: -4, y: banner.dismissButton.bounds.midY), with: nil), "the hit target stays 44pt")
        let dismissMaxX = banner.convert(banner.dismissButton.bounds, from: banner.dismissButton).maxX
        #expect(abs(dismissMaxX - (320 - LMKSpacing.small)) < 0.5)
    }

    @Test
    func `Action title shows and hides the button`() {
        let banner = LMKBannerView(status: .info, message: "Test")
        #expect(banner.actionButton.isHidden)
        banner.actionTitle = "Retry"
        #expect(!banner.actionButton.isHidden)
        #expect(banner.actionButton.title == "Retry")
        var fired = 0
        banner.onAction = { fired += 1 }
        banner.actionButton.didTap()
        #expect(fired == 1)
        banner.actionTitle = nil
        #expect(banner.actionButton.isHidden)
    }

    @Test
    func `Default strings are English`() {
        let strings = LMKBannerView.Strings()
        #expect(strings.dismissAccessibilityLabel == "Dismiss")
        let banner = LMKBannerView(status: .info, message: "Test")
        #expect(banner.dismissButton.accessibilityLabel == "Dismiss")
        banner.strings = LMKBannerView.Strings(dismissAccessibilityLabel: "Cerrar")
        #expect(banner.dismissButton.accessibilityLabel == "Cerrar")
    }

    @Test
    func `Banner manages accessibility elements`() {
        let banner = LMKBannerView(status: .info, message: "Test")
        #expect(!banner.isAccessibilityElement)
        #expect(banner.accessibilityElements?.count == 2)
        banner.actionTitle = "Go"
        #expect(banner.accessibilityElements?.count == 3)
        banner.showsDismissButton = false
        #expect(banner.accessibilityElements?.count == 2)
        #expect(banner.dismissButton.isHidden)
    }

    @Test
    func `Message updates in place`() {
        let banner = LMKBannerView(status: .info, message: "One")
        banner.message = "Two"
        #expect(banner.messageLabel.text == "Two")
    }

    @Test
    func `show installs at the top and dismiss removes with onDismiss once`() async {
        let controller = UIViewController()
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        window.rootViewController = controller
        window.isHidden = false
        defer { window.isHidden = true }
        let banner = LMKBannerView(status: .error, message: "Offline")
        var dismissed = 0
        banner.onDismiss = { dismissed += 1 }
        banner.dismiss()
        #expect(dismissed == 0, "a banner that was never shown has nothing to dismiss")
        #expect(banner.alpha == 1)
        banner.show(in: controller)
        #expect(banner.superview === controller.view)
        #expect(banner.isFloating)
        #expect(banner.layer.shadowOpacity > 0, "a floating banner lifts off the content")
        banner.dismiss()
        banner.dismiss()
        await LMKWait.until { banner.superview == nil }
        #expect(banner.superview == nil)
        #expect(!banner.isFloating)
        #expect(dismissed == 1, "a second dismiss during the fade is ignored")
        #expect(banner.alpha == 1, "handed back whole")
        #expect(banner.transform == .identity)
        #expect(banner.layer.shadowOpacity == 0, "the floating shadow goes with the float")
    }

    @Test
    func `A dismissed banner shows again, floating or inline`() async {
        let controller = UIViewController()
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        window.rootViewController = controller
        window.isHidden = false
        defer { window.isHidden = true }
        let banner = LMKBannerView(status: .warning, message: "Again")
        var dismissed = 0
        banner.onDismiss = { dismissed += 1 }
        banner.show(in: controller)
        banner.dismiss()
        await LMKWait.until { banner.superview == nil }
        banner.show(in: controller)
        await LMKWait.until { banner.alpha == 1 }
        #expect(banner.superview === controller.view)
        #expect(banner.isFloating)
        #expect(banner.alpha == 1)
        controller.view.layoutIfNeeded()
        #expect(banner.frame.width == 390 - LMKSpacing.cardPadding * 2, "the placement is remade from scratch")

        // Shown again while the fade-out is still running: the stale completion must not remove it.
        banner.dismiss()
        banner.show(in: controller)
        try? await Task.sleep(for: .milliseconds(400))
        #expect(banner.superview === controller.view)
        #expect(banner.alpha == 1)
        #expect(dismissed == 1, "the abandoned dismissal never completed")

        banner.dismiss()
        await LMKWait.until { banner.superview == nil }
        let stack = UIStackView()
        stack.addArrangedSubview(banner)
        #expect(banner.alpha == 1, "inline after a float: visible")
        #expect(!banner.isFloating)
        #expect(banner.layer.shadowOpacity == 0)
    }

    @Test
    func `Floating margins and the width cap follow the style while shown`() {
        let host = UIView(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        let banner = LMKBannerView(status: .info, message: "Margins")
        banner.show(in: host, insetsScrollView: false)
        host.layoutIfNeeded()
        #expect(banner.frame.minX == LMKSpacing.cardPadding)
        #expect(banner.frame.minY == LMKSpacing.small)
        banner.style.horizontalMargin = 30
        banner.style.verticalMargin = 12
        banner.style.maxWidth = 200
        host.layoutIfNeeded()
        #expect(banner.frame.width == 200)
        #expect(abs(banner.frame.midX - 195) < 0.5)
        #expect(banner.frame.minY == 12)
        banner.style.maxWidth = 1000
        host.layoutIfNeeded()
        #expect(banner.frame.minX == 30)
        #expect(banner.frame.width == 330)
    }

    @Test
    func `A floating banner sits under the navigation bar and makes room in the scroll view`() {
        let host = UIView(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        let bar = LMKNavigationBar()
        bar.install(in: host)
        let scrollView = UIScrollView()
        scrollView.contentInsetAdjustmentBehavior = .never
        host.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.top.equalTo(bar.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
        host.layoutIfNeeded()

        let banner = LMKBannerView(status: .warning, message: "No internet connection")
        banner.show(in: host)
        host.layoutIfNeeded()
        #expect(abs(banner.frame.minY - (bar.frame.maxY + LMKSpacing.small)) < 0.5)
        #expect(banner.frame.minX == LMKSpacing.cardPadding)
        #expect(banner.frame.width == 390 - LMKSpacing.cardPadding * 2)
        let room = banner.frame.height + LMKSpacing.small * 2
        #expect(abs(scrollView.contentInset.top - room) < 1)
        #expect(scrollView.contentOffset.y == -scrollView.contentInset.top, "content resting at the top moves down with the inset")

        banner.dismiss()
        #expect(scrollView.contentInset.top == 0)
        #expect(banner.superview == nil)
    }

    @Test
    func `A second banner replaces the first and keeps one inset`() {
        let host = UIView(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        let scrollView = UIScrollView(frame: host.bounds)
        scrollView.contentInsetAdjustmentBehavior = .never
        host.addSubview(scrollView)
        let first = LMKBannerView(status: .info, message: "One")
        first.show(in: host)
        let second = LMKBannerView(status: .error, message: "Two")
        second.show(in: host)
        host.layoutIfNeeded()
        #expect(first.superview == nil)
        #expect(second.superview === host)
        #expect(abs(scrollView.contentInset.top - (second.frame.maxY + LMKSpacing.small)) < 1)
        let inset = scrollView.contentInset.top
        second.show(in: host)
        host.layoutIfNeeded()
        #expect(scrollView.contentInset.top == inset, "showing again keeps the room it already made")
    }

    @Test
    func `A wide host caps the banner at the readable width`() {
        let host = UIView(frame: CGRect(x: 0, y: 0, width: 1200, height: 800))
        let banner = LMKBannerView(status: .success, message: "Saved")
        banner.show(in: host, insetsScrollView: false)
        host.layoutIfNeeded()
        #expect(banner.frame.width == LMKLayout.readableContentMaxWidth)
        #expect(abs(banner.frame.midX - 600) < 0.5)
    }

    @Test
    func `Style overrides apply per instance and through the theme`() {
        let banner = LMKBannerView(status: .info, message: "Test")
        banner.style.surface.background = .solid(.red)
        banner.style.messageColor = .white
        #expect(banner.backgroundColor == UIColor.red)
        #expect(banner.messageLabel.textColor == UIColor.white)

        var theme = LMKTheme()
        theme.banner = LMKBannerView.Style(surface: LMKSurfaceStyle(corners: .fixed(1)))
        let themed = LMKBannerView(status: .info, message: "Test")
        let window = LMKThemeTesting.host(themed, theme: theme)
        defer { window.isHidden = true }
        #expect(themed.layer.cornerRadius == 1)
    }
}
