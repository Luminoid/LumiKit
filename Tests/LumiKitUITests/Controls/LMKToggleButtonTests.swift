//
//  LMKToggleButtonTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

// MARK: - LMKToggleButton

@MainActor
struct LMKToggleButtonTests {
    @Test
    func `accessibilityValue updates with status changes`() {
        let button = LMKToggleButton(titleForStatusOn: "On", titleForStatusOff: "Off")
        button.status = .off
        #expect(button.accessibilityValue == "Off")
        button.status = .on
        #expect(button.accessibilityValue == "On")
    }

    @Test
    func `flipStatusOnTap toggles state on tap`() {
        let button = LMKToggleButton()
        button.flipStatusOnTap = true
        button.status = .off
        button.didTap()
        #expect(button.status == .on)
        button.didTap()
        #expect(button.status == .off)
    }

    @Test
    func `flipStatusOnTap false prevents toggle`() {
        let button = LMKToggleButton()
        button.flipStatusOnTap = false
        button.status = .off
        button.didTap()
        #expect(button.status == .off)
    }

    @Test
    func `Title and image update with status`() {
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

@MainActor
struct LMKToggleButtonStringsTests {
    @Test
    func `Default strings are English`() {
        let strings = LMKToggleButtonStrings()
        #expect(strings.onAccessibilityValue == "On")
        #expect(strings.offAccessibilityValue == "Off")
    }

    @Test
    func `Custom strings override accessibility values`() {
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
