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
        #expect(toggle.thumbView.backgroundColor === LMKColor.onAccent)
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
    func `Disabled switches dim, absorb touches inside their bounds, and expose the trait`() {
        let toggle = LMKSwitch()
        toggle.frame = CGRect(x: 0, y: 0, width: 52, height: 30)
        toggle.isEnabled = false
        #expect(abs(toggle.alpha - LMKTheme.current.alpha.disabled) < 0.001)
        #expect(toggle.accessibilityTraits.contains(.notEnabled))
        #expect(toggle.point(inside: CGPoint(x: 10, y: 10), with: nil), "a disabled switch absorbs a touch like UISwitch")
        #expect(!toggle.point(inside: CGPoint(x: 26, y: -6), with: nil), "without the expanded area")
        toggle.isEnabled = true
        #expect(toggle.alpha == 1)
        #expect(toggle.point(inside: CGPoint(x: 26, y: -6), with: nil), "44pt hit target")
        toggle.isHidden = true
        #expect(!toggle.point(inside: CGPoint(x: 10, y: 10), with: nil))
    }

    @Test
    func `setOn animated really animates the thumb and the track`() {
        let toggle = LMKSwitch()
        let window = LMKThemeTesting.host(toggle)
        defer { window.isHidden = true }
        toggle.frame = CGRect(x: 0, y: 0, width: 52, height: 30)
        toggle.layoutIfNeeded()
        toggle.setOn(true, animated: true)
        #expect(toggle.isOn)
        #expect(toggle.thumbView.frame.maxX == 50, "the model value lands immediately")
        #expect(toggle.accessibilityValue == LMKSwitch.strings.onAccessibilityValue)
        if LMKAnimation.shouldAnimate, UIView.areAnimationsEnabled {
            #expect(toggle.thumbView.layer.animationKeys()?.isEmpty == false, "the thumb slides instead of jumping")
            #expect(toggle.trackView.layer.animationKeys()?.isEmpty == false, "the track cross-fades")
        }
        toggle.setOn(true, animated: true)
        #expect(toggle.isOn, "setting the current state is a no-op")
    }

    @Test
    func `A tap toggles once, animates, and reports the new value`() {
        let toggle = LMKSwitch()
        var received: [Bool] = []
        toggle.onValueChange = { received.append($0) }
        toggle.perform(NSSelectorFromString("handleTap"))
        #expect(toggle.isOn)
        #expect(received == [true])
        toggle.isEnabled = false
        toggle.perform(NSSelectorFromString("handleTap"))
        #expect(received == [true], "a disabled switch ignores the tap")
        #expect(toggle.accessibilityTraits.contains(.toggleButton))
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
    func `Thumb inset and thumb shadow apply`() {
        let toggle = LMKSwitch(style: LMKSwitch.Style(thumbInset: 5, thumbShadow: .hidden))
        toggle.frame = CGRect(x: 0, y: 0, width: 52, height: 30)
        toggle.layoutIfNeeded()
        #expect(toggle.thumbView.frame == CGRect(x: 5, y: 5, width: 20, height: 20))
        #expect(toggle.thumbView.layer.shadowOpacity == 0)
        toggle.style.thumbShadow = .level(.level3)
        #expect(toggle.thumbView.layer.shadowOpacity > 0)
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
