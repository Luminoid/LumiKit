//
//  LMKToast.swift
//  LumiKit
//
//  The toast presenter: one `show` entry point taking a configuration (status,
//  message, optional title / action / undo countdown, duration, position,
//  presentation host, queue policy), returning a handle.
//

import UIKit

// MARK: - Configuration

public extension LMKToast {
    /// Everything a toast needs; build one and pass it to `LMKToast.show(_:)`, or use
    /// the `LMKToast.show(_:message:…)` shorthand.
    struct Configuration {
        /// How long the toast stays.
        public nonisolated enum Duration: Sendable, Hashable {
            case seconds(TimeInterval)
            /// Stays until dismissed; shows a dismiss button.
            case persistent
        }

        /// Which edge the toast slides in from.
        public nonisolated enum Position: Sendable, Hashable, CaseIterable {
            case top, bottom
        }

        /// Where the toast is installed.
        public enum Presentation {
            case inView(UIView)
            case onViewController(UIViewController)
            /// The window scene's key window (`nil` = the key window's scene), above any
            /// sheet presented before the toast.
            case inWindowScene(UIWindowScene?)
        }

        /// What happens when a toast is already showing in the same host.
        public nonisolated enum QueuePolicy: Sendable, Hashable, CaseIterable {
            /// Dismiss the current toast and show this one (the default).
            case replace
            /// Show this one after the current toast (and any queued ones) dismiss.
            case enqueue
            /// Do nothing; the returned handle is already dismissed and `onDismiss` has run
            /// with `.programmatic`.
            case dropIfBusy
        }

        /// A trailing action button.
        public struct Action {
            public var title: String
            public var onAction: () -> Void

            public init(title: String, onAction: @escaping () -> Void) {
                self.title = title
                self.onAction = onAction
            }
        }

        public var status: LMKStatus
        public var message: String
        public var title: String?
        /// Overrides the status symbol.
        public var icon: UIImage?
        public var action: Action?
        public var duration: Duration
        public var position: Position
        /// Tapping the toast dismisses it.
        public var tapToDismiss: Bool
        /// Play the status haptic when shown.
        public var haptics: Bool
        public var presentation: Presentation
        public var queuePolicy: QueuePolicy
        /// Draws a countdown ring around the icon over `duration` (undo toasts).
        public var showsCountdown: Bool
        public var style: LMKToastView.Style
        /// Called after the entrance animation.
        public var onPresent: (() -> Void)?
        /// Called once the toast is gone, with why. A toast that never reaches the screen (no
        /// host, dropped from a queue) still reports, with `.programmatic` or `.replaced`.
        public var onDismiss: ((LMKToast.DismissReason) -> Void)?

        public init(
            status: LMKStatus,
            message: String,
            title: String? = nil,
            icon: UIImage? = nil,
            action: Action? = nil,
            duration: Duration = .seconds(LMKToast.defaultDuration),
            position: Position = .top,
            tapToDismiss: Bool = true,
            haptics: Bool = true,
            presentation: Presentation = .inWindowScene(nil),
            queuePolicy: QueuePolicy = .replace,
            showsCountdown: Bool = false,
            style: LMKToastView.Style = LMKToastView.Style(),
            onPresent: (() -> Void)? = nil,
            onDismiss: ((LMKToast.DismissReason) -> Void)? = nil
        ) {
            self.status = status
            self.message = message
            self.title = title
            self.icon = icon
            self.action = action
            self.duration = duration
            self.position = position
            self.tapToDismiss = tapToDismiss
            self.haptics = haptics
            self.presentation = presentation
            self.queuePolicy = queuePolicy
            self.showsCountdown = showsCountdown
            self.style = style
            self.onPresent = onPresent
            self.onDismiss = onDismiss
        }
    }

    /// Why a toast left the screen.
    nonisolated enum DismissReason: Sendable, Hashable, CaseIterable {
        /// Its duration elapsed.
        case timeout
        /// The user tapped it or its dismiss button.
        case tap
        /// The user chose its action.
        case action
        /// Another toast replaced it (on screen or in the queue).
        case replaced
        /// `dismiss()`, `dismissAll`, a `.dropIfBusy` drop, no host to show in, or the host
        /// leaving the window (its screen went away).
        case programmatic
        /// Its scene resigned active (undo toasts commit here).
        case sceneResigned
    }

    /// Controls a presented toast.
    final class Handle {
        weak var view: LMKToastView?
        weak var presenter: LMKToastPresenter?

        /// Whether the toast is on screen or queued.
        public private(set) var isPresented = true

        init(view: LMKToastView?, presenter: LMKToastPresenter?, isPresented: Bool = true) {
            self.view = view
            self.presenter = presenter
            self.isPresented = isPresented
        }

        /// Dismisses the toast (or removes it from the queue).
        public func dismiss() {
            guard isPresented else { return }
            presenter?.dismiss(handle: self, reason: .programmatic)
        }

