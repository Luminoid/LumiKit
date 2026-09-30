//
//  SearchBarExample.swift
//  LumiKitExample
//
//  Search Bar: LMKSearchBar with cancel, debounce, and focus.
//

import LumiKitUI
import SnapKit
import UIKit

// MARK: - Search Bar

final class SearchBarDetailViewController: DetailViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        addSectionHeader("Basic")
        stack.addArrangedSubview(UILabel.lmk_make(.caption, text: "Uses backgroundTertiary, best visible on grouped/secondary backgrounds."))
        let basicBar = LMKSearchBar()
        basicBar.placeholder = "Search items..."
        stack.addArrangedSubview(basicBar)

        addDivider()
        addSectionHeader("Closures and debounce")
        let readout = LMKStatusLabel()
        let debouncedBar = LMKSearchBar()
        debouncedBar.placeholder = "Type to search"
        debouncedBar.debounceInterval = 0.4
        debouncedBar.onTextChange = { text in readout.show(text.isEmpty ? "Typing…" : "Typing: \(text)") }
        debouncedBar.onDebouncedTextChange = { text in readout.show(text.isEmpty ? "Cleared" : "Searched: \(text)", status: .success) }
        debouncedBar.onSearch = { text in readout.show("Return: \(text)", status: .info) }
        debouncedBar.onCancel = { readout.clear() }
        stack.addArrangedSubview(debouncedBar)
        stack.addArrangedSubview(readout)

        addDivider()
        addSectionHeader("Always-visible cancel, custom style")
        let styledBar = LMKSearchBar(style: LMKSearchBar.Style(surface: LMKSurfaceStyle(corners: .capsule, border: .solid()), iconTint: LMKColor.primary))
        styledBar.placeholder = "Capsule with outline"
        styledBar.cancelButtonMode = .always
        stack.addArrangedSubview(styledBar)

        addDivider()
        addSectionHeader("On Secondary Background")
        let container = UIView()
        container.backgroundColor = LMKColor.backgroundSecondary
        container.layer.cornerRadius = LMKCornerRadius.medium

        let searchBar = LMKSearchBar()
        searchBar.placeholder = "Search items..."
        container.addSubview(searchBar)
        searchBar.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(LMKSpacing.medium)
        }
        stack.addArrangedSubview(container)
    }
}
