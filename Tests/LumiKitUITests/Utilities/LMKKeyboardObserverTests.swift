//
//  LMKKeyboardObserverTests.swift
//  LumiKit
//

import Testing
import UIKit

@testable import LumiKitUI

// MARK: - LMKKeyboardObserver

@Suite("LMKKeyboardObserver")
@MainActor
struct LMKKeyboardObserverTests {
    @Test("Initial currentHeight is 0")
    func initialHeight() {
        let observer = LMKKeyboardObserver()
        #expect(observer.currentHeight == 0)
    }

    @Test("startObserving and stopObserving don't crash")
    func startStopObserving() {
        let observer = LMKKeyboardObserver()
        observer.startObserving()
        observer.stopObserving()
        // No crash = success
    }

    @Test("KeyboardInfo isVisible is true when height > 0")
    func keyboardInfoVisibility() {
        let info = LMKKeyboardObserver.KeyboardInfo(
            height: 300,
            animationDuration: 0.25,
            animationOptions: .curveEaseInOut
        )
        #expect(info.isVisible)

        let hidden = LMKKeyboardObserver.KeyboardInfo(
            height: 0,
            animationDuration: 0.25,
            animationOptions: .curveEaseInOut
        )
        #expect(!hidden.isVisible)
    }
}
