//
//  LMKErrorHandlerTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

private struct SuggestingError: LocalizedError {
    var errorDescription: String? { "Sync failed" }
    var recoverySuggestion: String? { "Check your connection." }
}

private struct PlainError: LocalizedError {
    var errorDescription: String? { "Plain" }
}

@MainActor
struct LMKErrorHandlerTests {
    private func makeHost() -> (UIViewController, UIWindow) {
        let host = UIViewController()
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 375, height: 812))
        window.rootViewController = host
        window.makeKeyAndVisible()
        return (host, window)
    }

    @Test
    func `Strings default to English and can be overridden`() {
        let strings = LMKErrorHandler.Strings()
        #expect(strings.errorTitle == "Error")
        #expect(strings.retry == "Retry")
        #expect(strings.ok == "OK")
        #expect(strings.warningTitle == "Warning")
        #expect(strings.infoTitle == "Info")
        let custom = LMKErrorHandler.Strings(errorTitle: "Oops", retry: "Again", ok: "Done")
        #expect(custom.errorTitle == "Oops")
        #expect(custom.retry == "Again")
        #expect(LMKErrorHandler.Severity.allCases.count == 4)
    }

    @Test
    func `The default policy routes severities and the message appends the recovery suggestion`() {
        let policy = LMKErrorHandler.Policy.default
        if case .toast = policy.resolve(.info, false) {} else { Issue.record("info should toast") }
        if case let .alert(showsRetry) = policy.resolve(.warning, true) { #expect(!showsRetry) } else { Issue.record("warning should alert") }
        if case .toast = policy.resolve(.error, false) {} else { Issue.record("error without retry should toast") }
        if case let .alert(showsRetry) = policy.resolve(.error, true) { #expect(showsRetry) } else { Issue.record("error with retry should alert") }
        if case let .alert(showsRetry) = policy.resolve(.critical, false) { #expect(!showsRetry) } else { Issue.record("critical should alert") }

        #expect(LMKErrorHandler.message(for: SuggestingError()) == "Sync failed\n\nCheck your connection.")
        #expect(LMKErrorHandler.message(for: PlainError()) == "Plain")
    }

    @Test
    func `Alerts carry the severity title and a retry button when offered`() {
        let (host, window) = makeHost()
        defer { window.isHidden = true }
        LMKErrorHandler.present(from: host, message: "Careful", severity: .warning)
        let warning = host.presentedViewController as? UIAlertController
        #expect(warning?.title == "Warning")
        #expect(warning?.actions.map(\.title) == ["OK"])

        let other = UIViewController()
        window.rootViewController = other
        var retried = 0
        LMKErrorHandler.present(from: other, error: SuggestingError(), severity: .critical, retryAction: { retried += 1 })
        let critical = other.presentedViewController as? UIAlertController
        #expect(critical?.title == "Error")
        #expect(critical?.message == "Sync failed\n\nCheck your connection.")
        #expect(critical?.actions.map(\.title) == ["Retry", "OK"])
        #expect(retried == 0)

        let third = UIViewController()
        window.rootViewController = third
        LMKErrorHandler.present(from: third, message: "Transient", severity: .error)
        #expect(third.presentedViewController == nil, "an error without retry is a toast")
        LMKToast.dismissAll(in: third)
    }

    @Test
    func `A custom policy receives the context and logging can be turned off`() {
        let (host, window) = makeHost()
        defer { window.isHidden = true }
        let original = LMKErrorHandler.policy
        let originalLogs = LMKErrorHandler.logsErrors
        defer {
            LMKErrorHandler.policy = original
            LMKErrorHandler.logsErrors = originalLogs
        }
        var contexts: [LMKErrorHandler.Context] = []
        LMKErrorHandler.policy = LMKErrorHandler.Policy { _, _ in .custom { contexts.append($0) } }
        LMKErrorHandler.logsErrors = false
        var retried = 0
        LMKErrorHandler.present(from: host, title: "Custom", message: "Body", severity: .critical, retryAction: { retried += 1 })
        #expect(contexts.count == 1)
        #expect(contexts.first?.title == "Custom")
        #expect(contexts.first?.message == "Body")
        #expect(contexts.first?.severity == .critical)
        #expect(contexts.first?.host === host)
        contexts.first?.retryAction?()
        #expect(retried == 1)
        #expect(host.presentedViewController == nil)
    }

    @Test
    func `The async form resolves false for toasts and for a custom presentation that drops the context`() async {
        let (host, window) = makeHost()
        defer { window.isHidden = true }
        let retried = await LMKErrorHandler.confirmRetry(from: host, message: "Note", severity: .info)
        #expect(!retried)
        LMKToast.dismissAll(in: host)

        let original = LMKErrorHandler.policy
        defer { LMKErrorHandler.policy = original }
        LMKErrorHandler.policy = LMKErrorHandler.Policy { _, _ in .custom { _ in } }
        let dropped = await LMKErrorHandler.confirmRetry(from: host, message: "Custom", severity: .critical)
        #expect(!dropped)
    }

    @Test
    func `A custom presentation reports a retry by running the context's retryAction`() async {
        let (host, window) = makeHost()
        defer { window.isHidden = true }
        let original = LMKErrorHandler.policy
        defer { LMKErrorHandler.policy = original }
        LMKErrorHandler.policy = LMKErrorHandler.Policy { _, _ in
            .custom { context in context.retryAction?() }
        }
        let retried = await LMKErrorHandler.confirmRetry(from: host, message: "Sync failed", severity: .error)
        #expect(retried)
    }

    @Test
    func `The async alert resolves false when the host cannot present`() async {
        let (host, window) = makeHost()
        defer { window.isHidden = true }
        LMKAlert.present(from: host, title: "Busy")
        let retried = await LMKErrorHandler.confirmRetry(from: host, message: "Sync failed", severity: .critical)
        #expect(!retried)
        #expect((host.presentedViewController as? UIAlertController)?.title == "Busy")
    }
}
