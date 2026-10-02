//
//  LMKCardPageViewControllerTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

@MainActor
struct LMKCardPageViewControllerTests {
    private final class TestPage: LMKCardPageViewController {
        var setupContentCalled = false
        var leadingTaps = 0
        var themeCalls: [String] = []

        override func setupContent() {
            setupContentCalled = true
        }

        override func leadingButtonTapped() {
            leadingTaps += 1
        }

        override func applyContentTheme(_ theme: LMKTheme) {
            themeCalls.append("content")
        }
    }

    private func layout(_ page: LMKCardPageViewController, width: CGFloat = 375) {
        page.view.frame = CGRect(x: 0, y: 0, width: width, height: 600)
        page.view.layoutIfNeeded()
    }

    @Test
    func `Default header: back chevron, no trailing item, no separator, title`() {
        let page = TestPage(title: "Details")
        page.loadViewIfNeeded()
        #expect(page.setupContentCalled)
        #expect(page.headerTitleLabel.text == "Details")
        #expect(page.headerTitleLabel.accessibilityTraits.contains(.header))
        #expect(!page.leadingButton.isHidden)
        #expect(page.leadingButton.image != nil)
        #expect(page.leadingButton.accessibilityLabel == "Back")
        #expect(page.trailingButton.isHidden)
        #expect(page.headerSeparator.isHidden)
        #expect(page.headerView.backgroundColor === LMKColor.backgroundPrimary)
        #expect(page.leadingButton.style.tintColor === LMKColor.secondary)
        #expect(!page.canPopContent)
        layout(page)
        #expect(page.headerView.frame.height == 52)
        #expect(page.leadingButton.frame.size == CGSize(width: 32, height: 32))
        #expect(page.leadingButton.frame.minX == LMKSpacing.large)
        #expect(page.leadingButton.point(inside: CGPoint(x: -5, y: -5), with: nil), "the hit target stays 44pt")
    }

