//
//  LMKPhotoCropViewControllerTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

@MainActor
struct LMKPhotoCropViewControllerTests {
    // MARK: - Initialization

    @Test
    func `Initializes with image`() {
        let image = UIImage.lmk_solidColor(.blue, size: CGSize(width: 200, height: 200))
        let cropVC = LMKPhotoCropViewController(image: image)

        #expect(cropVC.isViewLoaded == false)
        #expect(cropVC.image.size == image.size)
    }

    @Test
    func `Initializes with image and delegate`() {
        let image = UIImage.lmk_solidColor(.red, size: CGSize(width: 100, height: 100))
        let delegate = MockCropDelegate()
        let cropVC = LMKPhotoCropViewController(image: image, delegate: delegate)

        #expect(cropVC.isViewLoaded == false)
    }

    @Test
    func `Loads view without crashing`() {
        let image = UIImage.lmk_solidColor(.green, size: CGSize(width: 150, height: 150))
        let cropVC = LMKPhotoCropViewController(image: image)

        cropVC.loadViewIfNeeded()

        #expect(cropVC.isViewLoaded)
    }

    // MARK: - Different Image Sizes

    @Test
    func `Handles small image`() {
        let image = UIImage.lmk_solidColor(.yellow, size: CGSize(width: 50, height: 50))
        let cropVC = LMKPhotoCropViewController(image: image)

        cropVC.loadViewIfNeeded()

        #expect(cropVC.isViewLoaded)
    }

    @Test
    func `Handles large image`() {
        let image = UIImage.lmk_solidColor(.purple, size: CGSize(width: 1000, height: 1000))
        let cropVC = LMKPhotoCropViewController(image: image)

        cropVC.loadViewIfNeeded()

        #expect(cropVC.isViewLoaded)
    }

    @Test
    func `Handles portrait image`() {
        let image = UIImage.lmk_solidColor(.orange, size: CGSize(width: 100, height: 200))
        let cropVC = LMKPhotoCropViewController(image: image)

        cropVC.loadViewIfNeeded()

        #expect(cropVC.isViewLoaded)
    }

    @Test
    func `Handles landscape image`() {
        let image = UIImage.lmk_solidColor(.cyan, size: CGSize(width: 300, height: 200))
        let cropVC = LMKPhotoCropViewController(image: image)

        cropVC.loadViewIfNeeded()

        #expect(cropVC.isViewLoaded)
    }

    @Test
    func `Handles square image`() {
        let image = UIImage.lmk_solidColor(.magenta, size: CGSize(width: 200, height: 200))
        let cropVC = LMKPhotoCropViewController(image: image)

        cropVC.loadViewIfNeeded()

        #expect(cropVC.isViewLoaded)
    }

    // MARK: - Status Bar

    @Test
    func `Preferred status bar style is light content`() {
        let image = UIImage.lmk_solidColor(.brown, size: CGSize(width: 100, height: 100))
        let cropVC = LMKPhotoCropViewController(image: image)

        let style: UIStatusBarStyle = .lightContent
        #expect(cropVC.preferredStatusBarStyle == style)
    }

    // MARK: - View Lifecycle

    @Test
    func `View controller can appear`() {
        let image = UIImage.lmk_solidColor(.gray, size: CGSize(width: 150, height: 150))
        let cropVC = LMKPhotoCropViewController(image: image)

        cropVC.loadViewIfNeeded()
        cropVC.viewWillAppear(false)
        cropVC.viewDidAppear(false)

        #expect(cropVC.isViewLoaded)
    }
}

// MARK: - Mock Delegate

private final class MockCropDelegate: LMKPhotoCropDelegate {
    var didCropCalled = false
    var didCancelCalled = false

    func photoCropViewController(_ controller: LMKPhotoCropViewController, didCropImage image: UIImage) {
        didCropCalled = true
    }

    func photoCropViewControllerDidCancel(_ controller: LMKPhotoCropViewController) {
        didCancelCalled = true
    }
}
