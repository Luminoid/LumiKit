//
//  LMKDeviceHelperTests.swift
//  LumiKit
//

import Testing
import UIKit

@testable import LumiKitUI

// MARK: - LMKDeviceHelper

@Suite("LMKDeviceHelper")
@MainActor
struct LMKDeviceHelperTests {
    @Test("deviceType returns a valid case")
    func deviceTypeValid() {
        let type = LMKDeviceHelper.deviceType
        // Should be one of the valid cases (we can't predict which in tests)
        switch type {
        case .iPhone, .iPad, .macCatalyst, .other:
            break // All valid
        }
    }

    @Test("screenSize returns a valid case")
    func screenSizeValid() {
        let size = LMKDeviceHelper.screenSize
        switch size {
        case .compact, .regular, .large, .extraLarge:
            break // All valid
        }
    }

    @Test("isIPad and isMacCatalyst are consistent")
    func consistency() {
        let type = LMKDeviceHelper.deviceType
        if type == .iPad {
            #expect(LMKDeviceHelper.isIPad)
            #expect(!LMKDeviceHelper.isMacCatalyst)
        } else if type == .macCatalyst {
            #expect(!LMKDeviceHelper.isIPad)
            #expect(LMKDeviceHelper.isMacCatalyst)
        }
    }
}
