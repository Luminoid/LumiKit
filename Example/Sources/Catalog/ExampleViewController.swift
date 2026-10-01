//
//  ExampleViewController.swift
//  LumiKitExample
//
//  The catalog list: the sections of `ExampleCatalog`, a search field that
//  filters pages by name or type, and the About rows.
//

import LumiKitUI
import SnapKit
import UIKit

// MARK: - About Section

private struct InfoItem {
    let title: String
    let detail: String
    let iconName: String
    let isLink: Bool

    init(_ title: String, detail: String, iconName: String, isLink: Bool = false) {
        self.title = title
        self.detail = detail
        self.iconName = iconName
        self.isLink = isLink
    }
}

private let aboutItems: [InfoItem] = [
    InfoItem("Version", detail: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—", iconName: "tag"),
    InfoItem("GitHub", detail: "Luminoid/LumiKit", iconName: "link", isLink: true),
    InfoItem("Platform", detail: "iOS 18+ · Mac Catalyst 18+", iconName: "iphone"),
    InfoItem("Swift", detail: "6.2 · Strict Concurrency", iconName: "swift"),
    InfoItem("License", detail: "MIT", iconName: "doc.text"),
]

// MARK: - ExampleViewController

final class ExampleViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchResultsUpdating {
    // MARK: - Properties

    private static let githubURL = URL(string: "https://github.com/Luminoid/LumiKit")

    /// The catalog sections on screen: all of them, or the ones the search matches.
    private var sections = exampleSections
    private var isSearching = false

    private lazy var tableView = LMKListTable.makeInsetGrouped(dataSource: self, delegate: self)

    private lazy var searchController: UISearchController = {
        let controller = UISearchController(searchResultsController: nil)
        controller.searchResultsUpdater = self
        controller.obscuresBackgroundDuringPresentation = false
        controller.searchBar.placeholder = "Search \(ExampleCatalog.pages.count) pages"
        return controller
    }()

    private let emptyStateView = LMKEmptyStateView(style: .fullScreen)

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        // The theme is applied once by the app delegate, before any scene connects.
        title = "LumiKit"
        view.backgroundColor = LMKColor.backgroundPrimary
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true

        tableView.keyboardDismissMode = .onDrag
        view.addSubview(tableView)
        tableView.snp.makeConstraints { $0.edges.equalToSuperview() }

        emptyStateView.isHidden = true
        view.addSubview(emptyStateView)
        emptyStateView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.equalTo(view.safeAreaLayoutGuide).inset(LMKSpacing.large)
        }
    }

    // MARK: - Search

    func updateSearchResults(for searchController: UISearchController) {
        let query = searchController.searchBar.text ?? ""
        sections = ExampleCatalog.sections(matching: query)
        isSearching = !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        emptyStateView.configure(LMKEmptyStateView.Content(title: "No pages", message: "Nothing in the catalog matches \"\(query)\".", icon: .system("magnifyingglass")))
        emptyStateView.isHidden = !sections.isEmpty
        tableView.reloadData()
    }

    // MARK: - Data Source

    /// The About rows follow the catalog, except while searching.
    private var aboutSectionIndex: Int? { isSearching ? nil : sections.count }

    func numberOfSections(in tableView: UITableView) -> Int {
        sections.count + (isSearching ? 0 : 1)
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        section == aboutSectionIndex ? "About" : sections[section].title
    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        section == aboutSectionIndex || isSearching ? nil : sections[section].summary
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        section == aboutSectionIndex ? aboutItems.count : sections[section].items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: LMKListTable.cellReuseIdentifier, for: indexPath)

        if indexPath.section == aboutSectionIndex {
            let info = aboutItems[indexPath.row]
            cell.lmk_applyListRow(LMKListRowConfiguration(
                title: info.title,
                detail: info.detail,
                leading: .symbol(info.iconName, tint: LMKColor.textSecondary),
                trailing: info.isLink ? .disclosure : .none,
                style: LMKListRowConfiguration.Style(detailTextStyle: .body, detailColor: info.isLink ? LMKColor.primary : LMKColor.textSecondary)
            ), backgroundColor: LMKColor.backgroundSecondary)
            // lmk_applyListRow makes every enabled row selectable; the plain About rows do nothing on tap.
            if !info.isLink {
                cell.selectionStyle = .none
            }
            return cell
        }

        let item = sections[indexPath.section].items[indexPath.row]
        cell.lmk_applyListRow(
            LMKListRowConfiguration(title: item.title, subtitle: item.subtitle, leading: .symbol(item.iconName)),
            backgroundColor: LMKColor.backgroundSecondary
        )
        return cell
    }

    // MARK: - Delegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        if indexPath.section == aboutSectionIndex {
            guard aboutItems[indexPath.row].isLink, let url = Self.githubURL else { return }
            UIApplication.shared.open(url)
            return
        }

        let item = sections[indexPath.section].items[indexPath.row]
        let detail = item.makeViewController()
        detail.title = item.title
        navigationController?.pushViewController(detail, animated: true)
    }
}
