//
//  DesignSystemExamples.swift
//  LumiKitExample
//
//  Typography and color token examples.
//

import LumiKitUI
import SnapKit
import UIKit

// MARK: - Typography

final class TypographyDetailViewController: DetailViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        addSectionHeader("Headings")
        stack.addArrangedSubview(LMKLabelFactory.heading(text: "Heading 1", level: 1))
        stack.addArrangedSubview(LMKLabelFactory.heading(text: "Heading 2", level: 2))
        stack.addArrangedSubview(LMKLabelFactory.heading(text: "Heading 3", level: 3))
        stack.addArrangedSubview(LMKLabelFactory.heading(text: "Heading 4", level: 4))

        addDivider()
        addSectionHeader("Body Styles")
        stack.addArrangedSubview(LMKLabelFactory.body(text: "Body — the quick brown fox jumps over the lazy dog. This is the default paragraph style used for content."))
        stack.addArrangedSubview(LMKLabelFactory.caption(text: "Caption — used for secondary information and metadata"))
        stack.addArrangedSubview(LMKLabelFactory.small(text: "Small — fine print and tertiary details"))

        addDivider()
        addSectionHeader("Special")
        stack.addArrangedSubview(LMKLabelFactory.scientificName(text: "Monstera deliciosa"))
        stack.addArrangedSubview(LMKLabelFactory.scientificName(text: "Epipremnum aureum"))
    }
}

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

        addDivider()
        addSectionHeader("Hex Utilities")
        let hexColor = UIColor(lmk_hex: "#4CAF7D") ?? .clear
        let hexRow = UIStackView(lmk_axis: .horizontal, spacing: LMKSpacing.small)
        hexRow.alignment = .center

        let swatch = UIView()
        swatch.backgroundColor = hexColor
        swatch.layer.cornerRadius = LMKCornerRadius.small
        swatch.snp.makeConstraints { $0.width.height.equalTo(40) }

        let hexLabel = LMKLabelFactory.caption(text: "UIColor(lmk_hex: \"#4CAF7D\") \u{2192} \(hexColor.lmk_hexString)")
        hexRow.addArrangedSubview(swatch)
        hexRow.addArrangedSubview(hexLabel)
        stack.addArrangedSubview(hexRow)

        let contrastRow = UIStackView(lmk_axis: .horizontal, spacing: LMKSpacing.small)
        contrastRow.distribution = .fillEqually
        for (name, color) in [("Light bg", UIColor.white), ("Dark bg", UIColor.black)] {
            let box = UIView()
            box.backgroundColor = color
            box.layer.cornerRadius = LMKCornerRadius.small
            box.clipsToBounds = true
            let label = UILabel()
            label.text = "Auto contrast"
            label.textColor = color.lmk_contrastingTextColor
            label.font = LMKTypography.caption
            label.textAlignment = .center
            box.addSubview(label)
            label.snp.makeConstraints { $0.edges.equalToSuperview().inset(LMKSpacing.small) }
            box.snp.makeConstraints { $0.height.equalTo(40) }

            let col = UIStackView(lmk_axis: .vertical, spacing: LMKSpacing.xs)
            col.addArrangedSubview(box)
            col.addArrangedSubview(LMKLabelFactory.small(text: name))
            contrastRow.addArrangedSubview(col)
        }
        stack.addArrangedSubview(contrastRow)
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

            let label = LMKLabelFactory.small(text: name)
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
