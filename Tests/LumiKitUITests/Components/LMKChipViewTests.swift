//
//  LMKChipViewTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

// MARK: - LMKChipView

@MainActor
struct LMKChipViewTests {
    @Test
    func `Filled style has non-clear background`() {
        let chip = LMKChipView(text: "Test", style: .filled)
        #expect(chip.backgroundColor != .clear)
        #expect(chip.backgroundColor != nil)
    }

    @Test
    func `Outlined style has clear background and border`() {
        let chip = LMKChipView(text: "Test", style: .outlined)
        #expect(chip.backgroundColor == .clear)
        #expect(chip.layer.borderWidth > 0)
    }

    @Test
    func `Configure sets accessibility label`() {
        let chip = LMKChipView(text: "Indoor")
        #expect(chip.accessibilityLabel == "Indoor")
        #expect(chip.accessibilityTraits == .staticText)
        chip.tapHandler = {}
        #expect(chip.accessibilityTraits == .button)
    }

    // MARK: - Dismiss

    @Test
    func `Dismiss handler shows xmark and sets button trait`() {
        let chip = LMKChipView(text: "Filter", style: .outlined)
        #expect(chip.accessibilityTraits == .staticText)

        chip.dismissHandler = {}
        #expect(chip.accessibilityTraits == .button)
    }

    @Test
    func `Clearing dismiss handler removes button trait`() {
        let chip = LMKChipView(text: "Filter", style: .outlined)
        chip.dismissHandler = {}
        #expect(chip.accessibilityTraits == .button)

        chip.dismissHandler = nil
        #expect(chip.accessibilityTraits == .staticText)
    }

    // MARK: - Selection

    @Test
    func `Selection toggles filled chip to outlined appearance`() {
        let chip = LMKChipView(text: "Active", style: .filled)
        let filledBackground = chip.backgroundColor

        chip.isChipSelected = true
        #expect(chip.backgroundColor == .clear)
        #expect(chip.layer.borderWidth > 0)

        chip.isChipSelected = false
        #expect(chip.backgroundColor == filledBackground)
    }

    @Test
    func `Selection toggles outlined chip to filled appearance`() {
        let chip = LMKChipView(text: "Active", style: .outlined)
        #expect(chip.backgroundColor == .clear)

        chip.isChipSelected = true
        #expect(chip.backgroundColor != .clear)
        #expect(chip.backgroundColor != nil)
        #expect(chip.layer.borderWidth == 0)
    }

    // MARK: - Combined

    @Test
    func `Tap handler and dismiss handler both set button trait`() {
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
