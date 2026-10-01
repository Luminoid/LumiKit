//
//  LMKShareTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

@MainActor
struct LMKShareTests {
    @Test
    func `shareImage calls present on view controller`() {
        let presentingVC = PresentationTrackingViewController()
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 375, height: 812))
        window.rootViewController = presentingVC
        window.makeKeyAndVisible()
        presentingVC.loadViewIfNeeded()

        let image = UIImage.lmk_solidColor(.red, size: CGSize(width: 10, height: 10))
        LMKShare.image(image, from: presentingVC)

        #expect(presentingVC.lastPresentedViewController is UIActivityViewController)
    }

    @Test
    func `shareFile calls present on view controller`() {
        let presentingVC = PresentationTrackingViewController()
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 375, height: 812))
        window.rootViewController = presentingVC
        window.makeKeyAndVisible()
        presentingVC.loadViewIfNeeded()

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test_share_\(UUID().uuidString).txt")
        try? "test".write(to: tempURL, atomically: true, encoding: .utf8)

        LMKShare.file(at: tempURL, from: presentingVC)

        #expect(presentingVC.lastPresentedViewController is UIActivityViewController)
    }

    @Test
    func `shareImage with barButtonItem configures popover`() {
        let presentingVC = PresentationTrackingViewController()
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 375, height: 812))
        window.rootViewController = presentingVC
        window.makeKeyAndVisible()
        presentingVC.loadViewIfNeeded()

        let barButton = UIBarButtonItem(systemItem: .action)
        let image = UIImage.lmk_solidColor(.red, size: CGSize(width: 10, height: 10))
        LMKShare.image(image, from: presentingVC, sourceBarButtonItem: barButton)

        let activityVC = presentingVC.lastPresentedViewController as? UIActivityViewController
        #expect(activityVC != nil)
        #expect(activityVC?.popoverPresentationController?.barButtonItem === barButton)
    }
}

// MARK: - Items

@MainActor
struct LMKShareItemsTests {
    private func makeHost() -> PresentationTrackingViewController {
        let host = PresentationTrackingViewController()
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 375, height: 812))
        window.rootViewController = host
        window.makeKeyAndVisible()
        host.loadViewIfNeeded()
        return host
    }

    @Test
    func `Text and url conveniences present an activity controller`() throws {
        let host = makeHost()
        LMKShare.text("Hello", from: host)
        #expect(host.lastPresentedViewController is UIActivityViewController)

        try LMKShare.url(#require(URL(string: "https://example.com")), from: host)
        #expect(host.lastPresentedViewController is UIActivityViewController)
    }

    @Test
    func `Present returns the controller and anchors the popover to a view`() throws {
        let host = makeHost()
        let anchorView = UIView(frame: CGRect(x: 10, y: 20, width: 30, height: 40))
        host.view.addSubview(anchorView)

        let controller = try LMKShare.present([.text("a"), .url(#require(URL(string: "https://example.com")))], from: host, anchor: .view(anchorView))

        #expect(controller === host.lastPresentedViewController)
        #expect(controller?.popoverPresentationController?.sourceView === anchorView)
    }

    @Test
    func `Centered anchor uses the host view without an arrow`() {
        let host = makeHost()
        let controller = LMKShare.present([.text("a")], from: host)
        let popover = controller?.popoverPresentationController
        #expect(popover?.sourceRect == host.lmk_centeredPopoverSourceRect)
        #expect(popover?.permittedArrowDirections == [])
        #expect(popover?.barButtonItem == nil)
    }

    @Test
    func `A missing file fails without presenting`() {
        let host = makeHost()
        let missing = FileManager.default.temporaryDirectory.appendingPathComponent("missing_\(UUID().uuidString).txt")
        var result: LMKShareResult?

        let controller = LMKShare.present([.file(missing)], from: host) { result = $0 }

        #expect(controller == nil)
        #expect(host.lastPresentedViewController == nil)
        if case .failed = result {} else { Issue.record("expected .failed, got \(String(describing: result))") }
    }

    @Test
    func `Existing files present and keep the file until the sheet finishes`() throws {
        let host = makeHost()
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("share_\(UUID().uuidString).txt")
        try "x".write(to: url, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: url) }

        LMKShare.file(at: url, from: host)

        #expect(host.lastPresentedViewController is UIActivityViewController)
        #expect(FileManager.default.fileExists(atPath: url.path))
    }

    @Test
    func `A shared file is kept by default and removed only when asked`() throws {
        let host = makeHost()
        let kept = FileManager.default.temporaryDirectory.appendingPathComponent("share_kept_\(UUID().uuidString).txt")
        try "x".write(to: kept, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: kept) }
        var results: [LMKShareResult] = []

        LMKShare.file(at: kept, from: host) { results.append($0) }
        let keeping = try #require(host.lastPresentedViewController as? UIActivityViewController)
        keeping.completionWithItemsHandler?(nil, false, nil, nil)
        #expect(FileManager.default.fileExists(atPath: kept.path))
        if case .cancelled = results.last {} else { Issue.record("expected .cancelled") }

        let temporary = FileManager.default.temporaryDirectory.appendingPathComponent("share_temp_\(UUID().uuidString).txt")
        try "x".write(to: temporary, atomically: true, encoding: .utf8)
        LMKShare.file(at: temporary, from: host, deletesAfterShare: true) { results.append($0) }
        let deleting = try #require(host.lastPresentedViewController as? UIActivityViewController)
        deleting.completionWithItemsHandler?(.copyToPasteboard, true, nil, nil)
        #expect(!FileManager.default.fileExists(atPath: temporary.path))
        if case .completed(.copyToPasteboard) = results.last {} else { Issue.record("expected .completed") }
    }
}

// MARK: - Test Helper

/// Tracks calls to `present(_:animated:completion:)` synchronously.
private final class PresentationTrackingViewController: UIViewController {
    var lastPresentedViewController: UIViewController?

    override func present(
        _ viewControllerToPresent: UIViewController,
        animated flag: Bool,
        completion: (() -> Void)? = nil
    ) {
        lastPresentedViewController = viewControllerToPresent
        // Don't call super — avoids async presentation in tests
    }
}
