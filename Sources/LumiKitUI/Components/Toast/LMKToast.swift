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

/// Everything a toast needs; build one and pass it to `LMKToast.show(_:)`, or use
/// the `LMKToast.show(_:message:…)` shorthand.
public struct LMKToastConfiguration {
    /// How long the toast stays.
    public enum Duration: Equatable, Sendable {
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
        /// The window scene's root view (`nil` = the key window's scene), above any presented sheet.
        case inWindowScene(UIWindowScene?)
    }

    /// What happens when a toast is already showing in the same host.
    public nonisolated enum QueuePolicy: Sendable, Hashable, CaseIterable {
        /// Dismiss the current toast and show this one (the default).
        case replace
        /// Show this one after the current toast (and any queued ones) dismiss.
        case enqueue
        /// Do nothing; the returned handle is already dismissed.
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
    public var haptic: Bool
    public var presentation: Presentation
    public var queuePolicy: QueuePolicy
    /// Draws a countdown ring around the icon over `duration` (undo toasts).
    public var showsCountdown: Bool
    public var style: LMKToastView.Style
    /// Called after the entrance animation.
    public var onPresented: (() -> Void)?
    /// Called after the toast leaves, with why.
    public var onDismiss: ((LMKToastDismissReason) -> Void)?

    public init(
        status: LMKStatus,
        message: String,
        title: String? = nil,
        icon: UIImage? = nil,
        action: Action? = nil,
        duration: Duration = .seconds(LMKToast.defaultDuration),
        position: Position = .top,
        tapToDismiss: Bool = true,
        haptic: Bool = true,
        presentation: Presentation = .inWindowScene(nil),
        queuePolicy: QueuePolicy = .replace,
        showsCountdown: Bool = false,
        style: LMKToastView.Style = LMKToastView.Style(),
        onPresented: (() -> Void)? = nil,
        onDismiss: ((LMKToastDismissReason) -> Void)? = nil
    ) {
        self.status = status
        self.message = message
        self.title = title
        self.icon = icon
        self.action = action
        self.duration = duration
        self.position = position
        self.tapToDismiss = tapToDismiss
        self.haptic = haptic
        self.presentation = presentation
        self.queuePolicy = queuePolicy
        self.showsCountdown = showsCountdown
        self.style = style
        self.onPresented = onPresented
        self.onDismiss = onDismiss
    }
}

/// Why a toast left the screen.
public nonisolated enum LMKToastDismissReason: Sendable, Hashable, CaseIterable {
    /// Its duration elapsed.
    case timeout
    /// The user tapped it or its dismiss button.
    case tap
    /// The user chose its action.
    case action
    /// Another toast replaced it.
    case replaced
    /// `dismiss()` or `dismissAll`.
    case programmatic
    /// The scene resigned active (undo toasts commit here).
    case sceneResigned
}

// MARK: - Handle

/// Controls a presented toast.
public final class LMKToastHandle {
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

    /// Replaces the message in place.
    public func setMessage(_ message: String) {
        view?.setMessage(message)
    }

    func markDismissed() {
        isPresented = false
    }
}

// MARK: - LMKToast

/// Toast presentation.
///
/// ```swift
/// LMKToast.show(.success, "Saved", in: self)
/// LMKToast.show(LMKToastConfiguration(status: .error, message: "Upload failed", action: .init(title: "Retry") { retry() }))
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
    public static func show(_ configuration: LMKToastConfiguration) -> LMKToastHandle {
        LMKToastPresenter.shared.show(configuration)
    }

    /// Shows a status toast. `host` `nil` presents on the key window's root view (above sheets).
    @discardableResult
    public static func show(
        _ status: LMKStatus,
        _ message: String,
        duration: TimeInterval = defaultDuration,
        in host: UIViewController? = nil,
        completion: (() -> Void)? = nil
    ) -> LMKToastHandle {
        show(LMKToastConfiguration(
            status: status,
            message: message,
            duration: .seconds(duration),
            presentation: host.map { .onViewController($0) } ?? .inWindowScene(nil),
            onPresented: completion
        ))
    }

