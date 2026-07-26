//
//  LMKCountdownConfirmationTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

// MARK: - LMKCountdownConfirmation

@MainActor
struct LMKCountdownConfirmationTests {
    // MARK: - Helpers

    private func makePresenter() -> (UIViewController, UIWindow) {
        let presenter = UIViewController()
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 375, height: 812))
        window.rootViewController = presenter
        window.makeKeyAndVisible()
        return (presenter, window)
    }

    private func presentedDialog(_ presenter: UIViewController) -> LMKCountdownConfirmationViewController? {
        presenter.presentedViewController as? LMKCountdownConfirmationViewController
    }

    // MARK: - Presentation

    @Test
    func `Present shows countdown dialog as presented view controller`() {
        let (presenter, window) = makePresenter()
        _ = window

        LMKCountdownConfirmation.present(
            on: presenter,
            title: "Delete?",
            confirmTitle: "Delete",
            onConfirm: {}
        )

        #expect(presentedDialog(presenter) != nil)
    }

    @Test
    func `Presented dialog uses over-full-screen presentation`() {
        let (presenter, window) = makePresenter()
        _ = window

        LMKCountdownConfirmation.present(
            on: presenter,
            title: "Delete?",
            confirmTitle: "Delete",
            onConfirm: {}
        )

        let dialog = presentedDialog(presenter)
        #expect(dialog?.modalPresentationStyle == .overFullScreen)
        #expect(dialog?.isModalInPresentation == true)
    }

    // MARK: - Initial State

    @Test
    func `Confirm button is disabled initially`() {
        let (presenter, window) = makePresenter()
        _ = window

        LMKCountdownConfirmation.present(
            on: presenter,
            title: "Delete?",
            confirmTitle: "Delete",
            countdownSeconds: 3,
            onConfirm: {}
        )

        let dialog = presentedDialog(presenter)
        dialog?.loadViewIfNeeded()
        #expect(dialog?.isConfirmEnabled == false)
    }

    @Test
    func `Confirm title includes countdown suffix initially`() {
        let (presenter, window) = makePresenter()
        _ = window

        LMKCountdownConfirmation.present(
            on: presenter,
            title: "Delete?",
            confirmTitle: "Delete",
            countdownSeconds: 5,
            onConfirm: {}
        )

        let dialog = presentedDialog(presenter)
        dialog?.loadViewIfNeeded()
        #expect(dialog?.confirmDisplayedTitle == "Delete (5)")
    }

    @Test
    func `Default countdown is three seconds`() {
        let (presenter, window) = makePresenter()
        _ = window

        LMKCountdownConfirmation.present(
            on: presenter,
            title: "Delete?",
            confirmTitle: "Remove",
            onConfirm: {}
        )

        let dialog = presentedDialog(presenter)
        dialog?.loadViewIfNeeded()
        #expect(dialog?.countdownSeconds == 3)
        #expect(dialog?.confirmDisplayedTitle == "Remove (3)")
    }

    // MARK: - Cancel Button

    @Test
    func `Cancel button uses LMKAlertPresenter cancel string`() {
        let original = LMKAlertPresenter.strings
        defer { LMKAlertPresenter.strings = original }
        LMKAlertPresenter.strings = .init(cancel: "Abbrechen")

        let (presenter, window) = makePresenter()
        _ = window
        LMKCountdownConfirmation.present(
            on: presenter,
            title: "Delete?",
            confirmTitle: "Delete",
            onConfirm: {}
        )

        let dialog = presentedDialog(presenter)
        dialog?.loadViewIfNeeded()
        #expect(dialog?.cancelDisplayedTitle == "Abbrechen")
    }

    // MARK: - Countdown Completion

    @Test
    func `Confirm button enables after countdown completes`() async throws {
        let (presenter, window) = makePresenter()
        _ = window

        LMKCountdownConfirmation.present(
            on: presenter,
            title: "Delete?",
            confirmTitle: "Delete",
            countdownSeconds: 1,
            onConfirm: {}
        )

        let dialog = presentedDialog(presenter)
        dialog?.loadViewIfNeeded()

        // Poll — the countdown's `Task.sleep` continuation has to re-acquire the
        // main actor, and every suite in this target is main-actor isolated, so
        // the resume can be starved for as long as the whole target takes to run.
        // The budget must therefore exceed total suite wall time, not the 1s
        // countdown: a 5s budget passed at 844 tests and started failing at 860.
        // Polling exits as soon as the button enables, so a generous ceiling
        // costs nothing when the behavior is correct.
        let deadline = Date().addingTimeInterval(60)
        while Date() < deadline, dialog?.isConfirmEnabled != true {
            try await Task.sleep(for: .milliseconds(100))
        }
        #expect(dialog?.isConfirmEnabled == true)
        #expect(dialog?.confirmDisplayedTitle == "Delete")
    }

    @Test
    func `Zero-second countdown enables confirm immediately`() {
        let (presenter, window) = makePresenter()
        _ = window

        LMKCountdownConfirmation.present(
            on: presenter,
            title: "Delete?",
            confirmTitle: "Delete",
            countdownSeconds: 0,
            onConfirm: {}
        )

        let dialog = presentedDialog(presenter)
        dialog?.loadViewIfNeeded()
        #expect(dialog?.isConfirmEnabled == true)
        #expect(dialog?.confirmDisplayedTitle == "Delete")
    }

    // MARK: - Dismissal Safety

    @Test
    func `Dismissing dialog before countdown completes does not crash`() async throws {
        let (presenter, window) = makePresenter()
        _ = window

        LMKCountdownConfirmation.present(
            on: presenter,
            title: "Delete?",
            confirmTitle: "Delete",
            countdownSeconds: 3,
            onConfirm: {}
        )

        // Dismiss immediately. The countdown task weakly captures `self`
        // and exits cleanly once the dialog is released; viewDidDisappear
        // cancels it eagerly.
        presenter.dismiss(animated: false)

        // Wait past the original countdown to ensure no late mutation crashes.
        try await Task.sleep(for: .seconds(4))
    }
}
