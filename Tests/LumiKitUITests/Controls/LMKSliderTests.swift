//
//  LMKSliderTests.swift
//  LumiKit
//

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
        #expect(received == nil)
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
    func `Accessibility adjustments respect the step or a tenth of the range`() {
        let stepped = LMKSlider()
        stepped.maximumValue = 100
        stepped.step = 10
        stepped.setValue(20, animated: false)
        stepped.accessibilityIncrement()
        #expect(stepped.value == 30)
        stepped.setValue(0, animated: false)
        stepped.accessibilityDecrement()
        #expect(stepped.value == 0)

        let continuous = LMKSlider()
        continuous.maximumValue = 100
        continuous.setValue(20, animated: false)
        continuous.accessibilityIncrement()
        #expect(abs(continuous.value - 30) < 0.001)
        #expect(continuous.accessibilityTraits.contains(.adjustable))
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
            #expect(slider.slider.trackConfiguration == nil)
            slider.neutralValue = 50
            #expect(slider.slider.trackConfiguration?.neutralValue == 0.5)
        } else {
            #expect(slider.value == 0)
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