    /// Shows an undo toast: a countdown ring, an Undo action, and `onCommit` when the toast
    /// leaves any other way (timeout, replacement, dismissal, the scene resigning).
    /// `onCommit` is retained strongly so the commit survives the presenting screen.
    @discardableResult
    public static func showUndo(
        message: String,
        duration: TimeInterval = defaultUndoDuration,
        in host: UIViewController? = nil,
        onUndo: @escaping () -> Void,
        onCommit: @escaping () -> Void
    ) -> LMKToastHandle {
        show(LMKToastConfiguration(
            status: .neutral,
            message: message,
            action: .init(title: strings.undo, onAction: onUndo),
            duration: .seconds(duration),
            haptic: false,
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
        var current: (view: LMKToastView, handle: LMKToastHandle)?
        var pending: [(configuration: LMKToastConfiguration, handle: LMKToastHandle)] = []

        init(host: UIView) {
            self.host = host
        }
    }

    private var queues: [ObjectIdentifier: HostQueue] = [:]
    private var sceneObserver: (any NSObjectProtocol)?

    private init() {
        sceneObserver = NotificationCenter.default.addObserver(forName: UIScene.willDeactivateNotification, object: nil, queue: .main) { _ in
            MainActor.assumeIsolated {
                Self.shared.sceneWillDeactivate()
            }
        }
    }

    func show(_ configuration: LMKToastConfiguration) -> LMKToastHandle {
        guard let host = hostView(for: configuration.presentation) else {
            return LMKToastHandle(view: nil, presenter: nil, isPresented: false)
        }
        let queue = queue(for: host)
        let handle = LMKToastHandle(view: nil, presenter: self)

        if let current = queue.current {
            switch configuration.queuePolicy {
            case .replace:
                queue.pending.removeAll { $0.handle.markDismissed(); return true }
                dismiss(current.view, reason: .replaced)
                present(configuration, handle: handle, in: queue)
            case .enqueue:
                queue.pending.append((configuration, handle))
            case .dropIfBusy:
                handle.markDismissed()
            }
        } else {
            present(configuration, handle: handle, in: queue)
        }
        return handle
    }

    /// Presents a toast view built by the caller (the `LMKToastView.show(in:)` path).
    func present(_ view: LMKToastView, in host: UIView, completion: (() -> Void)?) -> LMKToastHandle {
        let queue = queue(for: host)
        if let current = queue.current {
            queue.pending.removeAll { $0.handle.markDismissed(); return true }
            dismiss(current.view, reason: .replaced)
        }
        let handle = LMKToastHandle(view: view, presenter: self)
        queue.current = (view, handle)
        view.present(in: host, presenter: self, completion: completion)
        return handle
    }

    func dismiss(handle: LMKToastHandle, reason: LMKToastDismissReason) {
        for queue in queues.values {
            if let current = queue.current, current.handle === handle {
                dismiss(current.view, reason: reason)
                return
            }
            if let index = queue.pending.firstIndex(where: { $0.handle === handle }) {
                queue.pending.remove(at: index)
                handle.markDismissed()
                return
            }
        }
    }

    func dismiss(_ view: LMKToastView, reason: LMKToastDismissReason) {
        view.dismiss(reason: reason)
    }

    func dismissAll(in host: UIView?) {
        for queue in queues.values where host == nil || queue.host === host {
            queue.pending.removeAll { $0.handle.markDismissed(); return true }
            if let current = queue.current {
                dismiss(current.view, reason: .programmatic)
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
            } else if queue.host == nil {
                queues[key] = nil
            }
            return
        }
    }

    private func present(_ configuration: LMKToastConfiguration, handle: LMKToastHandle, in queue: HostQueue) {
        guard let host = queue.host else {
            handle.markDismissed()
            return
        }
        let view = LMKToastView(configuration: configuration)
        handle.view = view
        queue.current = (view, handle)
        view.present(in: host, presenter: self, completion: configuration.onPresented)
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

    private func hostView(for presentation: LMKToastConfiguration.Presentation) -> UIView? {
        switch presentation {
        case let .inView(view): view
        case let .onViewController(controller): controller.view
        case let .inWindowScene(scene): (scene?.keyWindow ?? LMKScene.keyWindow)?.rootViewController?.view
        }
    }

    private func sceneWillDeactivate() {
        for queue in queues.values {
            guard let current = queue.current, current.view.configuration.showsCountdown else { continue }
            dismiss(current.view, reason: .sceneResigned)
        }
    }
}
