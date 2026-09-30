//
//  LMKBottomSheetViewControllerTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

@MainActor
struct LMKBottomSheetViewControllerTests {
    private func makeHost() -> (UIViewController, UIWindow) {
        let host = UIViewController()
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 375, height: 812))
        window.rootViewController = host
        window.makeKeyAndVisible()
        return (host, window)
    }

    @Test
    func `Cancel title comes from the strings, per instance`() {
        let sheet = TestBottomSheet()
        sheet.loadViewIfNeeded()
        #expect(sheet.cancelButton.title == "Cancel")
        sheet.strings = .init(cancel: "Close")
        #expect(sheet.cancelButton.title == "Close")
        #expect(LMKBottomSheetViewController.Strings().cancel == "Cancel")
    }

    @Test
    func `Default chrome: top corners, hidden dimming with a tap, indicator, and cancel look`() {
        let sheet = TestBottomSheet()
        sheet.loadViewIfNeeded()
        #expect(sheet.containerView.layer.cornerRadius == LMKCornerRadius.large)
        #expect(sheet.containerView.layer.maskedCorners == [.layerMinXMinYCorner, .layerMaxXMinYCorner])
        #expect(sheet.containerView.backgroundColor === LMKColor.backgroundPrimary)
        #expect(sheet.dimmingView.alpha == 0)
        #expect(sheet.dimmingView.gestureRecognizers?.contains { $0 is UITapGestureRecognizer } == true)
        #expect(!sheet.dragIndicator.isHidden)
        #expect(!sheet.cancelButton.isHidden)
        #expect(sheet.cancelButton.style.variant == .filled)
        #expect(sheet.cancelButton.style.foregroundColor === LMKColor.textPrimary)
        #expect(sheet.cancelButton.style.minimumHeight == 50)
        #expect(sheet.setupSheetContentCalled)
    }

    @Test
    func `Style hides the indicator and the cancel button and retunes the dimming`() {
        let sheet = TestBottomSheet(style: LMKBottomSheetViewController.Style(
            surface: LMKSurfaceStyle(background: .solid(.red)),
            dimmingColor: .blue,
            dimmingAlpha: 0.5,
            showsDragIndicator: false,
            showsCancelButton: false,
            maxHeightRatio: 0.5
        ))
        sheet.loadViewIfNeeded()
        #expect(sheet.containerView.backgroundColor == UIColor.red)
        #expect(sheet.dragIndicator.isHidden)
        #expect(sheet.cancelButton.isHidden)
        #expect(sheet.dimmingView.backgroundColor == UIColor.blue.withAlphaComponent(0.5))
        #expect(sheet.resolvedStyle.maxHeightRatio == 0.5)
        sheet.style.showsCancelButton = true
        #expect(!sheet.cancelButton.isHidden)
    }

    @Test
    func `present adds the sheet as a child and animates in once, even on a container host`() {
        let (host, window) = makeHost()
        defer { window.isHidden = true }
        let sheet = AnimationCountingSheet()
        sheet.present(from: host)
        sheet.viewDidAppear(false)
        #expect(host.children.first === sheet)
        #expect(sheet.view.superview === host.view)
        #expect(sheet.view.autoresizingMask.contains(.flexibleWidth))
        #expect(sheet.dimmingView.alpha == 1)
        #expect(sheet.animateInCount == 1)

        // Container controllers never forward viewDidAppear to manual children.
        let navigation = UINavigationController(rootViewController: UIViewController())
        window.rootViewController = navigation
        let second = TestBottomSheet()
        second.present(from: navigation)
        second.view.layoutIfNeeded()
        #expect(second.dimmingView.alpha == 1)
        #expect(second.containerView.frame.minY < second.view.bounds.height)
    }

    @Test
    func `dismiss removes the sheet and reports the reason`() async {
        let (host, window) = makeHost()
        defer { window.isHidden = true }
        let sheet = TestBottomSheet()
        var reasons: [LMKBottomSheetViewController.DismissReason] = []
        sheet.onDismiss = { reasons.append($0) }
        sheet.present(from: host)
        // Dismissing during the slide-in must still complete (a fast tap on the dimming).
        sheet.dismiss(reason: .dimmingTap)
        sheet.dismiss()
        await LMKWait.until { host.children.isEmpty }
        #expect(host.children.isEmpty)
        #expect(sheet.view.superview == nil)
        #expect(reasons == [.dimmingTap], "a second dismiss during the slide-out is ignored")
        #expect(sheet.willDismissReasons == [.dimmingTap])
        #expect(sheet.didDismissReasons == [.dimmingTap])
    }

    @Test
    func `Key commands offer Escape and Command-W`() {
        let sheet = TestBottomSheet()
        sheet.loadViewIfNeeded()
        #expect(sheet.canBecomeFirstResponder)
        let inputs = sheet.keyCommands?.map(\.input) ?? []
        #expect(inputs.contains(UIKeyCommand.inputEscape))
        #expect(inputs.contains("w"))
    }

    @Test
    func `A tall action sheet in an embedded child stays within the hosting bounds`() {
        // The sheet caps against the hosting view, not the screen, so its top chrome stays reachable.
        let (root, window) = makeHost()
        defer { window.isHidden = true }
        let host = UIViewController()
        root.addChild(host)
        host.view.frame = CGRect(x: 0, y: 212, width: 375, height: 600)
        host.view.autoresizingMask = []
        root.view.addSubview(host.view)
        host.didMove(toParent: root)

        let sheet = LMKActionSheet.present(from: host, title: "Move to", actions: (0 ..< 40).map { index in .init(title: "Day \(index)") {} })
        sheet.view.layoutIfNeeded()
        #expect(sheet.containerView.frame.minY >= 0)
        #expect(sheet.containerView.frame.height <= 600 * 0.9 + 1)
    }

    @Test
    func `theme.bottomSheet supplies app-wide defaults`() {
        var theme = LMKTheme()
        theme.bottomSheet = LMKBottomSheetViewController.Style(dragIndicatorColor: .magenta)
        let sheet = TestBottomSheet()
        let window = LMKThemeTesting.host(sheet.view, theme: theme)
        defer { window.isHidden = true }
        sheet.applyTheme(theme)
        #expect(sheet.dragIndicator.backgroundColor == UIColor.magenta)
    }
}

