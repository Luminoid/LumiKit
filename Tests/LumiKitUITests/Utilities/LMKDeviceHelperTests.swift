//
//  LMKDeviceHelperTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

// MARK: - LMKDeviceHelper

@MainActor
struct LMKDeviceHelperTests {
    @Test
    func `deviceType returns a valid case`() {
        let type = LMKDeviceHelper.deviceType
        // Should be one of the valid cases (we can't predict which in tests)
        switch type {
        case .iPhone, .iPad, .macCatalyst, .other:
            break // All valid
        }
    }

    @Test
    func `screenSize returns a valid case`() {
        let size = LMKDeviceHelper.screenSize
        switch size {
        case .compact, .regular, .large, .extraLarge:
            break // All valid
        }
    }

    @Test
    func `isIPad and isMacCatalyst are consistent`() {
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
