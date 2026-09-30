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
    func `configure builds the chips with an optional All chip`() {
        let bar = LMKFilterChipBar()
        bar.configure(items: [.init(title: "One"), .init(title: "Two"), .init(title: "Three")])
        #expect(bar.chips.count == 3)
        #expect(bar.selection.isEmpty)
        #expect(bar.chips.allSatisfy { !$0.isSelected })

        bar.configure(allTitle: "All", filterTitles: ["X", "Y"])
        #expect(bar.chips.count == 3)
        #expect(bar.chips[0].text == "All")
        #expect(bar.chips[0].isSelected, "the All chip highlights while nothing is selected")

        bar.configure(allTitle: "All", filterTitles: ["X"])
        #expect(bar.chips.count == 2)
    }

    @Test
    func `Icons match titles positionally and the All chip never carries one`() {
        let bar = LMKFilterChipBar()
        let icon = UIImage(systemName: "star")
        bar.configure(allTitle: "All", filterTitles: ["A", "B", "C"], filterIcons: [icon, nil])
        #expect(bar.chips[0].icon == nil)
        #expect(bar.chips[1].icon === icon)
        #expect(bar.chips[2].icon == nil)
        #expect(bar.chips[3].icon == nil)
    }

    @Test
    func `setSelection is silent and clamps to the mode`() {
        let bar = LMKFilterChipBar()
        var fired = false
        bar.onSelectionChange = { _ in fired = true }
        bar.configure(allTitle: "All", filterTitles: ["A", "B", "C"])
        bar.setSelection([1])
        #expect(bar.selection == [1])
        #expect(bar.chips[2].isSelected)
        #expect(!bar.chips[0].isSelected)
        bar.setSelection([0, 2])
        #expect(bar.selection == [0], "single mode keeps the lowest index")
        bar.setSelection([9])
        #expect(bar.selection.isEmpty, "out-of-range indices are dropped")
        #expect(!fired)
    }

    @Test
    func `Single selection taps switch chips and the All chip clears`() {
        let bar = LMKFilterChipBar()
        var reported: [Set<Int>] = []
        bar.onSelectionChange = { reported.append($0) }
        bar.configure(allTitle: "All", filterTitles: ["A", "B"])
        bar.chips[1].onTap?()
        bar.chips[2].onTap?()
        #expect(bar.selection == [1])
        bar.chips[0].onTap?()
        #expect(bar.selection.isEmpty)
        #expect(bar.chips[0].isSelected)
        #expect(reported == [[0], [1], []])
    }

    @Test
    func `Single selection can forbid clearing by re-tapping`() {
        let bar = LMKFilterChipBar()
        bar.configure(filterTitles: ["A", "B"])
        bar.chips[0].onTap?()
        bar.chips[0].onTap?()
        #expect(bar.selection.isEmpty, "allowsEmpty by default")
        bar.selectionMode = .single(allowsEmpty: false)
        bar.chips[0].onTap?()
        bar.chips[0].onTap?()
        #expect(bar.selection == [0])
    }

    @Test
    func `Multiple selection accumulates and toggles down to empty`() {
        let bar = LMKFilterChipBar()
        bar.selectionMode = .multiple
        var reported: [Set<Int>] = []
        bar.onSelectionChange = { reported.append($0) }
        bar.configure(allTitle: "All", filterTitles: ["A", "B", "C"])
        bar.chips[1].onTap?()
        bar.chips[3].onTap?()
        #expect(bar.selection == [0, 2])
        #expect(!bar.chips[0].isSelected)
        bar.chips[1].onTap?()
        bar.chips[3].onTap?()
        #expect(bar.selection.isEmpty)
        #expect(bar.chips[0].isSelected)
        #expect(reported == [[0], [0, 2], [2], []])
        bar.setSelection([0, 2])
        #expect(bar.selection == [0, 2])
        bar.selectionMode = .single(allowsEmpty: true)
        #expect(bar.selection == [0], "switching to single keeps the lowest index")
    }

    @Test
    func `Chips stay at least as wide as they are tall`() {
        let bar = LMKFilterChipBar()
        bar.frame = CGRect(x: 0, y: 0, width: 400, height: 44)
        bar.configure(filterTitles: ["A"])
        bar.layoutIfNeeded()
        let chip = bar.chips[0]
        #expect(chip.bounds.width >= chip.bounds.height)
    }

    @Test
    func `isEnabled and the chip style propagate`() {
        let bar = LMKFilterChipBar(style: LMKFilterChipBar.Style(chip: .filled.tint(.red), spacing: 3))
        bar.configure(filterTitles: ["A", "B"])
        bar.setSelection([0])
        #expect(bar.chips[0].backgroundColor == UIColor.red)
        #expect(bar.chipStack.spacing == 3)
        bar.isEnabled = false
        #expect(bar.chips.allSatisfy { !$0.isEnabled })
        bar.style.chip = .outlined
        #expect(bar.chips[1].backgroundColor == UIColor.clear)
    }

    @Test
    func `In a filled bar the selected chip carries the full tint and the others a wash of it`() {
        let bar = LMKFilterChipBar(style: LMKFilterChipBar.Style(chip: .filled.tint(.red)))
        bar.configure(allTitle: "All", filterTitles: ["A", "B"])
        bar.setSelection([1])
        let wash = UIColor.red.withAlphaComponent(LMKTheme.current.alpha.xs)
        #expect(bar.chips[0].backgroundColor == wash)
        #expect(bar.chips[1].backgroundColor == wash)
        #expect(bar.chips[2].backgroundColor == UIColor.red)
        #expect(bar.chips[1].titleLabel.textColor == UIColor.red)
        #expect(bar.chips[2].titleLabel.textColor != UIColor.red, "the selected chip draws on the tint")
        // Selected and not selected differ by far more than a shade.
        let selectedAlpha = bar.chips[2].backgroundColor?.cgColor.alpha ?? 0
        let restingAlpha = bar.chips[1].backgroundColor?.cgColor.alpha ?? 1
        #expect(selectedAlpha - restingAlpha > 0.5)
    }

    @Test
    func `The bar softens a filled style only when the host left the selected look open`() {
        #expect(LMKFilterChipBar.chipStyle(for: nil) == .outlined)
        #expect(LMKFilterChipBar.chipStyle(for: .outlined) == .outlined)
        #expect(LMKFilterChipBar.chipStyle(for: .tinted) == .tinted)

        let softened = LMKFilterChipBar.chipStyle(for: .filled.tint(.blue))
        #expect(softened.variant == .tinted)
        #expect(softened.selectedVariant == .filled)
        #expect(softened.tintColor == UIColor.blue)

        var decided = LMKChipView.Style.filled
        decided.selectedVariant = .outlined
        #expect(LMKFilterChipBar.chipStyle(for: decided) == decided)

        var colored = LMKChipView.Style.filled
        colored.selected = LMKControlStateStyle(background: .solid(.black))
        #expect(LMKFilterChipBar.chipStyle(for: colored) == colored)
    }

    @Test
    func `theme.filterChipBar supplies app-wide defaults`() {
        var theme = LMKTheme()
        theme.filterChipBar = LMKFilterChipBar.Style(spacing: 17)
        let bar = LMKFilterChipBar()
        bar.configure(filterTitles: ["A"])
        let window = LMKThemeTesting.host(bar, theme: theme)
        defer { window.isHidden = true }
        #expect(bar.chipStack.spacing == 17)
    }
}
