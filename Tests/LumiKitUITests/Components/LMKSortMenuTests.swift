//
//  LMKSortMenuTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

@MainActor
struct LMKSortMenuTests {
    private enum Sort: Hashable { case name, date, type }
    private enum Layout: Hashable { case list, grid }

    private let sortOptions: [LMKSortMenu.Option<Sort>] = [
        .init(id: .name, title: "Name"), .init(id: .date, title: "Date"), .init(id: .type, title: "Type"),
    ]
    private let layoutOptions: [LMKSortMenu.Option<Layout>] = [
        .init(id: .list, title: "List", systemImageName: "list.bullet"), .init(id: .grid, title: "Grid", systemImageName: "square.grid.2x2"),
    ]

    private func sections(
        state: LMKSortMenu.State<Sort, Layout>,
        onSelectSort: @escaping @MainActor (Sort, LMKSortMenu.Direction) -> Void = { _, _ in },
        onSelectLayout: (@MainActor (Layout) -> Void)? = nil
    ) -> [UIMenu] {
        LMKSortMenu.makeSections(sortOptions: sortOptions, layoutOptions: layoutOptions, strings: LMKSortMenu.Strings(), state: state, onSelectSort: onSelectSort, onSelectLayout: onSelectLayout)
            .compactMap { $0 as? UIMenu }
    }

    @Test
    func `Reduction: the selected sort flips direction, another sort starts ascending`() {
        #expect(LMKSortMenu.resolve(tapping: Sort.name, selected: .name, direction: .ascending) == (Sort.name, .descending))
        #expect(LMKSortMenu.resolve(tapping: Sort.name, selected: .name, direction: .descending) == (Sort.name, .ascending))
        #expect(LMKSortMenu.resolve(tapping: Sort.date, selected: .name, direction: .descending) == (Sort.date, .ascending))
        #expect(LMKSortMenu.resolve(tapping: Sort.date, selected: nil, direction: .descending) == (Sort.date, .ascending))
        #expect(LMKSortMenu.Direction.ascending.toggled == .descending)
        #expect(LMKSortMenu.Direction.descending.systemImageName == "arrow.down")
    }

    @Test
    func `Sections: single-selection sort rows with a live arrow, then the layout section`() throws {
        let menus = sections(state: .init(selectedSort: .date, direction: .descending, selectedLayout: .grid))
        #expect(menus.count == 2)
        let sortMenu = menus[0]
        #expect(sortMenu.options.contains(.singleSelection) && sortMenu.options.contains(.displayInline))
        let actions = try #require(sortMenu.children as? [UIAction])
        #expect(actions.map(\.title) == ["Name", "Date", "Type"])
        #expect(actions.map(\.state) == [.off, .on, .off])
        #expect(actions[1].image == UIImage(systemName: "arrow.down"))
        #expect(actions[1].subtitle == "Descending")
        #expect(actions[1].attributes.contains(.keepsMenuPresented))
        #expect(actions[0].image == nil)
        #expect(actions[0].subtitle == nil)
        #expect(!actions[0].attributes.contains(.keepsMenuPresented))

        let layoutMenu = menus[1]
        #expect(layoutMenu.title == "Layout")
        let layouts = try #require(layoutMenu.children as? [UIAction])
        #expect(layouts.map(\.title) == ["List", "Grid"])
        #expect(layouts.map(\.state) == [.off, .on])
        #expect(layouts[0].image == UIImage(systemName: "list.bullet"))
    }

    @Test
    func `Selecting rows reports through the callbacks and updates the kept-open row in place`() throws {
        var sorts: [(Sort, LMKSortMenu.Direction)] = []
        var layouts: [Layout] = []
        let menus = sections(state: .init(selectedSort: .name, direction: .ascending, selectedLayout: .list), onSelectSort: { sorts.append(($0, $1)) }, onSelectLayout: { layouts.append($0) })
        let actions = try #require(menus[0].children as? [UIAction])
        actions[0].performWithSender(nil, target: nil)
        #expect(sorts.count == 1)
        #expect(sorts[0].0 == .name && sorts[0].1 == .descending)
        #expect(actions[0].image == UIImage(systemName: "arrow.down"), "the kept-open row shows the new direction")
        #expect(actions[0].subtitle == "Descending")
        actions[2].performWithSender(nil, target: nil)
        #expect(sorts.count == 2)
        #expect(sorts[1].0 == .type && sorts[1].1 == .ascending)
        let layoutActions = try #require(menus[1].children as? [UIAction])
        layoutActions[1].performWithSender(nil, target: nil)
        #expect(layouts == [.grid])
    }

