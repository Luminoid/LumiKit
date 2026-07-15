//
//  LMKButtonTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

// MARK: - LMKButton

@MainActor
struct LMKButtonTests {
    @Test
    func `tapHandler is called on didTap`() {
        let button = LMKButton()
        var called = false
        button.tapHandler = { called = true }
        button.didTap()
        #expect(called)
    }

    @Test
    func `didTapHandler receives button instance`() {
        let button = LMKButton()
        var received: LMKButton?
        button.didTapHandler = { received = $0 }
        button.didTap()
        #expect(received === button)
    }

    @Test
    func `Pointer interaction is enabled by default`() {
        let button = LMKButton()
        #expect(button.isPointerInteractionEnabled)
    }

    @Test
    func `Both handlers fire on single tap`() {
        let button = LMKButton()
        var tapCalled = false
        var didTapCalled = false
        button.tapHandler = { tapCalled = true }
        button.didTapHandler = { _ in didTapCalled = true }
        button.didTap()
        #expect(tapCalled)
        #expect(didTapCalled)
    }

    @Test
    func `pressAnimationEnabled defaults to false`() {
        let button = LMKButton()
        #expect(!button.pressAnimationEnabled)
    }

    @Test
    func `imageContentMode defaults to scaleAspectFit`() {
        let button = LMKButton()
        #expect(button.imageContentMode == .scaleAspectFit)
    }

    @Test
    func `No crash when tapHandler is nil`() {
        let button = LMKButton()
        button.tapHandler = nil
        button.didTapHandler = nil
        button.didTap()
    }

    // MARK: - Style Tests

    @Test
    func `Ghost style applies correctly`() {
        let button = LMKButton(title: "Link", style: .ghost(.red))
        #expect(button.configuration != nil)
        #expect(button.pressAnimationEnabled)
    }

    @Test
    func `IconOnly style applies correctly`() {
        let button = LMKButton(frame: .zero)
        button.applyIconStyle(.iconOnly(.blue), iconName: "chevron.left")
        #expect(button.configuration?.image != nil)
        #expect(button.configuration?.title == nil)
    }

    @Test
    func `Filled style uses capsule corners`() {
        let button = LMKButton(title: "Save", style: .filled(.red))
        #expect(button.configuration?.cornerStyle == .capsule)
    }

    @Test
    func `Loading state shows activity indicator`() {
        let button = LMKButton(title: "Save", style: .filled(.red))
        button.isLoading = true
        #expect(button.configuration?.showsActivityIndicator == true)
        #expect(button.configuration?.title == " ") // Space preserves button height
        #expect(button.isUserInteractionEnabled == false)
    }

    @Test
    func `Loading state restores title when done`() {
        let button = LMKButton(title: "Save", style: .filled(.red))
        button.isLoading = true
        button.isLoading = false
        #expect(button.configuration?.title == "Save")
        #expect(button.isUserInteractionEnabled == true)
    }
}
