//
//  LMKToastViewTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

// MARK: - LMKToastView

@MainActor
struct LMKToastViewTests {
    @Test
    func `Toast type icon names are correct`() {
        #expect(LMKToastType.error.iconName == "exclamationmark.circle.fill")
        #expect(LMKToastType.success.iconName == "checkmark.circle.fill")
        #expect(LMKToastType.warning.iconName == "exclamationmark.triangle.fill")
        #expect(LMKToastType.info.iconName == "info.circle.fill")
    }

    @Test
    func `Toast type colors map to design tokens`() {
        #expect(LMKToastType.error.color == LMKColor.error)
        #expect(LMKToastType.success.color == LMKColor.success)
        #expect(LMKToastType.warning.color == LMKColor.warning)
        #expect(LMKToastType.info.color == LMKColor.info)
    }

    @Test
    func `Toast sets accessibility properties`() {
        let toast = LMKToastView(type: .error, message: "Something went wrong")
        #expect(toast.isAccessibilityElement)
        #expect(toast.accessibilityLabel == "Something went wrong")
        #expect(toast.accessibilityTraits == .staticText)
    }

    @Test
    func `Default duration is 3 seconds`() {
        #expect(LMKToastView.defaultDuration == 3.0)
    }
}
