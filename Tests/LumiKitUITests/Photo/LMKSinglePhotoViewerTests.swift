//
//  LMKSinglePhotoViewerTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

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

    @Test
    func `Serves exactly one photo`() {
        let image = makeImage()
        let viewer = LMKSinglePhotoViewer(image: image)
        #expect(viewer.numberOfPhotos == 1)
        #expect(viewer.photo(at: 0) === image)
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
    func `Presents a full-screen photo browser`() {
        let host = UIViewController()
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 375, height: 812))
        window.rootViewController = host
        window.makeKeyAndVisible()

        let viewer = LMKSinglePhotoViewer(image: makeImage())
        viewer.present(from: host)

        let browser = host.presentedViewController as? LMKPhotoBrowserViewController
        #expect(browser != nil)
        #expect(browser?.modalPresentationStyle == .fullScreen)
    }
}
