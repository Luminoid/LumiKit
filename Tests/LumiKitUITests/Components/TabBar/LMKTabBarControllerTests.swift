//
//  LMKTabBarControllerTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

@MainActor
struct LMKTabBarControllerTests {
    private final class Root: UIViewController {
        let name: String
        init(name: String) {
            self.name = name
            super.init(nibName: nil, bundle: nil)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError()
        }
    }

    private final class Counter {
        var built: [String] = []
    }

    private func makeController(style: LMKTabBarController.Style = LMKTabBarController.Style(), counter: Counter = Counter(), lazyThird: Bool = true) -> LMKTabBarController {
        let tabs = [
            LMKTab(identifier: "a", title: "Alpha", systemImage: "a.circle") { counter.built.append("a"); return Root(name: "a") },
            LMKTab(identifier: "b", title: "Beta", systemImage: "b.circle", badge: .count(3)) { counter.built.append("b"); return Root(name: "b") },
            LMKTab(identifier: "c", title: "Gamma", systemImage: "c.circle", isLazy: lazyThird) { counter.built.append("c"); return Root(name: "c") },
        ]
        let controller = LMKTabBarController(tabs: tabs, style: style)
        controller.loadViewIfNeeded()
        return controller
    }

    @Test
    func `Tabs build UITabs in order, wrap roots in LMKNavigationController, and start on the first`() {
        let counter = Counter()
        let controller = makeController(counter: counter)
        #expect(controller.identifiers == ["a", "b", "c"])
        #expect(controller.tabs.map(\.title) == ["Alpha", "Beta", "Gamma"])
        #expect(controller.tabDefinitions.count == 3)
        #expect(controller.selectedIdentifier == "a")
        #expect(controller.navigationController(for: "a") is LMKNavigationController)
        #expect((controller.rootViewController(for: "a") as? Root)?.name == "a")
        #expect(counter.built.contains("a"))
        #expect(controller.tab(identifier: "b")?.title == "Beta")
        #expect(controller.tab(identifier: "zzz") == nil)
    }

    @Test
    func `Roots are lazy unless asked otherwise`() {
        let lazyCounter = Counter()
        let lazy = makeController(counter: lazyCounter)
        #expect(lazyCounter.built == ["a"], "only the selected tab's root exists after load")
        #expect(!lazy.isRootLoaded(for: "c"))
        #expect(lazy.rootViewController(for: "c") == nil)
        #expect(lazy.navigationController(for: "c")?.viewControllers.first is LMKLazyTabPlaceholderViewController)
        lazy.selectTab(identifier: "c")
        #expect(lazyCounter.built == ["a", "c"])
        #expect(lazy.isRootLoaded(for: "c"))
        #expect((lazy.rootViewController(for: "c") as? Root)?.name == "c")
        #expect(lazy.navigationController(for: "c")?.viewControllers.first === lazy.rootViewController(for: "c"))
        #expect(lazy.loadRoot(for: "b") === lazy.rootViewController(for: "b"))
        #expect(lazyCounter.built == ["a", "c", "b"])

        let eagerCounter = Counter()
        _ = makeController(counter: eagerCounter, lazyThird: false)
        #expect(eagerCounter.built.contains("c"))
    }

    @Test
    func `selectTab goes through selectedTab and reports each change once`() {
        let controller = makeController()
        var selected: [String] = []
        controller.onTabSelect = { selected.append($0) }
        #expect(controller.selectTab(identifier: "b"))
        #expect(controller.selectedIdentifier == "b")
        #expect(controller.selectedViewController === controller.navigationController(for: "b"))
        #expect(!controller.selectTab(identifier: "missing"))
        controller.selectedIdentifier = "c"
        #expect(controller.selectedViewController === controller.navigationController(for: "c"))
        #expect(controller.selectedTab === controller.tabs[2])
        controller.selectTab(identifier: "c")
        #expect(selected == ["b", "c"], "once per change, whatever path UIKit reports through")
    }

    @Test
    func `selectTab right after init selects through the tab model`() {
        let controller = LMKTabBarController(tabs: [
            LMKTab(identifier: "a", title: "Alpha", systemImage: "a.circle") { UIViewController() },
            LMKTab(identifier: "c", title: "Gamma", systemImage: "c.circle") { UIViewController() },
        ])
        #expect(controller.selectTab(identifier: "c"))
        #expect(controller.selectedIdentifier == "c")
        #expect(controller.selectedTab?.identifier == "c")
        #expect(controller.selectedViewController === controller.navigationController(for: "c"))
    }

