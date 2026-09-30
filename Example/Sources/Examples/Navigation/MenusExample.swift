//
//  MenusExample.swift
//  LumiKitExample
//
//  Menus: LMKMenu: choices, toggles, commands, submenus; LMKSortMenu.
//

import LumiKitUI
import UIKit

// MARK: - Menus

final class MenusDetailViewController: DetailViewController {
    private enum Sort: Hashable, CaseIterable { case name, date, kind }
    private enum Layout: Hashable { case list, grid }
    private enum Filter: String, Hashable, CaseIterable { case archived = "Archived", shared = "Shared", flagged = "Flagged" }
    private enum Grouping: String, Hashable, CaseIterable { case none = "None", kind = "Kind", month = "Month" }

    private var sort = Sort.name
    private var direction = LMKSortMenu.Direction.ascending
    private var layout = Layout.list
    private var filters: Set<Filter> = [.shared]
    private var grouping = Grouping.none
    private let sortReadout = UILabel.lmk_make(.body)
    private let optionsReadout = UILabel.lmk_make(.body)

    private lazy var sortMenu = LMKSortMenu.makeMenu(
        sortOptions: [.init(id: Sort.name, title: "Name"), .init(id: .date, title: "Date added"), .init(id: .kind, title: "Kind")],
        layoutOptions: [.init(id: Layout.list, title: "List", systemImageName: "list.bullet"), .init(id: .grid, title: "Grid", systemImageName: "square.grid.2x2")],
        state: { [weak self] in .init(selectedSort: self?.sort, direction: self?.direction ?? .ascending, selectedLayout: self?.layout) },
        onSelectSort: { [weak self] sort, direction in
            self?.sort = sort
            self?.direction = direction
            self?.updateReadouts()
        },
        onSelectLayout: { [weak self] layout in
            self?.layout = layout
            self?.updateReadouts()
        }
    )

    private lazy var optionsMenu = LMKMenu.make(sections: [
        .multiple(
            title: "Show",
            options: Filter.allCases.map { .init(id: $0, title: $0.rawValue) },
            selected: { [weak self] in self?.filters ?? [] },
            onToggle: { [weak self] filter, isOn in
                if isOn { self?.filters.insert(filter) } else { self?.filters.remove(filter) }
                self?.updateReadouts()
            }
        ),
        .submenu(title: "Group By", systemImageName: "square.stack", sections: [
            .single(
                options: Grouping.allCases.map { .init(id: $0, title: $0.rawValue) },
                selected: { [weak self] in self?.grouping },
                onSelect: { [weak self] grouping in
                    self?.grouping = grouping
                    self?.updateReadouts()
                }
            ),
        ]),
        .actions([
            .init(title: "Select Items", systemImageName: "checkmark.circle") { [weak self] in self?.toast("Select Items") },
            .init(title: "Export", subtitle: "Nothing to export yet", systemImageName: "square.and.arrow.up", isEnabled: false) {},
            .init(title: "Delete All", systemImageName: "trash", isDestructive: true) { [weak self] in self?.toast("Delete All") },
        ]),
    ])

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItems = [
            LMKMenu.makeBarButtonItem(menu: optionsMenu, systemImageName: "ellipsis", accessibilityLabel: "Options"),
            LMKSortMenu.makeBarButtonItem(menu: sortMenu),
        ]

        addSectionHeader("LMKMenu")
        stack.addArrangedSubview(UILabel.lmk_make(
            .caption,
            text: "Native UIMenus from sections: single choices, toggles that flip in place while the menu stays open, sorts with a direction, commands, and submenus. "
                + "Every section reads the screen's state when the menu opens and after each toggle. Anchors natively on iPad and Mac. Try the bar buttons above or the buttons below."
        ))
        stack.addArrangedSubview(optionsReadout)
        let filterButton = LMKMenu.makeButton(menu: optionsMenu, systemImageName: "line.3.horizontal.decrease", accessibilityLabel: "Options")
        let moreButton = LMKMenu.makeButton(menu: optionsMenu, systemImageName: "ellipsis", accessibilityLabel: "More", style: .ghost(.neutral))
        let titled = LMKButton(title: "Options", style: LMKButton.Style(variant: .tinted, size: .small, showsMenuIndicator: true))
        titled.menu = optionsMenu
        titled.showsMenuAsPrimaryAction = true
        stack.addArrangedSubview(UIStackView(lmk_axis: .horizontal, spacing: LMKSpacing.medium, alignment: .center, arrangedSubviews: [filterButton, moreButton, titled, UIView()]))

        addDivider()
        addSectionHeader("LMKSortMenu")
        stack.addArrangedSubview(UILabel.lmk_make(
            .caption,
            text: "The sort menu is LMKMenu with a sort section and an optional layout section: "
                + "the selected row carries a live direction arrow and stays open when tapped again, other rows select ascending and close."
        ))
        stack.addArrangedSubview(sortReadout)
        let sortButton = LMKSortMenu.makeButton(menu: sortMenu, style: .tinted())
        let plainSortButton = LMKSortMenu.makeButton(menu: sortMenu)
        stack.addArrangedSubview(UIStackView(lmk_axis: .horizontal, spacing: LMKSpacing.medium, alignment: .center, arrangedSubviews: [sortButton, plainSortButton, UIView()]))
        updateReadouts()
    }

    private func updateReadouts() {
        let sortName = switch sort {
        case .name: "Name"
        case .date: "Date added"
        case .kind: "Kind"
        }
        sortReadout.text = "Sort: \(sortName) \(direction == .ascending ? "↑" : "↓") · Layout: \(layout == .list ? "List" : "Grid")"
        let shown = Filter.allCases.filter(filters.contains).map(\.rawValue).joined(separator: ", ")
        optionsReadout.text = "Show: \(shown.isEmpty ? "nothing extra" : shown) · Group by: \(grouping.rawValue)"
    }

    private func toast(_ message: String) {
        LMKToast.show(.info, message, in: self)
    }
}