// MARK: - Keyboard avoidance

@MainActor
struct LMKBottomSheetKeyboardTests {
    private func postKeyboard(name: Notification.Name, frame: CGRect) {
        NotificationCenter.default.post(
            name: name,
            object: nil,
            userInfo: [
                UIResponder.keyboardFrameEndUserInfoKey: NSValue(cgRect: frame),
                UIResponder.keyboardAnimationDurationUserInfoKey: 0.0,
                UIResponder.keyboardAnimationCurveUserInfoKey: UInt(7),
            ]
        )
    }

    private func makeHostedSheet(_ sheet: LMKBottomSheetViewController) -> UIWindow {
        let parent = UIViewController()
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 375, height: 812))
        window.rootViewController = parent
        window.makeKeyAndVisible()
        sheet.present(from: parent)
        sheet.view.layoutIfNeeded()
        return window
    }

    @Test
    func `avoidsKeyboard defaults to true`() {
        #expect(TestBottomSheet().avoidsKeyboard)
    }

    @Test
    func `Keyboard show lifts the sheet by the overlap and hide restores it`() {
        let sheet = TestBottomSheet()
        let window = makeHostedSheet(sheet)
        defer { window.isHidden = true }
        let height = window.bounds.height
        #expect(abs(sheet.containerView.frame.maxY - height) < 0.5)

        postKeyboard(name: UIResponder.keyboardWillShowNotification, frame: CGRect(x: 0, y: height - 300, width: 375, height: 300))
        sheet.view.layoutIfNeeded()
        #expect(abs(sheet.containerView.frame.maxY - (height - 300)) < 0.5)

        // A partially overlapping frame lifts by the covered portion only (a different height, since
        // the observer ignores a repeat of the same keyboard height).
        postKeyboard(name: UIResponder.keyboardWillShowNotification, frame: CGRect(x: 0, y: height - 120, width: 375, height: 250))
        sheet.view.layoutIfNeeded()
        #expect(abs(sheet.containerView.frame.maxY - (height - 120)) < 0.5)

        postKeyboard(name: UIResponder.keyboardWillHideNotification, frame: CGRect(x: 0, y: height, width: 375, height: 300))
        sheet.view.layoutIfNeeded()
        #expect(abs(sheet.containerView.frame.maxY - height) < 0.5)
    }

    @Test
    func `additionalBottomInset lifts the sheet and stacks with the keyboard`() {
        let sheet = TestBottomSheet()
        let window = makeHostedSheet(sheet)
        defer { window.isHidden = true }
        let height = window.bounds.height
        sheet.additionalBottomInset = 50
        sheet.view.layoutIfNeeded()
        #expect(abs(sheet.containerView.frame.maxY - (height - 50)) < 0.5)
        postKeyboard(name: UIResponder.keyboardWillShowNotification, frame: CGRect(x: 0, y: height - 300, width: 375, height: 300))
        sheet.view.layoutIfNeeded()
        #expect(abs(sheet.containerView.frame.maxY - (height - 350)) < 0.5)
        postKeyboard(name: UIResponder.keyboardWillHideNotification, frame: CGRect(x: 0, y: height, width: 375, height: 300))
    }

    @Test
    func `avoidsKeyboard false leaves the sheet at rest`() {
        let sheet = ManualKeyboardSheet()
        let window = makeHostedSheet(sheet)
        defer { window.isHidden = true }
        let height = window.bounds.height
        postKeyboard(name: UIResponder.keyboardWillShowNotification, frame: CGRect(x: 0, y: height - 300, width: 375, height: 300))
        sheet.view.layoutIfNeeded()
        #expect(abs(sheet.containerView.frame.maxY - height) < 0.5)
    }

    @Test
    func `Dismissal does not fight a lifted offset`() {
        let sheet = TestBottomSheet()
        let window = makeHostedSheet(sheet)
        defer { window.isHidden = true }
        let height = window.bounds.height
        postKeyboard(name: UIResponder.keyboardWillShowNotification, frame: CGRect(x: 0, y: height - 300, width: 375, height: 300))
        sheet.view.layoutIfNeeded()
        sheet.animateOut {}
        postKeyboard(name: UIResponder.keyboardWillHideNotification, frame: CGRect(x: 0, y: height, width: 375, height: 300))
        sheet.view.layoutIfNeeded()
        #expect(sheet.containerView.frame.maxY >= height - 0.5)
    }
}

// MARK: - Helpers

private final class ManualKeyboardSheet: LMKBottomSheetViewController {
    override var avoidsKeyboard: Bool { false }
}

private final class TestBottomSheet: LMKBottomSheetViewController {
    var setupSheetContentCalled = false
    var willDismissReasons: [DismissReason] = []
    var didDismissReasons: [DismissReason] = []

    override func setupSheetContent() {
        setupSheetContentCalled = true
    }

    override func willDismiss(reason: DismissReason) {
        willDismissReasons.append(reason)
    }

    override func didDismiss(reason: DismissReason) {
        didDismissReasons.append(reason)
    }
}

private final class AnimationCountingSheet: LMKBottomSheetViewController {
    var animateInCount = 0

    override func animateIn() {
        animateInCount += 1
        super.animateIn()
    }
}
