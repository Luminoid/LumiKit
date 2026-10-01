//
//  LMKLoadingStateViewTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

// MARK: - LMKLoadingStateView

@MainActor
struct LMKLoadingStateViewTests {
    @Test
    func `startLoading shows the view, spins, and sets accessibility`() {
        let view = LMKLoadingStateView()
        #expect(view.isHidden, "hidden until something loads")
        view.startLoading(message: "Loading plants...")
        #expect(!view.isHidden)
        #expect(view.isLoading)
        #expect(view.activityIndicator.isAnimating)
        #expect(view.accessibilityLabel == "Loading plants...")
        #expect(!view.messageLabel.isHidden)
        #expect(view.message == "Loading plants...")
    }

    @Test
    func `A loading view without a message still has a VoiceOver label`() {
        let view = LMKLoadingStateView()
        view.startLoading()
        #expect(view.messageLabel.isHidden)
        #expect(view.accessibilityLabel == LMKLoadingStateView.Strings().loadingAccessibilityLabel)
        view.strings = LMKLoadingStateView.Strings(loadingAccessibilityLabel: "Cargando")
        #expect(view.accessibilityLabel == "Cargando")
        view.startLoading(message: "")
        #expect(view.messageLabel.isHidden)
    }

    @Test
    func `stopLoading hides the view`() {
        let view = LMKLoadingStateView()
        view.startLoading(message: "Loading")
        view.stopLoading()
        #expect(view.isHidden)
        #expect(!view.isLoading)
        #expect(!view.activityIndicator.isAnimating)
    }

    @Test
    func `updateMessage sets the label and accessibility label`() {
        let view = LMKLoadingStateView()
        view.updateMessage("Step 2 of 3")
        #expect(view.messageLabel.text == "Step 2 of 3")
        #expect(view.accessibilityLabel == "Step 2 of 3")
        view.updateMessage(nil)
        #expect(view.messageLabel.isHidden)
    }

    @Test
    func `Accessibility traits include updatesFrequently`() {
        #expect(LMKLoadingStateView().accessibilityTraits.contains(.updatesFrequently))
    }

    @Test
    func `An inline view sizes to its indicator and message`() {
        let view = LMKLoadingStateView()
        view.startLoading(message: "Syncing")
        let fitted = view.systemLayoutSizeFitting(
            CGSize(width: 320, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
        #expect(fitted.height > 0, "a stack gives it a height without an explicit constraint")
        #expect(fitted.height.isFinite)
        view.frame = CGRect(origin: .zero, size: CGSize(width: 320, height: fitted.height))
        view.layoutIfNeeded()
        #expect(view.activityIndicator.frame.minY >= 0)
        #expect(view.messageLabel.frame.maxY <= view.bounds.height + 0.5)
        #expect(view.messageLabel.frame.minX == LMKSpacing.xl)

        let long = LMKLoadingStateView()
        long.startLoading(message: String(repeating: "A long message that wraps. ", count: 10))
        let tall = long.systemLayoutSizeFitting(
            CGSize(width: 320, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
        #expect(tall.height > fitted.height, "a long message grows the view")

        // A frame-laid-out host (a table's `backgroundView`) keeps working from size zero.
        let background = LMKLoadingStateView()
        background.frame = .zero
        background.layoutIfNeeded()
        background.frame = CGRect(x: 0, y: 0, width: 375, height: 600)
        background.layoutIfNeeded()
        #expect(background.translatesAutoresizingMaskIntoConstraints)
        #expect(abs(background.activityIndicator.center.x - 187.5) < 0.5)
    }

    @Test
    func `Overlay presentation dims the background and uses the large indicator`() {
        let inline = LMKLoadingStateView()
        #expect(inline.backgroundColor == UIColor.clear)
        #expect(inline.activityIndicator.style == .medium)

        let overlay = LMKLoadingStateView(style: .overlay)
        #expect(overlay.backgroundColor != UIColor.clear)
        #expect(overlay.backgroundColor?.cgColor.alpha ?? 0 < 1)
        #expect(overlay.activityIndicator.style == .large)
        overlay.style.overlayBackground = .red
        #expect(overlay.backgroundColor == UIColor.red)
    }

    @Test
    func `Style colors and theme defaults apply`() {
        let view = LMKLoadingStateView(style: LMKLoadingStateView.Style(indicatorColor: .red, messageColor: .blue))
        view.startLoading(message: "x")
        #expect(view.activityIndicator.color == UIColor.red)
        #expect(view.messageLabel.textColor == UIColor.blue)

        let tuned = LMKLoadingStateView(style: LMKLoadingStateView.Style(indicatorStyle: .large, messageTextStyle: .caption, indicatorOffset: 0))
        tuned.startLoading(message: "x")
        #expect(tuned.activityIndicator.style == .large)
        #expect(tuned.messageLabel.lmk_textStyle == .caption)
        tuned.frame = CGRect(x: 0, y: 0, width: 200, height: 200)
        tuned.layoutIfNeeded()
        #expect(abs(tuned.activityIndicator.center.y - 100) < 0.5, "no offset from the center")

        var theme = LMKTheme()
        theme.loadingState = LMKLoadingStateView.Style(presentation: .overlay)
        let themed = LMKLoadingStateView()
        let window = LMKThemeTesting.host(themed, theme: theme)
        defer { window.isHidden = true }
        #expect(themed.activityIndicator.style == .large)
    }
}
