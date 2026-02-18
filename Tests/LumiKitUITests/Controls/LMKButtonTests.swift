//
//  LMKButtonTests.swift
//  LumiKit
//

import Testing
import UIKit

@testable import LumiKitUI

// MARK: - LMKButton

@Suite("LMKButton")
@MainActor
struct LMKButtonTests {
    @Test("tapHandler is called on didTap")
    func tapHandlerCalled() {
        let button = LMKButton()
        var called = false
        button.tapHandler = { called = true }
        button.didTap()
        #expect(called)
    }

    @Test("didTapHandler receives button instance")
    func didTapHandlerReceivesButton() {
        let button = LMKButton()
        var received: LMKButton?
        button.didTapHandler = { received = $0 }
        button.didTap()
        #expect(received === button)
    }

    @Test("Both handlers fire on single tap")
    func bothHandlersFire() {
        let button = LMKButton()
        var tapCalled = false
        var didTapCalled = false
        button.tapHandler = { tapCalled = true }
        button.didTapHandler = { _ in didTapCalled = true }
        button.didTap()
        #expect(tapCalled)
        #expect(didTapCalled)
    }

    @Test("pressAnimationEnabled defaults to false")
    func pressAnimationDefaultsFalse() {
        let button = LMKButton()
        #expect(!button.pressAnimationEnabled)
    }

    @Test("imageContentMode defaults to scaleAspectFit")
    func imageContentModeDefault() {
        let button = LMKButton()
        #expect(button.imageContentMode == .scaleAspectFit)
    }

    @Test("No crash when tapHandler is nil")
    func nilHandlerNoCrash() {
        let button = LMKButton()
        button.tapHandler = nil
        button.didTapHandler = nil
        button.didTap()
    }
}