    @Test
    func `A page that fills the screen keeps its header content inside the safe area`() {
        let page = TestPage(title: "History")
        page.trailingItem = LMKNavigationBarItem(systemName: "trash")
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 375, height: 600))
        window.rootViewController = page
        window.makeKeyAndVisible()
        defer { window.isHidden = true }
        // The status bar or the Mac title bar strip on top, the sensor housing at the sides.
        page.additionalSafeAreaInsets = UIEdgeInsets(top: 30, left: 40, bottom: 0, right: 20)
        page.view.setNeedsLayout()
        page.view.layoutIfNeeded()
        let insets = page.view.safeAreaInsets
        #expect(page.headerView.frame.minY == 0, "the surface stays full-bleed")
        #expect(page.headerView.frame.height == insets.top + 52)
        #expect(page.headerTitleLabel.frame.midY == insets.top + 26)
        #expect(page.leadingButton.frame.minX == insets.left + LMKSpacing.large)
        #expect(page.trailingButton.frame.maxX == 375 - insets.right - LMKSpacing.large)
    }

    @Test
    func `In a stack whose bar shows, the page hands its title and items to that bar`() throws {
        let page = TestPage(title: "History")
        var clears = 0
        page.trailingItem = LMKNavigationBarItem(identifier: "clear", systemName: "trash") { clears += 1 }
        let navigation = UINavigationController(rootViewController: UIViewController())
        navigation.pushViewController(page, animated: false)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 375, height: 600))
        window.rootViewController = navigation
        window.makeKeyAndVisible()
        defer { window.isHidden = true }
        navigation.view.layoutIfNeeded()

        #expect(page.usesSystemNavigationBar)
        #expect(page.headerView.isHidden)
        #expect(page.navigationItem.title == "History")
        #expect(page.navigationItem.leftBarButtonItems == nil, "the default back item is the bar's own back button")
        #expect(!page.navigationItem.hidesBackButton)
        let clear = try #require(page.navigationItem.rightBarButtonItems?.first)
        #expect(clear.accessibilityIdentifier == "clear")
        clear.primaryAction?.performWithSender(nil, target: nil)
        #expect(clears == 1)
        let content = try #require(page.contentContainerView.superview)
        #expect(content.frame.minY == page.view.safeAreaInsets.top, "the content starts under the bar")
    }

    @Test
    func `Under the system bar, stacked content takes the back position and a hidden bar brings the header back`() throws {
        let page = TestPage(title: "Root")
        let navigation = UINavigationController(rootViewController: UIViewController())
        navigation.pushViewController(page, animated: false)
        page.loadViewIfNeeded()
        page.updateHeaderPlacement()

        page.pushContentView(UIView(), title: "Child", animated: false)
        #expect(page.navigationItem.title == "Child")
        #expect(page.navigationItem.hidesBackButton, "the bar's back button would pop the whole page")
        let back = try #require(page.navigationItem.leftBarButtonItems?.first)
        #expect(back.accessibilityLabel == "Back")
        back.primaryAction?.performWithSender(nil, target: nil)
        #expect(!page.canPopContent)
        #expect(page.navigationItem.title == "Root")
        #expect(!page.navigationItem.hidesBackButton)
        #expect(page.navigationItem.leftBarButtonItems == nil)

        page.leadingItem = .init(title: "Edit") {}
        #expect(page.navigationItem.leftBarButtonItems?.first?.title == "Edit", "an item with an action keeps it")
        #expect(page.navigationItem.leftItemsSupplementBackButton)

        navigation.setNavigationBarHidden(true, animated: false)
        page.updateHeaderPlacement()
        #expect(!page.usesSystemNavigationBar)
        #expect(!page.headerView.isHidden)
        #expect(page.navigationItem.leftBarButtonItems == nil, "the header takes the items back")
        #expect(page.leadingButton.title == "Edit")
    }

    @Test
    func `Items configure the buttons and their actions`() {
        let page = TestPage(title: "T")
        var trailingTaps = 0
        page.trailingItem = .init(identifier: "close", systemName: "xmark", accessibilityLabel: "Close") { trailingTaps += 1 }
        page.loadViewIfNeeded()
        #expect(!page.trailingButton.isHidden)
        #expect(page.trailingButton.accessibilityLabel == "Close")
        #expect(page.trailingButton.accessibilityIdentifier == "close")
        page.trailingButton.didTap()
        #expect(trailingTaps == 1)

        page.leadingButton.didTap()
        #expect(page.leadingTaps == 1, "an item without an action calls leadingButtonTapped()")
        var leadingActions = 0
        page.leadingItem = .init(title: "Cancel") { leadingActions += 1 }
        #expect(page.leadingButton.title == "Cancel")
        page.leadingButton.didTap()
        #expect(leadingActions == 1)
        #expect(page.leadingTaps == 1)

        page.leadingItem = nil
        #expect(page.leadingButton.isHidden)
        page.trailingItem = nil
        #expect(page.trailingButton.isHidden)
    }

    @Test
    func `A titled item takes the width of its text in a capsule, and roles and badges render`() throws {
        let page = TestPage(title: "T")
        page.leadingItem = .init(title: "Cancel")
        page.trailingItem = .init(title: "Save", role: .prominent, badge: .count(3))
        page.loadViewIfNeeded()
        layout(page)
        let fittingWidth = page.leadingButton.intrinsicContentSize.width
        #expect(fittingWidth > 32)
        #expect(page.leadingButton.frame.width >= fittingWidth - 0.5, "the title is not truncated into a 32pt square")
        #expect(page.leadingButton.frame.height == 32)
        #expect(page.leadingButton.style.surface.corners == .capsule)
        #expect(page.leadingButton.style.variant == .ghost)
        #expect(page.trailingButton.style.variant == .filled, "prominent fills the capsule")
        let badge = try #require(page.headerView.subviews.compactMap { $0 as? LMKBadgeView }.first)
        #expect(badge.accessibilityLabel == "3")
        #expect(abs(badge.center.x - (page.trailingButton.frame.maxX - LMKSpacing.xs)) < 0.5)

        page.trailingItem = .init(systemName: "trash", role: .destructive)
        #expect(page.trailingButton.style.role == .destructive)
        #expect(page.trailingButton.style.tintColor === LMKColor.error)
        #expect(page.trailingButton.style.surface.corners == .circle, "a glyph keeps the circle")
        #expect(page.headerView.subviews.contains { $0 is LMKBadgeView } == false, "the badge goes with its item")
        layout(page)
        #expect(page.trailingButton.frame.size == CGSize(width: 32, height: 32))
    }

    @Test
    func `Push shows the back button and swaps the title; pop restores both`() async {
        let page = TestPage(title: "Root")
        page.leadingItem = nil
        page.loadViewIfNeeded()
        layout(page)
        #expect(page.leadingButton.isHidden)

        let detail = UIView()
        page.pushContentView(detail, title: "Detail", animated: false)
        #expect(page.canPopContent)
        #expect(!page.leadingButton.isHidden)
        #expect(page.title == "Detail")
        #expect(page.headerTitleLabel.text == "Detail")
        #expect(detail.superview != nil)
        #expect(page.contentContainerView.superview == nil)

        page.leadingButton.didTap()
        #expect(!page.canPopContent, "the leading button pops while content is stacked")
        #expect(page.leadingTaps == 0)
        await LMKWait.until { detail.superview == nil }
        #expect(page.title == "Root")
        #expect(page.headerTitleLabel.text == "Root")
        #expect(page.leadingButton.isHidden)
        #expect(page.contentContainerView.superview != nil)
        #expect(detail.superview == nil)

        page.popContentView(animated: false)
        #expect(!page.canPopContent, "popping at the root is a no-op")
    }

    @Test
    func `Stacked content shows the back chevron whatever the leading item says`() async {
        let page = TestPage(title: "Root")
        page.leadingItem = .init(systemName: "xmark", accessibilityLabel: "Close", isEnabled: false, menu: UIMenu(children: [UIAction(title: "A") { _ in }]))
        page.loadViewIfNeeded()
        layout(page)
        #expect(page.leadingButton.accessibilityLabel == "Close")
        #expect(!page.leadingButton.isEnabled)
        #expect(page.leadingButton.menu != nil)

        let detail = UIView()
        page.pushContentView(detail, animated: false)
        #expect(page.leadingButton.accessibilityLabel == "Back")
        #expect(page.leadingButton.image == UIImage(systemName: "chevron.backward"))
        #expect(page.leadingButton.isEnabled, "a disabled item must not block the pop")
        #expect(page.leadingButton.menu == nil, "a menu-only item must not open its menu instead of popping")
        #expect(!page.leadingButton.showsMenuAsPrimaryAction)

        page.leadingButton.didTap()
        await LMKWait.until { detail.superview == nil }
        #expect(page.leadingButton.accessibilityLabel == "Close")
        #expect(!page.leadingButton.isEnabled)
        #expect(page.leadingButton.menu != nil)
    }

    @Test
    func `An animated push and pop in a window leaves the content visible`() async {
        let page = TestPage(title: "Root")
        let window = LMKThemeTesting.host(page.view)
        defer { window.isHidden = true }
        page.view.frame = window.bounds
        window.layoutIfNeeded()
        let detail = UIView()
        page.pushContentView(detail, title: "Detail", animated: true)
        await LMKWait.until { page.contentContainerView.superview == nil }
        #expect(detail.superview != nil)

        page.popContentView(animated: true)
        await LMKWait.until { detail.superview == nil && page.contentContainerView.superview != nil }
        #expect(page.contentContainerView.alpha == 1, "the root slid out faded; it comes back whole")
        #expect(page.contentContainerView.transform == .identity)
        #expect(detail.alpha == 1, "a popped view the host keeps is handed back whole")
        #expect(detail.transform == .identity)

        page.pushContentView(detail, title: "Detail", animated: true)
        await LMKWait.until { page.contentContainerView.superview == nil }
        #expect(detail.alpha == 1, "a view pushed a second time is visible")
        #expect(detail.transform == .identity)
    }

    @Test
    func `title set after load updates the header`() {
        let page = TestPage(title: "Before")
        page.loadViewIfNeeded()
        page.title = "After"
        #expect(page.headerTitleLabel.text == "After")
    }

    @Test
    func `Style controls the header, separator, buttons, and background`() {
        let page = TestPage(title: "T", style: LMKCardPageViewController.Style(
            header: LMKSurfaceStyle(background: .solid(.red)),
            backgroundColor: .yellow,
            headerHeight: 60,
            titleColor: .purple,
            buttonSize: 40,
            buttonTint: .blue,
            showsHeaderSeparator: true,
            separatorColor: .green,
            separatorThickness: 2
        ))
        page.loadViewIfNeeded()
        layout(page)
        #expect(page.headerView.backgroundColor == UIColor.red)
        #expect(page.view.backgroundColor == UIColor.yellow)
        #expect(page.headerView.frame.height == 60)
        #expect(page.headerTitleLabel.textColor == UIColor.purple)
        #expect(page.leadingButton.style.tintColor == UIColor.blue)
        #expect(page.leadingButton.frame.width == 40)
        #expect(!page.headerSeparator.isHidden)
        #expect(page.headerSeparator.backgroundColor == UIColor.green)
        #expect(page.headerSeparator.frame.height == 2)

        page.style.showsHeaderSeparator = false
        #expect(page.headerSeparator.isHidden)
    }

    @Test
    func `The drag indicator is off by default and takes its own band when on`() {
        let plain = TestPage(title: "Details")
        plain.loadViewIfNeeded()
        layout(plain)
        #expect(plain.dragIndicator.isHidden)
        #expect(plain.headerView.frame.height == 52)
        #expect(abs(plain.headerTitleLabel.frame.midY - 26) < 0.5)

        let page = TestPage(title: "Details", style: LMKCardPageViewController.Style(showsDragIndicator: true))
        page.loadViewIfNeeded()
        layout(page)
        #expect(!page.dragIndicator.isHidden)
        #expect(page.dragIndicator.superview === page.headerView)
        #expect(page.dragIndicator.frame.size == CGSize(width: 40, height: 5))
        #expect(page.dragIndicator.frame.minY == 8)
        #expect(abs(page.dragIndicator.frame.midX - 187.5) < 0.5)
        #expect(page.dragIndicator.backgroundColor === LMKColor.divider)
        #expect(!page.dragIndicator.isUserInteractionEnabled, "the sheet's own pan takes the drag")
        // The band (8 + 5) sits over the header's 52: the title and buttons keep their room.
        #expect(page.headerView.frame.height == 65)
        #expect(abs(page.headerTitleLabel.frame.midY - (13 + 26)) < 0.5)
        #expect(abs(page.leadingButton.frame.midY - (13 + 26)) < 0.5)
        #expect(page.headerTitleLabel.frame.minY >= page.dragIndicator.frame.maxY)

        page.style.showsDragIndicator = false
        layout(page)
        #expect(page.dragIndicator.isHidden)
        #expect(page.headerView.frame.height == 52)
    }

    @Test
    func `The drag indicator takes its size and color from the style and the theme`() {
        let page = TestPage(title: "T", style: LMKCardPageViewController.Style(showsDragIndicator: true, dragIndicatorSize: CGSize(width: 60, height: 4), dragIndicatorColor: .red))
        page.loadViewIfNeeded()
        layout(page)
        #expect(page.dragIndicator.frame.size == CGSize(width: 60, height: 4))
        #expect(page.dragIndicator.backgroundColor == UIColor.red)
        #expect(page.headerView.frame.height == 64, "52 plus the band: 8 over the indicator and its 4")

        let merged = LMKCardPageViewController.Style(showsDragIndicator: true).merging(LMKCardPageViewController.Style(dragIndicatorColor: .blue))
        #expect(merged.showsDragIndicator == true)
        #expect(merged.dragIndicatorColor == UIColor.blue)
    }

    @Test
    func `theme.cardPage supplies app-wide defaults and Dynamic Type raises the header floor`() {
        var theme = LMKTheme()
        theme.cardPage = LMKCardPageViewController.Style(titleColor: .magenta)
        let page = TestPage(title: "T")
        let window = LMKThemeTesting.host(page.view, theme: theme)
        defer { window.isHidden = true }
        page.applyTheme(theme)
        #expect(page.headerTitleLabel.textColor == UIColor.magenta)

        window.traitOverrides.preferredContentSizeCategory = .accessibilityExtraExtraExtraLarge
        page.view.updateTraitsIfNeeded()
        page.applyTheme(page.traitCollection.lmkTheme)
        window.layoutIfNeeded()
        #expect(page.headerTitleLabel.font.pointSize > 17)
    }

    @Test
    func `Header spacing follows the theme carried by the traits`() {
        let page = TestPage(title: "T", style: LMKCardPageViewController.Style(showsDragIndicator: true))
        let window = LMKThemeTesting.host(page.view, theme: LMKThemeTesting.distinct)
        defer { window.isHidden = true }
        page.view.frame = window.bounds
        window.layoutIfNeeded()
        let spacing = LMKThemeTesting.distinct.spacing
        // The page fills the window, so the header's content starts below the top safe area.
        let safeTop = page.view.safeAreaInsets.top
        #expect(page.leadingButton.frame.minX == spacing.large)
        #expect(page.dragIndicator.frame.minY == safeTop + spacing.small)
        #expect(page.headerView.frame.height == safeTop + 52 + spacing.small + 5)
    }

    @Test
    func `applyContentTheme runs on every apply, before didApplyStyle`() {
        let page = TestPage(title: "T")
        page.didApplyStyle = { page in (page as? TestPage)?.themeCalls.append("style") }
        page.loadViewIfNeeded()
        #expect(page.themeCalls == ["content", "style"])
        page.style.showsHeaderSeparator = true
        #expect(page.themeCalls == ["content", "style", "content", "style"])
    }
}
