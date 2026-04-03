//
//  LMKSceneUtilTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

// MARK: - LMKSceneUtil

@MainActor
struct LMKSceneUtilTests {
    @Test
    func `getKeyWindow returns optional window`() {
        // In test environment, may or may not have a key window
        let window = LMKSceneUtil.getKeyWindow()
        // Just verify it doesn't crash and returns the right type
        _ = window
    }

    @Test
    func `screenScale returns positive value`() {
        let scale = LMKSceneUtil.screenScale
        #expect(scale > 0)
    }

    @Test
    func `screenScale fallback is 3.0 or actual screen scale`() {
        let scale = LMKSceneUtil.screenScale
        // Should be either the actual screen scale or the 3.0 fallback
        #expect(scale == 1.0 || scale == 2.0 || scale == 3.0)
    }
}
