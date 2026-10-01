//
//  LMKNavigationBarSystemBarTests.swift
//  LumiKit
//
//  The system-bar bridge (`makeBarButtonItem`, `UINavigationItem.lmk_setItems`,
//  `lmk_setSubtitle`) and the nav bar's hero background.
//

import Testing
import UIKit
@testable import LumiKitUI

@MainActor
struct LMKNavigationBarSystemBarTests {
    @Test
    func `makeBarButtonItem maps content, state, menu, identity, and roles`() throws {
        var tapped = false
        let menu = UIMenu(children: [UIAction(title: "One") { _ in }])
        let glyph = LMKNavigationBarItem(identifier: "add", systemName: "plus", accessibilityLabel: "Add", isEnabled: false, badge: .count(3)) { tapped = true }
        let barItem = glyph.makeBarButtonItem()
        #expect(barItem.image != nil)
        #expect(barItem.title == nil, "a glyph shows alone")
        #expect(!barItem.isEnabled)
        #expect(barItem.accessibilityLabel == "Add")
        #expect(barItem.accessibilityIdentifier == "add")
        #expect(barItem.style == .plain)
        #expect(barItem.menu == nil)
        try #require(barItem.primaryAction).performWithSender(nil, target: nil)
        #expect(tapped)

        let text = LMKNavigationBarItem(identifier: "done", title: "Done", role: .prominent, menu: menu).makeBarButtonItem()
        #expect(text.title == "Done")
        #expect(text.image == nil)
        #expect(text.menu?.children.count == 1)
        #expect(text.primaryAction == nil, "a menu without an action opens on tap")
        #expect(text.accessibilityLabel == "Done")

        let destructive = LMKNavigationBarItem(identifier: "delete", systemName: "trash", role: .destructive).makeBarButtonItem(tintColor: .blue)
        #expect(destructive.tintColor == LMKColor.error, "the role wins over the bar tint")
        #expect(LMKNavigationBarItem(identifier: "x", systemName: "plus").makeBarButtonItem(tintColor: .blue).tintColor == .blue)

        if #available(iOS 26, *) {
            #expect(text.style == .prominent)
            #expect(text.hidesSharedBackground)
            #expect(barItem.identifier == "add")
            #expect(barItem.badge == .count(3))
            #expect(LMKNavigationBarItem.systemBadge(for: .dot) == .indicator())
            #expect(LMKNavigationBarItem.systemBadge(for: .text("New")) == .string("New"))
            #expect(LMKNavigationBarItem.systemBadge(for: .count(0)) == nil)
            #expect(LMKNavigationBarItem.systemBadge(for: nil) == nil)
        } else {
            #expect(text.style == .done)
        }
    }

    @Test
    func `lmk_setItems installs leading-to-trailing definitions on a navigation item`() {
        let navigationItem = UINavigationItem(title: "Title")
        navigationItem.lmk_setItems(
            leading: [LMKNavigationBarItem(identifier: "l1", title: "L1"), LMKNavigationBarItem(identifier: "l2", title: "L2")],
            trailing: [LMKNavigationBarItem(identifier: "t1", title: "T1"), LMKNavigationBarItem(identifier: "t2", title: "T2")]
        )
        #expect(navigationItem.leftBarButtonItems?.map(\.accessibilityIdentifier) == ["l1", "l2"])
        #expect(navigationItem.rightBarButtonItems?.map(\.accessibilityIdentifier) == ["t2", "t1"], "UIKit lists right items trailing-first")

        navigationItem.lmk_setItems()
        #expect(navigationItem.leftBarButtonItems?.count == 2, "an omitted side is left alone")
        #expect(navigationItem.rightBarButtonItems?.count == 2)
        navigationItem.lmk_setItems(trailing: [LMKNavigationBarItem(identifier: "t3", title: "T3")])
        #expect(navigationItem.leftBarButtonItems?.map(\.accessibilityIdentifier) == ["l1", "l2"])
        #expect(navigationItem.rightBarButtonItems?.map(\.accessibilityIdentifier) == ["t3"])
        navigationItem.lmk_setItems(leading: [], trailing: [])
        #expect(navigationItem.leftBarButtonItems == nil, "an empty side clears")
        #expect(navigationItem.rightBarButtonItems == nil)
    }

    @Test
    func `The two-line title view takes the theme's title text style`() {
        var theme = LMKTheme()
        theme.navigationBar = LMKNavigationBar.Style(titleTextStyle: .h1, titleColor: .purple)
        let view = LMKTwoLineTitleView()
        view.configure(title: "Plants", subtitle: "12 items")
        let window = LMKThemeTesting.host(view, theme: theme)
        defer { window.isHidden = true }
        #expect(view.titleLabel.font.pointSize == LMKTypography.font(for: .h1, compatibleWith: view.traitCollection).pointSize)
        #expect(view.titleLabel.textColor == UIColor.purple)
    }

    @Test
    func `lmk_setSubtitle uses the system subtitle on iOS 26 and a two-line title view before`() throws {
        let navigationItem = UINavigationItem(title: "Plants")
        navigationItem.lmk_setSubtitle("12 items")
        if #available(iOS 26, *) {
            #expect(navigationItem.subtitle == "12 items")
            #expect(navigationItem.titleView == nil)
            navigationItem.lmk_setSubtitle(nil)
            #expect(navigationItem.subtitle == nil)
        } else {
            let view = try #require(navigationItem.titleView as? LMKTwoLineTitleView)
            #expect(view.titleLabel.text == "Plants")
            #expect(view.subtitleLabel.text == "12 items")
            #expect(view.accessibilityLabel == "Plants, 12 items")
            #expect(view.intrinsicContentSize.height > view.titleLabel.font.lineHeight)
            navigationItem.lmk_setSubtitle(nil)
            #expect(navigationItem.titleView == nil)
        }
    }

    @Test
    func `backgroundContentView sits behind the bar in an extension host on iOS 26`() throws {
        let bar = LMKNavigationBar(style: LMKNavigationBar.Style(surface: LMKSurfaceStyle(background: .blur(.systemMaterial))))
        bar.title = "Hero"
        let hero = UIView()
        bar.backgroundContentView = hero
        let host = try #require(bar.backgroundContentHost)
        #expect(bar.subviews.first === host, "beneath everything, the blur included")
        #expect(!host.isUserInteractionEnabled)
        #expect(host.accessibilityElementsHidden)
        if #available(iOS 26, *) {
            let extensionView = try #require(host as? UIBackgroundExtensionView)
            #expect(extensionView.contentView === hero)
        } else {
            #expect(hero.superview === host)
        }

        // A theme pass re-inserts the surface's blur at index 0; the hero stays at the back.
        bar.applyTheme(.default)
        #expect(bar.subviews.first === host)

        bar.backgroundContentView = nil
        #expect(bar.backgroundContentHost == nil)
        #expect(host.superview == nil)
        #expect(hero.superview == nil)
    }
}
