//
//  LMKAlertCountdownConfirmationTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

@MainActor
struct LMKAlertCountdownConfirmationTests {
    private func makePresenter() -> (UIViewController, UIWindow) {
        let presenter = UIViewController()
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 375, height: 812))
        window.rootViewController = presenter
        window.makeKeyAndVisible()
        return (presenter, window)
    }

    private func presentedDialog(_ presenter: UIViewController) -> LMKCountdownAlertViewController? {
        presenter.presentedViewController as? LMKCountdownAlertViewController
    }

    @Test
    func `Presents a modal dialog with a disabled, counting confirm button`() {
        let (presenter, window) = makePresenter()
        defer { window.isHidden = true }
        let handle = LMKAlert.presentCountdownConfirmation(from: presenter, title: "Delete?", message: "All of it.", confirmTitle: "Delete", countdownSeconds: 5, onConfirm: {})
        let dialog = presentedDialog(presenter)
        dialog?.loadViewIfNeeded()
        #expect(dialog != nil)
        #expect(dialog?.modalPresentationStyle == .overFullScreen)
        #expect(dialog?.isModalInPresentation == true)
        #expect(!handle.isConfirmEnabled)
        #expect(handle.remainingSeconds == 5)
        #expect(dialog?.confirmDisplayedTitle == "Delete (5)")
        #expect(dialog?.confirmButton.accessibilityLabel == "Delete")
        #expect(dialog?.confirmButton.accessibilityValue == "5")
        #expect(dialog?.confirmButton.style.role == .destructive)
        #expect(dialog?.cancelDisplayedTitle == "Cancel")
        #expect(dialog?.titleLabel.text == "Delete?")
        #expect(dialog?.messageLabel.text == "All of it.")
        #expect(dialog?.cardView.layer.cornerRadius == LMKCornerRadius.xxl)
    }

    @Test
    func `Defaults: three seconds, custom cancel title, non-destructive role`() {
        let (presenter, window) = makePresenter()
        defer { window.isHidden = true }
        let handle = LMKAlert.presentCountdownConfirmation(from: presenter, title: "Reset?", confirmTitle: "Reset", cancelTitle: "Keep", confirmRole: .primary, onConfirm: {})
        let dialog = presentedDialog(presenter)
        dialog?.loadViewIfNeeded()
        #expect(handle.remainingSeconds == 3)
        #expect(dialog?.confirmDisplayedTitle == "Reset (3)")
        #expect(dialog?.cancelDisplayedTitle == "Keep")
        #expect(dialog?.confirmButton.style.role == .primary)
        #expect(dialog?.messageLabel.isHidden == true)
    }

    @Test
    func `The confirm button enables when the countdown completes`() async {
        let (presenter, window) = makePresenter()
        defer { window.isHidden = true }
        let handle = LMKAlert.presentCountdownConfirmation(from: presenter, title: "Delete?", confirmTitle: "Delete", countdownSeconds: 1, onConfirm: {})
        let dialog = presentedDialog(presenter)
        dialog?.loadViewIfNeeded()
        // The countdown's sleep continuation re-acquires the main actor, which parallel
        // suites can hold for a while, so the ceiling exceeds the one-second countdown by far.
        await LMKWait.until(timeout: .seconds(60)) { handle.isConfirmEnabled }
        #expect(handle.isConfirmEnabled)
        #expect(handle.remainingSeconds == 0)
        #expect(dialog?.confirmDisplayedTitle == "Delete")
        #expect(dialog?.confirmButton.accessibilityValue == nil)
    }

    @Test
    func `A zero-second countdown enables confirm immediately`() {
        let (presenter, window) = makePresenter()
        defer { window.isHidden = true }
        let handle = LMKAlert.presentCountdownConfirmation(from: presenter, title: "Delete?", confirmTitle: "Delete", countdownSeconds: 0, onConfirm: {})
        presentedDialog(presenter)?.loadViewIfNeeded()
        #expect(handle.isConfirmEnabled)
        #expect(presentedDialog(presenter)?.confirmDisplayedTitle == "Delete")
    }

    @Test
    func `Dismissing through the handle stops the countdown and does not crash afterwards`() async {
        let (presenter, window) = makePresenter()
        defer { window.isHidden = true }
        let handle = LMKAlert.presentCountdownConfirmation(from: presenter, title: "Delete?", confirmTitle: "Delete", countdownSeconds: 1, onConfirm: {}, onCancel: {})
        let dialog = presentedDialog(presenter)
        dialog?.loadViewIfNeeded()
        handle.dismiss()
        // UIKit does not run the modal dismissal inside the test host; the countdown task is
        // cancelled synchronously, so the button must never enable.
        try? await Task.sleep(for: .seconds(1.5))
        #expect(!handle.isConfirmEnabled)
        #expect(dialog?.confirmDisplayedTitle == "Delete (1)")
    }

    @Test
    func `Style and theme.countdownAlert shape the card`() {
        let (presenter, window) = makePresenter()
        defer { window.isHidden = true }
        LMKAlert.presentCountdownConfirmation(
            from: presenter,
            title: "T",
            confirmTitle: "Go",
            style: LMKAlert.CountdownStyle(surface: LMKSurfaceStyle(background: .solid(.red)), cardWidth: 300, titleColor: .purple, buttonHeight: 60),
            onConfirm: {}
        )
        let dialog = presentedDialog(presenter)
        dialog?.loadViewIfNeeded()
        dialog?.view.layoutIfNeeded()
        #expect(dialog?.cardView.backgroundColor == UIColor.red)
        #expect(dialog?.cardView.frame.width == 300)
        #expect(dialog?.titleLabel.textColor == UIColor.purple)
        #expect(dialog?.confirmButton.frame.height == 60)

        var theme = LMKTheme()
        theme.countdownAlert = LMKAlert.CountdownStyle(messageColor: .magenta)
        dialog?.applyTheme(theme)
        #expect(dialog?.messageLabel.textColor == UIColor.magenta)
    }
}
