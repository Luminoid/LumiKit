//
//  LMKPhotoCropViewControllerTests.swift
//  LumiKit
//

import Testing
import UIKit

@testable import LumiKitUI

@Suite("LMKPhotoCropViewController")
@MainActor
struct LMKPhotoCropViewControllerTests {
    // MARK: - Initialization

    @Test("Initializes with image")
    func initializesWithImage() {
        let image = UIImage.lmk_solidColor(.blue, size: CGSize(width: 200, height: 200))
        let cropVC = LMKPhotoCropViewController(image: image)

        #expect(cropVC.isViewLoaded == false)
        #expect(cropVC.image.size == image.size)
    }

    @Test("Initializes with image and delegate")
    func initializesWithImageAndDelegate() {
        let image = UIImage.lmk_solidColor(.red, size: CGSize(width: 100, height: 100))
        let delegate = MockCropDelegate()
        let cropVC = LMKPhotoCropViewController(image: image, delegate: delegate)

        #expect(cropVC.isViewLoaded == false)
    }

    @Test("Loads view without crashing")
    func loadsView() {
        let image = UIImage.lmk_solidColor(.green, size: CGSize(width: 150, height: 150))
        let cropVC = LMKPhotoCropViewController(image: image)

        cropVC.loadViewIfNeeded()

        #expect(cropVC.isViewLoaded)
    }

    // MARK: - Different Image Sizes

    @Test("Handles small image")
    func handlesSmallImage() {
        let image = UIImage.lmk_solidColor(.yellow, size: CGSize(width: 50, height: 50))
        let cropVC = LMKPhotoCropViewController(image: image)

        cropVC.loadViewIfNeeded()

        #expect(cropVC.isViewLoaded)
    }

    @Test("Handles large image")
    func handlesLargeImage() {
        let image = UIImage.lmk_solidColor(.purple, size: CGSize(width: 1000, height: 1000))
        let cropVC = LMKPhotoCropViewController(image: image)

        cropVC.loadViewIfNeeded()

        #expect(cropVC.isViewLoaded)
    }

    @Test("Handles portrait image")
    func handlesPortraitImage() {
        let image = UIImage.lmk_solidColor(.orange, size: CGSize(width: 100, height: 200))
        let cropVC = LMKPhotoCropViewController(image: image)

        cropVC.loadViewIfNeeded()

        #expect(cropVC.isViewLoaded)
    }

    @Test("Handles landscape image")
    func handlesLandscapeImage() {
        let image = UIImage.lmk_solidColor(.cyan, size: CGSize(width: 300, height: 200))
        let cropVC = LMKPhotoCropViewController(image: image)

        cropVC.loadViewIfNeeded()

        #expect(cropVC.isViewLoaded)
    }

    @Test("Handles square image")
    func handlesSquareImage() {
        let image = UIImage.lmk_solidColor(.magenta, size: CGSize(width: 200, height: 200))
        let cropVC = LMKPhotoCropViewController(image: image)

        cropVC.loadViewIfNeeded()

        #expect(cropVC.isViewLoaded)
    }

    // MARK: - Status Bar

    @Test("Preferred status bar style is light content")
    func statusBarStyleIsLightContent() {
        let image = UIImage.lmk_solidColor(.brown, size: CGSize(width: 100, height: 100))
        let cropVC = LMKPhotoCropViewController(image: image)

        let style: UIStatusBarStyle = .lightContent
        #expect(cropVC.preferredStatusBarStyle == style)
    }

    // MARK: - View Lifecycle

    @Test("View controller can appear")
    func canAppear() {
        let image = UIImage.lmk_solidColor(.gray, size: CGSize(width: 150, height: 150))
        let cropVC = LMKPhotoCropViewController(image: image)

        cropVC.loadViewIfNeeded()
        cropVC.viewWillAppear(false)
        cropVC.viewDidAppear(false)

        #expect(cropVC.isViewLoaded)
    }
}

// MARK: - Mock Delegate

private class MockCropDelegate: LMKPhotoCropDelegate {
    var didCropCalled = false
    var didCancelCalled = false

    func photoCropViewController(_ controller: LMKPhotoCropViewController, didCropImage image: UIImage) {
        didCropCalled = true
    }

    func photoCropViewControllerDidCancel(_ controller: LMKPhotoCropViewController) {
        didCancelCalled = true
    }
}
