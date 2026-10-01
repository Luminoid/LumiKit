//
//  LMKProgressViewControllerTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

/// A host that reports a presentation in progress.
private final class BusyHostViewController: UIViewController {
    private let presented = UIViewController()
    override var presentedViewController: UIViewController? { presented }
}

@MainActor
struct LMKProgressViewControllerTests {
    @Test
    func `Init sets the modal style, title, subtitle, and mode`() {
        let hud = LMKProgressViewController(title: "Importing")
        hud.loadViewIfNeeded()
        #expect(hud.modalPresentationStyle == .overFullScreen)
        #expect(hud.modalTransitionStyle == .crossDissolve)
        #expect(hud.isModalInPresentation)
        #expect(hud.mode == .determinate)
        #expect(hud.state == .running)
        #expect(hud.titleLabel.text == "Importing")
        #expect(hud.subtitleLabel.isHidden)
        #expect(hud.progressView.superview != nil)
        #expect(hud.progressLabel.text == "0%")
        #expect(hud.activityIndicator.isAnimating)
        #expect(hud.cancelButton.isHidden)
        #expect(hud.containerView.backgroundColor === LMKColor.backgroundPrimary)
        #expect(hud.containerView.layer.cornerRadius == LMKCornerRadius.large)
        #expect(hud.titleLabel.accessibilityTraits.contains(.header))

        let spinner = LMKProgressViewController(title: "Processing", subtitle: "Please wait", mode: .indeterminate)
        spinner.loadViewIfNeeded()
        #expect(spinner.progressView.superview == nil)
        #expect(!spinner.subtitleLabel.isHidden)
        #expect(spinner.subtitleLabel.text == "Please wait")
    }

    @Test
    func `Title and subtitle are live properties`() {
        let hud = LMKProgressViewController(title: "A", mode: .indeterminate)
        hud.loadViewIfNeeded()
        hud.title = "B"
        #expect(hud.titleLabel.text == "B")
        hud.subtitle = "Still working"
        #expect(!hud.subtitleLabel.isHidden)
        #expect(hud.subtitleLabel.text == "Still working")
        hud.subtitle = nil
        #expect(hud.subtitleLabel.isHidden)
    }

    @Test
    func `The cancel button renders only while onCancel is set, with the localized title`() {
        let hud = LMKProgressViewController(title: "T", mode: .indeterminate)
        hud.loadViewIfNeeded()
        #expect(hud.cancelButton.isHidden)
        #expect(hud.cancelButton.title == "Cancel")
        var cancelled = 0
        hud.onCancel = { cancelled += 1 }
        #expect(!hud.cancelButton.isHidden)
        hud.cancelButton.didTap()
        #expect(cancelled == 1)
        hud.onCancel = nil
        #expect(hud.cancelButton.isHidden)
        hud.strings = .init(cancel: "Stop")
        #expect(hud.cancelButton.title == "Stop")
        #expect(LMKProgressViewController.Strings().cancel == "Cancel")
    }

    @Test
    func `updateProgress clamps, updates the bar, the percent, and the task line`() {
        let hud = LMKProgressViewController(title: "Import")
        hud.loadViewIfNeeded()
        hud.updateProgress(0.5, task: "Reading files")
        #expect(hud.progress == 0.5)
        #expect(hud.progressView.progress == 0.5)
        #expect(hud.taskLabel.text == "Reading files")
        #expect(hud.progressLabel.text == "50%")
        hud.updateProgress(1.7)
        #expect(hud.progress == 1)
        hud.updateProgress(-1)
        #expect(hud.progress == 0)
    }

    @Test
    func `observe mirrors a Progress`() async {
        let hud = LMKProgressViewController(title: "Import")
        hud.loadViewIfNeeded()
        let progress = Progress(totalUnitCount: 4)
        hud.observe(progress)
        progress.completedUnitCount = 1
        await LMKWait.until { hud.progress == 0.25 }
        #expect(hud.progress == 0.25)
        progress.completedUnitCount = 3
        await LMKWait.until { hud.progress == 0.75 }
        #expect(hud.progressLabel.text == "75%")
    }

    @Test
    func `Terminal states swap the spinner for a glyph and hide the bar`() {
        let hud = LMKProgressViewController(title: "Import")
        hud.loadViewIfNeeded()
        hud.setState(.succeeded, message: "Done")
        #expect(hud.state == .succeeded)
        #expect(!hud.statusImageView.isHidden)
        #expect(hud.statusImageView.tintColor === LMKColor.success)
        #expect(!hud.activityIndicator.isAnimating)
        #expect(hud.progressView.isHidden)
        #expect(hud.taskLabel.text == "Done")

        hud.setState(.failed)
        #expect(hud.statusImageView.tintColor === LMKColor.error)

        hud.setState(.running)
        #expect(hud.statusImageView.isHidden)
        #expect(hud.activityIndicator.isAnimating)
        #expect(!hud.progressView.isHidden)
        #expect(!hud.taskLabel.isHidden)

        let spinner = LMKProgressViewController(title: "Sync", mode: .indeterminate)
        spinner.loadViewIfNeeded()
        spinner.setState(.failed, message: "No connection")
        #expect(spinner.taskLabel.superview === spinner.contentStack)
        #expect(!spinner.taskLabel.isHidden)
        spinner.setState(.running)
        #expect(spinner.taskLabel.isHidden, "the spinner layout has no task line; the failure text goes away")
    }

