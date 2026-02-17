//
//  LMKSharePreviewTests.swift
//  LumiKit
//

import Testing
import UIKit

@testable import LumiKitUI

@Suite("LMKSharePreviewViewController")
@MainActor
struct LMKSharePreviewTests {
    @Test("Init creates page sheet with large detent")
    func initCreatesPageSheet() {
        let image = UIImage.lmk_solidColor(.blue, size: CGSize(width: 100, height: 200))
        let vc = LMKSharePreviewViewController(image: image)

        #expect(vc.modalPresentationStyle == .pageSheet)
        #expect(vc.sheetPresentationController?.detents.count == 1)
        #expect(vc.sheetPresentationController?.prefersGrabberVisible == true)
    }

    @Test("Default strings have expected values")
    func defaultStrings() {
        let strings = LMKSharePreviewStrings()
        #expect(strings.share == "Share")
        #expect(strings.saveImage == "Save Image")
        #expect(strings.saveError == "Failed to save image")
        #expect(strings.saveSuccess == "Image saved to Photos")
        #expect(!strings.photoPermissionDenied.isEmpty)
    }

    @Test("Custom strings are applied")
    func customStrings() {
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

    @Test("Delegate can be set")
    func delegateCanBeSet() {
        let image = UIImage.lmk_solidColor(.blue, size: CGSize(width: 100, height: 200))
        let vc = LMKSharePreviewViewController(image: image)

        final class MockDelegate: LMKSharePreviewDelegate {}
        let delegate = MockDelegate()
        vc.delegate = delegate

        #expect(vc.delegate != nil)
    }

    @Test("viewDidLoad sets up UI")
    func viewDidLoadSetsUpUI() {
        let image = UIImage.lmk_solidColor(.blue, size: CGSize(width: 100, height: 200))
        let vc = LMKSharePreviewViewController(image: image)
        vc.loadViewIfNeeded()

        #expect(vc.view.subviews.count > 0)
    }
}