        /// Replaces the message in place (or in the queued configuration).
        public func setMessage(_ message: String) {
            if let view {
                view.setMessage(message)
            } else {
                presenter?.setMessage(message, for: self)
            }
        }

        func markDismissed() {
            isPresented = false
        }
    }
}

// MARK: - LMKToast

/// Toast presentation.
///
/// ```swift
/// LMKToast.show(.success, "Saved", in: self)
/// LMKToast.show(LMKToast.Configuration(status: .error, message: "Upload failed", action: .init(title: "Retry") { retry() }))
/// LMKToast.showUndo(message: "Deleted", onUndo: { restore() }, onCommit: { purge() })
/// ```
public enum LMKToast {
    public static let defaultDuration: TimeInterval = 3
    public static let defaultUndoDuration: TimeInterval = 5

    public nonisolated struct Strings: Sendable, Equatable {
        public var dismissAccessibilityLabel: String
        public var undo: String

        public init(
            dismissAccessibilityLabel: String = LMKLocalized("toast.dismiss.accessibilityLabel"),
            undo: String = LMKLocalized("toast.undo")
        ) {
            self.dismissAccessibilityLabel = dismissAccessibilityLabel
            self.undo = undo
        }
    }

    /// Process-wide defaults; set at app launch to override.
    public nonisolated(unsafe) static var strings = Strings()

    /// Shows a configured toast.
    @discardableResult
    public static func show(_ configuration: Configuration) -> Handle {
        LMKToastPresenter.shared.show(configuration)
    }

    /// Shows a status toast. `host` `nil` presents on the key window, above presented sheets.
    @discardableResult
    public static func show(
        _ status: LMKStatus,
        _ message: String,
        duration: TimeInterval = defaultDuration,
        in host: UIViewController? = nil,
        completion: (() -> Void)? = nil
    ) -> Handle {
        show(Configuration(
            status: status,
            message: message,
            duration: .seconds(duration),
            presentation: host.map { .onViewController($0) } ?? .inWindowScene(nil),
            onPresent: completion
        ))
    }

    /// Shows an undo toast: a countdown ring, an Undo action, and `onCommit` when the toast
    /// leaves any other way (timeout, replacement, dismissal, the scene resigning, or never
    /// having reached the screen). `onCommit` is retained strongly so the commit survives the
    /// presenting screen.
    @discardableResult
    public static func showUndo(
        message: String,
        duration: TimeInterval = defaultUndoDuration,
        in host: UIViewController? = nil,
        onUndo: @escaping () -> Void,
        onCommit: @escaping () -> Void
    ) -> Handle {
        show(Configuration(
            status: .neutral,
            message: message,
            action: .init(title: strings.undo, onAction: onUndo),
            duration: .seconds(duration),
            haptics: false,
            presentation: host.map { .onViewController($0) } ?? .inWindowScene(nil),
            showsCountdown: true,
            onDismiss: { reason in
                if reason != .action { onCommit() }
            }
        ))
    }

    /// Dismisses every toast in `host` (`nil` = every host).
    public static func dismissAll(in host: UIViewController? = nil) {
        LMKToastPresenter.shared.dismissAll(in: host?.view)
    }
}

// MARK: - Presenter

/// Owns the per-host queues.
@MainActor
final class LMKToastPresenter {
    static let shared = LMKToastPresenter()

    private final class HostQueue {
        weak var host: UIView?
        var current: (view: LMKToastView, handle: LMKToast.Handle)?
        var pending: [(configuration: LMKToast.Configuration, handle: LMKToast.Handle)] = []

        init(host: UIView) {
            self.host = host
        }
    }

    private var queues: [ObjectIdentifier: HostQueue] = [:]

    private init() {
        // The center holds a block observer itself, and the presenter lives for the process.
        _ = NotificationCenter.default.addObserver(forName: UIScene.willDeactivateNotification, object: nil, queue: .main) { notification in
            let sceneID = (notification.object as? UIScene).map(ObjectIdentifier.init)
            MainActor.assumeIsolated {
                Self.shared.sceneWillDeactivate(sceneID: sceneID)
            }
        }
    }

    func show(_ configuration: LMKToast.Configuration) -> LMKToast.Handle {
        guard let host = hostView(for: configuration.presentation) else {
            // Nothing to show in (a scene disconnecting, a background launch): the toast is
            // over before it began, and an undo toast's commit must not be lost with it.
            configuration.onDismiss?(.programmatic)
            return LMKToast.Handle(view: nil, presenter: nil, isPresented: false)
        }
        let queue = queue(for: host)
        let handle = LMKToast.Handle(view: nil, presenter: self)

        if let current = queue.current {
            switch configuration.queuePolicy {
            case .replace:
                dropPending(in: queue, reason: .replaced)
                current.handle.markDismissed()
                dismiss(current.view, reason: .replaced)
                present(configuration, handle: handle, in: queue)
            case .enqueue:
                queue.pending.append((configuration, handle))
            case .dropIfBusy:
                handle.markDismissed()
                configuration.onDismiss?(.programmatic)
            }
        } else {
            present(configuration, handle: handle, in: queue)
        }
        return handle
    }

