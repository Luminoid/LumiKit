//
//  LMKKeyboardObserver.swift
//  LumiKit
//
//  Keyboard show/hide observer with height tracking.
//

import UIKit

/// Observes keyboard show/hide notifications and provides height and animation info.
///
/// ```swift
/// let observer = LMKKeyboardObserver()
/// observer.onKeyboardChange = { info in
///     scrollView.contentInset.bottom = info.height
/// }
/// observer.startObserving()
/// ```
public final class LMKKeyboardObserver {
    /// Keyboard change info.
    public struct KeyboardInfo {
        /// Keyboard height (0 when hidden).
        public let height: CGFloat
        /// Animation duration.
        public let animationDuration: TimeInterval
        /// Animation curve as animation options.
        public let animationOptions: UIView.AnimationOptions
        /// Whether the keyboard is visible.
        public var isVisible: Bool { height > 0 }
    }

    /// Called on keyboard show/hide with animation info.
    public var onKeyboardChange: ((KeyboardInfo) -> Void)?

    /// Current keyboard height (0 when hidden).
    public private(set) var currentHeight: CGFloat = 0

    // nonisolated(unsafe): accessed from MainActor methods and deinit (exclusive access).
    private nonisolated(unsafe) var observers: [any NSObjectProtocol] = []

    public init() {}

    /// Start observing keyboard notifications.
    public func startObserving() {
        stopObserving()

        let showObserver = NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillShowNotification,
            object: nil, queue: .main
        ) { [weak self] notification in
            let parsed = Self.parseNotification(notification, visible: true)
            MainActor.assumeIsolated {
                self?.applyKeyboardInfo(parsed)
            }
        }

        let hideObserver = NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillHideNotification,
            object: nil, queue: .main
        ) { [weak self] notification in
            let parsed = Self.parseNotification(notification, visible: false)
            MainActor.assumeIsolated {
                self?.applyKeyboardInfo(parsed)
            }
        }

        observers = [showObserver, hideObserver]
    }

    /// Stop observing keyboard notifications.
    public func stopObserving() {
        observers.forEach { NotificationCenter.default.removeObserver($0) }
        observers = []
    }

    /// Extract keyboard info from notification outside MainActor isolation.
    private nonisolated static func parseNotification(_ notification: Notification, visible: Bool) -> KeyboardInfo {
        let userInfo = notification.userInfo
        let frameEnd = (userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue ?? .zero
        let duration = (userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval) ?? 0.25
        let curveRaw = (userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt) ?? 7
        let height: CGFloat = visible ? frameEnd.height : 0
        return KeyboardInfo(
            height: height,
            animationDuration: duration,
            animationOptions: UIView.AnimationOptions(rawValue: curveRaw << 16)
        )
    }

    private func applyKeyboardInfo(_ info: KeyboardInfo) {
        guard info.height != currentHeight else { return }
        currentHeight = info.height
        onKeyboardChange?(info)
    }

    deinit {
        // NotificationCenter.removeObserver is thread-safe; no MainActor requirement.
        observers.forEach { NotificationCenter.default.removeObserver($0) }
    }
}
