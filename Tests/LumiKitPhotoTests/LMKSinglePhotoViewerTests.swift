//
//  LMKSinglePhotoViewerTests.swift
//  LumiKit
//

import LumiKitUI
import Testing
import UIKit
@testable import LumiKitPhoto

// MARK: - LMKSinglePhotoViewer

@MainActor
struct LMKSinglePhotoViewerTests {
    private func makeImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 10, height: 10))
        return renderer.image { context in
            UIColor.systemTeal.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 10, height: 10))
        }
    }

    private func makeHost() -> UIViewController {
        let host = UIViewController()
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 375, height: 812))
        window.rootViewController = host
        window.makeKeyAndVisible()
        return host
    }

    @Test
    func `Serves exactly one photo`() async {
        let image = makeImage()
        let viewer = LMKSinglePhotoViewer(image: image)
        #expect(viewer.numberOfPhotos == 1)
        let photo = await viewer.photo(at: 0)
        #expect(photo === image)
        #expect(viewer.photoDate(at: 0) == nil)
    }

    @Test
    func `Subtitle is forwarded to the browser`() {
        let viewer = LMKSinglePhotoViewer(image: makeImage(), subtitle: "Cover photo")
        #expect(viewer.photoSubtitle(at: 0) == "Cover photo")

        let plain = LMKSinglePhotoViewer(image: makeImage())
        #expect(plain.photoSubtitle(at: 0) == nil)
    }

    @Test
    func `Action button callback fires onAction`() {
        var actioned = false
        let viewer = LMKSinglePhotoViewer(image: makeImage(), onAction: { actioned = true })

        viewer.photoBrowser(LMKPhotoBrowserViewController(), didRequestActionAt: 0)

        #expect(actioned)
    }

    @Test
    func `Presents a full-screen photo browser and exposes it while it is up`() {
        let host = makeHost()
        let viewer = LMKSinglePhotoViewer(image: makeImage())
        #expect(viewer.browser == nil)
        viewer.present(from: host)

        let browser = host.presentedViewController as? LMKPhotoBrowserViewController
        #expect(browser != nil)
        #expect(viewer.browser === browser, "onAction presents its UI from here")
        #expect(browser?.modalPresentationStyle == .overFullScreen)
    }

    @Test
    func `dismiss fires onDismiss once, clears the browser, and is idempotent`() {
        let host = makeHost()
        let viewer = LMKSinglePhotoViewer(image: makeImage())
        var dismissed = 0
        var completions = 0
        viewer.onDismiss = { dismissed += 1 }
        viewer.present(from: host)

        viewer.dismiss { completions += 1 }
        #expect(dismissed == 1)
        #expect(viewer.browser == nil)

        // The browser reporting its own dismissal afterwards adds nothing.
        viewer.photoBrowserDidDismiss(LMKPhotoBrowserViewController())
        #expect(dismissed == 2, "a browser the user closed still reports once")

        var again = 0
        viewer.dismiss { again += 1 }
        #expect(again == 1, "with no browser up only the completion runs")
        #expect(dismissed == 2)
    }

    @Test
    func `Browser strings default to the browser's process-wide strings`() {
        let original = LMKPhotoBrowserViewController.strings
        defer { LMKPhotoBrowserViewController.strings = original }
        LMKPhotoBrowserViewController.strings = LMKPhotoBrowserViewController.Strings(emptyText: "App Empty")
        let viewer = LMKSinglePhotoViewer(image: makeImage())
        #expect(viewer.browserStrings.emptyText == "App Empty")
    }

    @Test
    func `The action button follows onAction`() {
        let host = makeHost()
        let hidden = LMKSinglePhotoViewer(image: makeImage())
        hidden.present(from: host)
        #expect((host.presentedViewController as? LMKPhotoBrowserViewController)?.showsActionButton == false)

        let host2 = makeHost()
        let shown = LMKSinglePhotoViewer(image: makeImage(), actionIconSystemName: "trash", onAction: {})
        shown.present(from: host2)
        let browser = host2.presentedViewController as? LMKPhotoBrowserViewController
        #expect(browser?.showsActionButton == true)
        #expect(browser?.actionButtonSystemImageName == "trash")
    }

    @Test
    func `Style, strings, and the zoom source are forwarded`() {
        let host = makeHost()
        let viewer = LMKSinglePhotoViewer(image: makeImage())
        viewer.browserStyle = LMKPhotoBrowserViewController.Style(chromeTint: .red)
        viewer.browserStrings = LMKPhotoBrowserViewController.Strings(emptyText: "Nada")
        let thumbnail = UIView()
        viewer.zoomSourceView = { thumbnail }
        viewer.present(from: host)

        let browser = host.presentedViewController as? LMKPhotoBrowserViewController
        #expect(browser?.style.chromeTint == .red)
        #expect(browser?.strings.emptyText == "Nada")
        #expect(browser?.transitioningDelegate === browser)
        #expect(browser?.zoomSourceView?(0) === thumbnail)
    }

    @Test
    func `Dismissal fires onDismiss`() {
        var dismissed = false
        let viewer = LMKSinglePhotoViewer(image: makeImage())
        viewer.onDismiss = { dismissed = true }

        viewer.photoBrowserDidDismiss(LMKPhotoBrowserViewController())

        #expect(dismissed)
    }
}
