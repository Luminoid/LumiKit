//
//  CheckboxRatingExample.swift
//  LumiKitExample
//
//  Checkbox & Rating: LMKCheckbox and LMKRatingControl.
//

import LumiKitUI
import UIKit

// MARK: - Checkbox & Rating

final class CheckboxRatingDetailViewController: DetailViewController {
    override func setupStackContent() {
        addSectionHeader("LMKCheckbox")
        stackView.addArrangedSubview(UILabel.lmk_make(
            .caption,
            text: "A symbol that toggles between checked and unchecked with a 44pt hit target. isChecked is silent; onValueChange fires for user taps."
        ))
        let readout = UILabel.lmk_make(.body, text: "Unchecked")
        let checkbox = LMKCheckbox()
        checkbox.accessibilityLabel = "Sample task"
        checkbox.onValueChange = { readout.lmk_setText($0 ? "Checked" : "Unchecked") }
        stackView.addArrangedSubview(UIStackView(lmk_axis: .horizontal, spacing: LMKSpacing.medium, alignment: .center, arrangedSubviews: [checkbox, readout]))

        let preset = LMKCheckbox()
        preset.isChecked = true
        preset.accessibilityLabel = "Checked"
        let disabled = LMKCheckbox()
        disabled.isChecked = true
        disabled.isEnabled = false
        disabled.accessibilityLabel = "Disabled"
        let styled = LMKCheckbox(style: LMKCheckbox.Style(onSymbol: "heart.fill", offSymbol: "heart", onColor: LMKColor.error, glyphSize: LMKLayout.iconLarge))
        styled.accessibilityLabel = "Favorite"
        stackView.addArrangedSubview(UIStackView(lmk_axis: .horizontal, spacing: LMKSpacing.xl, alignment: .center, arrangedSubviews: [
            makeCaptioned(preset, "Checked"), makeCaptioned(disabled, "Disabled"), makeCaptioned(styled, "Custom style"), UIView(),
        ]))

        addDivider()
        addSectionHeader("LMKRatingControl")
        stackView.addArrangedSubview(UILabel.lmk_make(
            .caption,
            text: "Tap or drag to rate; tap the current star again to clear. VoiceOver adjusts with swipes. value is silent, onValueChange reports user changes."
        ))
        let ratingReadout = UILabel.lmk_make(.body, text: "0 of 5")
        let rating = LMKRatingControl()
        rating.onValueChange = { ratingReadout.lmk_setText("\($0) of 5") }
        stackView.addArrangedSubview(UIStackView(lmk_axis: .horizontal, spacing: LMKSpacing.medium, alignment: .center, arrangedSubviews: [rating, ratingReadout, UIView()]))

        let ten = LMKRatingControl(maximum: 10)
        ten.value = 7
        stackView.addArrangedSubview(makeCaptioned(ten, "Ten stars, value 7"))

        let readOnly = LMKRatingControl()
        readOnly.value = 4
        readOnly.isInteractive = false
        stackView.addArrangedSubview(makeCaptioned(readOnly, "Read-only (isInteractive = false)"))

        let hearts = LMKRatingControl(
            maximum: 5,
            style: LMKRatingControl.Style(filledSymbol: "heart.fill", emptySymbol: "heart", filledColor: LMKColor.error, glyphSize: LMKLayout.iconMedium, spacing: LMKSpacing.small)
        )
        hearts.value = 3
        stackView.addArrangedSubview(makeCaptioned(hearts, "Custom symbols and colors"))
    }

    private func makeCaptioned(_ control: UIView, _ caption: String) -> UIStackView {
        UIStackView(lmk_axis: .vertical, spacing: LMKSpacing.xs, alignment: .leading, arrangedSubviews: [control, UILabel.lmk_make(.small, text: caption)])
    }
}
