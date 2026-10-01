//
//  BadgesExample.swift
//  LumiKitExample
//
//  Badges: Count, text, and dot badges.
//

import LumiKitUI
import UIKit

// MARK: - Badges

final class BadgesDetailViewController: DetailViewController {
    override func setupStackContent() {
        addSectionHeader("Badge Styles")
        let row = UIStackView(lmk_axis: .horizontal, spacing: LMKSpacing.xxl)
        row.alignment = .center

        addBadgeColumn(to: row, label: "Count") { $0.configure(.count(5)) }
        addBadgeColumn(to: row, label: "Text") { $0.configure(.text("New")) }
        addBadgeColumn(to: row, label: "99+") { $0.configure(.count(150)) }
        addBadgeColumn(to: row, label: "Dot") { $0.configure(.dot) }
        row.addArrangedSubview(UIView())
        stackView.addArrangedSubview(row)

        addDivider()
        addSectionHeader("Custom Colors")
        let colorRow = UIStackView(lmk_axis: .horizontal, spacing: LMKSpacing.xxl)
        colorRow.alignment = .center

        for (name, color) in [("Success", LMKColor.success), ("Info", LMKColor.info), ("Warning", LMKColor.warning)] {
            let badge = LMKBadgeView(style: LMKBadgeView.Style(surface: LMKSurfaceStyle(background: .solid(color))))
            badge.configure(.text(name))
            let label = UILabel.lmk_make(.small, text: name)
            let col = UIStackView(lmk_axis: .vertical, spacing: LMKSpacing.xs)
            col.alignment = .center
            col.addArrangedSubview(badge)
            col.addArrangedSubview(label)
            colorRow.addArrangedSubview(col)
        }
        colorRow.addArrangedSubview(UIView())
        stackView.addArrangedSubview(makeScrollingRow(colorRow))
    }

    private func addBadgeColumn(to row: UIStackView, label text: String, configure: (LMKBadgeView) -> Void) {
        let badge = LMKBadgeView()
        configure(badge)
        let label = UILabel.lmk_make(.small, text: text)
        let col = UIStackView(lmk_axis: .vertical, spacing: LMKSpacing.xs)
        col.alignment = .center
        col.addArrangedSubview(badge)
        col.addArrangedSubview(label)
        row.addArrangedSubview(col)
    }
}
