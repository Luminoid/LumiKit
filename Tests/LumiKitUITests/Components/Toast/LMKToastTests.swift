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
        let toast = LMKToastView(configuration: LMKToast.Configuration(
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
        #expect(toast.messageLabel.accessibilityLabel == "Done. Uploaded")
        toast.setMessage("Synced")
        #expect(toast.messageLabel.accessibilityLabel == "Done. Synced", "VoiceOver reads the new text")
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
    func `Every style knob reaches the view`() {
        let ring = LMKToastView(configuration: LMKToast.Configuration(
            status: .success,
            message: "Deleted",
            action: .init(title: "Undo") {},
            showsCountdown: true,
            style: LMKToastView.Style(
                textStyle: .h4,
                titleTextStyle: .caption,
                titleColor: .brown,
                iconSize: 30,
                showsIcon: false,
                actionButton: LMKButton.Style(minimumHeight: 60),
                horizontalMargin: 40,
                maxWidth: 200,
                verticalOffset: 33,
                countdownRingColor: .purple,
                countdownRingWidth: 5
            )
        ))
        #expect(ring.iconView.isHidden, "showsIcon false hides a status glyph")
        #expect(ring.messageLabel.font.pointSize == LMKTypography.font(for: .h4, compatibleWith: ring.traitCollection).pointSize)
        #expect(ring.actionButton.style.minimumHeight == 60)
        #expect(ring.actionButton.style.variant == .ghost, "the action style layers on the default look")
        #expect(ring.actionButton.style.tintColor === LMKColor.success)
        let shape = ring.iconView.layer.sublayers?.compactMap { $0 as? CAShapeLayer }.first
        #expect(shape?.lineWidth == 5)
        #expect(shape.map { UIColor(cgColor: $0.strokeColor ?? UIColor.clear.cgColor) } == UIColor.purple.resolvedColor(with: ring.traitCollection))

        let host = UIView(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        ring.show(in: host)
        host.layoutIfNeeded()
        #expect(ring.frame.width == 200, "maxWidth caps the fill")
        #expect(ring.frame.minY == 33, "verticalOffset from the safe area")
        let wide = LMKToastView(configuration: LMKToast.Configuration(status: .info, message: "Wide", style: LMKToastView.Style(horizontalMargin: 40)))
        wide.show(in: host)
        host.layoutIfNeeded()
        #expect(wide.frame.minX == 40)
        #expect(wide.frame.width == 310)
        LMKToast.dismissAll()
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
    func `Default durations and a hashable duration`() {
        #expect(LMKToast.defaultDuration == 3)
        #expect(LMKToast.defaultUndoDuration == 5)
        #expect(Set<LMKToast.Configuration.Duration>([.persistent, .seconds(1), .seconds(1)]).count == 2)
    }
}

// MARK: - LMKToast presenter

@Suite(.serialized)
@MainActor
struct LMKToastPresenterTests {
    private static func makeHost() -> (UIWindow, UIViewController) {
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

    @Test
    func `A window-scene toast hosts on the window of the controller on top`() {
        // Under the Mac idiom a page sheet has a window of its own; here the top controller is the
        // root itself, so the host is that window, and no window means no host.
        let (window, _) = Self.makeHost()
        defer { window.isHidden = true }
        #expect(LMKToastPresenter.topWindow(above: window) === window)
        #expect(LMKToastPresenter.topWindow(above: nil) == nil)
        let bare = UIWindow(frame: window.frame)
        #expect(LMKToastPresenter.topWindow(above: bare) === bare, "a window without a root controller hosts itself")
    }

    @Test
    func `A persistent toast leaves with its screen and does not keep the controller alive`() async {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        window.rootViewController = UIViewController()
        window.isHidden = false
        defer { window.isHidden = true; LMKToast.dismissAll() }
        weak var released: UIViewController?
        var reasons: [LMKToast.DismissReason] = []
        do {
            let screen = UIViewController()
            released = screen
            window.rootViewController?.view.addSubview(screen.view)
            LMKToast.show(LMKToast.Configuration(
                status: .info,
                message: "Syncing",
                duration: .persistent,
                presentation: .onViewController(screen),
                onDismiss: { reasons.append($0) }
            ))
            #expect(Self.toasts(in: screen.view).count == 1)
            screen.view.removeFromSuperview()
        }
        await LMKWait.until { reasons == [.programmatic] && released == nil }
        #expect(reasons == [.programmatic], "the toast left with its screen")
        #expect(released == nil, "nothing keeps the screen's controller alive")
    }

    @Test
    func `A toast with an action fills the width and keeps a short message on one line`() throws {
        let (window, host) = Self.makeHost()
        defer { window.isHidden = true; LMKToast.dismissAll() }
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
        defer { window.isHidden = true; LMKToast.dismissAll() }
        LMKToast.show(LMKToast.Configuration(status: .info, message: "Syncing in the background", duration: .persistent, presentation: .onViewController(host)))
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
        defer { window.isHidden = true; LMKToast.dismissAll() }
        let handle = LMKToast.show(.success, "Saved", in: host)
        #expect(handle.isPresented)
        #expect(Self.toasts(in: host.view).count == 1)
        #expect(Self.toasts(in: host.view).first?.messageLabel.text == "Saved")
        handle.setMessage("Updated")
        #expect(Self.toasts(in: host.view).first?.messageLabel.text == "Updated")
        handle.dismiss()
        await LMKWait.until { Self.toasts(in: host.view).isEmpty }
        #expect(!handle.isPresented)
    }

    @Test
    func `The default host is the window itself, above presented sheets`() async {
        let (window, host) = Self.makeHost()
        defer { window.isHidden = true; LMKToast.dismissAll() }
        var reasons: [LMKToast.DismissReason] = []
        let inView = LMKToast.show(LMKToast.Configuration(status: .info, message: "Window", presentation: .inView(window), onDismiss: { reasons.append($0) }))
        #expect(Self.toasts(in: window).first?.messageLabel.text == "Window")
        #expect(Self.toasts(in: host.view).isEmpty, "not on the root view controller's view")
        inView.dismiss()
        await LMKWait.until { reasons == [.programmatic] }

        var sceneReasons: [LMKToast.DismissReason] = []
        let handle = LMKToast.show(LMKToast.Configuration(status: .info, message: "Scene", presentation: .inWindowScene(nil), onDismiss: { sceneReasons.append($0) }))
        if let keyWindow = LMKScene.keyWindow {
            #expect(Self.toasts(in: keyWindow).contains { $0.messageLabel.text == "Scene" }, "the key window, not its root view")
            #expect(keyWindow.rootViewController.map { Self.toasts(in: $0.view).isEmpty } ?? true)
            handle.dismiss()
            await LMKWait.until { sceneReasons == [.programmatic] }
        } else {
            // The xctest host has no scene: a toast with nowhere to go is over before it began.
            #expect(!handle.isPresented)
            #expect(sceneReasons == [.programmatic], "onDismiss still runs, so an undo commit is never lost")
        }
    }

    @Test
    func `replace dismisses the current toast and reports the replaced handle at once`() async {
        let (window, host) = Self.makeHost()
        defer { window.isHidden = true; LMKToast.dismissAll() }
        var reasons: [LMKToast.DismissReason] = []
        let first = LMKToast.show(LMKToast.Configuration(status: .info, message: "First", presentation: .onViewController(host), onDismiss: { reasons.append($0) }))
        let queued = LMKToast.show(LMKToast.Configuration(status: .info, message: "Queued", presentation: .onViewController(host), queuePolicy: .enqueue, onDismiss: { reasons.append($0) }))
        LMKToast.show(LMKToast.Configuration(status: .info, message: "Second", presentation: .onViewController(host)))
        #expect(!first.isPresented, "a replaced toast is not presented, even while it slides out")
        #expect(!queued.isPresented, "a replaced queue entry is gone")
        await LMKWait.until { reasons.count == 2 }
        #expect(reasons == [.replaced, .replaced])
        #expect(Self.toasts(in: host.view).map(\.messageLabel.text) == ["Second"])
    }

    @Test
    func `enqueue shows the next toast after the current one dismisses, with its latest message`() async {
        let (window, host) = Self.makeHost()
        defer { window.isHidden = true; LMKToast.dismissAll() }
        let first = LMKToast.show(LMKToast.Configuration(status: .info, message: "First", presentation: .onViewController(host)))
        let second = LMKToast.show(LMKToast.Configuration(status: .info, message: "Second", presentation: .onViewController(host), queuePolicy: .enqueue))
        #expect(second.isPresented)
        #expect(Self.toasts(in: host.view).map(\.messageLabel.text) == ["First"])
        second.setMessage("Second, updated")
        first.dismiss()
        await LMKWait.until { Self.toasts(in: host.view).map(\.messageLabel.text) == ["Second, updated"] }
        #expect(Self.toasts(in: host.view).map(\.messageLabel.text) == ["Second, updated"])
        second.dismiss()
        await LMKWait.until { Self.toasts(in: host.view).isEmpty }
    }

    @Test
    func `dropIfBusy returns a dismissed handle and reports it while a toast is showing`() {
        let (window, host) = Self.makeHost()
        defer { window.isHidden = true; LMKToast.dismissAll() }
        LMKToast.show(.info, "Busy", in: host)
        var reasons: [LMKToast.DismissReason] = []
        let dropped = LMKToast.show(LMKToast.Configuration(status: .info, message: "Dropped", presentation: .onViewController(host), queuePolicy: .dropIfBusy, onDismiss: { reasons.append($0) }))
        #expect(!dropped.isPresented)
        #expect(reasons == [.programmatic])
        #expect(Self.toasts(in: host.view).count == 1)
    }

    @Test
    func `A timed toast dismisses itself with the timeout reason`() async {
        let (window, host) = Self.makeHost()
        defer { window.isHidden = true; LMKToast.dismissAll() }
        var reason: LMKToast.DismissReason?
        LMKToast.show(LMKToast.Configuration(status: .info, message: "Quick", duration: .seconds(0.05), presentation: .onViewController(host), onDismiss: { reason = $0 }))
        await LMKWait.until { reason != nil }
        #expect(reason == .timeout)
        #expect(Self.toasts(in: host.view).isEmpty)
    }

    @Test
    func `Tap and tapToDismiss`() async {
        let (window, host) = Self.makeHost()
        defer { window.isHidden = true; LMKToast.dismissAll() }
        var reasons: [LMKToast.DismissReason] = []
        LMKToast.show(LMKToast.Configuration(status: .info, message: "Sticky", tapToDismiss: false, presentation: .onViewController(host), onDismiss: { reasons.append($0) }))
        Self.toasts(in: host.view).first?.didTapToast()
        #expect(Self.toasts(in: host.view).count == 1, "tapToDismiss false ignores the tap")
        #expect(reasons.isEmpty)
        LMKToast.dismissAll(in: host)
        await LMKWait.until { reasons.count == 1 }
        LMKToast.show(LMKToast.Configuration(status: .info, message: "Tappable", presentation: .onViewController(host), onDismiss: { reasons.append($0) }))
        Self.toasts(in: host.view).first?.didTapToast()
        await LMKWait.until { reasons.count == 2 }
        #expect(reasons == [.programmatic, .tap])
    }

    @Test
    func `Undo toasts commit on timeout and skip the commit when undone`() async {
        let (window, host) = Self.makeHost()
        defer { window.isHidden = true; LMKToast.dismissAll() }
        var commits = 0
        var undos = 0
        LMKToast.showUndo(message: "Deleted", duration: 0.05, in: host, onUndo: { undos += 1 }, onCommit: { commits += 1 })
        let undoToast = Self.toasts(in: host.view).first
        #expect(undoToast?.configuration.showsCountdown == true)
        #expect(undoToast?.configuration.haptics == false)
        #expect(undoToast?.actionButton.title == LMKToast.Strings().undo)
        await LMKWait.until { commits == 1 }
        #expect(commits == 1)
        #expect(undos == 0)

        LMKToast.showUndo(message: "Deleted again", duration: 5, in: host, onUndo: { undos += 1 }, onCommit: { commits += 1 })
        Self.toasts(in: host.view).first?.actionButton.didTap()
        await LMKWait.until { undos == 1 }
        #expect(undos == 1)
        #expect(commits == 1)
    }

    @Test
    func `An undo toast takes a status, an icon, a position, and tap-to-dismiss; by default a tap commits nothing`() async throws {
        let (window, host) = Self.makeHost()
        defer { window.isHidden = true; LMKToast.dismissAll() }
        var commits = 0
        let trash = try #require(UIImage(systemName: "trash.fill"))
        LMKToast.showUndo(
            message: "Walk deleted",
            in: host,
            status: .warning,
            icon: trash,
            position: .bottom,
            tapToDismiss: true,
            haptics: true,
            onUndo: {},
            onCommit: { commits += 1 }
        )
        let toast = try #require(Self.toasts(in: host.view).first)
        #expect(toast.configuration.status == .warning)
        #expect(toast.configuration.icon === trash)
        #expect(toast.iconView.image === trash, "the icon replaces the status glyph inside the ring")
        #expect(toast.configuration.position == .bottom)
        #expect(toast.configuration.tapToDismiss)
        #expect(toast.configuration.haptics == true)
        #expect(toast.configuration.showsCountdown)
        toast.didTapToast()
        await LMKWait.until { commits == 1 }
        #expect(commits == 1, "opted in, a tap dismisses it and commits")

        // The defaults: a tap that misses Undo leaves the toast up and deletes nothing.
        LMKToast.showUndo(message: "Deleted", in: host, onUndo: {}, onCommit: { commits += 1 })
        let plain = try #require(Self.toasts(in: host.view).last)
        #expect(plain.configuration.status == .neutral)
        #expect(plain.configuration.icon == nil)
        #expect(plain.configuration.position == .top)
        #expect(plain.configuration.tapToDismiss == false)
        #expect(plain.configuration.haptics == false)
        plain.didTapToast()
        #expect(plain.superview != nil, "a tap leaves it up")
        #expect(commits == 1)
    }

    @Test
    func `A resigning scene commits its undo toasts at once and leaves other toasts alone`() {
        let (window, host) = Self.makeHost()
        defer { window.isHidden = true; LMKToast.dismissAll() }
        var reasons: [LMKToast.DismissReason] = []
        LMKToast.showUndo(message: "Deleted", in: host, onUndo: {}, onCommit: { reasons.append(.sceneResigned) })
        let other = UIViewController()
        window.addSubview(other.view)
        LMKToast.show(LMKToast.Configuration(status: .info, message: "Plain", presentation: .onViewController(other), onDismiss: { reasons.append($0) }))
        // No scene in the notification: every scene's undo toasts commit, synchronously.
        NotificationCenter.default.post(name: UIScene.willDeactivateNotification, object: nil)
        #expect(reasons == [.sceneResigned])
        #expect(Self.toasts(in: host.view).isEmpty)
        #expect(Self.toasts(in: other.view).count == 1, "a toast without a countdown stays")
    }

    @Test
    func `dismissAll clears the host and reports the queued toasts`() async {
        let (window, host) = Self.makeHost()
        defer { window.isHidden = true }
        var reasons: [LMKToast.DismissReason] = []
        LMKToast.show(.info, "One", in: host)
        LMKToast.show(LMKToast.Configuration(status: .info, message: "Two", presentation: .onViewController(host), queuePolicy: .enqueue, onDismiss: { reasons.append($0) }))
        LMKToast.dismissAll(in: host)
        #expect(reasons == [.programmatic], "the queued toast reports right away")
        await LMKWait.until { Self.toasts(in: host.view).isEmpty }
        #expect(Self.toasts(in: host.view).isEmpty)
    }

    @Test
    func `LMKToastView.show(in:) presents through the same presenter and can be shown again`() async {
        let (window, host) = Self.makeHost()
        defer { window.isHidden = true; LMKToast.dismissAll() }
        let toast = LMKToastView(status: .warning, message: "Careful")
        toast.show(in: host)
        #expect(Self.toasts(in: host.view).first === toast)
        toast.dismiss()
        await LMKWait.until { Self.toasts(in: host.view).isEmpty }
        toast.show(in: host)
        #expect(Self.toasts(in: host.view).first === toast)
        toast.dismiss()
        await LMKWait.until { Self.toasts(in: host.view).isEmpty }
        #expect(Self.toasts(in: host.view).isEmpty, "a re-shown toast can be dismissed again")

        // Shown again while its exit is still in flight: the new presentation stays on screen
        // and is still the host's current toast.
        toast.show(in: host)
        toast.dismiss()
        toast.show(in: host)
        try? await Task.sleep(for: .milliseconds(400))
        #expect(Self.toasts(in: host.view).first === toast, "the stale exit did not remove the new presentation")
        LMKToast.show(.info, "Next", in: host)
        await LMKWait.until { Self.toasts(in: host.view).map(\.messageLabel.text) == ["Next"] }
        #expect(Self.toasts(in: host.view).map(\.messageLabel.text) == ["Next"], "the queue still knew the re-shown toast and replaced it")
    }
}