    @Test
    func `No layout options means no layout section, and the sort-only overload builds a menu`() {
        let menus = LMKSortMenu.makeSections(
            sortOptions: sortOptions,
            layoutOptions: [LMKSortMenu.Option<Never>](),
            strings: LMKSortMenu.Strings(),
            state: LMKSortMenu.State<Sort, Never>(selectedSort: .name),
            onSelectSort: { _, _ in },
            onSelectLayout: nil
        )
        #expect(menus.count == 1)
        let menu = LMKSortMenu.makeMenu(sortOptions: sortOptions, state: { (Sort.name, .ascending) }, onSelectSort: { _, _ in })
        #expect(menu.children.count == 1)
        #expect(menu.children.first is UIDeferredMenuElement)
    }

    @Test
    func `Anchors carry the sort glyph and label`() {
        let menu = LMKSortMenu.makeMenu(sortOptions: sortOptions, state: { (nil, .ascending) }, onSelectSort: { _, _ in })
        let barItem = LMKSortMenu.makeBarButtonItem(menu: menu)
        #expect(barItem.menu?.identifier == menu.identifier, "UIKit copies the menu")
        #expect(barItem.image == LMKMenu.anchorImage(systemImageName: "arrow.up.arrow.down"), "the glyph at the anchor size, not the symbol's natural one")
        #expect(barItem.accessibilityLabel == "Sort")
        let navItem = LMKSortMenu.makeNavigationBarItem(menu: menu)
        #expect(navItem.identifier == "sort")
        #expect(navItem.menu === menu)
        #expect(navItem.accessibilityLabel == "Sort")
        let button = LMKSortMenu.makeButton(menu: menu)
        #expect(button.menu?.identifier == menu.identifier)
        #expect(button.showsMenuAsPrimaryAction)
        #expect(button.accessibilityLabel == "Sort")
        #expect(LMKSortMenu.Strings(ascending: "Up").ascending == "Up")
    }

    @Test
    func `The kept-open sort row flips back on a second tap`() throws {
        var sorts: [(Sort, LMKSortMenu.Direction)] = []
        let menus = sections(state: .init(selectedSort: .name, direction: .ascending), onSelectSort: { sorts.append(($0, $1)) })
        let actions = try #require(menus[0].children as? [UIAction])
        actions[0].performWithSender(nil, target: nil)
        actions[0].performWithSender(nil, target: nil)
        actions[0].performWithSender(nil, target: nil)
        #expect(sorts.map(\.1) == [.descending, .ascending, .descending])
        #expect(actions[0].image == UIImage(systemName: "arrow.down"))
    }

    @Test
    func `Additional sections follow the sort and layout sections`() {
        var archived = false
        let menu = LMKSortMenu.makeMenu(
            sortOptions: sortOptions,
            additionalSections: [.multiple(title: "Show", options: [.init(id: "archived", title: "Archived")], selected: { archived ? ["archived"] : [] }, onToggle: { _, isOn in archived = isOn })],
            state: { (Sort.name, .ascending) },
            onSelectSort: { _, _ in }
        )
        #expect(menu.children.first is UIDeferredMenuElement)
        let sections = LMKSortMenu.makeMenuSections(
            sortOptions: sortOptions,
            layoutOptions: layoutOptions,
            strings: LMKSortMenu.Strings(),
            state: { LMKSortMenu.State<Sort, Layout>(selectedSort: .name) },
            onSelectSort: { _, _ in },
            onSelectLayout: nil
        )
        #expect(sections.map(\.title) == [nil, "Layout"])
    }

    @Test
    func `The default button is a compact glyph and a style layers on it`() {
        let menu = LMKSortMenu.makeMenu(sortOptions: sortOptions, state: { (nil, .ascending) }, onSelectSort: { _, _ in })
        let button = LMKSortMenu.makeButton(menu: menu)
        #expect(button.style.symbolPointSize == LMKLayout.symbolRow)
        #expect(button.style.variant == .ghost)
        let tinted = LMKSortMenu.makeButton(menu: menu, style: .tinted())
        #expect(tinted.style.variant == .tinted)
        #expect(tinted.style.surface.corners == .circle)
        #expect(tinted.style.symbolPointSize == LMKLayout.symbolRow)
        tinted.frame.size = tinted.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        #expect(tinted.bounds.width < 40, "\(tinted.bounds.width)pt across")
    }
}
