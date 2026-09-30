//
//  LMKPhotoPickCropCoordinatorTests.swift
//  LumiKit
//

import LumiKitUI
import PhotosUI
import Testing
import UIKit
@testable import LumiKitPhoto

// MARK: - LMKPhotoPickCropCoordinator

@MainActor
struct LMKPhotoPickCropCoordinatorTests {
    // MARK: - Helpers

    private func makeImage() -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 10, height: 10), format: format)
        return renderer.image { context in
            UIColor.systemOrange.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 10, height: 10))
        }
    }

    private func makeJPEGData() throws -> Data {
        try #require(makeImage().jpegData(compressionQuality: 0.9))
    }

    // MARK: - Crop hand-off

    @Test
    func `Successful save reports the identifier`() async {
        let host = UIViewController()
        var savedImage: UIImage?
        var reportedIdentifier: String?
        var failed = false
        let coordinator = LMKPhotoPickCropCoordinator(
            host: host,
            save: { image, _ in
                savedImage = image
                return "stored-id"
            },
            onSaved: { reportedIdentifier = $0 },
            onFailure: { _ in failed = true }
        )

        let image = makeImage()
        coordinator.handleCropped(image)
        await settleMainActor()

        #expect(savedImage === image)
        #expect(reportedIdentifier == "stored-id")
        #expect(!failed)
    }

    @Test
    func `Failed save reports onFailure without an identifier`() async {
        let host = UIViewController()
        var reportedIdentifier: String?
        var failure: LMKPhotoPickCropCoordinator.Failure?
        let coordinator = LMKPhotoPickCropCoordinator(
            host: host,
            save: { _, _ in nil },
            onSaved: { reportedIdentifier = $0 },
            onFailure: { failure = $0 }
        )

        coordinator.handleCropped(makeImage())
        await settleMainActor()

        #expect(reportedIdentifier == nil)
        if case .saveFailed = failure {} else {
            Issue.record("expected saveFailed, got \(String(describing: failure))")
        }
    }

    @Test
    func `Cancelled crop saves nothing and reports onCancel`() async {
        let host = UIViewController()
        var saveCalled = false
        var cancelled = false
        let coordinator = LMKPhotoPickCropCoordinator(
            host: host,
            save: { _, _ in
                saveCalled = true
                return nil
            },
            onSaved: { _ in },
            onCancel: { cancelled = true }
        )

        coordinator.handleCropCancelled()
        await settleMainActor()

        #expect(!saveCalled)
        #expect(cancelled)
    }

    // MARK: - Picked bytes

    @Test
    func `Picked bytes decode with their metadata and skip the crop when disabled`() async throws {
        let host = UIViewController()
        let data = try makeJPEGData()
        var pickedSize: CGSize?
        var pickedMetadata: LMKPhotoMetadata?
        var savedMetadata: LMKPhotoMetadata?
        var identifier: String?
        let coordinator = LMKPhotoPickCropCoordinator(
            host: host,
            croppingEnabled: false,
            save: { _, metadata in
                savedMetadata = metadata
                return "saved"
            },
            onSaved: { identifier = $0 },
            onPicked: { image, metadata in
                pickedSize = image.size
                pickedMetadata = metadata
            }
        )

        coordinator.handlePicked(data: data)
        await settleMainActor(iterations: 200)

        #expect(pickedSize == CGSize(width: 10, height: 10))
        #expect(pickedMetadata?.pixelSize == CGSize(width: 10, height: 10))
        #expect(savedMetadata == pickedMetadata)
        #expect(identifier == "saved")
    }

    @Test
    func `A maximum pixel size downsamples the pick`() async throws {
        let host = UIViewController()
        let large = UIImage.lmk_solidColor(.blue, size: CGSize(width: 400, height: 200))
        let data = try #require(large.jpegData(compressionQuality: 0.8))
        var pickedSize: CGSize?
        let coordinator = LMKPhotoPickCropCoordinator(
            host: host,
            croppingEnabled: false,
            maximumPixelSize: 100,
            save: { _, _ in "saved" },
            onSaved: { _ in },
            onPicked: { image, _ in pickedSize = image.size }
        )

        coordinator.handlePicked(data: data)
        await settleMainActor(iterations: 200)

        #expect(pickedSize?.width == 100)
        #expect(pickedSize?.height == 50)
    }

    @Test
    func `Undecodable bytes report decodeFailed`() async {
        let host = UIViewController()
        var failure: LMKPhotoPickCropCoordinator.Failure?
        let coordinator = LMKPhotoPickCropCoordinator(
            host: host,
            croppingEnabled: false,
            save: { _, _ in "saved" },
            onSaved: { _ in },
            onFailure: { failure = $0 }
        )

        coordinator.handlePicked(data: Data("not an image".utf8))
        await settleMainActor(iterations: 200)

        if case .decodeFailed = failure {} else {
            Issue.record("expected decodeFailed, got \(String(describing: failure))")
        }
    }

    @Test
    func `Empty picker results report onCancel and save nothing`() {
        let host = UIViewController()
        var saveCalled = false
        var cancelled = false
        let coordinator = LMKPhotoPickCropCoordinator(
            host: host,
            save: { _, _ in
                saveCalled = true
                return nil
            },
            onSaved: { _ in },
            onCancel: { cancelled = true }
        )

        let picker = PHPickerViewController(configuration: PHPickerConfiguration())
        coordinator.picker(picker, didFinishPicking: [])

        #expect(!saveCalled)
        #expect(cancelled)
    }

    // MARK: - Lifecycle

    // PHPicker is a remote system view controller whose presentation never commits in a
    // non-hosted test bundle, so `start()` cannot be asserted here.

    @Test
    func `Coordinator does not retain its host`() {
        var host: UIViewController? = UIViewController()
        weak let weakHost = host
        let coordinator = host.map { LMKPhotoPickCropCoordinator(host: $0, save: { _, _ in nil }, onSaved: { _ in }) }

        host = nil

        #expect(weakHost == nil)
        #expect(coordinator != nil)
    }

    @Test
    func `cancel drops an in-flight save`() async {
        let host = UIViewController()
        let gate = AsyncGate()
        var saved = false
        let coordinator = LMKPhotoPickCropCoordinator(
            host: host,
            save: { _, _ in
                await gate.wait()
                return "late"
            },
            onSaved: { _ in saved = true }
        )

        coordinator.handleCropped(makeImage())
        coordinator.cancel()
        gate.open()
        await settleMainActor()

        #expect(!saved)
    }
}
