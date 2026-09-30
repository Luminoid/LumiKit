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
        controller.onTabSelected = { selected.append($0) }
        #expect(controller.selectTab(identifier: "b"))
        #expect(controller.selectedIdentifier == "b")
        #expect(controller.selectedViewController === controller.navigationController(for: "b"))
        #expect(!controller.selectTab(identifier: "missing"))
        controller.selectedIdentifier = "c"
        #expect(controller.selectedIdentifier == "c")
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
        controller.onTabSelected = { selected.append($0) }
        controller.onTabReselected = { reselected.append($0) }
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
        controller.onTabSelected = { selected.append($0) }
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
        let style = LMKTabBarController.Style(backgroundColor: .yellow, selectedTint: .red, normalTint: .blue, titleTextStyle: .caption, badgeBackgroundColor: .green, forcesOpaqueBackground: true)
        let appearance = LMKTabBarAppearance.makeAppearance(style, theme: LMKTheme())
        #expect(appearance.backgroundColor == UIColor.yellow)
        #expect(appearance.stackedLayoutAppearance.selected.iconColor == UIColor.red)
        #expect(appearance.stackedLayoutAppearance.normal.iconColor == UIColor.blue)
        #expect(appearance.inlineLayoutAppearance.selected.iconColor == UIColor.red)
        #expect(appearance.compactInlineLayoutAppearance.normal.badgeBackgroundColor == UIColor.green)
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
