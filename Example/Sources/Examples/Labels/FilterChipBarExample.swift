//
//  FilterChipBarExample.swift
//  LumiKitExample
//
//  Filter Chip Bar: Single or multiple selection with an optional All chip.
//

import LumiKitUI
import SnapKit
import UIKit

// MARK: - Filter Chip Bar

final class FilterChipBarDetailViewController: DetailViewController {
    private let selectionLabel = UILabel.lmk_make(.body, text: "Selected: All")
    private let multiSelectionLabel = UILabel.lmk_make(.body, text: "Selected: filter indices 0, 2")

    override func setupStackContent() {
        addSectionHeader("With All Chip")
        stackView.addArrangedSubview(UILabel.lmk_make(.caption, text: "An 'All' chip is prepended; tapping it clears the selection and fires with an empty set."))

        let withAll = LMKFilterChipBar()
        withAll.configure(allTitle: "All", filterTitles: ["Photos", "Notes", "Tasks", "Links", "Files"])
        withAll.onSelectionChange = { [weak self] indices in
            self?.selectionLabel.lmk_setText(indices.isEmpty ? "Selected: All" : "Selected: filter index \(indices.sorted().map(String.init).joined(separator: ", "))")
        }
        withAll.snp.makeConstraints { $0.height.equalTo(LMKLayout.minimumTouchTarget) }
        stackView.addArrangedSubview(withAll)
        stackView.addArrangedSubview(selectionLabel)

        addDivider()
        addSectionHeader("Without All Chip")
        stackView.addArrangedSubview(UILabel.lmk_make(
            .caption,
            text: "Omit `allTitle` for a pure filter row; the initial state has no selection, and re-tapping the selected chip clears it (`.single(allowsEmpty: true)`)."
        ))

        let withoutAll = LMKFilterChipBar()
        withoutAll.configure(filterTitles: ["Today", "Week", "Month", "Year"])
        withoutAll.snp.makeConstraints { $0.height.equalTo(LMKLayout.minimumTouchTarget) }
        stackView.addArrangedSubview(withoutAll)

        addDivider()
        addSectionHeader("Filled Chips + Preselected")
        stackView.addArrangedSubview(UILabel.lmk_make(
            .caption,
            text: "`style.chip = .filled`: the selected chip carries the full tint and the others a soft wash of it. `setSelection(_:)` seeds the selection silently."
        ))

        let filled = LMKFilterChipBar(style: LMKFilterChipBar.Style(chip: .filled))
        filled.configure(allTitle: "All", filterTitles: ["Draft", "In Review", "Published"])
        filled.setSelection([1])
        filled.snp.makeConstraints { $0.height.equalTo(LMKLayout.minimumTouchTarget) }
        stackView.addArrangedSubview(filled)

        addDivider()
        addSectionHeader("With Icons")
        stackView.addArrangedSubview(UILabel.lmk_make(.caption, text: "`Item(title:icon:)` carries an optional leading icon; the 'All' chip never has one."))

        let icons = LMKFilterChipBar()
        icons.configure(
            items: [
                .init(title: "Photos", icon: UIImage(systemName: "photo")),
                .init(title: "Notes", icon: UIImage(systemName: "note.text")),
                .init(title: "Tasks", icon: UIImage(systemName: "checkmark.circle")),
                .init(title: "Links"),
            ],
            allTitle: "All"
        )
        icons.snp.makeConstraints { $0.height.equalTo(LMKLayout.minimumTouchTarget) }
        stackView.addArrangedSubview(icons)

        addDivider()
        addSectionHeader("Multi-Select")
        stackView.addArrangedSubview(UILabel.lmk_make(.caption, text: "`selectionMode = .multiple` toggles chips additively. The 'All' chip clears the set and highlights while it's empty."))

        let multi = LMKFilterChipBar()
        multi.selectionMode = .multiple
        multi.configure(allTitle: "All", filterTitles: ["Photos", "Notes", "Tasks", "Links"])
        multi.onSelectionChange = { [weak self] indices in
            self?.multiSelectionLabel.lmk_setText(indices.isEmpty
                ? "Selected: none (show all)"
                : "Selected: filter indices \(indices.sorted().map(String.init).joined(separator: ", "))")
        }
        multi.setSelection([0, 2])
        multi.snp.makeConstraints { $0.height.equalTo(LMKLayout.minimumTouchTarget) }
        stackView.addArrangedSubview(multi)
        stackView.addArrangedSubview(multiSelectionLabel)
    }
}
