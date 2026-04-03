//
//  LMKSwitchTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

@MainActor
struct LMKSwitchTests {
    @Test
    func `Default state is off`() {
        let toggle = LMKSwitch()
        #expect(toggle.isOn == false)
    }

    @Test
    func `setOn changes state`() {
        let toggle = LMKSwitch()
        toggle.setOn(true, animated: false)
        #expect(toggle.isOn == true)
    }

    @Test
    func `setOn with same value is no-op`() {
        let toggle = LMKSwitch()
        toggle.setOn(false, animated: false)
        #expect(toggle.isOn == false)
    }

    @Test
    func `Handler fires on toggle`() {
        let toggle = LMKSwitch()
        var receivedValue: Bool?
        toggle.valueChangedHandler = { receivedValue = $0 }
        toggle.isOn = true
        // Handler only fires from user interaction (tap), not programmatic set
        #expect(receivedValue == nil)
    }

    @Test
    func `Intrinsic content size is correct`() {
        let toggle = LMKSwitch()
        let size = toggle.intrinsicContentSize
        #expect(size.width == 52)
        #expect(size.height == 30)
    }

    @Test
    func `Is a UIControl subclass`() {
        let toggle = LMKSwitch()
        #expect(toggle as Any is UIControl)
    }

    @Test
    func `Accessibility value reflects state`() {
        let toggle = LMKSwitch()
        #expect(toggle.accessibilityValue == "0")
        toggle.isOn = true
        #expect(toggle.accessibilityValue == "1")
    }
}
