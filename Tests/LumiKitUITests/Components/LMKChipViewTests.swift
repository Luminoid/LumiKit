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
        #expect(chip.accessibilityTraits == .staticText)
        chip.tapHandler = {}
        #expect(chip.accessibilityTraits == .button)
    }

    // MARK: - Dismiss

    @Test("Dismiss handler shows xmark and sets button trait")
    func dismissHandler() {
        let chip = LMKChipView(text: "Filter", style: .outlined)
        #expect(chip.accessibilityTraits == .staticText)

        chip.dismissHandler = {}
        #expect(chip.accessibilityTraits == .button)
    }

    @Test("Clearing dismiss handler removes button trait")
    func clearDismissHandler() {
        let chip = LMKChipView(text: "Filter", style: .outlined)
        chip.dismissHandler = {}
        #expect(chip.accessibilityTraits == .button)

        chip.dismissHandler = nil
        #expect(chip.accessibilityTraits == .staticText)
    }

    // MARK: - Selection

    @Test("Selection toggles filled chip to outlined appearance")
    func selectionTogglesFilled() {
        let chip = LMKChipView(text: "Active", style: .filled)
        let filledBackground = chip.backgroundColor

        chip.isChipSelected = true
        #expect(chip.backgroundColor == .clear)
        #expect(chip.layer.borderWidth > 0)

        chip.isChipSelected = false
        #expect(chip.backgroundColor == filledBackground)
    }

    @Test("Selection toggles outlined chip to filled appearance")
    func selectionTogglesOutlined() {
        let chip = LMKChipView(text: "Active", style: .outlined)
        #expect(chip.backgroundColor == .clear)

        chip.isChipSelected = true
        #expect(chip.backgroundColor != .clear)
        #expect(chip.backgroundColor != nil)
        #expect(chip.layer.borderWidth == 0)
    }

    // MARK: - Combined

    @Test("Tap handler and dismiss handler both set button trait")
    func bothHandlers() {
        let chip = LMKChipView(text: "Both")
        chip.tapHandler = {}
        chip.dismissHandler = {}
        #expect(chip.accessibilityTraits == .button)

        chip.tapHandler = nil
        #expect(chip.accessibilityTraits == .button)

        chip.dismissHandler = nil
        #expect(chip.accessibilityTraits == .staticText)
    }
}
