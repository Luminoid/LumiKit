//
//  LMKTabSearchTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

@MainActor
struct LMKTabSearchTests {
    @Test
    func `A search tab is backed by UISearchTab with the system glyph unless overridden`() throws {
        let tabs = [
            LMKTab(identifier: "home", title: "Home", systemImage: "house") { UIViewController() },
            LMKTab.search { UIViewController() },
            LMKTab(identifier: "find", title: "Find", systemImage: "binoculars", role: .search) { UIViewController() },
        ]
        let controller = LMKTabBarController(tabs: tabs, style: LMKTabBarController.Style(automaticallyActivatesSearch: false))
        controller.loadViewIfNeeded()
        if #available(iOS 26, *) {
            // The first theme pass ran inside `super.init`, before the tabs existed.
            let activating = LMKTabBarController(tabs: [LMKTab.search { UIViewController() }], style: LMKTabBarController.Style(automaticallyActivatesSearch: true))
            #expect((activating.tabs.first as? UISearchTab)?.automaticallyActivatesSearch == true, "applied to the real tabs right after init")
        }

        #expect(tabs[1].role == .search)
        #expect(tabs[0].role == .standard)
        #expect(controller.identifiers == ["home", "search", "find"])
        let system = try #require(controller.tabs[1] as? UISearchTab)
        #expect(!system.title.isEmpty, "the system supplies a title")
        #expect(system.image != nil, "and a glyph")
        let custom = try #require(controller.tabs[2] as? UISearchTab)
        #expect(custom.title == "Find")
        #expect(custom.identifier != "find", "UIKit owns a search tab's identifier")
        #expect(!(controller.tabs[0] is UISearchTab))
        #expect(controller.selectTab(identifier: "find"))
        #expect(controller.selectedIdentifier == "find", "the definition identifier maps back")
        #expect(controller.tab(identifier: "search")?.role == .search)
        #expect(controller.navigationController(for: "search") != nil)

        if #available(iOS 26, *) {
            #expect(!system.automaticallyActivatesSearch)
            controller.style = LMKTabBarController.Style(automaticallyActivatesSearch: true)
            #expect(custom.automaticallyActivatesSearch)
        }
        #expect(LMKTabBarController.Style(automaticallyActivatesSearch: true).merging(LMKTabBarController.Style()).automaticallyActivatesSearch == true)
        #expect(LMKTab.Role.allCases.count == 2)
    }
}
