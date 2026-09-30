//
//  LMKToastTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

// MARK: - LMKStatus

struct LMKStatusTests {
    @Test
    func `Status symbols and colors`() {
        #expect(LMKStatus.error.systemImageName == "exclamationmark.circle.fill")
        #expect(LMKStatus.success.systemImageName == "checkmark.circle.fill")
        #expect(LMKStatus.warning.systemImageName == "exclamationmark.triangle.fill")
        #expect(LMKStatus.info.systemImageName == "info.circle.fill")
        #expect(LMKStatus.neutral.systemImageName == nil)
        #expect(LMKStatus.error.color === LMKColor.error)
        #expect(LMKStatus.success.color === LMKColor.success)
        #expect(LMKStatus.warning.color === LMKColor.warning)
        #expect(LMKStatus.info.color === LMKColor.info)
        #expect(LMKStatus.neutral.color === LMKColor.textSecondary)
        #expect(LMKStatus.allCases.count == 5)
    }
}

// MARK: - LMKToastView

@MainActor
struct LMKToastViewTests {
    @Test
    func `Toast sets accessibility properties`() {
        let toast = LMKToastView(status: .error, message: "Something went wrong")
        #expect(toast.isAccessibilityElement)
        #expect(toast.accessibilityLabel == "Something went wrong")
        #expect(toast.accessibilityTraits == .staticText)
        #expect(toast.iconView.image != nil)
        #expect(toast.titleLabel.isHidden)
        #expect(toast.actionButton.isHidden)
        #expect(toast.dismissButton.isHidden)
    }

    @Test
    func `A title, an action, and persistence add elements`() {
        let toast = LMKToastView(configuration: LMKToastConfiguration(
            status: .info, message: "Uploaded", title: "Done", action: .init(title: "View") {}, duration: .persistent
        ))
        #expect(toast.accessibilityLabel == "Done. Uploaded")
        #expect(!toast.titleLabel.isHidden)
        #expect(!toast.actionButton.isHidden)
        #expect(toast.actionButton.title == "View")
        #expect(!toast.dismissButton.isHidden)
        #expect(toast.dismissButton.accessibilityLabel == LMKToast.Strings().dismissAccessibilityLabel)
        #expect(!toast.isAccessibilityElement)
        #expect(toast.accessibilityElements?.count == 3)
    }

    @Test
    func `A neutral toast has no icon`() {
        let toast = LMKToastView(status: .neutral, message: "Deleted")
        #expect(toast.iconView.isHidden)
    }

    @Test
    func `Default surface is the elevated card`() {
        let toast = LMKToastView(status: .success, message: "Saved")
        #expect(toast.layer.cornerRadius == LMKCornerRadius.large)
        #expect(toast.layer.shadowRadius == LMKTheme.current.shadow.level2.radius)
        #expect(toast.backgroundColor == LMKColor.backgroundPrimary)
        #expect(toast.iconView.tintColor === LMKColor.success)
    }

    @Test
    func `Style overrides apply per instance and through the theme`() {
        let toast = LMKToastView(status: .success, message: "Saved")
        toast.style.iconTint = .red
        toast.style.surface.corners = .fixed(4)
        #expect(toast.iconView.tintColor == UIColor.red)
        #expect(toast.layer.cornerRadius == 4)

        var theme = LMKTheme()
        theme.toast = LMKToastView.Style(messageColor: .blue)
        let themed = LMKToastView(status: .info, message: "Hi")
        let window = LMKThemeTesting.host(themed, theme: theme)
        defer { window.isHidden = true }
        #expect(themed.messageLabel.textColor == UIColor.blue)
    }

    @Test
    func `setMessage updates the label and accessibility label`() {
        let toast = LMKToastView(status: .info, message: "One")
        toast.setMessage("Two")
        #expect(toast.messageLabel.text == "Two")
        #expect(toast.accessibilityLabel == "Two")
        #expect(toast.configuration.message == "Two")
    }

    @Test
    func `Default durations`() {
        #expect(LMKToast.defaultDuration == 3)
        #expect(LMKToast.defaultUndoDuration == 5)
    }
}

// MARK: - LMKToast presenter

