//
//  LMKSliderTests.swift
//  LumiKit
//

import LumiKitCore
import Testing
import UIKit
@testable import LumiKitUI

@MainActor
struct LMKSliderTests {
    @Test
    func `Default value sits at minimum`() {
        let slider = LMKSlider()
        #expect(slider.value == 0)
        #expect(slider.minimumValue == 0)
        #expect(slider.maximumValue == 1)
    }

    @Test
    func `setValue clamps to the range`() {
        let slider = LMKSlider()
        slider.maximumValue = 100
        slider.setValue(-50, animated: false)
        #expect(slider.value == 0)
        slider.setValue(150, animated: false)
        #expect(slider.value == 100)
    }

    @Test
    func `Step snaps to the nearest multiple from the minimum`() {
        let slider = LMKSlider()
        slider.maximumValue = 100
        slider.step = 10
        slider.setValue(53, animated: false)
        #expect(slider.value == 50)
        slider.setValue(56, animated: false)
        #expect(slider.value == 60)

        let offset = LMKSlider()
        offset.minimumValue = 5
        offset.maximumValue = 25
        offset.step = 10
        offset.setValue(11, animated: false)
        #expect(offset.value == 15)

        let continuous = LMKSlider()
        continuous.setValue(0.37, animated: false)
        #expect(continuous.value == 0.37)
    }

    @Test
    func `Programmatic changes are silent`() {
        let slider = LMKSlider()
        var received: Float?
        slider.onValueChange = { received = $0 }
        slider.setValue(0.5, animated: false)
        slider.value = 0.75
        slider.minimumValue = 0.8
        #expect(received == nil)
    }

    @Test
    func `A range change re-clamps and re-snaps the value`() {
        let slider = LMKSlider()
        slider.maximumValue = 100
        slider.step = 10
        slider.valueFormatter = { "\(Int($0))" }
        #expect(slider.value == 0)
        slider.minimumValue = 20
        #expect(slider.value == 20, "the value follows the new lower bound")
        #expect(slider.readoutLabel.text == "20")
        #expect(slider.accessibilityValue == "20")
        slider.setValue(90, animated: false)
        slider.maximumValue = 55
        #expect(slider.value == 55, "clamped to the new upper bound")
        slider.maximumValue = 100
        #expect(slider.value == 60, "back on the grid from the minimum once there is room")
        slider.minimumValue = 5
        #expect(slider.value == 65, "re-snapped to the grid from the new minimum")
        #expect(slider.readoutLabel.text == "65")
    }

    @Test
    func `A drag reports only a changed value`() {
        let slider = LMKSlider()
        slider.maximumValue = 100
        slider.step = 10
        var received: [Float] = []
        slider.onValueChange = { received.append($0) }
        slider.slider.value = 33
        slider.perform(NSSelectorFromString("handleSliderChanged"))
        #expect(received == [30])
        slider.slider.value = 34
        slider.perform(NSSelectorFromString("handleSliderChanged"))
        #expect(received == [30], "a move inside one step bucket is not a change")
        slider.slider.value = 36
        slider.perform(NSSelectorFromString("handleSliderChanged"))
        #expect(received == [30, 40])

        let continuous = LMKSlider()
        var values: [Float] = []
        continuous.onValueChange = { values.append($0) }
        continuous.slider.value = 0.4
        continuous.perform(NSSelectorFromString("handleSliderChanged"))
        continuous.slider.value = 0.4
        continuous.perform(NSSelectorFromString("handleSliderChanged"))
        #expect(values == [0.4], "a continuous slider reports each new value once")
    }

    @Test
    func `Caption and readout drive accessibility and the row`() {
        let slider = LMKSlider()
        slider.caption = "Severity"
        #expect(slider.accessibilityLabel == "Severity")
        #expect(!slider.captionLabel.isHidden)
        slider.maximumValue = 100
        slider.valueFormatter = { "\(Int($0))%" }
        slider.setValue(40, animated: false)
        #expect(slider.accessibilityValue == "40%")
        #expect(slider.readoutLabel.text == "40%")
        #expect(slider.intrinsicContentSize.height > slider.slider.intrinsicContentSize.height)
    }

    @Test
    func `Accessibility adjustments respect the step or a tenth of the range and report only changes`() {
        let stepped = LMKSlider()
        var received: [Float] = []
        stepped.onValueChange = { received.append($0) }
        stepped.maximumValue = 100
        stepped.step = 10
        stepped.setValue(20, animated: false)
        stepped.accessibilityIncrement()
        #expect(stepped.value == 30)
        stepped.setValue(0, animated: false)
        stepped.accessibilityDecrement()
        #expect(stepped.value == 0)
        #expect(received == [30], "an adjustment at the end of the range is not a change")
        stepped.isEnabled = false
        stepped.accessibilityIncrement()
        #expect(stepped.value == 0, "a disabled slider ignores adjustments")

        let continuous = LMKSlider()
        continuous.maximumValue = 100
        continuous.setValue(20, animated: false)
        continuous.accessibilityIncrement()
        #expect(abs(continuous.value - 30) < 0.001)
        #expect(continuous.accessibilityTraits.contains(.adjustable))
    }

    @Test
    func `The default accessibility value is a localized number`() {
        let slider = LMKSlider()
        slider.setValue(0.5, animated: false)
        #expect(slider.accessibilityValue == LMKFormat.number(0.5))
        slider.maximumValue = 2_000_000
        slider.setValue(1_234_567, animated: false)
        #expect(slider.accessibilityValue == LMKFormat.number(1_234_567.0), "no exponent notation")
    }

