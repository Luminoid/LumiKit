//
//  ListRowExample.swift
//  LumiKitExample
//
//  List Row: LMKListRowConfiguration: symbol or thumbnail, text, accessories.
//

import LumiKitUI
import SnapKit
import UIKit

// MARK: - List Row

/// A full-screen list, the way a settings or index screen uses the rows.
final class ListRowDetailViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private enum Section: Int, CaseIterable {
        case rows
        case compact
        case system
    }

    private var notificationsOn = true

    private lazy var thumbnail: UIImage = {
        let size = CGSize(width: 120, height: 120)
        return UIGraphicsImageRenderer(size: size).image { context in
            LMKColor.secondary.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            LMKColor.onAccent.setFill()
            context.cgContext.fillEllipse(in: CGRect(x: 30, y: 30, width: 60, height: 60))
        }
    }()

    private lazy var rows: [LMKListRowConfiguration] = [
        LMKListRowConfiguration(title: "General", subtitle: "Language, appearance, units", leading: .symbol("gearshape")),
        LMKListRowConfiguration(title: "Destinations", subtitle: "Tokyo, Kyoto, Osaka", detail: "3", leading: .symbol("mappin.and.ellipse", tint: LMKColor.success)),
        LMKListRowConfiguration(title: "Kibble", subtitle: "Harbor Pet Foods", detail: "$42", leading: .image(thumbnail)),
        LMKListRowConfiguration(title: "Loaded later", subtitle: "asyncImage with a placeholder", leading: .asyncImage(id: "sample") { [thumbnail] _ in
            try? await Task.sleep(for: .seconds(1))
            return thumbnail
        }),
        LMKListRowConfiguration(title: "Inbox", leading: .symbol("tray"), trailing: .badge(.count(4))),
        LMKListRowConfiguration(title: "Selected plan", leading: .symbol("checkmark.seal", tint: LMKColor.info), trailing: .checkmark),
        LMKListRowConfiguration(title: "Archived", subtitle: "Disabled row", leading: .symbol("archivebox"), isEnabled: false),
    ]

    /// Text-only rows at the compact height, and one with a custom style.
    private lazy var compactRows: [LMKListRowConfiguration] = [
        LMKListRowConfiguration(title: "About"),
        LMKListRowConfiguration(title: "Version", detail: "1.0.0", trailing: .none),
        LMKListRowConfiguration(
            title: "Roomy row",
            subtitle: "contentInsets and textSpacing from Style",
            leading: .symbol("arrow.up.and.down", tint: LMKColor.tertiary),
            style: LMKListRowConfiguration.Style(
                textSpacing: LMKSpacing.xs,
                contentInsets: NSDirectionalEdgeInsets(top: LMKSpacing.large, leading: LMKSpacing.large, bottom: LMKSpacing.large, trailing: LMKSpacing.large)
            )
        ),
    ]

    private lazy var tableView = LMKListTable.makeInsetGrouped(dataSource: self, delegate: self)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = LMKColor.backgroundPrimary
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    // MARK: - UITableViewDataSource

    func numberOfSections(in _: UITableView) -> Int {
        Section.allCases.count
    }

    func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section) {
        case .rows: rows.count + 1
        case .compact: compactRows.count
        case .system: 2
        case nil: 0
        }
    }

    func tableView(_: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch Section(rawValue: section) {
        case .rows: "lmk_applyListRow"
        case .compact: "Heights and insets"
        case .system: "UIListContentConfiguration helpers"
        case nil: nil
        }
    }

    func tableView(_: UITableView, titleForFooterInSection section: Int) -> String? {
        switch Section(rawValue: section) {
        case .rows:
            "One content configuration for the standard row: a symbol in a tinted circle or a thumbnail, title, subtitle, detail, and a trailing chevron, checkmark, switch, badge, image, or view. "
                + "cell.lmk_applyListRow adds the highlight and a whole-row pointer effect."
        case .compact:
            "A row is as tall as its content plus the vertical insets, never shorter than the compact row height. Style sets both per row; theme.listRow sets them app-wide."
        case .system:
            "The same tokens on a system content configuration."
        case nil:
            nil
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: LMKListTable.cellReuseIdentifier, for: indexPath)
        switch Section(rawValue: indexPath.section) {
        case .rows:
            if indexPath.row < rows.count {
                cell.lmk_applyListRow(rows[indexPath.row], backgroundColor: LMKColor.backgroundSecondary)
            } else {
                cell.lmk_applyListRow(LMKListRowConfiguration(
                    title: "Notifications",
                    leading: .symbol("bell", tint: LMKColor.warning),
                    trailing: .toggle(isOn: notificationsOn) { [weak self] in self?.notificationsOn = $0 }
                ), backgroundColor: LMKColor.backgroundSecondary)
            }
        case .compact:
            cell.lmk_applyListRow(compactRows[indexPath.row], backgroundColor: LMKColor.backgroundSecondary)
        case .system:
            var content = cell.defaultContentConfiguration()
            content.lmk_applyTextStyle()
            if indexPath.row == 0 {
                content.text = "lmk_applyLeadingSymbol"
                content.secondaryText = "Tinted circle in the system image slot"
                content.lmk_applyLeadingSymbol("person.2", tint: LMKColor.secondary)
            } else {
                content.text = "lmk_applyThumbnail"
                content.secondaryText = "Square thumbnail, symbol fallback"
                content.lmk_applyThumbnail(thumbnail)
            }
            cell.contentConfiguration = content
            cell.backgroundColor = LMKColor.backgroundSecondary
            cell.accessoryType = .disclosureIndicator
            cell.lmk_configureCustomHighlight()
            cell.lmk_installRowPointerInteraction()
        case nil:
            break
        }
        return cell
    }

    // MARK: - UITableViewDelegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