@Suite(.serialized)
@MainActor
struct LMKToastPresenterTests {
    /// Animations off so entrance and exit completions run synchronously.
    private static func makeHost() -> (UIWindow, UIViewController) {
        UIView.setAnimationsEnabled(false)
        let controller = UIViewController()
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        window.rootViewController = controller
        window.isHidden = false
        window.layoutIfNeeded()
        return (window, controller)
    }

    private static func toasts(in view: UIView) -> [LMKToastView] {
        view.subviews.compactMap { $0 as? LMKToastView }
    }

    private static func settle() async {
        try? await Task.sleep(for: .milliseconds(50))
    }

    @Test
    func `A toast with an action fills the width and keeps a short message on one line`() throws {
        let (window, host) = Self.makeHost()
        defer { window.isHidden = true; LMKToast.dismissAll(); UIView.setAnimationsEnabled(true) }
        LMKToast.showUndo(message: "Bath deleted", in: host, onUndo: {}, onCommit: {})
        host.view.layoutIfNeeded()
        let toast = try #require(Self.toasts(in: host.view).first)
        let margin = LMKSpacing.cardPadding
        #expect(abs(toast.frame.width - (390 - margin * 2)) < 0.5, "the fill beats the stack's text-width disambiguation")
        #expect(toast.messageLabel.frame.height < toast.messageLabel.font.lineHeight * 1.5)
        #expect(abs(toast.actionButton.convert(toast.actionButton.bounds, to: toast).maxX - (toast.bounds.maxX - LMKSpacing.medium)) < 0.5)
    }

    @Test
    func `A persistent toast's dismiss button fits its glyph and the message takes the rest`() throws {
        let (window, host) = Self.makeHost()
        defer { window.isHidden = true; LMKToast.dismissAll(); UIView.setAnimationsEnabled(true) }
        LMKToast.show(LMKToastConfiguration(status: .info, message: "Syncing in the background", duration: .persistent, presentation: .onViewController(host)))
        host.view.layoutIfNeeded()
        let toast = try #require(Self.toasts(in: host.view).first)
        let dismiss = toast.dismissButton.convert(toast.dismissButton.bounds, to: toast)
        #expect(!toast.dismissButton.isHidden)
        #expect(dismiss.width < 28, "\(dismiss.width)pt: the button stretched to fill the row")
        #expect(abs(dismiss.maxX - (toast.bounds.maxX - LMKSpacing.medium)) < 0.5)
        #expect(toast.dismissButton.point(inside: CGPoint(x: -4, y: toast.dismissButton.bounds.midY), with: nil), "the hit target stays 44pt")
        let text = toast.messageLabel.convert(toast.messageLabel.bounds, to: toast)
        #expect(text.maxX <= dismiss.minX)
        #expect(text.width > 200)
    }

    @Test
    func `show installs the toast on the host and the handle reports it`() async {
        let (window, host) = Self.makeHost()
        defer { window.isHidden = true; LMKToast.dismissAll(); UIView.setAnimationsEnabled(true) }
        let handle = LMKToast.show(.success, "Saved", in: host)
        #expect(handle.isPresented)
        #expect(Self.toasts(in: host.view).count == 1)
        #expect(Self.toasts(in: host.view).first?.messageLabel.text == "Saved")
        handle.setMessage("Updated")
        #expect(Self.toasts(in: host.view).first?.messageLabel.text == "Updated")
        handle.dismiss()
        await Self.settle()
        #expect(!handle.isPresented)
        #expect(Self.toasts(in: host.view).isEmpty)
    }

    @Test
    func `replace dismisses the current toast`() async {
        let (window, host) = Self.makeHost()
        defer { window.isHidden = true; LMKToast.dismissAll(); UIView.setAnimationsEnabled(true) }
        var reasons: [LMKToastDismissReason] = []
        LMKToast.show(LMKToastConfiguration(status: .info, message: "First", presentation: .onViewController(host), onDismiss: { reasons.append($0) }))
        LMKToast.show(LMKToastConfiguration(status: .info, message: "Second", presentation: .onViewController(host)))
        await Self.settle()
        #expect(reasons == [.replaced])
        #expect(Self.toasts(in: host.view).map(\.messageLabel.text) == ["Second"])
    }

