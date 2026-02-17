//
//  LMKChipViewTests.swift
//  LumiKit
//

import Testing
import UIKit

@testable import LumiKitUI

// MARK: - LMKChipView

@Suite("LMKChipView")
@MainActor
struct LMKChipViewTests {
    @Test("Filled style has non-clear background")
    func filledBackground() {
        let chip = LMKChipView(text: "Test", style: .filled)
        #expect(chip.backgroundColor != .clear)
        #expect(chip.backgroundColor != nil)
    }

    @Test("Outlined style has clear background and border")
    func outlinedBackground() {
        let chip = LMKChipView(text: "Test", style: .outlined)
        #expect(chip.backgroundColor == .clear)
        #expect(chip.layer.borderWidth > 0)
    }

    @Test("Configure sets accessibility label")
    func accessibilityLabel() {
        let chip = LMKChipView(text: "Indoor")
        #expect(chip.accessibilityLabel == "Indoor")
        // Default trait is .staticText; becomes .button when tapHandler is set
        #expect(chip.accessibilityTraits == .staticText)
        chip.tapHandler = {}
        #expect(chip.accessibilityTraits == .button)
    }
}