    /// Mirrors an app that reorders its tabs and applies a launch-tab preference from `viewDidLoad`.
    private final class LaunchTabController: LMKTabBarController {
        var appliesInViewDidLoad = true
        override func viewDidLoad() {
            super.viewDidLoad()
            guard appliesInViewDidLoad else { return }
            reorderTabs(identifiers: ["c", "a", "b"])
            selectTab(identifier: "b")
        }
    }

    private func makeLaunchTabController(appliesInViewDidLoad: Bool = true) -> LaunchTabController {
        let controller = LaunchTabController(tabs: [
            LMKTab(identifier: "a", title: "Alpha", systemImage: "a.circle") { UIViewController() },
            LMKTab(identifier: "b", title: "Beta", systemImage: "b.circle") { UIViewController() },
            LMKTab(identifier: "c", title: "Gamma", systemImage: "c.circle") { UIViewController() },
        ])
        controller.appliesInViewDidLoad = appliesInViewDidLoad
        return controller
    }

    @Test
    func `Variant A: reorder and selection in viewDidLoad hold before a window`() {
        let controller = makeLaunchTabController()
        controller.loadViewIfNeeded()
        #expect(controller.identifiers == ["c", "a", "b"])
        #expect(controller.selectedIdentifier == "b")
    }

    @Test
    func `Variant B: reorder and selection in viewDidLoad survive the first layout in a window`() {
        let controller = makeLaunchTabController()
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        window.rootViewController = controller
        window.makeKeyAndVisible()
        #expect(controller.identifiers == ["c", "a", "b"], "after makeKeyAndVisible")
        #expect(controller.selectedIdentifier == "b", "after makeKeyAndVisible")
        window.layoutIfNeeded()
        #expect(controller.identifiers == ["c", "a", "b"], "after layout")
        #expect(controller.selectedIdentifier == "b", "after layout")
    }

    @Test
    func `Variant C: reorder and selection after the window is up hold`() {
        let controller = makeLaunchTabController(appliesInViewDidLoad: false)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        window.rootViewController = controller
        window.makeKeyAndVisible()
        window.layoutIfNeeded()
        controller.reorderTabs(identifiers: ["c", "a", "b"])
        controller.selectTab(identifier: "b")
        window.layoutIfNeeded()
        #expect(controller.identifiers == ["c", "a", "b"])
        #expect(controller.selectedIdentifier == "b")
    }

    @Test
    func `The delegate reports user selection and reselection`() throws {
        let controller = makeController()
        var selected: [String] = []
        var reselected: [String] = []
        controller.onTabSelect = { selected.append($0) }
        controller.onTabReselect = { reselected.append($0) }
        let a = try #require(controller.tabs.first { $0.identifier == "a" })
        let b = try #require(controller.tabs.first { $0.identifier == "b" })
        controller.tabBarController(controller, didSelectTab: b, previousTab: a)
        controller.tabBarController(controller, didSelectTab: b, previousTab: b)
        #expect(selected == ["b"])
        #expect(reselected == ["b"])
        #expect(controller.delegate === controller)
    }

    @Test
    func `Reordering keeps the selection and drops unknown identifiers`() {
        let controller = makeController()
        controller.selectTab(identifier: "b")
        controller.reorderTabs(identifiers: ["c", "b", "zzz", "a"])
        #expect(controller.identifiers == ["c", "b", "a"])
        #expect(controller.tabDefinitions.map(\.identifier) == ["c", "b", "a"])
        #expect(controller.selectedIdentifier == "b")
        controller.reorderTabs(identifiers: ["a"])
        #expect(controller.identifiers == ["a"])
        controller.reorderTabs(identifiers: [])
        #expect(controller.identifiers == ["a"], "an empty order is ignored")
    }

