//
//  LMKCornerRadiusTests.swift
//  LumiKit
//

import Testing
import UIKit

@testable import LumiKitUI

// MARK: - LMKCornerRadius

@Suite("LMKCornerRadius")
@MainActor
struct LMKCornerRadiusTests {
    @Test("Corner radii are positive and ordered")
    func cornerRadiiOrdered() {
        #expect(LMKCornerRadius.xs > 0)
        #expect(LMKCornerRadius.small > LMKCornerRadius.xs)
        #expect(LMKCornerRadius.medium > LMKCornerRadius.small)
        #expect(LMKCornerRadius.large > LMKCornerRadius.medium)
        #expect(LMKCornerRadius.xlarge > LMKCornerRadius.large)
    }
}

// MARK: - LMKCornerRadiusTheme

@Suite("LMKCornerRadiusTheme")
@MainActor
struct LMKCornerRadiusConfigurationTests {
    @Test("Default corner radius matches original values")
    func defaultCornerRadius() {
        let config = LMKCornerRadiusTheme()
        #expect(config.xs == 4)
        #expect(config.small == 8)
        #expect(config.medium == 12)
        #expect(config.large == 16)
        #expect(config.xlarge == 20)
        #expect(config.circular == 999)
    }

    @Test("Custom corner radius is applied via proxy")
    func customCornerRadius() {
        let original = LMKThemeManager.shared.cornerRadius
        defer { LMKThemeManager.shared.apply(cornerRadius: original) }

        LMKThemeManager.shared.apply(cornerRadius: .init(small: 12, medium: 16))
        #expect(LMKCornerRadius.small == 12)
        #expect(LMKCornerRadius.medium == 16)
        #expect(LMKCornerRadius.xs == 4) // unchanged
    }
}
