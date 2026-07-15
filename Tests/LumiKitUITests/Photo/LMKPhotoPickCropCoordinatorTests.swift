//
//  LMKPhotoPickCropCoordinatorTests.swift
//  LumiKit
//

import PhotosUI
import Testing
import UIKit
@testable import LumiKitUI

// MARK: - LMKPhotoPickCropCoordinator

@MainActor
struct LMKPhotoPickCropCoordinatorTests {
    // MARK: - Helpers

    private func makeImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 10, height: 10))
        return renderer.image { context in
            UIColor.systemOrange.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 10, height: 10))
        }
    }

    // MARK: - Crop hand-off

    @Test
    func `Successful save reports the identifier`() {
        let host = UIViewController()
        var savedImage: UIImage?
        var reportedIdentifier: String?
        var failed = false
        let coordinator = LMKPhotoPickCropCoordinator(
            host: host,
            save: { image in
                savedImage = image
                return "stored-id"
            },
            onSaved: { reportedIdentifier = $0 },
            onFailure: { failed = true }
        )

        let image = makeImage()
        coordinator.photoCropViewController(LMKPhotoCropViewController(image: image), didCropImage: image)

        #expect(savedImage === image)
        #expect(reportedIdentifier == "stored-id")
        #expect(!failed)
    }

    @Test
    func `Failed save reports onFailure without an identifier`() {
        let host = UIViewController()
        var reportedIdentifier: String?
        var failed = false
        let coordinator = LMKPhotoPickCropCoordinator(
            host: host,
            save: { _ in nil },
            onSaved: { reportedIdentifier = $0 },
            onFailure: { failed = true }
        )

        let image = makeImage()
        coordinator.photoCropViewController(LMKPhotoCropViewController(image: image), didCropImage: image)

        #expect(reportedIdentifier == nil)
        #expect(failed)
    }

    @Test
    func `Cancelled crop saves nothing`() {
        let host = UIViewController()
        var saveCalled = false
        var failed = false
        let coordinator = LMKPhotoPickCropCoordinator(
            host: host,
            save: { _ in
                saveCalled = true
                return nil
            },
            onSaved: { _ in },
            onFailure: { failed = true }
        )

        coordinator.photoCropViewControllerDidCancel(LMKPhotoCropViewController(image: makeImage()))

        #expect(!saveCalled)
        #expect(!failed)
    }

    // MARK: - Picker hand-off

    @Test
    func `Empty picker results save nothing`() {
        let host = UIViewController()
        var saveCalled = false
        let coordinator = LMKPhotoPickCropCoordinator(
            host: host,
            save: { _ in
                saveCalled = true
                return nil
            },
            onSaved: { _ in }
        )

        let picker = PHPickerViewController(configuration: PHPickerConfiguration())
        coordinator.picker(picker, didFinishPicking: [])

        #expect(!saveCalled)
    }

    // MARK: - Lifecycle

    // PHPicker is a remote system view controller whose presentation never commits
    // in a non-hosted test bundle, so `start()` cannot be asserted here; the crop
    // and picker delegate paths above cover the coordinator's own behavior.

    @Test
    func `Coordinator does not retain its host`() {
        var host: UIViewController? = UIViewController()
        weak var weakHost = host
        let coordinator = host.map { LMKPhotoPickCropCoordinator(host: $0, save: { _ in nil }, onSaved: { _ in }) }

        host = nil

        #expect(weakHost == nil)
        #expect(coordinator != nil)
    }
}
