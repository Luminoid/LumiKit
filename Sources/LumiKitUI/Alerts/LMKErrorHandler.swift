//
//  LMKErrorHandler.swift
//  LumiKit
//
//  Helper for displaying user-friendly error messages with retry support.
//

import UIKit

/// Helper for displaying user-friendly error messages.
///
/// Configure strings at app launch:
/// ```swift
/// LMKErrorHandler.strings = .init(errorTitle: "Error", retry: "Retry", ok: "OK", warningTitle: "Warning")
/// ```
public enum LMKErrorHandler {
    // MARK: - Configurable Strings

    /// Configurable display strings.
    public nonisolated struct Strings: Sendable {
        public var errorTitle: String
        public var retry: String
        public var ok: String
        public var warningTitle: String

        public init(
            errorTitle: String = "Error",
            retry: String = "Retry",
            ok: String = "OK",
            warningTitle: String = "Warning",
        ) {
            self.errorTitle = errorTitle
            self.retry = retry
            self.ok = ok
            self.warningTitle = warningTitle
        }
    }

    /// Override these at app launch with localized values.
    public nonisolated(unsafe) static var strings = Strings()

    // MARK: - Presentation

    /// Present a user-friendly error message from an `Error`.
    public static func presentError(
        on viewController: UIViewController,
        error: Error,
        retryAction: (() -> Void)? = nil,
        showRetry: Bool? = nil,
    ) {
        let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        presentError(on: viewController, message: message, retryAction: retryAction, showRetry: showRetry)
    }

    /// Present a user-friendly error message with optional retry.
    public static func presentError(
        on viewController: UIViewController,
        title: String? = nil,
        message: String,
        retryAction: (() -> Void)? = nil,
        showRetry: Bool? = nil,
    ) {
        let shouldShowRetry = showRetry ?? (retryAction != nil)

        if shouldShowRetry, retryAction != nil {
            let alert = UIAlertController(title: title ?? strings.errorTitle, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: strings.retry, style: .default) { _ in retryAction?() })
            alert.addAction(UIAlertAction(title: strings.ok, style: .cancel))
            viewController.present(alert, animated: true)
        } else {
            LMKToast.showError(message: message, on: viewController)
        }
    }

    /// Present a warning message (non-critical error).
    public static func presentWarning(
        on viewController: UIViewController,
        title: String? = nil,
        message: String,
    ) {
        let alert = UIAlertController(title: title ?? strings.warningTitle, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: strings.ok, style: .default))
        viewController.present(alert, animated: true)
    }
}
