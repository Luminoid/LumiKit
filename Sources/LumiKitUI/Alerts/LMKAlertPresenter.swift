//
//  LMKAlertPresenter.swift
//  LumiKit
//
//  Centralized alert presentation helper with configurable strings.
//

import UIKit

/// Helper for presenting alerts consistently.
///
/// Configure strings at app launch:
/// ```swift
/// LMKAlertPresenter.strings = .init(ok: "OK", cancel: "Cancel")
/// ```
@MainActor
public enum LMKAlertPresenter {
    // MARK: - Configurable Strings

    /// Configurable button title strings.
    public struct Strings: Sendable {
        public var ok: String
        public var cancel: String

        public init(ok: String = "OK", cancel: String = "Cancel") {
            self.ok = ok
            self.cancel = cancel
        }
    }

    /// Override these at app launch with localized values.
    nonisolated(unsafe) public static var strings = Strings()

    // MARK: - Presentation

    /// Present a confirmation alert with confirm and cancel buttons.
    public static func presentConfirmation(
        on viewController: UIViewController,
        title: String,
        message: String? = nil,
        confirmTitle: String? = nil,
        cancelTitle: String? = nil,
        confirmStyle: UIAlertAction.Style = .default,
        onConfirm: @escaping () -> Void,
        onCancel: (() -> Void)? = nil
    ) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: cancelTitle ?? strings.cancel, style: .cancel) { _ in onCancel?() })
        alert.addAction(UIAlertAction(title: confirmTitle ?? strings.ok, style: confirmStyle) { _ in onConfirm() })
        viewController.present(alert, animated: true)
    }

    /// Present a simple alert with a single dismiss button.
    public static func presentAlert(
        on viewController: UIViewController,
        title: String,
        message: String? = nil,
        buttonTitle: String? = nil,
        onDismiss: (() -> Void)? = nil
    ) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: buttonTitle ?? strings.ok, style: .default) { _ in onDismiss?() })
        viewController.present(alert, animated: true)
    }

    /// Present an action sheet with multiple actions.
    public static func presentActionSheet(
        on viewController: UIViewController,
        title: String? = nil,
        message: String? = nil,
        actions: [(title: String, style: UIAlertAction.Style, handler: () -> Void)],
        cancelTitle: String? = nil
    ) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
        for action in actions {
            alert.addAction(UIAlertAction(title: action.title, style: action.style) { _ in action.handler() })
        }
        alert.addAction(UIAlertAction(title: cancelTitle ?? strings.cancel, style: .cancel))
        viewController.lmk_configurePopoverForActionSheet(alert)
        viewController.present(alert, animated: true)
    }
}
