//
//  LMKFilterChipBarTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

@MainActor
struct LMKFilterChipBarTests {
    @Test
    func `Without allTitle has no All chip and starts with no selection`() {
        let bar = LMKFilterChipBar()
        bar.configure(filterTitles: ["One", "Two", "Three"])
        #expect(bar.selectedIndex == nil)
    }

    @Test
    func `setSelectedIndex updates state without firing handler`() {
        let bar = LMKFilterChipBar()
        var handlerFired = false
        bar.selectionChangedHandler = { _ in handlerFired = true }
        bar.configure(allTitle: "All", filterTitles: ["A", "B"])

        bar.setSelectedIndex(1)
        #expect(bar.selectedIndex == 1)
        #expect(!handlerFired, "setSelectedIndex is silent")
    }

    @Test
    func `configure with allTitle shows All chip`() {
        let bar = LMKFilterChipBar()
        bar.configure(allTitle: "All", filterTitles: ["X", "Y"])

        let stack = bar.subviews
            .compactMap { $0 as? UIScrollView }
            .first?.subviews
            .compactMap { $0 as? UIStackView }
            .first
        #expect(stack?.arrangedSubviews.count == 3, "1 All chip + 2 filters")
    }

    @Test
    func `configure without allTitle omits All chip`() {
        let bar = LMKFilterChipBar()
        bar.configure(filterTitles: ["X", "Y"])

        let stack = bar.subviews
            .compactMap { $0 as? UIScrollView }
            .first?.subviews
            .compactMap { $0 as? UIStackView }
            .first
        #expect(stack?.arrangedSubviews.count == 2, "2 filters only")
    }

    @Test
    func `Reconfiguring replaces chips`() {
        let bar = LMKFilterChipBar()
        bar.configure(allTitle: "All", filterTitles: ["A", "B", "C"])
        bar.configure(allTitle: "All", filterTitles: ["X"])

        let stack = bar.subviews
            .compactMap { $0 as? UIScrollView }
            .first?.subviews
            .compactMap { $0 as? UIStackView }
            .first
        #expect(stack?.arrangedSubviews.count == 2, "1 All + 1 filter after reconfigure")
    }

    @Test
    func `Short-label chip is at least as wide as it is tall`() {
        let bar = LMKFilterChipBar()
        bar.frame = CGRect(x: 0, y: 0, width: 400, height: 44)
        bar.configure(filterTitles: ["A"])
        bar.setNeedsLayout()
        bar.layoutIfNeeded()

        let stack = bar.subviews
            .compactMap { $0 as? UIScrollView }
            .first?.subviews
            .compactMap { $0 as? UIStackView }
            .first
        let chip = stack?.arrangedSubviews.first
        // Width must be >= height so the capsule corner radius (height/2) renders fully.
        #expect(chip != nil)
        #expect((chip?.bounds.width ?? 0) >= (chip?.bounds.height ?? 0))
    }
}
