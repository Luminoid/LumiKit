//
//  LMKShareServiceTests.swift
//  LumiKit
//

import Testing
import UIKit

@testable import LumiKitUI

@Suite("LMKShareService")
@MainActor
struct LMKShareServiceTests {
    @Test("shareImage calls present on view controller")
    func shareImagePresents() {
        let presentingVC = PresentationTrackingViewController()
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 375, height: 812))
        window.rootViewController = presentingVC
        window.makeKeyAndVisible()
        presentingVC.loadViewIfNeeded()

        let image = UIImage.lmk_solidColor(.red, size: CGSize(width: 10, height: 10))
        LMKShareService.shareImage(image, from: presentingVC)

        #expect(presentingVC.lastPresentedViewController is UIActivityViewController)
    }

    @Test("shareFile calls present on view controller")
    func shareFilePresents() {
        let presentingVC = PresentationTrackingViewController()
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 375, height: 812))
        window.rootViewController = presentingVC
        window.makeKeyAndVisible()
        presentingVC.loadViewIfNeeded()

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test_share_\(UUID().uuidString).txt")
        try? "test".write(to: tempURL, atomically: true, encoding: .utf8)

        LMKShareService.shareFile(at: tempURL, from: presentingVC)

        #expect(presentingVC.lastPresentedViewController is UIActivityViewController)
    }

    @Test("shareImage with barButtonItem configures popover")
    func shareImageWithBarButtonItem() {
        let presentingVC = PresentationTrackingViewController()
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 375, height: 812))
        window.rootViewController = presentingVC
        window.makeKeyAndVisible()
        presentingVC.loadViewIfNeeded()

        let barButton = UIBarButtonItem(systemItem: .action)
        let image = UIImage.lmk_solidColor(.red, size: CGSize(width: 10, height: 10))
        LMKShareService.shareImage(image, from: presentingVC, sourceBarButtonItem: barButton)

        let activityVC = presentingVC.lastPresentedViewController as? UIActivityViewController
        #expect(activityVC != nil)
        #expect(activityVC?.popoverPresentationController?.barButtonItem === barButton)
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
