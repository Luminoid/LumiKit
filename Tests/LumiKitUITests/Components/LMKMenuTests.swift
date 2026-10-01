//
//  LMKMenuTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

@MainActor
struct LMKMenuTests {
    private enum Layout: Hashable { case list, grid }
    private enum Filter: Hashable { case archived, shared, flagged }

    /// A host whose state the menu reads on each open (a reference, so a test can change it after the capture).
    private final class FilterHost {
        var filters: Set<Filter>

        init(_ filters: Set<Filter>) {
            self.filters = filters
        }
    }

    private static func actions(of section: LMKMenu.Section) throws -> [UIAction] {
        try #require(section.makeMenu().children as? [UIAction])
    }

    @Test
    func `A single section checks the chosen row and reports a tap`() throws {
        var layout = Layout.list
        let section = LMKMenu.Section.single(
            title: "Layout",
            options: [.init(id: Layout.list, title: "List", systemImageName: "list.bullet"), .init(id: .grid, title: "Grid", subtitle: "Two columns", isEnabled: false)],
            selected: { layout },
            onSelect: { layout = $0 }
        )
        let menu = section.makeMenu()
        #expect(menu.title == "Layout")
        #expect(menu.options.contains(.displayInline) && menu.options.contains(.singleSelection))
        let actions = try Self.actions(of: section)
        #expect(actions.map(\.state) == [.on, .off])
        #expect(actions[0].image == UIImage(systemName: "list.bullet"))
        #expect(actions[1].subtitle == "Two columns")
        #expect(actions[1].attributes.contains(.disabled))
        #expect(!actions[0].attributes.contains(.keepsMenuPresented))
        actions[1].performWithSender(nil, target: nil)
        #expect(layout == .grid)
        // The next open reads the host's state again.
        #expect(try Self.actions(of: section).map(\.state) == [.off, .on])
    }

    @Test
    func `A multiple section toggles rows in place and keeps the menu open`() throws {
        var filters: Set<Filter> = [.shared]
        let section = LMKMenu.Section.multiple(
            title: "Show",
            options: [.init(id: Filter.archived, title: "Archived"), .init(id: .shared, title: "Shared"), .init(id: .flagged, title: "Flagged")],
            selected: { filters },
            onToggle: { filter, isOn in
                if isOn { filters.insert(filter) } else { filters.remove(filter) }
            }
        )
        #expect(!section.makeMenu().options.contains(.singleSelection))
        let actions = try Self.actions(of: section)
        #expect(actions.map(\.state) == [.off, .on, .off])
        #expect(actions.allSatisfy { $0.attributes.contains(.keepsMenuPresented) })
        actions[0].performWithSender(nil, target: nil)
        actions[1].performWithSender(nil, target: nil)
        #expect(filters == [.archived])
        #expect(actions.map(\.state) == [.on, .off, .off], "the open menu shows the new checkmarks")
        actions[0].performWithSender(nil, target: nil)
        #expect(filters.isEmpty)

        let closing = LMKMenu.Section.multiple(options: [.init(id: Filter.archived, title: "Archived")], keepsMenuOpen: false, selected: { [] }, onToggle: { _, _ in })
        #expect(try Self.actions(of: closing).allSatisfy { !$0.attributes.contains(.keepsMenuPresented) })
    }

    @Test
    func `A toggle reports from the host's state, so a row that is not rebuilt still alternates`() throws {
        var filters: Set<Filter> = []
        var reported: [Bool] = []
        let section = LMKMenu.Section.multiple(
            options: [.init(id: Filter.archived, title: "Archived")],
            selected: { filters },
            onToggle: { filter, isOn in
                reported.append(isOn)
                if isOn { filters.insert(filter) } else { filters.remove(filter) }
            }
        )
        // A nested copy UIKit does not repaint: the same row is tapped three times.
        let row = try #require(Self.actions(of: section).first)
        row.performWithSender(nil, target: nil)
        row.state = .off
        row.performWithSender(nil, target: nil)
        row.performWithSender(nil, target: nil)
        #expect(reported == [true, false, true])
        #expect(filters == [.archived])

        // The host's state wins over a stale row: a row showing "on" for a filter the host dropped turns it on.
        filters = []
        row.state = .on
        row.performWithSender(nil, target: nil)
        #expect(reported.last == true)
        #expect(row.state == .on)
    }

