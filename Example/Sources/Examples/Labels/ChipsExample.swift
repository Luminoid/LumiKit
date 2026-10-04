//
//  ChipsExample.swift
//  LumiKitExample
//
//  Chips: Filled, tinted, outlined, dismissible, selectable, and wrapping.
//

import LumiKitUI
import UIKit

// MARK: - Chips

final class ChipsDetailViewController: DetailViewController {
    override func setupStackContent() {
        addSectionHeader("Filled")
        let filledRow = UIStackView(lmk_axis: .horizontal, spacing: LMKSpacing.small)
        filledRow.addArrangedSubview(LMKChipView(text: "Design", style: .filled))
        filledRow.addArrangedSubview(LMKChipView(text: "Swift", style: .filled))
        filledRow.addArrangedSubview(LMKChipView(text: "UIKit", style: .filled))
        filledRow.addArrangedSubview(UIView())
        stackView.addArrangedSubview(makeScrollingRow(filledRow))

        addDivider()
        addSectionHeader("Tinted")
        let tintedRow = UIStackView(lmk_axis: .horizontal, spacing: LMKSpacing.small)
        tintedRow.addArrangedSubview(LMKChipView(text: "Draft", style: .tinted))
        tintedRow.addArrangedSubview(LMKChipView(text: "Shared", style: .tinted.tint(LMKColor.info)))
        tintedRow.addArrangedSubview(LMKChipView(text: "Overdue", style: .tinted.tint(LMKColor.error)))
        tintedRow.addArrangedSubview(UIView())
        stackView.addArrangedSubview(makeScrollingRow(tintedRow))

        addDivider()
        addSectionHeader("Outlined")
        let outlinedRow = UIStackView(lmk_axis: .horizontal, spacing: LMKSpacing.small)
        outlinedRow.addArrangedSubview(LMKChipView(text: "Layout", style: .outlined))
        outlinedRow.addArrangedSubview(LMKChipView(text: "Theme", style: .outlined))
        outlinedRow.addArrangedSubview(LMKChipView(text: "Token", style: .outlined))
        outlinedRow.addArrangedSubview(UIView())
        stackView.addArrangedSubview(makeScrollingRow(outlinedRow))

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
        stackView.addArrangedSubview(makeScrollingRow(colorRow))

        addDivider()
        addSectionHeader("With Icons")
        let iconRow = UIStackView(lmk_axis: .horizontal, spacing: LMKSpacing.small)
        iconRow.addArrangedSubview(LMKChipView(text: "Star", icon: UIImage(systemName: "star"), style: .filled))
        iconRow.addArrangedSubview(LMKChipView(text: "Heart", icon: UIImage(systemName: "heart"), style: .outlined))
        iconRow.addArrangedSubview(UIView())
        stackView.addArrangedSubview(makeScrollingRow(iconRow))

        addDivider()
        addSectionHeader("Dismissible")
        let dismissRow = UIStackView(lmk_axis: .horizontal, spacing: LMKSpacing.small)
        for text in ["Active", "Recent", "Archived"] {
            let chip = LMKChipView(text: text, style: .outlined.tint(LMKColor.secondary))
            chip.onDismiss = { [weak chip] in chip?.removeFromSuperview() }
            dismissRow.addArrangedSubview(chip)
        }
        dismissRow.addArrangedSubview(UIView())
        stackView.addArrangedSubview(makeScrollingRow(dismissRow))

        addDivider()
        addSectionHeader("Toggle Selection")
        stackView.addArrangedSubview(UILabel.lmk_make(
            .caption,
            text: "A chip that toggles is outlined or tinted while off; the full tint is the selected look. Press and hold to see the pressed shade."
        ))
        for style in [LMKChipView.Style.outlined, .tinted] {
            let toggleRow = UIStackView(lmk_axis: .horizontal, spacing: LMKSpacing.small)
            for (index, text) in ["All", "Photos", "Notes"].enumerated() {
                let chip = LMKChipView(text: text, style: style)
                chip.isSelected = index == 0
                // The chip stores the closure, so it captures itself weakly.
                chip.onTap = { [weak chip] in chip?.isSelected.toggle() }
                toggleRow.addArrangedSubview(chip)
            }
            toggleRow.addArrangedSubview(UIView())
            stackView.addArrangedSubview(makeScrollingRow(toggleRow))
        }

        addDivider()
        addSectionHeader("Wrapping")
        stackView.addArrangedSubview(UILabel.lmk_make(
            .caption,
            text: "LMKChipFlowView wraps chips onto new lines at the page width. Dismiss one and the rest close the gap."
        ))
        let tags = ["Design", "Swift", "UIKit", "Accessibility", "Dynamic Type", "Dark Mode", "Localization", "Mac Catalyst", "Right to Left"]
        let flow = LMKChipFlowView(arrangedSubviews: tags.map { text in
            let chip = LMKChipView(text: text, style: .outlined.tint(LMKColor.secondary))
            // Removing the chip from its superview takes it out of the flow.
            chip.onDismiss = { [weak chip] in chip?.removeFromSuperview() }
            return chip
        })
        stackView.addArrangedSubview(flow)
    }
}
