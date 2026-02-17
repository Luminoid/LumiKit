//
//  LMKLoadingStateViewTests.swift
//  LumiKit
//

import Testing
import UIKit

@testable import LumiKitUI

// MARK: - LMKLoadingStateView

@Suite("LMKLoadingStateView")
@MainActor
struct LMKLoadingStateViewTests {
    @Test("startLoading shows view and sets accessibility")
    func startLoading() {
        let view = LMKLoadingStateView()
        view.startLoading(message: "Loading plants...")
        #expect(!view.isHidden)
        #expect(view.accessibilityLabel == "Loading plants...")
    }

    @Test("stopLoading hides view")
    func stopLoading() {
        let view = LMKLoadingStateView()
        view.startLoading(message: "Loading")
        view.stopLoading()
        #expect(view.isHidden)
    }

    @Test("updateMessage sets label text and accessibility")
    func updateMessage() {
        let view = LMKLoadingStateView()
        view.updateMessage("Step 2 of 3")
        #expect(view.accessibilityLabel == "Step 2 of 3")
    }

    @Test("Accessibility traits include updatesFrequently")
    func accessibilityTraits() {
        let view = LMKLoadingStateView()
        #expect(view.accessibilityTraits.contains(.updatesFrequently))
    }

    @Test("Overlay style has non-clear background")
    func overlayStyle() {
        let view = LMKLoadingStateView(overlayStyle: true)
        #expect(view.backgroundColor != .clear)
    }
}