    @Test
    func `A tab filtered out keeps its definition and badge, and can be shown and built again`() {
        let counter = Counter()
        let controller = makeController(counter: counter)
        controller.reorderTabs(identifiers: ["a", "b"])
        #expect(controller.identifiers == ["a", "b"])
        #expect(controller.tabDefinitions.map(\.identifier) == ["a", "b"])
        #expect(controller.tab(identifier: "c")?.title == "Gamma", "still known while hidden")
        controller.setBadge(.count(7), for: "c")
        #expect(controller.tab(identifier: "c")?.badge == .count(7))

        controller.reorderTabs(identifiers: ["a", "b", "c"])
        #expect(controller.identifiers == ["a", "b", "c"])
        #expect(controller.tabDefinitions.map(\.badge) == [nil, .count(3), .count(7)])
        #expect(controller.selectTab(identifier: "c"))
        #expect(controller.isRootLoaded(for: "c"), "the lazy root is built from the kept definition")
        #expect((controller.rootViewController(for: "c") as? Root)?.name == "c")
        #expect(counter.built == ["a", "c"])
    }

    @Test
    func `Filtering out the selected tab loads and reports the tab UIKit moves to`() {
        let counter = Counter()
        let controller = makeController(counter: counter)
        var selected: [String] = []
        controller.onTabSelect = { selected.append($0) }
        controller.selectTab(identifier: "b")
        controller.reorderTabs(identifiers: ["c", "a"])
        let replacement = controller.selectedIdentifier
        #expect(replacement != nil && replacement != "b")
        #expect(selected == ["b", replacement ?? ""])
        #expect(replacement.map { controller.isRootLoaded(for: $0) } == true)
    }

    @Test
    func `Badges map to badge values`() throws {
        let controller = makeController()
        let b = try #require(controller.tabs.first { $0.identifier == "b" })
        #expect(b.badgeValue == "3")
        controller.setBadge(.dot, for: "b")
        #expect(b.badgeValue == "")
        controller.setBadge(.text("New"), for: "b")
        #expect(b.badgeValue == "New")
        #expect(controller.tab(identifier: "b")?.badge == .text("New"))
        controller.setBadge(nil, for: "b")
        #expect(b.badgeValue == nil)
        #expect(LMKTab.badgeValue(for: .count(0)) == nil)
        #expect(LMKTab.badgeValue(for: .text("")) == nil)
    }

    @Test
    func `Key commands rest while a modal is presented over the tab controller`() throws {
        let controller = makeController()
        controller.tabKeyCommandsEnabled = true
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        window.rootViewController = controller
        window.makeKeyAndVisible()
        defer { window.isHidden = true }
        #expect(controller.keyCommands?.count == 3)
        let modal = UIViewController()
        controller.present(modal, animated: false)
        try #require(controller.presentedViewController === modal)
        #expect(controller.keyCommands?.isEmpty ?? true, "a presented controller's chain reaches the presenter")
    }

    @Test
    func `Key commands select tabs with command-number and can be switched off`() throws {
        let controller = makeController()
        controller.tabKeyCommandsEnabled = true
        let commands = try #require(controller.keyCommands)
        #expect(commands.count == 3)
        #expect(commands.map(\.input) == ["1", "2", "3"])
        #expect(commands.allSatisfy { $0.modifierFlags == .command })
        #expect(commands.map(\.discoverabilityTitle) == ["Alpha", "Beta", "Gamma"])
        #expect(commands[1].propertyList as? String == "b")
        var selected: [String] = []
        controller.onTabSelect = { selected.append($0) }
        controller.perform(NSSelectorFromString("handleTabKeyCommand:"), with: commands[1])
        #expect(controller.selectedIdentifier == "b")
        #expect(selected == ["b"])
        controller.perform(NSSelectorFromString("handleTabKeyCommand:"), with: commands[1])
        #expect(selected == ["b"], "the same tab again is not a selection")
        controller.tabKeyCommandsEnabled = false
        #expect(controller.keyCommands?.isEmpty ?? true)
        #expect(controller.canBecomeFirstResponder)
    }

