//
//  EnumSelectionExample.swift
//  LumiKitExample
//
//  Enum Selection: LMKEnumPicker: single and multiple choice.
//

import LumiKitUI
import SnapKit
import UIKit

// MARK: - Enum Picker

private enum SortOption: String, CaseIterable, LMKEnumSelectable {
    case dateAdded, name, category, priority

    var displayName: String {
        switch self {
        case .dateAdded: "Date Added"
        case .name: "Name"
        case .category: "Category"
        case .priority: "Priority"
        }
    }

    var iconName: String? {
        switch self {
        case .dateAdded: "calendar"
        case .name: "textformat.abc"
        case .category: "folder"
        case .priority: "flag"
        }
    }
}

private enum ThemeOption: String, CaseIterable, LMKEnumSelectable {
    case system, light, dark

    var displayName: String {
        switch self {
        case .system: "System"
        case .light: "Light"
        case .dark: "Dark"
        }
    }

    var iconName: String? {
        switch self {
        case .system: "gear"
        case .light: "sun.max"
        case .dark: "moon"
        }
    }
}

private enum FilterOption: String, CaseIterable, LMKEnumSelectable {
    case photos, notes, favorites, archived

    var displayName: String {
        switch self {
        case .photos: "Has Photos"
        case .notes: "Has Notes"
        case .favorites: "Favorites"
        case .archived: "Archived"
        }
    }

    var iconName: String? {
        switch self {
        case .photos: "photo"
        case .notes: "note.text"
        case .favorites: "star"
        case .archived: "archivebox"
        }
    }
}

final class EnumSelectionDetailViewController: DetailViewController {
    private var currentSort: SortOption = .name
    private var currentTheme: ThemeOption = .system
    private var activeFilters: Set<FilterOption> = [.photos, .favorites]

    override func viewDidLoad() {
        super.viewDidLoad()

        addSectionHeader("Single Select (No Icons)")
        stack.addArrangedSubview(UILabel.lmk_make(.caption, text: "A T? selection is single-select: a tap commits and dismisses. showsIcons: false hides the option icons."))
        let sortButton = LMKButton(title: "Sort By: Name", style: .filled(.primary), target: self, action: #selector(showSortSheet))
        sortButton.tag = 1
        stack.addArrangedSubview(sortButton)

        addDivider()
        addSectionHeader("Single Select (With Icons and Search)")
        stack.addArrangedSubview(UILabel.lmk_make(.caption, text: "Icons show by default when the enum provides iconName. showsSearch adds a filter field; disabledOptions dims rows."))
        let themeButton = LMKButton(title: "Theme: System", style: .filled(.secondary), target: self, action: #selector(showThemeSheet))
        themeButton.tag = 2
        stack.addArrangedSubview(themeButton)

        addDivider()
        addSectionHeader("Multi-Select")
        stack.addArrangedSubview(UILabel.lmk_make(.caption, text: "A Set<T> selection is multi-select: taps toggle, Done commits, Cancel discards."))
        let filterButton = LMKButton(title: "Filters: 2 active", style: .filled(.primary), target: self, action: #selector(showFilterSheet))
        filterButton.tag = 3
        stack.addArrangedSubview(filterButton)

        addDivider()
        addSectionHeader("Multi-Select (Custom Done)")
        stack.addArrangedSubview(UILabel.lmk_make(.caption, text: "Multi-select with a custom Done title."))
        let iconFilterButton = LMKButton(title: "Filters (icons): 2 active", style: .filled(.secondary), target: self, action: #selector(showIconFilterSheet))
        iconFilterButton.tag = 4
        stack.addArrangedSubview(iconFilterButton)
    }

    @objc private func showSortSheet() {
        LMKEnumPicker.present(from: self, title: "Sort By", options: SortOption.allCases, selection: currentSort, showsIcons: false) { [weak self] option in
            guard let self else { return }
            currentSort = option
            (view.viewWithTag(1) as? LMKButton)?.title = "Sort By: \(option.displayName)"
            LMKToast.show(.success, "Sort: \(option.displayName)", in: self)
        }
    }

    @objc private func showThemeSheet() {
        LMKEnumPicker.present(from: self, title: "Appearance", options: ThemeOption.allCases, selection: currentTheme, disabledOptions: [.dark], showsSearch: true) { [weak self] option in
            guard let self else { return }
            currentTheme = option
            (view.viewWithTag(2) as? LMKButton)?.title = "Theme: \(option.displayName)"
            LMKToast.show(.success, "Theme: \(option.displayName)", in: self)
        }
    }

    @objc private func showFilterSheet() {
        LMKEnumPicker.present(from: self, title: "Filter By", options: FilterOption.allCases, selection: activeFilters, showsIcons: false) { [weak self] selection in
            self?.applyFilters(selection)
        }
    }

    @objc private func showIconFilterSheet() {
        LMKEnumPicker.present(from: self, title: "Filter By", options: FilterOption.allCases, selection: activeFilters, doneTitle: "Apply Filters") { [weak self] selection in
            self?.applyFilters(selection)
        }
    }

    private func applyFilters(_ selection: Set<FilterOption>) {
        activeFilters = selection
        (view.viewWithTag(3) as? LMKButton)?.title = "Filters: \(selection.count) active"
        (view.viewWithTag(4) as? LMKButton)?.title = "Filters (icons): \(selection.count) active"
        let names = selection.map(\.displayName).sorted().joined(separator: ", ")
        LMKToast.show(.success, names.isEmpty ? "No filters" : names, in: self)
    }
}
