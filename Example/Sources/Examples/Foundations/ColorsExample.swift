//
//  ColorsExample.swift
//  LumiKitExample
//
//  Colors: LMKColor roles: accents, status, text, backgrounds.
//

import LumiKitUI
import SnapKit
import UIKit

// MARK: - Colors

final class ColorsDetailViewController: DetailViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        addColorRow("Primary", [
            ("Primary", LMKColor.primary),
            ("Secondary", LMKColor.secondary),
        ])

        addDivider()
        addColorRow("Semantic", [
            ("Success", LMKColor.success),
            ("Warning", LMKColor.warning),
            ("Error", LMKColor.error),
            ("Info", LMKColor.info),
        ])

        addDivider()
        addColorRow("Text", [
            ("Primary", LMKColor.textPrimary),
            ("Secondary", LMKColor.textSecondary),
            ("Tertiary", LMKColor.textTertiary),
        ])

        addDivider()
        addColorRow("Backgrounds", [
            ("Primary", LMKColor.backgroundPrimary),
            ("Secondary", LMKColor.backgroundSecondary),
            ("Tertiary", LMKColor.backgroundTertiary),
        ])
    }

    private func addColorRow(_ title: String, _ colors: [(String, UIColor)]) {
        addSectionHeader(title)
        let row = UIStackView(lmk_axis: .horizontal, spacing: LMKSpacing.small)
        row.distribution = .fillEqually

        for (name, color) in colors {
            let swatch = UIView()
            swatch.backgroundColor = color
            swatch.layer.cornerRadius = LMKCornerRadius.small
            swatch.layer.borderWidth = 0.5
            swatch.layer.borderColor = LMKColor.divider.cgColor

            let label = UILabel.lmk_make(.small, text: name)
            label.textAlignment = .center

            let col = UIStackView(lmk_axis: .vertical, spacing: LMKSpacing.xs)
            col.addArrangedSubview(swatch)
            col.addArrangedSubview(label)
            swatch.snp.makeConstraints { $0.height.equalTo(52) }
            row.addArrangedSubview(col)
        }
        stack.addArrangedSubview(row)
    }
}
