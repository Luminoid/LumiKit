//
//  LMKKeyboardObserverTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

// MARK: - LMKKeyboardObserver

@MainActor
struct LMKKeyboardObserverTests {
    @Test
    func `Initial currentHeight is 0`() {
        let observer = LMKKeyboardObserver()
        #expect(observer.currentHeight == 0)
    }

    @Test
    func `startObserving and stopObserving don't crash`() {
        let observer = LMKKeyboardObserver()
        observer.startObserving()
        observer.stopObserving()
    }

    @Test
    func `KeyboardInfo isVisible is true when height > 0`() {
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

    @Test
    func `Show notification updates currentHeight`() {
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

    @Test
    func `Hide notification resets currentHeight to 0`() {
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

    @Test
    func `onKeyboardChange callback fires on show`() {
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

    @Test
    func `Duplicate height does not fire callback`() {
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

    @Test
    func `stopObserving prevents future notifications from updating height`() {
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

    @Test
    func `startObserving twice cleans up previous observers`() {
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
