//
//  LMKToggleButtonTests.swift
//  LumiKit
//

import Testing
import UIKit

@testable import LumiKitUI

// MARK: - LMKToggleButton

@Suite("LMKToggleButton")
@MainActor
struct LMKToggleButtonTests {
    @Test("accessibilityValue updates with status changes")
    func accessibilityValueUpdates() {
        let button = LMKToggleButton(titleForStatusOn: "On", titleForStatusOff: "Off")
        button.status = .off
        #expect(button.accessibilityValue == "Off")
        button.status = .on
        #expect(button.accessibilityValue == "On")
    }

    @Test("flipStatusOnTap toggles state on tap")
    func flipStatusOnTap() {
        let button = LMKToggleButton()
        button.flipStatusOnTap = true
        button.status = .off
        button.didTap()
        #expect(button.status == .on)
        button.didTap()
        #expect(button.status == .off)
    }

    @Test("flipStatusOnTap false prevents toggle")
    func flipStatusDisabled() {
        let button = LMKToggleButton()
        button.flipStatusOnTap = false
        button.status = .off
        button.didTap()
        #expect(button.status == .off)
    }

    @Test("Title and image update with status")
    func titleImageUpdate() {
        let onImage = UIImage(systemName: "heart.fill")
        let offImage = UIImage(systemName: "heart")
        let button = LMKToggleButton(
            titleForStatusOn: "Liked",
            titleForStatusOff: "Like",
            imageForStatusOn: onImage,
            imageForStatusOff: offImage
        )
        button.status = .on
        #expect(button.title(for: .normal) == "Liked")
        button.status = .off
        #expect(button.title(for: .normal) == "Like")
    }
}

// MARK: - LMKToggleButtonStrings

@Suite("LMKToggleButtonStrings")
@MainActor
struct LMKToggleButtonStringsTests {
    @Test("Default strings are English")
    func defaultStrings() {
        let strings = LMKToggleButtonStrings()
        #expect(strings.onAccessibilityValue == "On")
        #expect(strings.offAccessibilityValue == "Off")
    }

    @Test("Custom strings override accessibility values")
    func customStringsOverride() {
        let original = lmkToggleButtonStrings
        defer { lmkToggleButtonStrings = original }

        lmkToggleButtonStrings = LMKToggleButtonStrings(
            onAccessibilityValue: "Activado",
            offAccessibilityValue: "Desactivado"
        )
        let button = LMKToggleButton()
        button.status = .on
        #expect(button.accessibilityValue == "Activado")
        button.status = .off
        #expect(button.accessibilityValue == "Desactivado")
    }
}