    @Test
    func `An actions section runs commands and marks destructive and disabled rows`() throws {
        var ran: [String] = []
        let section = LMKMenu.Section.actions([
            .init(title: "Select", systemImageName: "checkmark.circle") { ran.append("select") },
            .init(title: "Delete All", isDestructive: true) { ran.append("delete") },
            .init(title: "Export", isEnabled: false) { ran.append("export") },
        ])
        let actions = try Self.actions(of: section)
        #expect(actions.map(\.title) == ["Select", "Delete All", "Export"])
        #expect(actions[1].attributes.contains(.destructive))
        #expect(actions[2].attributes.contains(.disabled))
        #expect(actions.allSatisfy { $0.state == .off })
        actions[0].performWithSender(nil, target: nil)
        actions[1].performWithSender(nil, target: nil)
        #expect(ran == ["select", "delete"])
    }

    @Test
    func `A submenu nests its sections behind one row, and custom passes elements through`() throws {
        let nested = LMKMenu.Section.submenu(title: "Group By", systemImageName: "square.stack", sections: [
            .single(options: [.init(id: 1, title: "Kind"), .init(id: 2, title: "Date")], selected: { 2 }, onSelect: { _ in }),
        ])
        let menu = nested.makeMenu()
        #expect(menu.title == "Group By")
        #expect(menu.image == UIImage(systemName: "square.stack"))
        #expect(!menu.options.contains(.displayInline), "a submenu is a row, not an inline group")
        let inner = try #require(menu.children.first as? UIMenu)
        #expect((inner.children as? [UIAction])?.map(\.state) == [.off, .on])

        let custom = LMKMenu.Section.custom(title: "More") { [UIAction(title: "Raw") { _ in }] }
        #expect(custom.makeMenu().children.count == 1)
    }

    @Test
    func `make defers the sections so every open rebuilds them`() {
        var builds = 0
        let menu = LMKMenu.make(title: "Options", sections: [.custom { builds += 1; return [] }])
        #expect(menu.title == "Options")
        #expect(menu.children.count == 1)
        #expect(menu.children.first is UIDeferredMenuElement)
        #expect(builds == 0, "nothing is built until the menu opens")
        _ = LMKMenu.makeElements(sections: [.custom { builds += 1; return [] }])
        #expect(builds == 1)
    }

    @Test
    func `Anchors carry the glyph at the anchor size and the label`() {
        let menu = LMKMenu.make(sections: [])
        let barItem = LMKMenu.makeBarButtonItem(menu: menu, systemImageName: "ellipsis", accessibilityLabel: "Options")
        #expect(barItem.image == UIImage(systemName: "ellipsis", withConfiguration: LMKMenu.anchorSymbolConfiguration))
        #expect(barItem.accessibilityLabel == "Options")
        #expect(barItem.menu != nil)

        let navItem = LMKMenu.makeNavigationBarItem(identifier: "options", menu: menu, systemImageName: "ellipsis", accessibilityLabel: "Options")
        #expect(navItem.identifier == "options")
        #expect(navItem.menu === menu)

        let button = LMKMenu.makeButton(menu: menu, systemImageName: "line.3.horizontal.decrease", accessibilityLabel: "Filter")
        #expect(button.showsMenuAsPrimaryAction)
        #expect(button.accessibilityLabel == "Filter")
        #expect(button.style.variant == .tinted)
        #expect(button.style.symbolPointSize == LMKLayout.symbolRow)
        button.frame.size = button.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        #expect(button.bounds.width < 40)
        #expect(button.point(inside: CGPoint(x: -4, y: button.bounds.midY), with: nil), "the hit target stays 44pt")

        let ghost = LMKMenu.makeButton(menu: menu, systemImageName: "ellipsis", accessibilityLabel: "More", style: .ghost(.neutral))
        #expect(ghost.style.variant == .ghost)
        #expect(ghost.style.role == .neutral)
    }

