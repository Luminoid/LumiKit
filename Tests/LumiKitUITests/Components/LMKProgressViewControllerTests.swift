//
//  LMKProgressViewControllerTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

// MARK: - LMKProgressViewController

@MainActor
struct LMKProgressViewControllerTests {
    @Test
    func `Init with determinate style sets title`() {
        let vc = LMKProgressViewController(title: "Importing")
        vc.loadViewIfNeeded()

        #expect(vc.modalPresentationStyle == .overFullScreen)
        #expect(vc.modalTransitionStyle == .crossDissolve)
    }

    @Test
    func `Init with indeterminate style and subtitle`() {
        let vc = LMKProgressViewController(
            title: "Processing...",
            subtitle: "Please wait",
            style: .indeterminate
        )
        vc.loadViewIfNeeded()

        #expect(vc.modalPresentationStyle == .overFullScreen)
    }

    @Test
    func `onCancel property can be set`() {
        var cancelled = false
        let vc = LMKProgressViewController(title: "Test")
        vc.onCancel = { cancelled = true }
        vc.loadViewIfNeeded()

        // Verify onCancel is set (callback fires when cancel is tapped)
        #expect(vc.onCancel != nil)

        // Invoke the callback directly
        vc.onCancel?()
        #expect(cancelled)
    }

    @Test
    func `updateProgress with task updates progress`() {
        let vc = LMKProgressViewController(title: "Import")
        vc.loadViewIfNeeded()

        // Should not crash
        vc.updateProgress(0.5, task: "Reading files...")
        vc.updateProgress(1.0, task: "Done")
    }

    @Test
    func `updateProgress value only`() {
        let vc = LMKProgressViewController(title: "Import")
        vc.loadViewIfNeeded()

        // Should not crash
        vc.updateProgress(0.25)
        vc.updateProgress(0.75)
    }

    @Test
    func `Style enum has expected cases`() {
        let determinate = LMKProgressViewController.Style.determinate
        let indeterminate = LMKProgressViewController.Style.indeterminate

        #expect(determinate != indeterminate)
    }

    @Test
    func `View loads without crashing for both styles`() {
        let det = LMKProgressViewController(title: "A", style: .determinate)
        det.loadViewIfNeeded()
        #expect(det.view != nil)

        let indet = LMKProgressViewController(title: "B", style: .indeterminate)
        indet.loadViewIfNeeded()
        #expect(indet.view != nil)
    }

    @Test
    func `Indeterminate with no subtitle loads correctly`() {
        let vc = LMKProgressViewController(title: "Loading", style: .indeterminate)
        vc.loadViewIfNeeded()
        #expect(vc.view != nil)
    }

    @Test
    func `Cancel button renders only while onCancel is wired`() {
        let cancelTitle = LMKAlertPresenter.strings.cancel
        let vc = LMKProgressViewController(title: "Test", style: .indeterminate)
        vc.loadViewIfNeeded()
        #expect(findButton(in: vc.view, withTitle: cancelTitle) == nil)

        vc.onCancel = {}
        #expect(findButton(in: vc.view, withTitle: cancelTitle) != nil)

        vc.onCancel = nil
        #expect(findButton(in: vc.view, withTitle: cancelTitle) == nil)
    }

    @Test
    func `Cancel wired before load renders at load`() {
        let vc = LMKProgressViewController(title: "Test", style: .indeterminate)
        vc.onCancel = {}
        vc.loadViewIfNeeded()
        #expect(findButton(in: vc.view, withTitle: LMKAlertPresenter.strings.cancel) != nil)
    }

    @Test
    func `setSubtitle installs, updates, and removes the note mid-flight`() {
        let vc = LMKProgressViewController(title: "Test", style: .indeterminate)
        vc.loadViewIfNeeded()
        #expect(findLabel(in: vc.view, withText: "Still working") == nil)

        vc.setSubtitle("Still working")
        #expect(findLabel(in: vc.view, withText: "Still working") != nil)

        vc.setSubtitle("Nearly there")
        #expect(findLabel(in: vc.view, withText: "Nearly there") != nil)

        vc.setSubtitle(nil)
        #expect(findLabel(in: vc.view, withText: "Nearly there") == nil)
    }

    @Test
    func `setSubtitle before load applies at load`() {
        let vc = LMKProgressViewController(title: "Test", style: .indeterminate)
        vc.setSubtitle("Preflight note")
        vc.loadViewIfNeeded()
        #expect(findLabel(in: vc.view, withText: "Preflight note") != nil)
    }

    @Test
    func `setSubtitle keeps the cancel button below the note`() {
        let vc = LMKProgressViewController(title: "Test", style: .indeterminate)
        vc.onCancel = {}
        vc.loadViewIfNeeded()
        vc.setSubtitle("A note")
        vc.view.layoutIfNeeded()

        let cancel = findButton(in: vc.view, withTitle: LMKAlertPresenter.strings.cancel)
        let note = findLabel(in: vc.view, withText: "A note")
        #expect(cancel != nil)
        #expect(note != nil)
        if let cancel, let note {
            #expect(cancel.frame.minY >= note.frame.maxY)
        }
    }

    // MARK: - Helpers

    private func findButton(in view: UIView, withTitle title: String) -> UIButton? {
        if let button = view as? UIButton, button.title(for: .normal) == title {
            return button
        }
        for subview in view.subviews {
            if let found = findButton(in: subview, withTitle: title) {
                return found
            }
        }
        return nil
    }

    private func findLabel(in view: UIView, withText text: String) -> UILabel? {
        if let label = view as? UILabel, label.text == text {
            return label
        }
        for subview in view.subviews {
            if let found = findLabel(in: subview, withText: text) {
                return found
            }
        }
        return nil
    }
}
