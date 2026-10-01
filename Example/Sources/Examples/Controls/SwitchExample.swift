//
//  SwitchExample.swift
//  LumiKitExample
//
//  Switch: LMKSwitch with a spring thumb and custom tints.
//

import LumiKitUI
import UIKit

// MARK: - Switch

final class SwitchDetailViewController: DetailViewController {
    override func setupStackContent() {
        addSectionHeader("Basic")
        stackView.addArrangedSubview(UILabel.lmk_make(.caption, text: "Custom toggle replacing UISwitch. Rounded track + sliding thumb with spring animation."))

        let toggleLabel = UILabel.lmk_make(.body, text: "Off")
        toggleLabel.textAlignment = .center

        let toggle = LMKSwitch()
        toggle.accessibilityLabel = "Notifications"
        toggle.onValueChange = { isOn in
            toggleLabel.lmk_setText(isOn ? "On" : "Off")
        }

        let toggleRow = UIStackView(lmk_axis: .horizontal, alignment: .center, arrangedSubviews: [UILabel.lmk_make(.body, text: "Notifications"), UIView(), toggle])
        stackView.addArrangedSubview(toggleRow)
        stackView.addArrangedSubview(toggleLabel)

        addDivider()
        addSectionHeader("Pre-set State")

        let presetToggle = LMKSwitch()
        presetToggle.accessibilityLabel = "Dark Mode"
        presetToggle.setOn(true, animated: false)
        let presetRow = UIStackView(lmk_axis: .horizontal, alignment: .center, arrangedSubviews: [UILabel.lmk_make(.body, text: "Dark Mode"), UIView(), presetToggle])
        stackView.addArrangedSubview(presetRow)
    }
}