    @Test
    func `enqueue shows the next toast after the current one dismisses`() async {
        let (window, host) = Self.makeHost()
        defer { window.isHidden = true; LMKToast.dismissAll(); UIView.setAnimationsEnabled(true) }
        let first = LMKToast.show(LMKToastConfiguration(status: .info, message: "First", presentation: .onViewController(host)))
        let second = LMKToast.show(LMKToastConfiguration(status: .info, message: "Second", presentation: .onViewController(host), queuePolicy: .enqueue))
        #expect(second.isPresented)
        #expect(Self.toasts(in: host.view).map(\.messageLabel.text) == ["First"])
        first.dismiss()
        await Self.settle()
        #expect(Self.toasts(in: host.view).map(\.messageLabel.text) == ["Second"])
        second.dismiss()
        await Self.settle()
        #expect(Self.toasts(in: host.view).isEmpty)
    }

    @Test
    func `dropIfBusy returns a dismissed handle while a toast is showing`() {
        let (window, host) = Self.makeHost()
        defer { window.isHidden = true; LMKToast.dismissAll(); UIView.setAnimationsEnabled(true) }
        LMKToast.show(.info, "Busy", in: host)
        let dropped = LMKToast.show(LMKToastConfiguration(status: .info, message: "Dropped", presentation: .onViewController(host), queuePolicy: .dropIfBusy))
        #expect(!dropped.isPresented)
        #expect(Self.toasts(in: host.view).count == 1)
    }

    @Test
    func `A timed toast dismisses itself with the timeout reason`() async {
        let (window, host) = Self.makeHost()
        defer { window.isHidden = true; LMKToast.dismissAll(); UIView.setAnimationsEnabled(true) }
        var reason: LMKToastDismissReason?
        LMKToast.show(LMKToastConfiguration(status: .info, message: "Quick", duration: .seconds(0.05), presentation: .onViewController(host), onDismiss: { reason = $0 }))
        try? await Task.sleep(for: .milliseconds(400))
        #expect(reason == .timeout)
        #expect(Self.toasts(in: host.view).isEmpty)
    }

    @Test
    func `Undo toasts commit on timeout and skip the commit when undone`() async {
        let (window, host) = Self.makeHost()
        defer { window.isHidden = true; LMKToast.dismissAll(); UIView.setAnimationsEnabled(true) }
        var commits = 0
        var undos = 0
        LMKToast.showUndo(message: "Deleted", duration: 0.05, in: host, onUndo: { undos += 1 }, onCommit: { commits += 1 })
        let undoToast = Self.toasts(in: host.view).first
        #expect(undoToast?.configuration.showsCountdown == true)
        #expect(undoToast?.actionButton.title == LMKToast.Strings().undo)
        try? await Task.sleep(for: .milliseconds(400))
        #expect(commits == 1)
        #expect(undos == 0)

        LMKToast.showUndo(message: "Deleted again", duration: 5, in: host, onUndo: { undos += 1 }, onCommit: { commits += 1 })
        Self.toasts(in: host.view).first?.actionButton.didTap()
        await Self.settle()
        #expect(undos == 1)
        #expect(commits == 1)
    }

    @Test
    func `dismissAll clears the host`() async {
        let (window, host) = Self.makeHost()
        defer { window.isHidden = true; UIView.setAnimationsEnabled(true) }
        LMKToast.show(.info, "One", in: host)
        LMKToast.show(LMKToastConfiguration(status: .info, message: "Two", presentation: .onViewController(host), queuePolicy: .enqueue))
        LMKToast.dismissAll(in: host)
        await Self.settle()
        #expect(Self.toasts(in: host.view).isEmpty)
    }

    @Test
    func `LMKToastView.show(in:) presents through the same presenter`() async {
        let (window, host) = Self.makeHost()
        defer { window.isHidden = true; LMKToast.dismissAll(); UIView.setAnimationsEnabled(true) }
        let toast = LMKToastView(status: .warning, message: "Careful")
        toast.show(in: host)
        #expect(Self.toasts(in: host.view).first === toast)
        toast.dismiss()
        await Self.settle()
        #expect(Self.toasts(in: host.view).isEmpty)
    }
}
