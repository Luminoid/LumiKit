//
//  SendableComplianceTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

// MARK: - Sendable compliance

struct SendableComplianceTests {
    @Test
    func `All configuration structs are Sendable`() {
        func checkSendable(_ value: some Sendable) {
            _ = value
        }

        checkSendable(LMKTypographyTheme())
        checkSendable(LMKSpacingTheme())
        checkSendable(LMKCornerRadiusTheme())
        checkSendable(LMKAlphaTheme())
        checkSendable(LMKShadowTheme())
        checkSendable(LMKLayoutTheme())
        checkSendable(LMKAnimationTheme())
    }
}
