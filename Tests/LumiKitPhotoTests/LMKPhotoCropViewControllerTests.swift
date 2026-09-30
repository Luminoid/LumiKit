//
//  LMKPhotoCropViewControllerTests.swift
//  LumiKit
//

import LumiKitUI
import Testing
import UIKit
@testable import LumiKitPhoto

@MainActor
struct LMKPhotoCropViewControllerTests {
    // MARK: - Helpers

    private func makeImage(_ size: CGSize = CGSize(width: 200, height: 200), color: UIColor = .blue) -> UIImage {
        UIImage.lmk_solidColor(color, size: size)
    }

    private func makeLaidOutCrop(image: UIImage, initialAspectRatio: LMKCropAspectRatio = .square) -> LMKPhotoCropViewController {
        let crop = LMKPhotoCropViewController(image: image, initialAspectRatio: initialAspectRatio)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 375, height: 812))
        window.rootViewController = crop
        window.makeKeyAndVisible()
        crop.loadViewIfNeeded()
        crop.view.layoutIfNeeded()
        return crop
    }

    // MARK: - Initialization

    @Test
    func `Initializes with the image and the standard presets`() {
        let image = makeImage()
        let crop = LMKPhotoCropViewController(image: image)

        #expect(crop.isViewLoaded == false)
        #expect(crop.image.size == image.size)
        #expect(crop.aspectRatios == LMKCropAspectRatio.standard)
        #expect(crop.currentAspectRatio == .square)
        #expect(crop.modalPresentationStyle == .overFullScreen)
        #expect(crop.preferredStatusBarStyle == .lightContent)
    }

    @Test
    func `A missing initial preset is inserted and empty presets fall back`() {
        let crop = LMKPhotoCropViewController(image: makeImage(), aspectRatios: [.free], initialAspectRatio: .sixteenNine)
        #expect(crop.aspectRatios == [.sixteenNine, .free])
        #expect(crop.currentAspectRatio == .sixteenNine)

        let fallback = LMKPhotoCropViewController(image: makeImage(), aspectRatios: [])
        #expect(fallback.aspectRatios == LMKCropAspectRatio.standard)
    }

    @Test
    func `Loads the view for every image shape`() {
        for size in [CGSize(width: 50, height: 50), CGSize(width: 1000, height: 1000), CGSize(width: 100, height: 200), CGSize(width: 300, height: 200)] {
            let crop = LMKPhotoCropViewController(image: makeImage(size))
            crop.loadViewIfNeeded()
            crop.viewWillAppear(false)
            crop.viewDidAppear(false)
            #expect(crop.isViewLoaded)
            #expect(crop.aspectRatioControl.numberOfSegments == LMKCropAspectRatio.standard.count)
        }
    }

    // MARK: - Aspect ratio

    @Test
    func `setAspectRatio moves the control and reshapes the frame`() {
        let crop = makeLaidOutCrop(image: makeImage(CGSize(width: 400, height: 300)))
        let squareFrame = crop.cropRect
        #expect(abs(squareFrame.width - squareFrame.height) < 0.5)

        crop.setAspectRatio(.fourThree, animated: false)

        #expect(crop.currentAspectRatio == .fourThree)
        #expect(crop.aspectRatioControl.selectedSegmentIndex == 1)
        #expect(abs(crop.cropRect.width / crop.cropRect.height - 4 / 3) < 0.01)

        crop.setAspectRatio(.nineSixteen, animated: false)
        #expect(crop.currentAspectRatio == .fourThree, "presets outside the list are ignored")
    }

    @Test
    func `The control's selection drives the preset`() {
        let crop = makeLaidOutCrop(image: makeImage())
        crop.aspectRatioControl.setSelectedSegmentIndex(5, animated: false)
        crop.aspectRatioControl.onValueChange?(5)
        #expect(crop.currentAspectRatio == .free)
    }

    // MARK: - Actions

    @Test
    func `Cancel fires onCancel`() {
        let crop = LMKPhotoCropViewController(image: makeImage())
        var cancelled = false
        crop.onCancel = { cancelled = true }
        crop.loadViewIfNeeded()

        crop.cancelTapped()

        #expect(cancelled)
    }

    @Test
    func `Done delivers the cropped image off the main actor`() async {
        let crop = makeLaidOutCrop(image: makeImage(CGSize(width: 400, height: 200)))

        let cropped = await withCheckedContinuation { continuation in
            crop.onCrop = { continuation.resume(returning: $0) }
            crop.doneTapped()
        }

        #expect(abs(cropped.size.width - cropped.size.height) < 1.5, "a square preset yields a square")
        #expect(cropped.size.height <= 200)
        #expect(crop.isCropping == false)
    }

    @Test
    func `croppedImage returns the current crop`() async {
        let crop = makeLaidOutCrop(image: makeImage(CGSize(width: 300, height: 300)), initialAspectRatio: .free)
        let cropped = await crop.croppedImage()
        #expect(cropped != nil)
    }

    @Test
    func `Key commands map Command-Return to Done and Escape to Cancel`() {
        let crop = LMKPhotoCropViewController(image: makeImage())
        #expect(crop.canBecomeFirstResponder)
        let commands = crop.keyCommands ?? []
        #expect(commands.count == 2)
        #expect(commands.contains { $0.input == "\r" && $0.modifierFlags == .command })
        #expect(commands.contains { $0.input == UIKeyCommand.inputEscape })
    }

    // MARK: - Style

    @Test
    func `Style resolves through the theme slot`() {
        var theme = LMKTheme.default
        theme.photoCrop = LMKPhotoCropViewController.Style(handleSize: 30, gridLineCount: 3)
        let crop = LMKPhotoCropViewController(image: makeImage(), style: LMKPhotoCropViewController.Style(gridLineCount: 1))
        crop.traitOverrides.lmkTheme = LMKThemeReference(theme)
        crop.loadViewIfNeeded()

        #expect(crop.resolvedStyle.handleSize == 30)
        #expect(crop.resolvedStyle.gridLineCount == 1, "the instance style wins")
        #expect(crop.resolvedStyle.drawsGrid)
        #expect(LMKPhotoCropViewController.Style(showsGrid: false).drawsGrid == false)
    }

    @Test
    func `Orientation lock defaults on for iOS 26`() {
        guard #available(iOS 26, *) else { return }
        let crop = LMKPhotoCropViewController(image: makeImage())
        crop.loadViewIfNeeded()
        #expect(crop.prefersInterfaceOrientationLocked)
        crop.style = LMKPhotoCropViewController.Style(locksOrientation: false)
        #expect(crop.prefersInterfaceOrientationLocked == false)
    }

    // MARK: - Pure geometry

    @Test
    func `cropRect maps the frame into pixels and clamps to the image`() throws {
        let imageFrame = CGRect(x: 50, y: 100, width: 200, height: 100)
        let imageSize = CGSize(width: 400, height: 200)
        let rect = try #require(LMKPhotoCropViewController.cropRect(cropFrame: CGRect(x: 100, y: 125, width: 50, height: 50), imageFrame: imageFrame, imageSize: imageSize))
        #expect(rect == CGRect(x: 100, y: 50, width: 100, height: 100))

        let clamped = try #require(LMKPhotoCropViewController.cropRect(cropFrame: CGRect(x: 0, y: 0, width: 400, height: 400), imageFrame: imageFrame, imageSize: imageSize))
        #expect(clamped == CGRect(origin: .zero, size: imageSize))

        #expect(LMKPhotoCropViewController.cropRect(cropFrame: CGRect(x: 0, y: 0, width: 10, height: 10), imageFrame: imageFrame, imageSize: imageSize) == nil, "outside the image")
    }

    @Test
    func `render crops to the pixel rect`() async {
        let image = makeImage(CGSize(width: 100, height: 60))
        let cropped = await LMKPhotoCropViewController.render(image: image, cropRect: CGRect(x: 10, y: 10, width: 40, height: 20))
        #expect(cropped?.size == CGSize(width: 40, height: 20))
        let empty = await LMKPhotoCropViewController.render(image: image, cropRect: CGRect(x: 500, y: 500, width: 10, height: 10))
        #expect(empty == nil)
    }

    @Test
    func `Initial size, reshaping, and clamping`() {
        #expect(LMKPhotoCropViewController.initialCropSize(ratio: 1, in: CGSize(width: 300, height: 500)) == CGSize(width: 300, height: 300))
        #expect(LMKPhotoCropViewController.initialCropSize(ratio: 0.5, in: CGSize(width: 300, height: 500)) == CGSize(width: 250, height: 500))
        #expect(LMKPhotoCropViewController.initialCropSize(ratio: nil, in: CGSize(width: 300, height: 500)) == CGSize(width: 300, height: 500))

        let reshaped = LMKPhotoCropViewController.reshaped(CGSize(width: 200, height: 100), toRatio: 1, maximum: CGSize(width: 150, height: 150))
        #expect(reshaped == CGSize(width: 150, height: 150))

        let bounds = CGRect(x: 20, y: 20, width: 300, height: 400)
        let clamped = LMKPhotoCropViewController.clamped(CGRect(x: -50, y: 500, width: 10, height: 1000), within: bounds, minimumSize: 44)
        #expect(clamped == CGRect(x: 20, y: 20, width: 44, height: 400))
    }

    @Test
    func `Free resize moves the dragged edges and respects the bounds`() {
        let bounds = CGRect(x: 0, y: 0, width: 300, height: 300)
        let frame = CGRect(x: 100, y: 100, width: 100, height: 100)
        let right = LMKPhotoCropViewController.resized(frame, handle: .right, deltaX: 50, deltaY: 0, ratio: nil, within: bounds, minimumSize: 44)
        #expect(right == CGRect(x: 100, y: 100, width: 150, height: 100))

        let past = LMKPhotoCropViewController.resized(frame, handle: .right, deltaX: 500, deltaY: 0, ratio: nil, within: bounds, minimumSize: 44)
        #expect(past.maxX == 300)

        let tiny = LMKPhotoCropViewController.resized(frame, handle: .topLeft, deltaX: 90, deltaY: 90, ratio: nil, within: bounds, minimumSize: 44)
        #expect(tiny.width == 44)
        #expect(tiny.height == 44)
    }

    @Test
    func `Fixed-ratio resize anchors the opposite corner and keeps the ratio`() {
        let bounds = CGRect(x: 0, y: 0, width: 400, height: 400)
        let frame = CGRect(x: 100, y: 100, width: 100, height: 100)
        let grown = LMKPhotoCropViewController.resized(frame, handle: .bottomRight, deltaX: 60, deltaY: 20, ratio: 1, within: bounds, minimumSize: 44)
        #expect(grown.origin == frame.origin, "the top-left corner anchors")
        #expect(abs(grown.width - grown.height) < 0.001)
        #expect(grown.width == 120, "the smaller delta wins under a fixed ratio")

        let edge = LMKPhotoCropViewController.resized(frame, handle: .right, deltaX: 60, deltaY: 0, ratio: 1, within: bounds, minimumSize: 44)
        #expect(edge == frame, "edges do not resize a fixed ratio")
    }

    @Test
    func `Handle hit testing prefers corners and gates edges`() {
        let size = CGSize(width: 200, height: 100)
        #expect(LMKPhotoCropViewController.handle(at: CGPoint(x: 2, y: 2), frameSize: size, hitSide: 30, includesEdges: true) == .topLeft)
        #expect(LMKPhotoCropViewController.handle(at: CGPoint(x: 198, y: 98), frameSize: size, hitSide: 30, includesEdges: true) == .bottomRight)
        #expect(LMKPhotoCropViewController.handle(at: CGPoint(x: 100, y: 2), frameSize: size, hitSide: 30, includesEdges: true) == .top)
        #expect(LMKPhotoCropViewController.handle(at: CGPoint(x: 100, y: 2), frameSize: size, hitSide: 30, includesEdges: false) == nil)
        #expect(LMKPhotoCropViewController.handle(at: CGPoint(x: 100, y: 50), frameSize: size, hitSide: 30, includesEdges: true) == nil)
    }
}