    @Test
    func `Appearance follows the style and the theme slot`() {
        let style = LMKTabBarController.Style(
            backgroundColor: .yellow,
            selectedTint: .red,
            normalTint: .blue,
            titleTextStyle: .caption,
            badgeBackgroundColor: .green,
            badgeTextColor: .purple,
            forcesOpaqueBackground: true
        )
        let appearance = LMKTabBarAppearance.makeAppearance(style, theme: LMKTheme())
        #expect(appearance.backgroundColor == UIColor.yellow)
        #expect(appearance.stackedLayoutAppearance.selected.iconColor == UIColor.red)
        #expect(appearance.stackedLayoutAppearance.normal.iconColor == UIColor.blue)
        #expect(appearance.inlineLayoutAppearance.selected.iconColor == UIColor.red)
        #expect(appearance.compactInlineLayoutAppearance.normal.badgeBackgroundColor == UIColor.green)
        #expect(appearance.stackedLayoutAppearance.selected.badgeTextAttributes[.foregroundColor] as? UIColor == UIColor.purple)
        #expect(appearance.stackedLayoutAppearance.selected.titleTextAttributes[.font] as? UIFont == LMKTypography.font(for: .caption, compatibleWith: nil))
        #expect(appearance.stackedLayoutAppearance.normal.titleTextAttributes[.foregroundColor] as? UIColor == UIColor.blue)

        let controller = makeController(style: style)
        #expect(controller.tabBar.tintColor == UIColor.red)
        #expect(controller.tabBar.standardAppearance.backgroundColor == UIColor.yellow)
        #expect(controller.tabBar.scrollEdgeAppearance?.stackedLayoutAppearance.normal.iconColor == UIColor.blue)

        var theme = LMKTheme()
        theme.tabBar = LMKTabBarController.Style(selectedTint: .purple)
        let themed = makeController()
        themed.applyTheme(theme)
        #expect(themed.tabBar.tintColor == UIColor.purple)
        #expect(themed.resolvedStyle.selectedTint == UIColor.purple)
        #expect(LMKTabBarController.Style(selectedTint: .red).merging(LMKTabBarController.Style(normalTint: .blue)).selectedTint == UIColor.red)
        #expect(LMKTabBarController.Style.defaultValue == LMKTabBarController.Style())
    }

    @Test
    func `applyGlobally writes the appearance proxy every later tab bar reads`() {
        let proxy = UITabBar.appearance()
        let previous = (proxy.standardAppearance, proxy.scrollEdgeAppearance, proxy.tintColor)
        defer {
            proxy.standardAppearance = previous.0
            proxy.scrollEdgeAppearance = previous.1
            proxy.tintColor = previous.2
        }
        LMKTabBarAppearance.applyGlobally(LMKTabBarController.Style(backgroundColor: .yellow, selectedTint: .red, forcesOpaqueBackground: true), theme: LMKTheme())
        #expect(proxy.standardAppearance.backgroundColor == UIColor.yellow)
        #expect(proxy.scrollEdgeAppearance?.stackedLayoutAppearance.selected.iconColor == UIColor.red)
        #expect(proxy.tintColor == UIColor.red)
        // Appearance proxies land when a view enters a window.
        let plain = UITabBarController()
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        window.rootViewController = plain
        window.isHidden = false
        defer { window.isHidden = true }
        window.layoutIfNeeded()
        #expect(plain.tabBar.standardAppearance.backgroundColor == UIColor.yellow)
    }

    /// A subclass that styles something of its own from the hook.
    private final class ThemedController: LMKTabBarController {
        var order: [String] = []
        override func applyContentTheme(_ theme: LMKTheme) {
            order.append("content")
        }
    }

    @Test
    func `applyContentTheme runs before didApplyStyle`() {
        let controller = ThemedController(tabs: [LMKTab(identifier: "a", title: "Alpha", systemImage: "a.circle") { UIViewController() }])
        controller.didApplyStyle = { ($0 as? ThemedController)?.order.append("didApplyStyle") }
        controller.order = []
        controller.style = LMKTabBarController.Style(selectedTint: .red)
        #expect(controller.order == ["content", "didApplyStyle"])
    }

    @Test
    func `Sidebar mode follows the style and the size class; the bottom accessory is gated`() {
        let controller = makeController()
        #expect(controller.mode == .tabBar)
        controller.style = LMKTabBarController.Style(prefersSidebarOnIPad: true)
        #expect(controller.mode == (controller.traitCollection.horizontalSizeClass == .regular && controller.traitCollection.userInterfaceIdiom != .phone ? .tabSidebar : .tabBar))
        let accessory = UIView()
        controller.setBottomAccessory(accessory)
        #expect(controller.bottomAccessoryContentView === accessory)
        if #available(iOS 26, *) {
            #expect(controller.bottomAccessory?.contentView === accessory)
        }
        controller.setBottomAccessory(nil)
        #expect(controller.bottomAccessoryContentView == nil)
    }
}
