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

    // MARK: - Notification Simulation

    @Test("Show notification updates currentHeight")
    func showNotificationUpdatesHeight() {
        let observer = LMKKeyboardObserver()
        observer.startObserving()

        let keyboardFrame = CGRect(x: 0, y: 500, width: 375, height: 346)
        NotificationCenter.default.post(
            name: UIResponder.keyboardWillShowNotification,
            object: nil,
            userInfo: [
                UIResponder.keyboardFrameEndUserInfoKey: NSValue(cgRect: keyboardFrame),
                UIResponder.keyboardAnimationDurationUserInfoKey: 0.25,
                UIResponder.keyboardAnimationCurveUserInfoKey: UInt(7),
            ]
        )

        #expect(observer.currentHeight == 346)
        observer.stopObserving()
    }

    @Test("Hide notification resets currentHeight to 0")
    func hideNotificationResetsHeight() {
        let observer = LMKKeyboardObserver()
        observer.startObserving()

        // First show
        let keyboardFrame = CGRect(x: 0, y: 500, width: 375, height: 346)
        NotificationCenter.default.post(
            name: UIResponder.keyboardWillShowNotification,
            object: nil,
            userInfo: [
                UIResponder.keyboardFrameEndUserInfoKey: NSValue(cgRect: keyboardFrame),
                UIResponder.keyboardAnimationDurationUserInfoKey: 0.25,
                UIResponder.keyboardAnimationCurveUserInfoKey: UInt(7),
            ]
        )
        #expect(observer.currentHeight == 346)

        // Then hide
        NotificationCenter.default.post(
            name: UIResponder.keyboardWillHideNotification,
            object: nil,
            userInfo: [
                UIResponder.keyboardFrameEndUserInfoKey: NSValue(cgRect: .zero),
                UIResponder.keyboardAnimationDurationUserInfoKey: 0.25,
                UIResponder.keyboardAnimationCurveUserInfoKey: UInt(7),
            ]
        )
        #expect(observer.currentHeight == 0)
        observer.stopObserving()
    }

    @Test("onKeyboardChange callback fires on show")
    func callbackFiresOnShow() {
        let observer = LMKKeyboardObserver()
        var receivedInfo: LMKKeyboardObserver.KeyboardInfo?
        observer.onKeyboardChange = { info in
            receivedInfo = info
        }
        observer.startObserving()

        let keyboardFrame = CGRect(x: 0, y: 500, width: 375, height: 300)
        NotificationCenter.default.post(
            name: UIResponder.keyboardWillShowNotification,
            object: nil,
            userInfo: [
                UIResponder.keyboardFrameEndUserInfoKey: NSValue(cgRect: keyboardFrame),
                UIResponder.keyboardAnimationDurationUserInfoKey: 0.3,
                UIResponder.keyboardAnimationCurveUserInfoKey: UInt(7),
            ]
        )

        #expect(receivedInfo != nil)
        #expect(receivedInfo?.height == 300)
        #expect(receivedInfo?.animationDuration == 0.3)
        #expect(receivedInfo?.isVisible == true)
        observer.stopObserving()
    }

    @Test("Duplicate height does not fire callback")
    func duplicateHeightNoCallback() {
        let observer = LMKKeyboardObserver()
        var callCount = 0
        observer.onKeyboardChange = { _ in
            callCount += 1
        }
        observer.startObserving()

        let keyboardFrame = CGRect(x: 0, y: 500, width: 375, height: 300)
        let userInfo: [AnyHashable: Any] = [
            UIResponder.keyboardFrameEndUserInfoKey: NSValue(cgRect: keyboardFrame),
            UIResponder.keyboardAnimationDurationUserInfoKey: 0.25,
            UIResponder.keyboardAnimationCurveUserInfoKey: UInt(7),
        ]

        NotificationCenter.default.post(name: UIResponder.keyboardWillShowNotification, object: nil, userInfo: userInfo)
        NotificationCenter.default.post(name: UIResponder.keyboardWillShowNotification, object: nil, userInfo: userInfo)

        #expect(callCount == 1)
        observer.stopObserving()
    }

    @Test("stopObserving prevents future notifications from updating height")
    func stopObservingPreventsUpdates() {
        let observer = LMKKeyboardObserver()
        observer.startObserving()
        observer.stopObserving()

        let keyboardFrame = CGRect(x: 0, y: 500, width: 375, height: 346)
        NotificationCenter.default.post(
            name: UIResponder.keyboardWillShowNotification,
            object: nil,
            userInfo: [
                UIResponder.keyboardFrameEndUserInfoKey: NSValue(cgRect: keyboardFrame),
                UIResponder.keyboardAnimationDurationUserInfoKey: 0.25,
                UIResponder.keyboardAnimationCurveUserInfoKey: UInt(7),
            ]
        )

        #expect(observer.currentHeight == 0)
    }

    @Test("startObserving twice cleans up previous observers")
    func startObservingTwice() {
        let observer = LMKKeyboardObserver()
        var callCount = 0
        observer.onKeyboardChange = { _ in
            callCount += 1
        }
        observer.startObserving()
        observer.startObserving()

        let keyboardFrame = CGRect(x: 0, y: 500, width: 375, height: 300)
        NotificationCenter.default.post(
            name: UIResponder.keyboardWillShowNotification,
            object: nil,
            userInfo: [
                UIResponder.keyboardFrameEndUserInfoKey: NSValue(cgRect: keyboardFrame),
                UIResponder.keyboardAnimationDurationUserInfoKey: 0.25,
                UIResponder.keyboardAnimationCurveUserInfoKey: UInt(7),
            ]
        )

        // Should only fire once (no duplicate observers)
        #expect(callCount == 1)
        observer.stopObserving()
    }
}
