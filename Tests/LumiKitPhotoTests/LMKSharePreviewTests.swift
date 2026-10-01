//
//  LMKSharePreviewTests.swift
//  LumiKit
//

import LumiKitUI
import Photos
import Testing
import UIKit
@testable import LumiKitPhoto

@MainActor
struct LMKSharePreviewTests {
    private func makeImage() -> UIImage {
        UIImage.lmk_solidColor(.blue, size: CGSize(width: 100, height: 200))
    }

    /// A sheet whose photo library is a fake: declared, authorized, and writing succeeds.
    private func makeSheet(status: PHAuthorizationStatus = .authorized, declared: Bool = true, write: @escaping (UIImage) async -> (Bool, (any Error)?) = { _ in
        (true, nil)
    }) -> LMKSharePreviewViewController {
        let vc = LMKSharePreviewViewController(image: makeImage())
        vc.hasPhotoLibraryAddUsageDescription = declared
        vc.photoLibraryAuthorizationStatus = { status }
        vc.requestPhotoLibraryAuthorization = { .authorized }
        vc.writeToPhotoLibrary = write
        vc.loadViewIfNeeded()
        return vc
    }

    @Test
    func `Init creates a page sheet with the large detent by default`() {
        let vc = LMKSharePreviewViewController(image: makeImage())

        #expect(vc.modalPresentationStyle == .pageSheet)
        #expect(vc.sheetPresentationController?.detents.count == 1)
        #expect(vc.sheetPresentationController?.prefersGrabberVisible == true)
    }

    @Test
    func `Detents are configurable and never empty`() {
        let vc = LMKSharePreviewViewController(image: makeImage(), detents: [.medium(), .large()])
        #expect(vc.sheetPresentationController?.detents.count == 2)

        let fallback = LMKSharePreviewViewController(image: makeImage(), detents: [])
        #expect(fallback.sheetPresentationController?.detents.count == 1)
    }

    @Test
    func `Default strings have expected values`() {
        let strings = LMKSharePreviewViewController.Strings()
        #expect(strings.share == "Share")
        #expect(strings.saveImage == "Save Image")
        #expect(!strings.photoPermissionDenied.isEmpty)
        #expect(!strings.closeAccessibilityLabel.isEmpty)
    }

    @Test
    func `Instance strings reach the buttons`() {
        let vc = LMKSharePreviewViewController(image: makeImage())
        vc.strings = .init(share: "Compartir", saveImage: "Guardar imagen", photoPermissionDenied: "Se requiere acceso a fotos")
        vc.loadViewIfNeeded()

        #expect(vc.shareButton.title == "Compartir")
        #expect(vc.saveButton.title == "Guardar imagen")
    }

    @Test
    func `viewDidLoad sets up the image and both buttons`() {
        let vc = makeSheet()

        #expect(!vc.view.subviews.isEmpty)
        #expect(vc.imageView.image != nil)
        #expect(vc.shareButton.isHidden == false)
        #expect(vc.saveButton.isHidden == false)
        #expect(vc.closeButton.isHidden == false)
        #expect(vc.dismissesAfterSave)
    }

    @Test
    func `Without the usage description the save button hides and a save is refused`() {
        let vc = makeSheet(declared: false)
        var failure: LMKSharePreviewViewController.Failure?
        vc.onFailure = { failure = $0 }
        #expect(vc.saveButton.isHidden, "a save without NSPhotoLibraryAddUsageDescription would abort the app")

        vc.saveToPhotoLibrary()
        if case .photoLibraryAccessDenied = failure {} else {
            Issue.record("expected photoLibraryAccessDenied, got \(String(describing: failure))")
        }
        #expect(!vc.isSaving)

        // A style that shows the button anyway is respected.
        vc.style = LMKSharePreviewViewController.Style(showsSaveButton: true)
        #expect(vc.saveButton.isHidden == false)
    }

    @Test
    func `A save writes once and reports onSave, and a second tap during it does nothing`() async {
        let gate = AsyncGate()
        var writes = 0
        let vc = makeSheet { _ in
            writes += 1
            await gate.wait()
            return (true, nil)
        }
        var saved = 0
        vc.onSave = { saved += 1 }
        vc.dismissesAfterSave = false

        vc.saveToPhotoLibrary()
        #expect(vc.isSaving)
        #expect(!vc.saveButton.isEnabled, "the button is disabled while the save is in flight")
        vc.saveToPhotoLibrary()
        gate.open()
        await LMKWait.until { saved == 1 }

        #expect(writes == 1, "a double tap must not write two copies")
        #expect(saved == 1)
        #expect(!vc.isSaving)
        #expect(vc.saveButton.isEnabled)
    }

