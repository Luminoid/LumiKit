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

    // MARK: - Presentation

    @Test
    func `Present shows alert as presented view controller`() {
        let (presenter, window) = makePresenter()
        _ = window

        LMKCountdownConfirmation.present(
            on: presenter,
            title: "Delete?",
            confirmTitle: "Delete",
            onConfirm: {}
        )

        #expect(presenter.presentedViewController is UIAlertController)
    }

    @Test
    func `Alert has cancel and confirm actions`() {
        let (presenter, window) = makePresenter()
        _ = window

        LMKCountdownConfirmation.present(
            on: presenter,
            title: "Delete?",
            confirmTitle: "Delete",
            onConfirm: {}
        )

        let alert = presenter.presentedViewController as? UIAlertController
        #expect(alert?.actions.count == 2)
        #expect(alert?.actions[0].style == .cancel)
        #expect(alert?.actions[1].style == .destructive)
    }

    // MARK: - Initial State

    @Test
    func `Confirm action is disabled initially`() {
        let (presenter, window) = makePresenter()
        _ = window

        LMKCountdownConfirmation.present(
            on: presenter,
            title: "Delete?",
            confirmTitle: "Delete",
            countdownSeconds: 3,
            onConfirm: {}
        )

        let alert = presenter.presentedViewController as? UIAlertController
        let confirm = alert?.actions[1]
        #expect(confirm?.isEnabled == false)
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

        let alert = presenter.presentedViewController as? UIAlertController
        #expect(alert?.actions[1].title == "Delete (5)")
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

        let alert = presenter.presentedViewController as? UIAlertController
        #expect(alert?.actions[1].title == "Remove (3)")
    }

    // MARK: - Cancel Button

    @Test
    func `Cancel action uses LMKAlertPresenter cancel string`() {
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

        let alert = presenter.presentedViewController as? UIAlertController
        #expect(alert?.actions[0].title == "Abbrechen")
    }

    // MARK: - Countdown Completion

    @Test
    func `Confirm action enables after countdown completes`() async throws {
        let (presenter, window) = makePresenter()
        _ = window

        LMKCountdownConfirmation.present(
            on: presenter,
            title: "Delete?",
            confirmTitle: "Delete",
            countdownSeconds: 1,
            onConfirm: {}
        )

        // Poll the action — `Task.sleep` inside the countdown can be delayed
        // when the main actor is busy under parallel test execution.
        let alert = presenter.presentedViewController as? UIAlertController
        let confirm = alert?.actions[1]
        let deadline = Date().addingTimeInterval(5)
        while Date() < deadline, confirm?.isEnabled != true {
            try await Task.sleep(for: .milliseconds(100))
        }
        #expect(confirm?.isEnabled == true)
        #expect(confirm?.title == "Delete")
    }

    // MARK: - Dismissal Safety

    @Test
    func `Dismissing alert before countdown completes does not crash`() async throws {
        let (presenter, window) = makePresenter()
        _ = window

        LMKCountdownConfirmation.present(
            on: presenter,
            title: "Delete?",
            confirmTitle: "Delete",
            countdownSeconds: 3,
            onConfirm: {}
        )

        // Dismiss immediately. The countdown task must weakly hold the
        // UIAlertAction and exit cleanly once the alert is released.
        presenter.dismiss(animated: false)

        // Wait past the original countdown to ensure no late mutation crashes.
        try await Task.sleep(for: .seconds(4))
    }
}
