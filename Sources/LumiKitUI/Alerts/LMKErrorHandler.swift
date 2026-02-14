//
//  LMKErrorHandler.swift
//  LumiKit
//
//  Helper for displaying user-friendly error messages with severity-based presentation.
//

import LumiKitCore
import UIKit

/// Helper for displaying user-friendly error messages.
///
/// Configure strings at app launch:
/// ```swift
/// LMKErrorHandler.strings = .init(errorTitle: "Error", retry: "Retry", ok: "OK", warningTitle: "Warning", infoTitle: "Info")
/// ```
///
/// Present errors with severity:
/// ```swift
/// LMKErrorHandler.present(on: self, message: "Something went wrong", retryAction: { retry() })
/// LMKErrorHandler.present(on: self, error: error, severity: .warning)
/// ```
public enum LMKErrorHandler {
    // MARK: - Configurable Strings

    /// Configurable display strings.
    public nonisolated struct Strings: Sendable {
        public var errorTitle: String
        public var retry: String
        public var ok: String
        public var warningTitle: String
        public var infoTitle: String

        public init(
            errorTitle: String = "Error",
            retry: String = "Retry",
            ok: String = "OK",
            warningTitle: String = "Warning",
            infoTitle: String = "Info"
        ) {
            self.errorTitle = errorTitle
            self.retry = retry
            self.ok = ok
            self.warningTitle = warningTitle
            self.infoTitle = infoTitle
        }
    }

    /// Override these at app launch with localized values.
    public nonisolated(unsafe) static var strings = Strings()

    // MARK: - Severity

    /// Error severity determines presentation style.
    public enum Severity: Sendable {
        /// Informational toast.
        case info
        /// Alert with OK button.
        case warning
        /// Toast for transient errors, alert with retry for recoverable errors.
        case error
        /// Always shows an alert, retry if available.
        case critical
    }

    // MARK: - Presentation

    /// Present a user-friendly error from an `Error` with severity-based presentation.
    ///
    /// - `info`: Shows an info toast.
    /// - `warning`: Shows an alert with OK button.
    /// - `error`: Toast for transient errors, alert with retry for recoverable errors (default).
    /// - `critical`: Always shows an alert, retry button if `retryAction` is provided.
    public static func present(
        on viewController: UIViewController,
        error: Error,
        severity: Severity = .error,
        retryAction: (() -> Void)? = nil
    ) {
        let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        LMKLogger.error("Presenting \(severity) to user: \(message)", error: error, category: .error)
        present(on: viewController, message: message, severity: severity, retryAction: retryAction)
    }

    /// Present a message with severity-based presentation.
    ///
    /// - `info`: Shows an info toast.
    /// - `warning`: Shows an alert with OK button.
    /// - `error`: Toast for transient errors, alert with retry for recoverable errors (default).
    /// - `critical`: Always shows an alert, retry button if `retryAction` is provided.
    public static func present(
        on viewController: UIViewController,
        title: String? = nil,
        message: String,
        severity: Severity = .error,
        retryAction: (() -> Void)? = nil
    ) {
        switch severity {
        case .info:
            LMKToast.showInfo(message: message, on: viewController)

        case .warning:
            LMKLogger.warning("Showing warning: \(message)", category: .ui)
            let alert = UIAlertController(title: title ?? strings.warningTitle, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: strings.ok, style: .default))
            viewController.present(alert, animated: true)

        case .error:
            if let retryAction {
                LMKLogger.error("Showing error alert with retry: \(message)", category: .error)
                let alert = UIAlertController(title: title ?? strings.errorTitle, message: message, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: strings.retry, style: .default) { _ in retryAction() })
                alert.addAction(UIAlertAction(title: strings.ok, style: .cancel))
                viewController.present(alert, animated: true)
            } else {
                LMKLogger.error("Showing error toast: \(message)", category: .error)
                LMKToast.showError(message: message, on: viewController)
            }

        case .critical:
            LMKLogger.error("Showing critical alert: \(message)", category: .error)
            let alert = UIAlertController(
                title: title ?? strings.errorTitle,
                message: message,
                preferredStyle: .alert
            )
            if let retryAction {
                alert.addAction(UIAlertAction(title: strings.retry, style: .default) { _ in retryAction() })
            }
            alert.addAction(UIAlertAction(title: strings.ok, style: .cancel))
            viewController.present(alert, animated: true)
        }
    }
}
