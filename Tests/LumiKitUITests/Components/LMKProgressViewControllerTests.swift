//
//  LMKProgressViewControllerTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

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

        var theme = LMKTheme()
        theme.progress = LMKProgressViewController.Style(barTrackColor: .magenta)
        let themed = LMKProgressViewController(title: "T")
        let window = LMKThemeTesting.host(themed.view, theme: theme)
        defer { window.isHidden = true }
        themed.applyTheme(theme)
        #expect(themed.progressView.trackTintColor == UIColor.magenta)
    }
}
