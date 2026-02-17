//
//  LMKToastViewTests.swift
//  LumiKit
//

import Testing
import UIKit

@testable import LumiKitUI

// MARK: - LMKToastView

@Suite("LMKToastView")
@MainActor
struct LMKToastViewTests {
    @Test("Toast type icon names are correct")
    func toastTypeIcons() {
        #expect(LMKToastType.error.iconName == "exclamationmark.circle.fill")
        #expect(LMKToastType.success.iconName == "checkmark.circle.fill")
        #expect(LMKToastType.warning.iconName == "exclamationmark.triangle.fill")
        #expect(LMKToastType.info.iconName == "info.circle.fill")
    }

    @Test("Toast type colors map to design tokens")
    func toastTypeColors() {
        #expect(LMKToastType.error.color == LMKColor.error)
        #expect(LMKToastType.success.color == LMKColor.success)
        #expect(LMKToastType.warning.color == LMKColor.warning)
        #expect(LMKToastType.info.color == LMKColor.info)
    }

    @Test("Toast sets accessibility properties")
    func toastAccessibility() {
        let toast = LMKToastView(type: .error, message: "Something went wrong")
        #expect(toast.isAccessibilityElement)
        #expect(toast.accessibilityLabel == "Something went wrong")
        #expect(toast.accessibilityTraits == .staticText)
    }

    @Test("Default duration is 3 seconds")
    func defaultDuration() {
        #expect(LMKToastView.defaultDuration == 3.0)
    }
}
