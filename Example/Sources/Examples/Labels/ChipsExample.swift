//
//  ChipsExample.swift
//  LumiKitExample
//
//  Chips: Filled, tinted, outlined, dismissible, and selectable.
//

import LumiKitUI
import SnapKit
import UIKit

// MARK: - Chips

final class ChipsDetailViewController: DetailViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        addSectionHeader("Filled")
        let filledRow = UIStackView(lmk_axis: .horizontal, spacing: LMKSpacing.small)
        filledRow.addArrangedSubview(LMKChipView(text: "Design", style: .filled))
        filledRow.addArrangedSubview(LMKChipView(text: "Swift", style: .filled))
        filledRow.addArrangedSubview(LMKChipView(text: "UIKit", style: .filled))
        filledRow.addArrangedSubview(UIView())
        stack.addArrangedSubview(makeScrollingRow(filledRow))

        addDivider()
        addSectionHeader("Tinted")
        let tintedRow = UIStackView(lmk_axis: .horizontal, spacing: LMKSpacing.small)
        tintedRow.addArrangedSubview(LMKChipView(text: "Draft", style: .tinted))
        tintedRow.addArrangedSubview(LMKChipView(text: "Shared", style: .tinted.tint(LMKColor.info)))
        tintedRow.addArrangedSubview(LMKChipView(text: "Overdue", style: .tinted.tint(LMKColor.error)))
        tintedRow.addArrangedSubview(UIView())
        stack.addArrangedSubview(makeScrollingRow(tintedRow))

        addDivider()
        addSectionHeader("Outlined")
        let outlinedRow = UIStackView(lmk_axis: .horizontal, spacing: LMKSpacing.small)
        outlinedRow.addArrangedSubview(LMKChipView(text: "Layout", style: .outlined))
        outlinedRow.addArrangedSubview(LMKChipView(text: "Theme", style: .outlined))
        outlinedRow.addArrangedSubview(LMKChipView(text: "Token", style: .outlined))
        outlinedRow.addArrangedSubview(UIView())
        stack.addArrangedSubview(makeScrollingRow(outlinedRow))

        addDivider()
        addSectionHeader("Custom Colors")
        let colorRow = UIStackView(lmk_axis: .horizontal, spacing: LMKSpacing.small)
        let colors: [(String, UIColor)] = [
            ("Success", LMKColor.success),
            ("Warning", LMKColor.warning),
            ("Info", LMKColor.info),
        ]
        for (text, color) in colors {
            let chip = LMKChipView(text: text, style: .filled.tint(color))
            colorRow.addArrangedSubview(chip)
        }
        colorRow.addArrangedSubview(UIView())
        stack.addArrangedSubview(makeScrollingRow(colorRow))

        addDivider()
        addSectionHeader("With Icons")
        let iconRow = UIStackView(lmk_axis: .horizontal, spacing: LMKSpacing.small)
        iconRow.addArrangedSubview(LMKChipView(text: "Star", icon: UIImage(systemName: "star"), style: .filled))
        iconRow.addArrangedSubview(LMKChipView(text: "Heart", icon: UIImage(systemName: "heart"), style: .outlined))
        iconRow.addArrangedSubview(UIView())
        stack.addArrangedSubview(makeScrollingRow(iconRow))

        addDivider()
        addSectionHeader("Dismissible")
        let dismissRow = UIStackView(lmk_axis: .horizontal, spacing: LMKSpacing.small)
        for text in ["Active", "Recent", "Archived"] {
            let chip = LMKChipView(text: text, style: .outlined.tint(LMKColor.secondary))
            chip.onDismiss = { [weak chip] in chip?.removeFromSuperview() }
            dismissRow.addArrangedSubview(chip)
        }
        dismissRow.addArrangedSubview(UIView())
        stack.addArrangedSubview(makeScrollingRow(dismissRow))

        addDivider()
        addSectionHeader("Toggle Selection")
        stack.addArrangedSubview(UILabel.lmk_make(.caption, text: "A chip that toggles is outlined or tinted while off; the full tint is the selected look. Press and hold to see the pressed shade."))
        for style in [LMKChipView.Style.outlined, .tinted] {
            let toggleRow = UIStackView(lmk_axis: .horizontal, spacing: LMKSpacing.small)
            for (index, text) in ["All", "Photos", "Notes"].enumerated() {
                let chip = LMKChipView(text: text, style: style)
                chip.isSelected = index == 0
                chip.onTap = { chip.isSelected.toggle() }
                toggleRow.addArrangedSubview(chip)
            }
            toggleRow.addArrangedSubview(UIView())
            stack.addArrangedSubview(makeScrollingRow(toggleRow))
        }
    }
}
