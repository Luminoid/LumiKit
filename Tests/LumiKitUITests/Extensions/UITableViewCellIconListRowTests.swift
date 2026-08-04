//
//  UITableViewCellIconListRowTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

// MARK: - UITableViewCell (lmk_configureIconListRow)

@MainActor
struct UITableViewCellIconListRowTests {
    private func makeConfiguredCell(subtitle: String? = nil) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "Row")
        cell.lmk_configureIconListRow(
            iconSystemName: "person.circle",
            title: "Alex",
            subtitle: subtitle
        )
        return cell
    }

    @Test
    func `Sets title and subtitle on the content configuration`() {
        let cell = makeConfiguredCell(subtitle: "Organizer")
        let content = cell.contentConfiguration as? UIListContentConfiguration
        #expect(content?.text == "Alex")
        #expect(content?.secondaryText == "Organizer")
    }

    @Test
    func `Renders a circular tinted icon at the token size`() {
        let cell = makeConfiguredCell()
        let content = cell.contentConfiguration as? UIListContentConfiguration
        #expect(content?.image != nil)
        #expect(content?.image?.size == CGSize(width: LMKLayout.iconCircle, height: LMKLayout.iconCircle))
        #expect(content?.imageProperties.cornerRadius == LMKLayout.iconCircle / 2)
    }

    @Test
    func `Shows a disclosure indicator`() {
        let cell = makeConfiguredCell()
        #expect(cell.accessoryType == .disclosureIndicator)
    }

    @Test
    func `Subtitle is optional`() {
        let cell = makeConfiguredCell(subtitle: nil)
        let content = cell.contentConfiguration as? UIListContentConfiguration
        #expect(content?.secondaryText == nil)
    }

    private func pointerInteractionCount(of cell: UITableViewCell) -> Int {
        cell.interactions.count { $0 is UIPointerInteraction }
    }

    @Test
    func `Pointer interaction is installed once across reconfiguration`() {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "Row")
        let baseline = pointerInteractionCount(of: cell)

        cell.lmk_configureIconListRow(iconSystemName: "person.circle", title: "Alex")
        cell.lmk_configureIconListRow(iconSystemName: "gearshape", title: "Settings")

        #expect(pointerInteractionCount(of: cell) == baseline + 1)
    }

    @Test
    func `pointerEnabled false installs no pointer interaction`() {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "Row")
        let baseline = pointerInteractionCount(of: cell)

        cell.lmk_configureIconListRow(iconSystemName: "person.circle", title: "Alex", pointerEnabled: false)

        #expect(pointerInteractionCount(of: cell) == baseline)
    }
}
