//
//  LMKCheckboxTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

@MainActor
struct LMKCheckboxTests {
    @Test
    func `Default state, glyph, and colors`() {
        let checkbox = LMKCheckbox()
        #expect(!checkbox.isChecked)
        #expect(checkbox.glyphView.tintColor === LMKColor.primary)
        #expect(checkbox.glyphView.image == UIImage(systemName: "circle"))
        #expect(checkbox.intrinsicContentSize == CGSize(width: LMKLayout.iconMedium, height: LMKLayout.iconMedium))
        checkbox.isChecked = true
        #expect(checkbox.glyphView.tintColor === LMKColor.success)
        #expect(checkbox.glyphView.image == UIImage(systemName: "checkmark.circle.fill"))
    }

    @Test
    func `setChecked is silent and the tap fires onValueChange once`() {
        let checkbox = LMKCheckbox()
        var values: [Bool] = []
        checkbox.onValueChange = { values.append($0) }
        checkbox.setChecked(true, animated: false)
        #expect(checkbox.isChecked)
        #expect(values.isEmpty)
        checkbox.perform(NSSelectorFromString("handleTap"))
        #expect(!checkbox.isChecked)
        #expect(values == [false])
        checkbox.isEnabled = false
        checkbox.perform(NSSelectorFromString("handleTap"))
        #expect(values == [false], "a disabled box ignores the tap")
    }

    @Test
    func `setChecked animated swaps the glyph from the state it showed`() {
        let checkbox = LMKCheckbox()
        let window = LMKThemeTesting.host(checkbox)
        defer { window.isHidden = true }
        checkbox.setChecked(true, animated: true)
        #expect(checkbox.isChecked)
        #expect(checkbox.glyphView.image == UIImage(systemName: "checkmark.circle.fill"))
        #expect(checkbox.accessibilityValue == "Checked")
        #expect(checkbox.accessibilityTraits.contains(.selected))
        checkbox.setChecked(true, animated: true)
        #expect(checkbox.isChecked, "setting the current state is a no-op")
        checkbox.setChecked(false, animated: true)
        #expect(checkbox.glyphView.image == UIImage(systemName: "circle"))
        #expect(!checkbox.accessibilityTraits.contains(.selected))
    }

    @Test
    func `Hit target, disabled state, and accessibility`() {
        let checkbox = LMKCheckbox()
        checkbox.frame = CGRect(x: 0, y: 0, width: 24, height: 24)
        #expect(checkbox.point(inside: CGPoint(x: 12, y: -9), with: nil))
        #expect(checkbox.accessibilityTraits.contains(.button))
        #expect(checkbox.accessibilityTraits.contains(.toggleButton))
        #expect(checkbox.accessibilityValue == "Unchecked")
        checkbox.isChecked = true
        #expect(checkbox.accessibilityValue == "Checked")
        #expect(checkbox.accessibilityTraits.contains(.selected))
        checkbox.strings = LMKCheckbox.Strings(onAccessibilityValue: "Sí", offAccessibilityValue: "No")
        #expect(checkbox.accessibilityValue == "Sí")
        checkbox.isEnabled = false
        #expect(abs(checkbox.alpha - LMKTheme.current.alpha.disabled) < 0.001)
        #expect(checkbox.accessibilityTraits.contains(.notEnabled))
        #expect(checkbox.point(inside: CGPoint(x: 12, y: 12), with: nil), "a disabled box absorbs a touch inside its bounds")
        #expect(!checkbox.point(inside: CGPoint(x: 12, y: -9), with: nil), "without the expanded area")
        checkbox.isHidden = true
        #expect(!checkbox.point(inside: CGPoint(x: 12, y: 12), with: nil))
    }

    @Test
    func `Style overrides symbols and colors`() {
        let checkbox = LMKCheckbox(style: LMKCheckbox.Style(onSymbol: "star.fill", offSymbol: "star", onColor: .red, offColor: .blue, glyphSize: 30, symbolWeight: .bold))
        #expect(checkbox.glyphView.tintColor == UIColor.blue)
        #expect(checkbox.intrinsicContentSize.width == 30)
        #expect(checkbox.glyphView.preferredSymbolConfiguration == UIImage.SymbolConfiguration(pointSize: 30, weight: .bold))
        checkbox.isChecked = true
        #expect(checkbox.glyphView.tintColor == UIColor.red)
        #expect(checkbox.glyphView.image == UIImage(systemName: "star.fill"))
    }

    @Test
    func `Pointer hover is installed`() {
        #expect(LMKCheckbox().interactions.contains { $0 is UIPointerInteraction })
        #expect(LMKSwitch().interactions.contains { $0 is UIPointerInteraction })
    }
}
