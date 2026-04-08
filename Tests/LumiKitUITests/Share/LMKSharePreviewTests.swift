//
//  LMKSharePreviewTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

@MainActor
struct LMKSharePreviewTests {
    @Test
    func `Init creates page sheet with large detent`() {
        let image = UIImage.lmk_solidColor(.blue, size: CGSize(width: 100, height: 200))
        let vc = LMKSharePreviewViewController(image: image)

        #expect(vc.modalPresentationStyle == .pageSheet)
        #expect(vc.sheetPresentationController?.detents.count == 1)
        #expect(vc.sheetPresentationController?.prefersGrabberVisible == true)
    }

    @Test
    func `Default strings have expected values`() {
        let strings = LMKSharePreviewStrings()
        #expect(strings.share == "Share")
        #expect(strings.saveImage == "Save Image")
        #expect(strings.saveError == "Failed to save image")
        #expect(strings.saveSuccess == nil)
        #expect(!strings.photoPermissionDenied.isEmpty)
    }

    @Test
    func `Custom strings are applied`() {
        let original = LMKSharePreviewViewController.strings
        defer { LMKSharePreviewViewController.strings = original }

        LMKSharePreviewViewController.strings = .init(
            share: "Compartir",
            saveImage: "Guardar imagen",
            saveError: "Error al guardar",
            saveSuccess: "Imagen guardada",
            photoPermissionDenied: "Se requiere acceso a fotos"
        )

        #expect(LMKSharePreviewViewController.strings.share == "Compartir")
        #expect(LMKSharePreviewViewController.strings.saveImage == "Guardar imagen")
    }

    @Test
    func `Delegate can be set`() {
        let image = UIImage.lmk_solidColor(.blue, size: CGSize(width: 100, height: 200))
        let vc = LMKSharePreviewViewController(image: image)

        final class MockDelegate: LMKSharePreviewDelegate {}
        let delegate = MockDelegate()
        vc.delegate = delegate

        #expect(vc.delegate != nil)
    }

    @Test
    func `viewDidLoad sets up UI`() {
        let image = UIImage.lmk_solidColor(.blue, size: CGSize(width: 100, height: 200))
        let vc = LMKSharePreviewViewController(image: image)
        vc.loadViewIfNeeded()

        #expect(!vc.view.subviews.isEmpty)
    }
}