    @Test
    func `A failed write reports onFailure with the error`() async {
        let vc = makeSheet { _ in (false, CocoaError(.fileWriteUnknown)) }
        var failure: LMKSharePreviewViewController.Failure?
        vc.onFailure = { failure = $0 }

        vc.saveToPhotoLibrary()
        await LMKWait.until { failure != nil }

        if case let .save(error) = failure {
            #expect((error as? CocoaError)?.code == .fileWriteUnknown)
            #expect(failure?.errorDescription == error.localizedDescription)
        } else {
            Issue.record("expected save, got \(String(describing: failure))")
        }
        #expect(!vc.isSaving)
    }

    @Test
    func `Denied access reports onFailure, and an undetermined status asks first`() async {
        let denied = makeSheet(status: .denied)
        var failure: LMKSharePreviewViewController.Failure?
        denied.onFailure = { failure = $0 }
        denied.saveToPhotoLibrary()
        await LMKWait.until { failure != nil }
        if case .photoLibraryAccessDenied = failure {} else {
            Issue.record("expected photoLibraryAccessDenied, got \(String(describing: failure))")
        }
        #expect(failure?.errorDescription == denied.strings.photoPermissionDenied)

        var writes = 0
        let asking = makeSheet(status: .notDetermined) { _ in
            writes += 1
            return (true, nil)
        }
        var asked = false
        asking.requestPhotoLibraryAuthorization = {
            asked = true
            return .limited
        }
        var saved = false
        asking.onSave = { saved = true }
        asking.dismissesAfterSave = false
        asking.saveToPhotoLibrary()
        await LMKWait.until { saved }
        #expect(asked)
        #expect(writes == 1)
    }

    @Test
    func `A swipe dismissal reports onDismiss`() throws {
        let vc = makeSheet()
        var dismissed = 0
        vc.onDismiss = { dismissed += 1 }
        try vc.presentationControllerDidDismiss(#require(vc.presentationController))
        #expect(dismissed == 1)
    }

    @Test
    func `Style resolves through the theme slot and hides the save button`() {
        var theme = LMKTheme.default
        theme.sharePreview = LMKSharePreviewViewController.Style(showsSaveButton: false)
        let vc = LMKSharePreviewViewController(image: makeImage())
        vc.hasPhotoLibraryAddUsageDescription = true
        vc.traitOverrides.lmkTheme = LMKThemeReference(theme)
        vc.loadViewIfNeeded()

        #expect(vc.saveButton.isHidden)
        #expect(vc.resolvedStyle.showsSaveButton == false)

        vc.style = LMKSharePreviewViewController.Style(showsCloseButton: false, showsSaveButton: true)
        #expect(vc.saveButton.isHidden == false)
        #expect(vc.closeButton.isHidden)
    }

    @Test
    func `Style merging layers non-nil fields`() {
        let base = LMKSharePreviewViewController.Style(closeButtonSize: 40, showsSaveButton: false)
        let merged = base.merging(LMKSharePreviewViewController.Style(buttonSpacing: 4))
        #expect(merged.closeButtonSize == 40)
        #expect(merged.showsSaveButton == false)
        #expect(merged.buttonSpacing == 4)
    }

    @Test
    func `Layout spacing follows the theme handed to applyTheme`() {
        var theme = LMKTheme.default
        theme.spacing = .init(small: 2, large: 30)
        let vc = LMKSharePreviewViewController(image: makeImage())
        vc.traitOverrides.lmkTheme = LMKThemeReference(theme)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 375, height: 812))
        window.rootViewController = vc
        window.makeKeyAndVisible()
        vc.view.layoutIfNeeded()

        #expect(vc.closeButton.frame.maxX == 345)
        #expect(vc.scrollView.frame.minY == vc.closeButton.frame.maxY + 2)
        #expect(vc.imageView.frame.minX == 30, "the content insets default to spacing.large")
    }
}
