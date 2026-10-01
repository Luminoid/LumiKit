//
//  EnumPickerExample.swift
//  LumiKitExample
//
//  Enum Picker: LMKEnumPicker: single and multiple choice.
//

import LumiKitUI
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

final class EnumPickerDetailViewController: DetailViewController {
    private var currentSort: SortOption = .name
    private var currentTheme: ThemeOption = .system
    private var activeFilters: Set<FilterOption> = [.photos, .favorites]

    private lazy var sortButton = LMKButton(title: "Sort By: Name", style: .filled(.primary), target: self, action: #selector(showSortSheet))
    private lazy var themeButton = LMKButton(title: "Theme: System", style: .filled(.secondary), target: self, action: #selector(showThemeSheet))
    private lazy var filterButton = LMKButton(title: "Filters: 2 active", style: .filled(.primary), target: self, action: #selector(showFilterSheet))
    private lazy var iconFilterButton = LMKButton(title: "Filters (icons): 2 active", style: .filled(.secondary), target: self, action: #selector(showIconFilterSheet))

    override func setupStackContent() {
        addSectionHeader("Single Select (No Icons)")
        stackView.addArrangedSubview(UILabel.lmk_make(.caption, text: "A T? selection is single-select: a tap commits and dismisses. showsIcons: false hides the option icons."))
        stackView.addArrangedSubview(sortButton)

        addDivider()
        addSectionHeader("Single Select (With Icons and Search)")
        stackView.addArrangedSubview(UILabel.lmk_make(.caption, text: "Icons show by default when the enum provides iconName. showsSearch adds a filter field; disabledOptions dims rows."))
        stackView.addArrangedSubview(themeButton)

        addDivider()
        addSectionHeader("Multi-Select")
        stackView.addArrangedSubview(UILabel.lmk_make(.caption, text: "A Set<T> selection is multi-select: taps toggle, Done commits, Cancel discards."))
        stackView.addArrangedSubview(filterButton)

        addDivider()
        addSectionHeader("Multi-Select (Custom Done)")
        stackView.addArrangedSubview(UILabel.lmk_make(.caption, text: "Multi-select with a custom Done title."))
        stackView.addArrangedSubview(iconFilterButton)
    }

    @objc private func showSortSheet() {
        LMKEnumPicker.present(from: self, title: "Sort By", options: SortOption.allCases, selection: currentSort, showsIcons: false) { [weak self] option in
            guard let self else { return }
            currentSort = option
            sortButton.title = "Sort By: \(option.displayName)"
            LMKToast.show(.success, "Sort: \(option.displayName)", in: self)
        }
    }

    @objc private func showThemeSheet() {
        LMKEnumPicker.present(from: self, title: "Appearance", options: ThemeOption.allCases, selection: currentTheme, disabledOptions: [.dark], showsSearch: true) { [weak self] option in
            guard let self else { return }
            currentTheme = option
            themeButton.title = "Theme: \(option.displayName)"
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
        filterButton.title = "Filters: \(selection.count) active"
        iconFilterButton.title = "Filters (icons): \(selection.count) active"
        let names = selection.map(\.displayName).sorted().joined(separator: ", ")
        LMKToast.show(.success, names.isEmpty ? "No filters" : names, in: self)
    }
}
