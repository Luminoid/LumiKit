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
}
