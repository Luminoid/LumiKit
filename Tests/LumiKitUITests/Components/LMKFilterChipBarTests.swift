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

    // MARK: - Multi-select

    private func chips(in bar: LMKFilterChipBar) -> [LMKChipView] {
        bar.subviews
            .compactMap { $0 as? UIScrollView }
            .first?.subviews
            .compactMap { $0 as? UIStackView }
            .first?.arrangedSubviews
            .compactMap { $0 as? LMKChipView } ?? []
    }

    @Test
    func `Multi-select tap selects a chip and reports the set`() {
        let bar = LMKFilterChipBar()
        bar.allowsMultipleSelection = true
        var reported: Set<Int>?
        bar.multiSelectionChangedHandler = { reported = $0 }
        bar.configure(filterTitles: ["A", "B", "C"])

        chips(in: bar)[1].tapHandler?()
        #expect(bar.selectedIndices == [1])
        #expect(reported == [1])
    }

    @Test
    func `Multi-select taps accumulate without radio behavior`() {
        let bar = LMKFilterChipBar()
        bar.allowsMultipleSelection = true
        bar.configure(filterTitles: ["A", "B", "C"])

        let barChips = chips(in: bar)
        barChips[0].tapHandler?()
        barChips[2].tapHandler?()
        #expect(bar.selectedIndices == [0, 2])
        #expect(barChips[0].isChipSelected)
        #expect(!barChips[1].isChipSelected)
        #expect(barChips[2].isChipSelected)
    }

    @Test
    func `Multi-select tap on a selected chip deselects it down to an empty set`() {
        let bar = LMKFilterChipBar()
        bar.allowsMultipleSelection = true
        var reported: Set<Int>?
        bar.multiSelectionChangedHandler = { reported = $0 }
        bar.configure(filterTitles: ["A", "B"])

        let barChips = chips(in: bar)
        barChips[0].tapHandler?()
        barChips[0].tapHandler?()
        #expect(bar.selectedIndices.isEmpty, "Deselecting the last chip is allowed")
        #expect(reported == [])
        #expect(!barChips[0].isChipSelected)
    }

    @Test
    func `setSelectedIndices updates chip states without firing handler`() {
        let bar = LMKFilterChipBar()
        bar.allowsMultipleSelection = true
        var handlerFired = false
        bar.multiSelectionChangedHandler = { _ in handlerFired = true }
        bar.configure(filterTitles: ["A", "B", "C"])

        bar.setSelectedIndices([0, 2])
        #expect(bar.selectedIndices == [0, 2])
        #expect(!handlerFired, "setSelectedIndices is silent")

        let barChips = chips(in: bar)
        #expect(barChips[0].isChipSelected)
        #expect(!barChips[1].isChipSelected)
        #expect(barChips[2].isChipSelected)
    }

    @Test
    func `Multi-select All chip clears the selection and highlights while empty`() {
        let bar = LMKFilterChipBar()
        bar.allowsMultipleSelection = true
        var reported: Set<Int>?
        bar.multiSelectionChangedHandler = { reported = $0 }
        bar.configure(allTitle: "All", filterTitles: ["A", "B"])

        let barChips = chips(in: bar)
        #expect(barChips[0].isChipSelected, "All chip highlights while nothing is selected")

        barChips[1].tapHandler?()
        #expect(bar.selectedIndices == [0])
        #expect(!barChips[0].isChipSelected)

        barChips[0].tapHandler?()
        #expect(bar.selectedIndices.isEmpty)
        #expect(reported == [])
        #expect(barChips[0].isChipSelected)
    }

    @Test
    func `Multi-select does not fire the single-select handler`() {
        let bar = LMKFilterChipBar()
        bar.allowsMultipleSelection = true
        var singleFired = false
        bar.selectionChangedHandler = { _ in singleFired = true }
        bar.configure(filterTitles: ["A", "B"])

        chips(in: bar)[0].tapHandler?()
        #expect(!singleFired)
        #expect(bar.selectedIndex == nil, "selectedIndex tracks single-select mode only")
    }

    @Test
    func `Single-select mode does not fire the multi-select handler`() {
        let bar = LMKFilterChipBar()
        var multiFired = false
        bar.multiSelectionChangedHandler = { _ in multiFired = true }
        bar.configure(filterTitles: ["A", "B"])

        chips(in: bar)[1].tapHandler?()
        #expect(!multiFired)
        #expect(bar.selectedIndex == 1)
    }
}
