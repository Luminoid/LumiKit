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
    func `Drag thresholds come from the style`() {
        let sheet = TestBottomSheet()
        sheet.loadViewIfNeeded()
        #expect(sheet.dismissesOnDragEnd(velocity: 501, offset: 0, containerHeight: 400))
        #expect(!sheet.dismissesOnDragEnd(velocity: 499, offset: 100, containerHeight: 400))
        #expect(sheet.dismissesOnDragEnd(velocity: 0, offset: 121, containerHeight: 400), "30% of the height")
        sheet.style.dismissVelocityThreshold = 1000
        sheet.style.dismissDistanceRatio = 0.5
        #expect(!sheet.dismissesOnDragEnd(velocity: 900, offset: 150, containerHeight: 400))
        #expect(sheet.dismissesOnDragEnd(velocity: 0, offset: 201, containerHeight: 400))
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
    func `present ends editing on the host so the sheet is not hidden behind the keyboard`() {
        let (host, window) = makeHost()
        defer { window.isHidden = true }
        let field = UITextField(frame: CGRect(x: 0, y: 100, width: 375, height: 44))
        host.view.addSubview(field)
        field.becomeFirstResponder()
        #expect(field.isFirstResponder)
        let sheet = TestBottomSheet()
        sheet.present(from: host)
        #expect(!field.isFirstResponder)
    }

    @Test
    func `dismiss removes the sheet, reports the reason once, and runs every completion`() async {
        let (host, window) = makeHost()
        defer { window.isHidden = true }
        let sheet = TestBottomSheet()
        var reasons: [LMKBottomSheetViewController.DismissReason] = []
        var order: [String] = []
        sheet.onDismiss = { reasons.append($0); order.append("onDismiss") }
        sheet.present(from: host)
        // Dismissing during the slide-in must still complete (a fast tap on the dimming).
        sheet.dismiss(reason: .dimmingTap) { order.append("first") }
        sheet.dismiss { order.append("second") }
        await LMKWait.until { order.count == 3 }
        #expect(host.children.isEmpty)
        #expect(sheet.view.superview == nil)
        #expect(reasons == [.dimmingTap], "a second dismiss during the slide-out is ignored")
        #expect(order == ["onDismiss", "first", "second"], "completions run after onDismiss, the ignored call's too")
        #expect(sheet.willDismissReasons == [.dimmingTap])
        #expect(sheet.didDismissReasons == [.dimmingTap])
    }

    @Test
    func `A dismissed sheet can be presented again`() async {
        let (host, window) = makeHost()
        defer { window.isHidden = true }
        let sheet = TestBottomSheet()
        var reasons: [LMKBottomSheetViewController.DismissReason] = []
        sheet.onDismiss = { reasons.append($0) }
        sheet.present(from: host)
        sheet.dismiss(reason: .cancelButton)
        await LMKWait.until { host.children.isEmpty }

        sheet.present(from: host)
        sheet.view.layoutIfNeeded()
        #expect(host.children.first === sheet)
        #expect(sheet.dimmingView.alpha == 1, "the second slide-in ran")
        #expect(abs(sheet.containerView.frame.maxY - 812) < 0.5, "the container is back on screen")
        sheet.dismiss(reason: .keyCommand)
        await LMKWait.until { host.children.isEmpty }
        #expect(reasons == [.cancelButton, .keyCommand])
    }

    @Test
    func `UIKit's dismiss on a presented sheet closes the sheet, not the host's modal`() async {
        let (host, window) = makeHost()
        defer { window.isHidden = true }
        let sheet = TestBottomSheet()
        var reasons: [LMKBottomSheetViewController.DismissReason] = []
        var completed = false
        sheet.onDismiss = { reasons.append($0) }
        sheet.present(from: host)
        sheet.dismiss(animated: true) { completed = true }
        await LMKWait.until { host.children.isEmpty && completed }
        #expect(reasons == [.programmatic])
        #expect(window.rootViewController === host, "the host stays where it was")
    }

    @Test
    func `The sheet is a VoiceOver modal with an escape gesture`() async {
        let (host, window) = makeHost()
        defer { window.isHidden = true }
        let sheet = TestBottomSheet()
        var reasons: [LMKBottomSheetViewController.DismissReason] = []
        sheet.onDismiss = { reasons.append($0) }
        sheet.present(from: host)
        #expect(sheet.view.accessibilityViewIsModal)
        #expect(sheet.view.accessibilityPerformEscape())
        await LMKWait.until { host.children.isEmpty }
        #expect(reasons == [.keyCommand])
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
    func `Content and the cancel button keep clear of the side safe areas`() {
        let (host, window) = makeHost()
        defer { window.isHidden = true }
        host.additionalSafeAreaInsets = UIEdgeInsets(top: 0, left: 62, bottom: 0, right: 62)
        let sheet = TestBottomSheet()
        sheet.present(from: host)
        sheet.view.layoutIfNeeded()
        #expect(sheet.containerView.frame.minX == 0, "the surface stays full-bleed")
        #expect(sheet.containerView.frame.width == 375)
        #expect(sheet.cancelButton.frame.minX >= 62 + LMKSpacing.xl - 0.5)
        #expect(sheet.cancelButton.frame.maxX <= 375 - 62 - LMKSpacing.xl + 0.5)
        #expect(sheet.contentLayoutGuide.layoutFrame.minX >= 62 - 0.5)
        #expect(sheet.contentLayoutGuide.layoutFrame.maxX <= 375 - 62 + 0.5)
    }

    @Test
    func `theme.bottomSheet supplies app-wide defaults and the subclass layers its own style between`() {
        var theme = LMKTheme()
        theme.bottomSheet = LMKBottomSheetViewController.Style(dimmingColor: .blue, dragIndicatorColor: .magenta)
        theme.spacing = LMKSpacingTheme(small: 11)
        let sheet = LayeredSheet()
        sheet.style.dimmingColor = .green
        let window = LMKThemeTesting.host(sheet.view, theme: theme)
        defer { window.isHidden = true }
        sheet.applyTheme(theme)
        #expect(sheet.dragIndicator.backgroundColor == UIColor.magenta, "from the theme")
        #expect(sheet.resolvedStyle.dimmingAlpha == 1, "from the subclass resolver")
        #expect(sheet.resolvedStyle.dimmingColor == UIColor.green, "the instance style wins")
        sheet.view.layoutIfNeeded()
        #expect(sheet.dragIndicator.frame.minY == 11, "the indicator gap reads the passed theme's spacing")
    }

    @Test
    func `applyContentTheme runs after the chrome and before didApplyStyle`() {
        let sheet = LayeredSheet()
        var order: [String] = []
        sheet.contentThemeHook = { order.append("content") }
        sheet.didApplyStyle = { _ in order.append("didApplyStyle") }
        sheet.loadViewIfNeeded()
        #expect(order == ["content", "didApplyStyle"])
        #expect(sheet.contentThemeSawCancelStyle, "the chrome is styled when the hook runs")
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

    private func makeHostedSheet(_ sheet: LMKBottomSheetViewController, windowFrame: CGRect = CGRect(x: 0, y: 0, width: 375, height: 812)) -> UIWindow {
        let parent = UIViewController()
        let window = UIWindow(frame: windowFrame)
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
    func `The keyboard frame is read in screen coordinates, so an offset window lifts the right amount`() {
        let sheet = TestBottomSheet()
        // A window 100pt down the screen (Stage Manager, Slide Over), 600pt tall.
        let window = makeHostedSheet(sheet, windowFrame: CGRect(x: 0, y: 100, width: 375, height: 600))
        defer { window.isHidden = true }
        let screenHeight = window.screen.bounds.height
        // The keyboard covers the bottom 300pt of the screen: the window's last 126pt when
        // the screen is 874pt tall (it is what overlaps the window, never the raw height).
        let keyboardTop = screenHeight - 300
        let overlap = (window.frame.maxY - keyboardTop).rounded()
        #expect(overlap > 0 && overlap < 300)
        postKeyboard(name: UIResponder.keyboardWillShowNotification, frame: CGRect(x: 0, y: keyboardTop, width: 375, height: 300))
        sheet.view.layoutIfNeeded()
        #expect(abs(sheet.containerView.frame.maxY - (600 - overlap)) < 0.5, "maxY \(sheet.containerView.frame.maxY), overlap \(overlap)")
    }

    @Test
    func `A tall sheet lifted by the keyboard stays below the top safe area`() {
        let parent = UIViewController()
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 375, height: 812))
        window.rootViewController = parent
        window.makeKeyAndVisible()
        defer { window.isHidden = true }
        let sheet = LMKActionSheet.present(from: parent, title: "Move to", actions: (0 ..< 40).map { index in .init(title: "Day \(index)") {} })
        sheet.view.layoutIfNeeded()
        let restingHeight = sheet.containerView.frame.height
        #expect(restingHeight > 812 * 0.8, "the fixture reaches the cap")

        postKeyboard(name: UIResponder.keyboardWillShowNotification, frame: CGRect(x: 0, y: 512, width: 375, height: 300))
        sheet.view.layoutIfNeeded()
        let top = sheet.view.safeAreaInsets.top
        #expect(sheet.containerView.frame.minY >= top - 0.5, "the sheet was pushed off the top: \(sheet.containerView.frame)")
        #expect(abs(sheet.containerView.frame.maxY - 512) < 0.5, "still lifted above the keyboard")
        #expect(sheet.containerView.frame.height < restingHeight, "the list gave up the height, not the chrome")
        postKeyboard(name: UIResponder.keyboardWillHideNotification, frame: CGRect(x: 0, y: 812, width: 375, height: 300))
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

/// A subclass with a style layer of its own (a fully opaque dimming) between the theme and the instance.
private final class LayeredSheet: LMKBottomSheetViewController {
    var contentThemeHook: (() -> Void)?
    var contentThemeSawCancelStyle = false

    override func resolveStyle(for theme: LMKTheme) -> Style {
        theme.bottomSheet.merging(Style(dimmingAlpha: 1)).merging(style)
    }

    override func applyContentTheme(_ theme: LMKTheme) {
        contentThemeSawCancelStyle = cancelButton.style.variant == .filled
        contentThemeHook?()
    }
}
