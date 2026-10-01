//
//  SliderExample.swift
//  LumiKitExample
//
//  Slider: Caption, live readout, steps, negative range.
//

import LumiKitUI
import UIKit

// MARK: - Slider

final class SliderDetailViewController: DetailViewController {
    override func setupStackContent() {
        addSectionHeader("Basic (continuous)")
        stackView.addArrangedSubview(UILabel.lmk_make(.caption, text: "Bare slider: no caption, no readout. Range 0…1, continuous."))
        let basicLabel = UILabel.lmk_make(.body, text: "Value: 0.00")
        basicLabel.textAlignment = .center
        let basic = LMKSlider()
        basic.accessibilityLabel = "Basic slider"
        basic.onValueChange = { value in
            basicLabel.lmk_setText(String(format: "Value: %.2f", value))
        }
        stackView.addArrangedSubview(basic)
        stackView.addArrangedSubview(basicLabel)

        addDivider()
        addSectionHeader("Caption + Live Readout")
        stackView.addArrangedSubview(UILabel.lmk_make(.caption, text: "caption + valueFormatter render a header row above the track. Range 0…100, continuous."))
        let withCaption = LMKSlider()
        withCaption.caption = "Brightness"
        withCaption.minimumValue = 0
        withCaption.maximumValue = 100
        withCaption.value = 40
        withCaption.valueFormatter = { "\(Int($0))%" }
        stackView.addArrangedSubview(withCaption)

        addDivider()
        addSectionHeader("Stepped (snap to multiples)")
        stackView.addArrangedSubview(UILabel.lmk_make(.caption, text: "step = 10 snaps to 0, 10, 20, …, 100. The slider thumb glides during drag and "
                + "lands on exact multiples on release. Useful for indexed parameters (severity, "
                + "zoom levels, quantized intensity)."))
        let stepped = LMKSlider()
        stepped.caption = "Severity"
        stepped.minimumValue = 0
        stepped.maximumValue = 100
        stepped.step = 10
        stepped.value = 50
        stepped.valueFormatter = { "\(Int($0))" }
        stackView.addArrangedSubview(stepped)

        addDivider()
        addSectionHeader("Negative Range")
        stackView.addArrangedSubview(UILabel.lmk_make(.caption, text: "Range −2…+2 (EV stops). step = 0.5. Formatter shows signed value."))
        let ev = LMKSlider()
        ev.caption = "Exposure"
        ev.minimumValue = -2
        ev.maximumValue = 2
        ev.step = 0.5
        ev.value = 0
        ev.valueFormatter = { value in
            value > 0 ? String(format: "+%.1f EV", value) : String(format: "%.1f EV", value)
        }
        stackView.addArrangedSubview(ev)

        addDivider()
        addSectionHeader("Programmatic Reset")
        stackView.addArrangedSubview(UILabel.lmk_make(.caption, text: "Programmatic value changes are silent: onValueChange only fires on user drag. "
                + "Tap Reset to see the slider animate without re-firing the handler."))
        let resetSlider = LMKSlider()
        resetSlider.caption = "Volume"
        resetSlider.minimumValue = 0
        resetSlider.maximumValue = 1
        resetSlider.value = 0.75
        resetSlider.valueFormatter = { String(format: "%.0f%%", $0 * 100) }
        stackView.addArrangedSubview(resetSlider)

        let resetButton = LMKButton(title: "Reset to 50%", style: .ghost(.primary))
        resetButton.onTap = { [weak resetSlider] in
            resetSlider?.setValue(0.5, animated: true)
        }
        let resetRow = UIStackView(
            lmk_axis: .horizontal,
            alignment: .center,
            arrangedSubviews: [resetButton, UIView()]
        )
        stackView.addArrangedSubview(resetRow)
    }
}
