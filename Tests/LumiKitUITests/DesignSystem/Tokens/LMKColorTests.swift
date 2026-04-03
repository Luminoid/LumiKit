//
//  LMKColorTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

// MARK: - LMKColor

@MainActor
struct LMKColorTests {
    @Test
    func `LMKColor proxies to active theme`() {
        LMKThemeManager.shared.apply(LMKDefaultTheme())
        #expect(LMKColor.primary == LMKThemeManager.shared.current.primary)
        #expect(LMKColor.error == LMKThemeManager.shared.current.error)
        #expect(LMKColor.textPrimary == LMKThemeManager.shared.current.textPrimary)
    }
}

// MARK: - LMKColor proxy

@MainActor
struct LMKColorProxyTests {
    @Test
    func `imageBorder token resolves from theme`() {
        let color = LMKColor.imageBorder
        #expect(color == LMKThemeManager.shared.current.imageBorder)
    }

    @Test
    func `photoBrowserBackground token resolves from theme`() {
        let color = LMKColor.photoBrowserBackground
        #expect(color == LMKThemeManager.shared.current.photoBrowserBackground)
    }
}