    /// Presents a toast view built by the caller (the `LMKToastView.show(in:)` path).
    func present(_ view: LMKToastView, in host: UIView, completion: (() -> Void)?) -> LMKToast.Handle {
        let queue = queue(for: host)
        if let current = queue.current {
            dropPending(in: queue, reason: .replaced)
            current.handle.markDismissed()
            dismiss(current.view, reason: .replaced)
        }
        let handle = LMKToast.Handle(view: view, presenter: self)
        queue.current = (view, handle)
        view.present(in: host, presenter: self, completion: completion)
        return handle
    }

    func dismiss(handle: LMKToast.Handle, reason: LMKToast.DismissReason) {
        for queue in queues.values {
            if let current = queue.current, current.handle === handle {
                dismiss(current.view, reason: reason)
                return
            }
            if let index = queue.pending.firstIndex(where: { $0.handle === handle }) {
                let entry = queue.pending.remove(at: index)
                entry.handle.markDismissed()
                entry.configuration.onDismiss?(reason)
                return
            }
        }
    }

    func dismiss(_ view: LMKToastView, reason: LMKToast.DismissReason) {
        view.dismiss(reason: reason)
    }

    func dismissAll(in host: UIView?) {
        for queue in queues.values where host == nil || queue.host === host {
            dropPending(in: queue, reason: .programmatic)
            if let current = queue.current {
                dismiss(current.view, reason: .programmatic)
            }
        }
    }

    /// Updates the message of a toast that is still waiting in a queue.
    func setMessage(_ message: String, for handle: LMKToast.Handle) {
        for queue in queues.values {
            if let index = queue.pending.firstIndex(where: { $0.handle === handle }) {
                queue.pending[index].configuration.message = message
                return
            }
        }
    }

    /// Called by the view after its exit animation.
    func toastDidDismiss(_ view: LMKToastView) {
        for (key, queue) in queues {
            guard let current = queue.current, current.view === view else { continue }
            current.handle.markDismissed()
            queue.current = nil
            if !queue.pending.isEmpty {
                let next = queue.pending.removeFirst()
                present(next.configuration, handle: next.handle, in: queue)
            } else {
                queues[key] = nil
            }
            return
        }
    }

    private func present(_ configuration: LMKToast.Configuration, handle: LMKToast.Handle, in queue: HostQueue) {
        guard let host = queue.host else {
            handle.markDismissed()
            configuration.onDismiss?(.programmatic)
            return
        }
        let view = LMKToastView(configuration: configuration)
        handle.view = view
        queue.current = (view, handle)
        view.present(in: host, presenter: self, completion: configuration.onPresent)
    }

    /// Empties the queue, reporting `reason` to every dropped toast.
    private func dropPending(in queue: HostQueue, reason: LMKToast.DismissReason) {
        let dropped = queue.pending
        queue.pending = []
        for entry in dropped {
            entry.handle.markDismissed()
            entry.configuration.onDismiss?(reason)
        }
    }

    /// The live queue for `host`; a queue whose host was released (its address may be reused) is replaced.
    private func queue(for host: UIView) -> HostQueue {
        let key = ObjectIdentifier(host)
        if let existing = queues[key], existing.host === host {
            return existing
        }
        let queue = HostQueue(host: host)
        queues[key] = queue
        return queue
    }

    /// The window itself hosts the default presentation: UIKit puts presented controllers in
    /// a transition view above the root view controller's view, so a toast on that view would
    /// sit under every sheet. It is the window of the controller on top, since under the Mac
    /// idiom a page sheet is hosted in a window of its own.
    private func hostView(for presentation: LMKToast.Configuration.Presentation) -> UIView? {
        switch presentation {
        case let .inView(view): view
        case let .onViewController(controller): controller.view
        case let .inWindowScene(scene):
            Self.topWindow(above: scene?.keyWindow ?? LMKScene.keyWindow)
        }
    }

    /// The window of the top-most controller presented from `window`'s root, else `window`.
    static func topWindow(above window: UIWindow?) -> UIWindow? {
        guard let root = window?.rootViewController else { return window }
        return UIViewController.lmk_topViewController(controller: root)?.viewIfLoaded?.window ?? window
    }

    /// Commits the undo toasts of the scene that resigned (every scene when it is unknown).
    private func sceneWillDeactivate(sceneID: ObjectIdentifier?) {
        for queue in queues.values {
            guard let current = queue.current, current.view.configuration.showsCountdown else { continue }
            let viewSceneID = current.view.window?.windowScene.map(ObjectIdentifier.init)
            guard sceneID == nil || viewSceneID == nil || viewSceneID == sceneID else { continue }
            dismiss(current.view, reason: .sceneResigned)
        }
    }
}
