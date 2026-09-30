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
    func `Default state is off and setOn changes it silently`() {
        let toggle = LMKSwitch()
        #expect(!toggle.isOn)
        var received: Bool?
        toggle.onValueChange = { received = $0 }
        toggle.setOn(true, animated: false)
        #expect(toggle.isOn)
        toggle.isOn = false
        #expect(received == nil, "the handler only fires from user interaction")
    }

    @Test
    func `Intrinsic size and layout priorities pin the control`() {
        let toggle = LMKSwitch()
        #expect(toggle.intrinsicContentSize == CGSize(width: 52, height: 30))
        #expect(toggle.contentHuggingPriority(for: .horizontal) == .required)
        #expect(toggle.contentHuggingPriority(for: .vertical) == .required)
        #expect(toggle.contentCompressionResistancePriority(for: .horizontal) == .required)
        #expect(toggle.contentCompressionResistancePriority(for: .vertical) == .required)
        toggle.style.trackSize = CGSize(width: 40, height: 24)
        #expect(toggle.intrinsicContentSize == CGSize(width: 40, height: 24))
    }

    @Test
    func `Track and thumb colors follow the state and the style`() {
        let toggle = LMKSwitch()
        toggle.frame = CGRect(x: 0, y: 0, width: 52, height: 30)
        toggle.layoutIfNeeded()
        #expect(toggle.trackView.backgroundColor === LMKColor.fill)
        #expect(toggle.thumbView.backgroundColor == UIColor.white)
        #expect(toggle.thumbView.frame.minX == 2)
        toggle.isOn = true
        #expect(toggle.trackView.backgroundColor === LMKColor.primary)
        #expect(toggle.thumbView.frame.maxX == 50)
        toggle.style.onTint = .red
        toggle.style.thumbTint = .black
        #expect(toggle.trackView.backgroundColor == UIColor.red)
        #expect(toggle.thumbView.backgroundColor == UIColor.black)
    }

    @Test
    func `Disabled switches dim, ignore taps, and expose the trait`() {
        let toggle = LMKSwitch()
        toggle.isEnabled = false
        #expect(abs(toggle.alpha - LMKTheme.current.alpha.disabled) < 0.001)
        #expect(toggle.accessibilityTraits.contains(.notEnabled))
        #expect(!toggle.point(inside: CGPoint(x: 10, y: 10), with: nil))
        toggle.isEnabled = true
        #expect(toggle.alpha == 1)
        toggle.frame = CGRect(x: 0, y: 0, width: 52, height: 30)
        #expect(toggle.point(inside: CGPoint(x: 26, y: -6), with: nil), "44pt hit target")
    }

    @Test
    func `Accessibility value reflects the state and per-instance strings`() {
        let toggle = LMKSwitch()
        #expect(toggle.accessibilityValue == LMKSwitch.strings.offAccessibilityValue)
        #expect(toggle.accessibilityValue != "0")
        toggle.isOn = true
        #expect(toggle.accessibilityValue == LMKSwitch.strings.onAccessibilityValue)
        toggle.strings = .init(onAccessibilityValue: "Yes", offAccessibilityValue: "No")
        #expect(toggle.accessibilityValue == "Yes")
        toggle.isOn = false
        #expect(toggle.accessibilityValue == "No")
    }

    @Test
    func `theme.switch supplies app-wide defaults`() {
        var theme = LMKTheme()
        theme.switch = LMKSwitch.Style(offTint: .magenta)
        let toggle = LMKSwitch()
        let window = LMKThemeTesting.host(toggle, theme: theme)
        defer { window.isHidden = true }
        #expect(toggle.trackView.backgroundColor == UIColor.magenta)
    }
}
