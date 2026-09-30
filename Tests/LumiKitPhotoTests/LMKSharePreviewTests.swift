//
//  LMKSharePreviewTests.swift
//  LumiKit
//

import LumiKitUI
import Testing
import UIKit
@testable import LumiKitPhoto

@MainActor
struct LMKSharePreviewTests {
    private func makeImage() -> UIImage {
        UIImage.lmk_solidColor(.blue, size: CGSize(width: 100, height: 200))
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
    func `Closures can be set`() {
        let vc = LMKSharePreviewViewController(image: makeImage())
        vc.onShare = { _ in }
        vc.onSave = {}
        vc.onFailure = { _ in }
        vc.onDismiss = {}

        #expect(vc.onShare != nil)
        #expect(vc.onSave != nil)
        #expect(vc.onFailure != nil)
        #expect(vc.dismissesAfterSave)
    }

    @Test
    func `viewDidLoad sets up the image and both buttons`() {
        let vc = LMKSharePreviewViewController(image: makeImage())
        vc.loadViewIfNeeded()

        #expect(!vc.view.subviews.isEmpty)
        #expect(vc.imageView.image != nil)
        #expect(vc.shareButton.isHidden == false)
        #expect(vc.saveButton.isHidden == false)
        #expect(vc.closeButton.isHidden == false)
    }

    @Test
    func `Style resolves through the theme slot and hides the save button`() {
        var theme = LMKTheme.default
        theme.sharePreview = LMKSharePreviewViewController.Style(showsSaveButton: false)
        let vc = LMKSharePreviewViewController(image: makeImage())
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
}