    // MARK: - Reloading the open menu

    private static func filterSection(_ filters: @escaping @MainActor () -> Set<Filter>, onToggle: @escaping @MainActor (Filter, Bool) -> Void = { _, _ in }) -> LMKMenu.Section {
        .multiple(
            title: "Show",
            options: [.init(id: Filter.archived, title: "Archived"), .init(id: .shared, title: "Shared")],
            selected: filters,
            onToggle: onToggle
        )
    }

    @Test
    func `A section keeps its identifier across rebuilds`() {
        let section = Self.filterSection { [] }
        #expect(section.makeMenu().identifier == section.makeMenu().identifier)
        #expect(Self.filterSection { [] }.makeMenu().identifier != section.makeMenu().identifier)
    }

    @Test
    func `An open menu is rebuilt from the host's state`() throws {
        let host = FilterHost([.shared])
        let root = LMKMenu.Root(title: "Options", sections: [Self.filterSection { host.filters }])
        let menu = root.makeMenu()
        #expect(menu.identifier == root.identifier)
        #expect(menu.title == "Options")

        // What UIKit shows: the root with the rows it resolved when the menu opened.
        let visible = menu.replacingChildren(LMKMenu.makeElements(sections: root.sections))
        host.filters = [.archived]
        let refreshed = try #require(root.refreshed(visible))
        #expect(refreshed.identifier == root.identifier)
        let rows = try #require((refreshed.children.first as? UIMenu)?.children as? [UIAction])
        #expect(rows.map(\.state) == [.on, .off], "changing the tapped action's state does not repaint an open menu; rebuilding it does")
    }

    @Test
    func `An open submenu is rebuilt in place`() throws {
        let host = FilterHost([])
        let inner = Self.filterSection { host.filters }
        let submenu = LMKMenu.Section.submenu(title: "More", sections: [inner])
        let root = LMKMenu.Root(title: "", sections: [submenu])

        let visibleSubmenu = submenu.makeMenu()
        host.filters = [.shared]
        let refreshed = try #require(root.refreshed(visibleSubmenu))
        #expect(refreshed.identifier == visibleSubmenu.identifier)
        let rows = try #require((refreshed.children.first as? UIMenu)?.children as? [UIAction])
        #expect(rows.map(\.state) == [.off, .on])

        // A menu from elsewhere is left alone.
        #expect(root.refreshed(UIMenu(title: "Other", children: [])) == nil)
    }

    @Test
    func `A bar button's open menu is replaced by a fresh one with the same identifier`() throws {
        let menu = LMKMenu.make(title: "Options", sections: [Self.filterSection { [] }])
        let item = LMKMenu.makeBarButtonItem(menu: menu, systemImageName: "ellipsis", accessibilityLabel: "Options")
        let before = try #require(item.menu)
        LMKMenu.reloadVisibleMenu(presentedFrom: item)
        let after = try #require(item.menu)
        #expect(after.identifier == before.identifier)
        #expect(after.title == "Options")

        // A menu LMKMenu did not make stays as it is.
        let foreign = UIBarButtonItem(title: "Other", menu: UIMenu(title: "Foreign", children: []))
        LMKMenu.reloadVisibleMenu(presentedFrom: foreign)
        #expect(foreign.menu?.title == "Foreign")
    }

    @Test
    func `Reloading from a button or from nothing is safe without an open menu`() {
        let menu = LMKMenu.make(sections: [Self.filterSection { [] }])
        let button = LMKMenu.makeButton(menu: menu, systemImageName: "ellipsis", accessibilityLabel: "More")
        LMKMenu.reloadVisibleMenu(presentedFrom: button)
        LMKMenu.reloadVisibleMenu(presentedFrom: nil)
        LMKMenu.reloadVisibleMenu(presentedFrom: UIView())
        #expect(button.menu?.identifier == menu.identifier)
    }
}
