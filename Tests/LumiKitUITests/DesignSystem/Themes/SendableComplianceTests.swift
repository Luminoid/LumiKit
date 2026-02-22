//
//  SendableComplianceTests.swift
//  LumiKit
//

import Testing
import UIKit

@testable import LumiKitUI

// MARK: - Sendable compliance

@Suite("Sendable compliance")
struct SendableComplianceTests {
    @Test("All configuration structs are Sendable")
    func sendableStructs() {
        func checkSendable<T: Sendable>(_ value: T) { _ = value }

        checkSendable(LMKTypographyTheme())
        checkSendable(LMKSpacingTheme())
        checkSendable(LMKCornerRadiusTheme())
        checkSendable(LMKAlphaTheme())
        checkSendable(LMKShadowTheme())
        checkSendable(LMKLayoutTheme())
        checkSendable(LMKAnimationTheme())
    }
}