    @Test
    func `Progress set before the view loads shows on load`() {
        let hud = LMKProgressViewController(title: "Import")
        hud.updateProgress(0.4)
        hud.loadViewIfNeeded()
        #expect(hud.progressView.progress == 0.4)
        #expect(hud.progressLabel.text == "40%")
    }

    @Test
    func `A dismiss during the presentation is deferred until it lands, and a never-presented modal completes at once`() {
        var completions = 0
        let idle = LMKProgressViewController(title: "Idle")
        idle.dismiss { completions += 1 }
        #expect(completions == 1, "nothing to dismiss: the completion still runs")

        let host = UIViewController()
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        window.rootViewController = host
        window.isHidden = false
        defer { window.isHidden = true }
        let hud = LMKProgressViewController(title: "Import")
        hud.present(from: host)
        #expect(hud.isPresentationInFlight)
        #expect(host.presentedViewController === hud)
        var deferred = 0
        hud.dismiss { deferred += 1 }
        #expect(hud.hasPendingDismiss, "UIKit would drop a dismiss that overlaps the presentation")
        #expect(deferred == 0)
        #expect(host.presentedViewController === hud)
        // The presentation lands (the host's completion never runs in the xctest host).
        hud.viewDidAppear(false)
        #expect(!hud.isPresentationInFlight)
        #expect(!hud.hasPendingDismiss, "the deferred dismiss ran once the presentation landed")

        let busy = BusyHostViewController()
        let second = LMKProgressViewController(title: "Second")
        second.present(from: busy)
        #expect(!second.isPresentationInFlight, "a host that is already presenting is skipped, not wedged")
        var skipped = 0
        second.dismiss { skipped += 1 }
        #expect(skipped == 1)
    }

    @Test
    func `Escape and the VoiceOver escape gesture run onCancel; the modal is a VoiceOver modal`() {
        let hud = LMKProgressViewController(title: "T")
        hud.loadViewIfNeeded()
        #expect(hud.view.accessibilityViewIsModal)
        #expect(!hud.accessibilityPerformEscape(), "nothing to cancel")
        #expect(hud.keyCommands == nil)
        #expect(!hud.canBecomeFirstResponder)
        var cancelled = 0
        hud.onCancel = { cancelled += 1 }
        #expect(hud.accessibilityPerformEscape())
        #expect(cancelled == 1)
        #expect(hud.keyCommands?.first?.input == UIKeyCommand.inputEscape)
        #expect(hud.canBecomeFirstResponder)
    }

    @Test
    func `The container keeps its top and bottom inside the safe area`() {
        let hud = LMKProgressViewController(title: "Tall")
        hud.subtitle = String(repeating: "A long subtitle that wraps over many lines. ", count: 30)
        hud.onCancel = {}
        hud.view.frame = CGRect(x: 0, y: 0, width: 375, height: 300)
        hud.view.layoutIfNeeded()
        #expect(hud.containerView.frame.minY >= LMKSpacing.large)
        #expect(hud.containerView.frame.maxY <= 300 - LMKSpacing.large, "the cancel button stays on screen")
    }

    @Test
    func `Style and theme.progress shape the container and the bar`() {
        let hud = LMKProgressViewController(title: "T", style: LMKProgressViewController.Style(
            surface: LMKSurfaceStyle(background: .solid(.red)),
            containerWidth: 300,
            barHeight: 8,
            barTint: .blue,
            titleColor: .purple
        ))
        hud.view.frame = CGRect(x: 0, y: 0, width: 375, height: 812)
        hud.view.layoutIfNeeded()
        #expect(hud.containerView.backgroundColor == UIColor.red)
        #expect(hud.containerView.frame.width == 300)
        #expect(hud.progressView.frame.height == 8)
        #expect(hud.progressView.progressTintColor == UIColor.blue)
        #expect(hud.titleLabel.textColor == UIColor.purple)

        let terminal = LMKProgressViewController(title: "T", style: LMKProgressViewController.Style(taskTextStyle: .caption, successColor: .green, failureColor: .orange))
        terminal.loadViewIfNeeded()
        #expect(terminal.taskLabel.lmk_textStyle == .caption)
        terminal.setState(.succeeded)
        #expect(terminal.statusImageView.tintColor == UIColor.green)
        terminal.setState(.failed)
        #expect(terminal.statusImageView.tintColor == UIColor.orange)

        var theme = LMKTheme()
        theme.progress = LMKProgressViewController.Style(barTrackColor: .magenta)
        let themed = LMKProgressViewController(title: "T")
        let window = LMKThemeTesting.host(themed.view, theme: theme)
        defer { window.isHidden = true }
        themed.applyTheme(theme)
        #expect(themed.progressView.trackTintColor == UIColor.magenta)
    }
}