    @Test
    func `The intrinsic height measures the caption row's labels`() {
        let slider = LMKSlider()
        let trackHeight = slider.slider.intrinsicContentSize.height
        #expect(slider.intrinsicContentSize.height == trackHeight)
        slider.caption = "Severity"
        let expected = slider.captionLabel.intrinsicContentSize.height + LMKTheme.current.spacing.xs + trackHeight
        #expect(abs(slider.intrinsicContentSize.height - expected) < 0.01)
        #expect(
            slider.captionLabel.contentCompressionResistancePriority(for: .horizontal) < slider.readoutLabel.contentCompressionResistancePriority(for: .horizontal),
            "a long caption yields to the readout"
        )
    }

    @Test
    func `Track colors follow the style and disabled state dims`() {
        let slider = LMKSlider()
        #expect(slider.slider.minimumTrackTintColor === LMKColor.primary)
        #expect(slider.slider.maximumTrackTintColor === LMKColor.fill)
        slider.style.minimumTrackColor = .red
        slider.style.thumbColor = .blue
        #expect(slider.slider.minimumTrackTintColor == UIColor.red)
        #expect(slider.slider.thumbTintColor == UIColor.blue)
        slider.isEnabled = false
        #expect(!slider.slider.isEnabled)
        #expect(abs(slider.alpha - LMKTheme.current.alpha.disabled) < 0.001)
        #expect(slider.accessibilityTraits.contains(.notEnabled))
        slider.style.disabled = LMKControlStateStyle(alpha: 0.2)
        #expect(abs(slider.alpha - 0.2) < 0.001, "the disabled style's alpha applies")
        #expect(LMKSlider.Style(disabled: LMKControlStateStyle(alpha: 0.2)).merging(LMKSlider.Style()).disabled?.alpha == 0.2)
    }

    @Test
    func `Caption, readout, and thumb styles apply`() {
        let thumb = UIImage.lmk_solidColor(.green, size: CGSize(width: 10, height: 10))
        let slider = LMKSlider(style: LMKSlider.Style(thumbImage: thumb, captionTextStyle: .h4, captionColor: .red, readoutTextStyle: .small, readoutColor: .blue, spacing: 9))
        slider.caption = "Volume"
        slider.valueFormatter = { "\($0)" }
        #expect(slider.slider.thumbImage(for: .normal) === thumb)
        #expect(slider.captionLabel.lmk_textStyle == .h4)
        #expect(slider.captionLabel.textColor == UIColor.red)
        #expect(slider.readoutLabel.lmk_textStyle == .small)
        #expect(slider.readoutLabel.textColor == UIColor.blue)
        #expect(slider.intrinsicContentSize.height == slider.captionLabel.intrinsicContentSize.height + 9 + slider.slider.intrinsicContentSize.height)
    }

    @Test
    func `Steps publish track ticks and a neutral value on iOS 26`() {
        let slider = LMKSlider()
        slider.maximumValue = 100
        slider.step = 25
        if #available(iOS 26, *) {
            #expect(slider.slider.trackConfiguration?.ticks.count == 5)
            #expect(slider.slider.trackConfiguration?.allowsTickValuesOnly == true)
            slider.style.showsTicks = false
            #expect(slider.slider.trackConfiguration?.ticks.isEmpty == true, "a plain configuration stands in: clearing one pins the slider to its minimum")
            #expect(slider.slider.trackConfiguration?.allowsTickValuesOnly == false)
            slider.setValue(75, animated: false)
            #expect(slider.slider.value == 75, "the slider still takes values")
            slider.neutralValue = 50
            #expect(slider.slider.trackConfiguration?.neutralValue == 0.5)
            slider.neutralValue = 500
            #expect(slider.slider.trackConfiguration?.neutralValue == 1, "clamped to the range")
        } else {
            #expect(slider.value == 0)
        }
    }

    @Test
    func `Ticks appear only when they coincide with the snap grid, so every step stays reachable`() {
        #expect(LMKSlider.tickCount(range: 100, step: 25) == 5)
        #expect(LMKSlider.tickCount(range: 1, step: 0.1) == 11)
        #expect(LMKSlider.tickCount(range: 100, step: 1) == nil, "101 stops are more than the track shows")
        #expect(LMKSlider.tickCount(range: 100, step: 30) == nil, "an uneven grid would put ticks off the snap values")
        #expect(LMKSlider.tickCount(range: 100, step: 0) == nil)
        #expect(LMKSlider.tickCount(range: 1_000_000_000, step: 0.000_000_001) == nil, "an extreme ratio never traps")

        let slider = LMKSlider()
        slider.maximumValue = 100
        slider.step = 1
        slider.setValue(37, animated: false)
        #expect(slider.value == 37)
        if #available(iOS 26, *) {
            #expect(slider.slider.trackConfiguration == nil, "no ticks pin the drag to 50 of 101 values")
        }
    }

    @Test
    func `theme.slider supplies app-wide defaults`() {
        var theme = LMKTheme()
        theme.slider = LMKSlider.Style(maximumTrackColor: .magenta)
        let slider = LMKSlider()
        let window = LMKThemeTesting.host(slider, theme: theme)
        defer { window.isHidden = true }
        #expect(slider.slider.maximumTrackTintColor == UIColor.magenta)
    }
}
