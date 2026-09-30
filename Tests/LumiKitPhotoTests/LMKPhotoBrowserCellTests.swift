//
//  LMKPhotoBrowserCellTests.swift
//  LumiKit
//

import LumiKitUI
import Testing
import UIKit
@testable import LumiKitPhoto

@MainActor
struct LMKPhotoBrowserCellTests {
    private func makeCell() -> LMKPhotoBrowserCell {
        LMKPhotoBrowserCell(frame: CGRect(x: 0, y: 0, width: 375, height: 667))
    }

    // MARK: - Initialization

    @Test
    func `Cell has its identifier and frame`() {
        let cell = makeCell()
        #expect(LMKPhotoBrowserCell.identifier == "LMKPhotoBrowserCell")
        #expect(cell.frame.width == 375)
        #expect(cell.frame.height == 667)
    }

    // MARK: - Image Configuration

    @Test
    func `configure installs the image for every aspect ratio and screen size`() {
        let cell = makeCell()
        for size in [CGSize(width: 100, height: 100), CGSize(width: 100, height: 200), CGSize(width: 200, height: 100)] {
            let image = UIImage.lmk_solidColor(.red, size: size)
            cell.configure(with: image, screenSize: CGSize(width: 375, height: 667))
            #expect(cell.installedImage === image)
            cell.configure(with: image, screenSize: CGSize(width: 320, height: 568))
            cell.configure(with: image, screenSize: CGSize(width: 428, height: 926))
        }
        cell.resetZoom()
        cell.layoutSubviews()
        #expect(!cell.isZoomed)
        cell.prepareForReuse()
        #expect(cell.installedImage == nil)
    }

    @Test
    func `fittedSize aspect-fits inside the page`() {
        let page = CGSize(width: 300, height: 600)
        #expect(LMKPhotoBrowserCell.fittedSize(imageSize: CGSize(width: 100, height: 100), in: page) == CGSize(width: 300, height: 300))
        #expect(LMKPhotoBrowserCell.fittedSize(imageSize: CGSize(width: 100, height: 400), in: page) == CGSize(width: 150, height: 600))
        #expect(LMKPhotoBrowserCell.fittedSize(imageSize: .zero, in: page) == page, "a degenerate image falls back to the page")
    }

    // MARK: - Style

    @Test
    func `apply(style:) keeps the page clear and sets the dynamic range and the badge`() {
        let cell = makeCell()
        cell.apply(style: LMKPhotoBrowserViewController.Style(backgroundColor: .purple), theme: .default, dynamicRange: .high)
        cell.apply(strings: LMKPhotoBrowserViewController.Strings(liveBadge: "VIVO"))

        #expect(cell.backgroundColor == .clear, "the stage is the browser's layer, not the page's")
        #expect(cell.preferredImageDynamicRange == .high)
        cell.preferredImageDynamicRange = .standard
        #expect(cell.preferredImageDynamicRange == .standard)
    }

    // MARK: - Async Image Loading

    @Test
    func `async configure shows placeholder then installs the loaded image`() async {
        let cell = makeCell()
        let image = UIImage.lmk_solidColor(.red, size: CGSize(width: 100, height: 50))

        cell.configure(screenSize: CGSize(width: 375, height: 667)) { image }
        #expect(cell.installedImage == nil)

        await settleMainActor()
        #expect(cell.installedImage === image)
    }

    @Test
    func `stale async result never lands after reuse`() async {
        let cell = makeCell()
        let staleImage = UIImage.lmk_solidColor(.red, size: CGSize(width: 100, height: 100))
        let freshImage = UIImage.lmk_solidColor(.blue, size: CGSize(width: 100, height: 100))
        let gate = AsyncGate()

        cell.configure(screenSize: CGSize(width: 375, height: 667)) {
            await gate.wait()
            return staleImage
        }

        // Recycle the page for another index while the first load is in flight.
        cell.prepareForReuse()
        cell.configure(screenSize: CGSize(width: 375, height: 667)) { freshImage }
        await settleMainActor()
        #expect(cell.installedImage === freshImage)

        gate.open()
        await settleMainActor()
        #expect(cell.installedImage === freshImage)
    }

    @Test
    func `synchronous configure supersedes an in-flight async load`() async {
        let cell = makeCell()
        let asyncImage = UIImage.lmk_solidColor(.red, size: CGSize(width: 100, height: 100))
        let syncImage = UIImage.lmk_solidColor(.green, size: CGSize(width: 100, height: 100))
        let gate = AsyncGate()

        cell.configure(screenSize: CGSize(width: 375, height: 667)) {
            await gate.wait()
            return asyncImage
        }
        cell.configure(with: syncImage, screenSize: CGSize(width: 375, height: 667))

        gate.open()
        await settleMainActor()
        #expect(cell.installedImage === syncImage)
    }

    @Test
    func `refitInstalledImage is a no-op while loading and refits once installed`() async {
        let cell = makeCell()
        let image = UIImage.lmk_solidColor(.blue, size: CGSize(width: 200, height: 100))
        let gate = AsyncGate()

        cell.configure(screenSize: CGSize(width: 375, height: 667)) {
            await gate.wait()
            return image
        }
        cell.refitInstalledImage(to: CGSize(width: 667, height: 375))
        #expect(cell.installedImage == nil)

        gate.open()
        await settleMainActor()
        cell.refitInstalledImage(to: CGSize(width: 667, height: 375))
        #expect(cell.installedImage === image)
    }

    @Test
    func `a stale Live Photo load never lands after reuse`() async {
        let cell = makeCell()
        let gate = AsyncGate()
        var providerCalls = 0

        cell.configure(screenSize: CGSize(width: 375, height: 667), isLive: true) { nil }
        cell.loadLivePhoto {
            providerCalls += 1
            await gate.wait()
            return nil
        }
        cell.prepareForReuse()
        gate.open()
        await settleMainActor()

        #expect(providerCalls == 1)
        #expect(cell.installedImage == nil)
    }
}
