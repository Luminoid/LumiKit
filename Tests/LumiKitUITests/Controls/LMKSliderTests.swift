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
    func `setValue clamps below minimum`() {
        let slider = LMKSlider()
        slider.minimumValue = 0
        slider.maximumValue = 100
        slider.setValue(-50, animated: false)
        #expect(slider.value == 0)
    }

    @Test
    func `setValue clamps above maximum`() {
        let slider = LMKSlider()
        slider.minimumValue = 0
        slider.maximumValue = 100
        slider.setValue(150, animated: false)
        #expect(slider.value == 100)
    }

    @Test
    func `Step snaps to nearest multiple from minimum`() {
        let slider = LMKSlider()
        slider.minimumValue = 0
        slider.maximumValue = 100
        slider.step = 10
        slider.setValue(53, animated: false)
        #expect(slider.value == 50)
        slider.setValue(56, animated: false)
        #expect(slider.value == 60)
    }

    @Test
    func `Step snap respects non-zero minimum`() {
        let slider = LMKSlider()
        slider.minimumValue = 5
        slider.maximumValue = 25
        slider.step = 10
        slider.setValue(11, animated: false)
        // Offset 6 / step 10 → 1 → 5 + 10 = 15
        #expect(slider.value == 15)
    }

    @Test
    func `Step zero leaves value continuous`() {
        let slider = LMKSlider()
        slider.minimumValue = 0
        slider.maximumValue = 1
        slider.step = 0
        slider.setValue(0.37, animated: false)
        #expect(slider.value == 0.37)
    }

    @Test
    func `Programmatic value change does not fire handler`() {
        let slider = LMKSlider()
        var received: Float?
        slider.valueChangedHandler = { received = $0 }
        slider.setValue(0.5, animated: false)
        slider.value = 0.75
        #expect(received == nil)
    }

    @Test
    func `Caption sets accessibility label and shows row`() {
        let slider = LMKSlider()
        slider.caption = "Severity"
        #expect(slider.accessibilityLabel == "Severity")
    }

    @Test
    func `valueFormatter populates accessibility value`() {
        let slider = LMKSlider()
        slider.minimumValue = 0
        slider.maximumValue = 100
        slider.valueFormatter = { "\(Int($0))%" }
        slider.setValue(40, animated: false)
        #expect(slider.accessibilityValue == "40%")
    }

    @Test
    func `Accessibility increment respects step when set`() {
        let slider = LMKSlider()
        slider.minimumValue = 0
        slider.maximumValue = 100
        slider.step = 10
        slider.setValue(20, animated: false)
        slider.accessibilityIncrement()
        #expect(slider.value == 30)
    }

    @Test
    func `Accessibility increment uses tenth-of-range when no step`() {
        let slider = LMKSlider()
        slider.minimumValue = 0
        slider.maximumValue = 100
        slider.setValue(20, animated: false)
        slider.accessibilityIncrement()
        // Continuous mode: UISlider's float round-trip drifts on the order of 1e-6; use tolerance.
        #expect(abs(slider.value - 30) < 0.001)
    }

    @Test
    func `Accessibility decrement clamps at minimum`() {
        let slider = LMKSlider()
        slider.minimumValue = 0
        slider.maximumValue = 100
        slider.step = 10
        slider.setValue(0, animated: false)
        slider.accessibilityDecrement()
        #expect(slider.value == 0)
    }

    @Test
    func `Is a UIControl subclass`() {
        let slider = LMKSlider()
        #expect(slider as Any is UIControl)
    }

    @Test
    func `Adjustable accessibility trait is set`() {
        let slider = LMKSlider()
        #expect(slider.accessibilityTraits.contains(.adjustable))
    }
}
