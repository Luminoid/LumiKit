//
//  DividerExample.swift
//  LumiKitExample
//
//  Divider: Hairline separators, horizontal and vertical.
//

import LumiKitUI
import UIKit

// MARK: - Divider

final class DividerDetailViewController: DetailViewController {
    override func setupStackContent() {
        addSectionHeader("Horizontal")
        stackView.addArrangedSubview(UILabel.lmk_make(.caption, text: "Pixel-perfect separator between content sections:"))
        stackView.addArrangedSubview(LMKDividerView())
        stackView.addArrangedSubview(UILabel.lmk_make(.caption, text: "Content continues here"))

        addDivider()
        addSectionHeader("Vertical")
        stackView.addArrangedSubview(UILabel.lmk_make(.caption, text: "orientation: .vertical separates items in a row; the row's height sets its length."))
        let row = UIStackView(lmk_axis: .horizontal, spacing: LMKSpacing.medium, alignment: .fill)
        for (index, title) in ["Photos", "Notes", "Tasks"].enumerated() {
            if index > 0 {
                row.addArrangedSubview(LMKDividerView(orientation: .vertical))
            }
            row.addArrangedSubview(UILabel.lmk_make(.body, text: title))
        }
        row.addArrangedSubview(UIView())
        stackView.addArrangedSubview(row)

        addDivider()
        addSectionHeader("Dashed and Tinted")
        stackView.addArrangedSubview(UILabel.lmk_make(.caption, text: "Style(dash:) draws a dashed line; color and thickness come from the style too."))
        stackView.addArrangedSubview(LMKDividerView(style: LMKDividerView.Style(dash: [4, 2])))
        stackView.addArrangedSubview(LMKDividerView(style: LMKDividerView.Style(color: LMKColor.primary, thickness: 2)))
    }
}
