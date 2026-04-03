//
//  LMKLoadingStateViewTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

// MARK: - LMKLoadingStateView

@MainActor
struct LMKLoadingStateViewTests {
    @Test
    func `startLoading shows view and sets accessibility`() {
        let view = LMKLoadingStateView()
        view.startLoading(message: "Loading plants...")
        #expect(!view.isHidden)
        #expect(view.accessibilityLabel == "Loading plants...")
    }

    @Test
    func `stopLoading hides view`() {
        let view = LMKLoadingStateView()
        view.startLoading(message: "Loading")
        view.stopLoading()
        #expect(view.isHidden)
    }

    @Test
    func `updateMessage sets label text and accessibility`() {
        let view = LMKLoadingStateView()
        view.updateMessage("Step 2 of 3")
        #expect(view.accessibilityLabel == "Step 2 of 3")
    }

    @Test
    func `Accessibility traits include updatesFrequently`() {
        let view = LMKLoadingStateView()
        #expect(view.accessibilityTraits.contains(.updatesFrequently))
    }

    @Test
    func `Overlay style has non-clear background`() {
        let view = LMKLoadingStateView(overlayStyle: true)
        #expect(view.backgroundColor != .clear)
    }
}
