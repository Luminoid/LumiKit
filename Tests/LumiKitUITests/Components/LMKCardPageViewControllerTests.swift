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

        override func setupContent() {
            setupContentCalled = true
        }

        override func leadingButtonTapped() {
            leadingTaps += 1
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
        #expect(page.leadingButton.point(inside: CGPoint(x: -5, y: -5), with: nil), "the hit target stays 44pt")
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
}
