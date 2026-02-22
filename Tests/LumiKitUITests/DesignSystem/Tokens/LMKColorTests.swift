//
//  LMKColorTests.swift
//  LumiKit
//

import Testing
import UIKit

@testable import LumiKitUI

// MARK: - LMKColor

@Suite("LMKColor")
@MainActor
struct LMKColorTests {
    @Test("LMKColor proxies to active theme")
    func colorProxiesToTheme() {
        LMKThemeManager.shared.apply(LMKDefaultTheme())
        #expect(LMKColor.primary == LMKThemeManager.shared.current.primary)
        #expect(LMKColor.error == LMKThemeManager.shared.current.error)
        #expect(LMKColor.textPrimary == LMKThemeManager.shared.current.textPrimary)
    }

}

// MARK: - LMKColor proxy

@Suite("LMKColor proxy")
@MainActor
struct LMKColorProxyTests {
    @Test("imageBorder token resolves from theme")
    func imageBorderToken() {
        let color = LMKColor.imageBorder
        #expect(color == LMKThemeManager.shared.current.imageBorder)
    }

    @Test("photoBrowserBackground token resolves from theme")
    func photoBrowserBackgroundToken() {
        let color = LMKColor.photoBrowserBackground
        #expect(color == LMKThemeManager.shared.current.photoBrowserBackground)
    }
}
