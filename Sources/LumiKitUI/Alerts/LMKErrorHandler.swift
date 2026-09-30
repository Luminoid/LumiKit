//
//  LMKErrorHandler.swift
//  LumiKit
//
//  User-facing errors with a severity-to-presentation policy: toast, alert
//  (with an optional retry), or a host-provided presentation.
//

import LumiKitCore
import UIKit

/// Presents user-friendly errors by severity.
///
/// ```swift
/// LMKErrorHandler.present(from: self, error: error)                     // toast, or alert when retry is offered
/// LMKErrorHandler.present(from: self, error: error, severity: .critical, retryAction: reload)
/// if await LMKErrorHandler.confirmRetry(from: self, message: "Sync failed", severity: .error) { retry() }
/// ```
///
/// `policy` decides how each severity presents; replace it to route through the app's own
/// surfaces. `LocalizedError.recoverySuggestion` is appended to the message when present.
public enum LMKErrorHandler {
    // MARK: - Vocabulary

    /// Severity picks the presentation through `policy`.
    public nonisolated enum Severity: Sendable, Hashable, CaseIterable {
        /// A passing note.
        case info
        /// Needs attention, not action.
        case warning
        /// Something failed; retry when one is offered.
        case error
        /// Always an alert, retry when offered.
        case critical
    }

    /// What the error is shown as.
    public enum Presentation {
        case toast
        /// An alert; `showsRetry` adds the retry button when a retry is available.
        case alert(showsRetry: Bool)
        /// A host-provided presentation.
        case custom((Context) -> Void)
    }

    /// Everything a custom presentation gets.
    public struct Context {
        public let host: UIViewController
        public let title: String
        public let message: String
        public let severity: Severity
        /// Runs a retry, when the caller offered one.
        public let retryAction: (() -> Void)?
    }

    /// Maps a severity (and whether a retry is available) to a presentation.
    public struct Policy {
        public var resolve: (Severity, _ hasRetry: Bool) -> Presentation

        public init(resolve: @escaping (Severity, _ hasRetry: Bool) -> Presentation) {
            self.resolve = resolve
        }

        /// info: toast; warning: alert; error: alert with retry when offered, else toast; critical: alert.
        public static let `default` = Self { severity, hasRetry in
            switch severity {
            case .info: .toast
            case .warning: .alert(showsRetry: false)
            case .error: hasRetry ? .alert(showsRetry: true) : .toast
            case .critical: .alert(showsRetry: hasRetry)
            }
        }
    }

    // MARK: - Configuration

    /// The active policy; replace it at launch to change how severities present.
    public static var policy = Policy.default

    /// Whether presentations are logged through `LMKLogger`. Default `true`.
    public static var logsErrors = true

    // MARK: - Strings

    public nonisolated struct Strings: Sendable, Equatable {
        public var errorTitle: String
        public var retry: String
        public var ok: String
        public var warningTitle: String
        public var infoTitle: String

        public init(
            errorTitle: String = LMKLocalized("errorHandler.errorTitle"),
            retry: String = LMKLocalized("errorHandler.retry"),
            ok: String = LMKLocalized("errorHandler.ok"),
            warningTitle: String = LMKLocalized("errorHandler.warningTitle"),
            infoTitle: String = LMKLocalized("errorHandler.infoTitle")
        ) {
            self.errorTitle = errorTitle
            self.retry = retry
            self.ok = ok
            self.warningTitle = warningTitle
            self.infoTitle = infoTitle
        }
    }

    /// Process-wide defaults; set at app launch to override.
    public nonisolated(unsafe) static var strings = Strings()

    // MARK: - Presentation

    /// Presents `error` (its description plus any recovery suggestion) by severity.
    public static func present(from host: UIViewController, error: Error, severity: Severity = .error, retryAction: (() -> Void)? = nil) {
        let message = message(for: error)
        if logsErrors {
            LMKLogger.error("Presenting \(severity) to user: \(message)", error: error, category: .error)
        }
        present(from: host, message: message, severity: severity, retryAction: retryAction)
    }

    /// Presents `message` by severity.
    public static func present(from host: UIViewController, title: String? = nil, message: String, severity: Severity = .error, retryAction: (() -> Void)? = nil) {
        show(from: host, title: title, message: message, severity: severity, retryAction: retryAction, onRetryChosen: nil)
    }

    /// Presents `message` by severity and waits for the user; `true` when a retry was chosen.
    /// Retry is offered when the policy presents an alert with retry. Named apart from
    /// `present` so the async overload never shadows it inside async code.
    @discardableResult
    public static func confirmRetry(from host: UIViewController, title: String? = nil, message: String, severity: Severity = .error) async -> Bool {
        await withCheckedContinuation { continuation in
            show(from: host, title: title, message: message, severity: severity, retryAction: {}, onRetryChosen: { chosen in
                continuation.resume(returning: chosen)
            })
        }
    }

    /// The message for `error`: the localized description, plus the recovery suggestion when there is one.
    public static func message(for error: Error) -> String {
        let localized = error as? LocalizedError
        let description = localized?.errorDescription ?? error.localizedDescription
        if let suggestion = localized?.recoverySuggestion, !suggestion.isEmpty {
            return description + "\n\n" + suggestion
        }
        return description
    }

    // MARK: - Internals

    private static func show(
        from host: UIViewController,
        title: String?,
        message: String,
        severity: Severity,
        retryAction: (() -> Void)?,
        onRetryChosen: ((Bool) -> Void)?
    ) {
        let hasRetry = retryAction != nil
        let presentation = policy.resolve(severity, hasRetry)
        let resolvedTitle = title ?? defaultTitle(for: severity)
        if logsErrors {
            log(severity: severity, message: message)
        }
        switch presentation {
        case .toast:
            LMKToast.show(status(for: severity), message, in: host)
            onRetryChosen?(false)
        case let .alert(showsRetry):
            let alert = UIAlertController(title: resolvedTitle, message: message, preferredStyle: .alert)
            if showsRetry, let retryAction {
                alert.addAction(UIAlertAction(title: strings.retry, style: .default) { _ in
                    retryAction()
                    onRetryChosen?(true)
                })
                alert.addAction(UIAlertAction(title: strings.ok, style: .cancel) { _ in onRetryChosen?(false) })
            } else {
                alert.addAction(UIAlertAction(title: strings.ok, style: .default) { _ in onRetryChosen?(false) })
            }
            host.present(alert, animated: true)
        case let .custom(handler):
            handler(Context(host: host, title: resolvedTitle, message: message, severity: severity, retryAction: retryAction))
            onRetryChosen?(false)
        }
    }

    private static func defaultTitle(for severity: Severity) -> String {
        switch severity {
        case .info: strings.infoTitle
        case .warning: strings.warningTitle
        case .error, .critical: strings.errorTitle
        }
    }

    private static func status(for severity: Severity) -> LMKStatus {
        switch severity {
        case .info: .info
        case .warning: .warning
        case .error, .critical: .error
        }
    }

    private static func log(severity: Severity, message: String) {
        switch severity {
        case .info: LMKLogger.info("Showing info: \(message)", category: .ui)
        case .warning: LMKLogger.warning("Showing warning: \(message)", category: .ui)
        case .error, .critical: LMKLogger.error("Showing \(severity): \(message)", category: .error)
        }
    }
}
