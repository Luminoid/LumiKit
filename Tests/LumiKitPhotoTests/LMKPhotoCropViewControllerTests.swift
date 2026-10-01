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
    func `A locked ratio survives the crop area shrinking under the frame`() {
        // 4:3 photo, 1:1 preset: zoom in, grow the square to the boundary, pinch back to 1x.
        let crop = makeLaidOutCrop(image: makeImage(CGSize(width: 400, height: 300)))
        crop.currentZoomScale = 2
        crop.updateImageViewFrame()
        crop.cropFrame = crop.cropArea
        crop.updateCropFrame()
        #expect(abs(crop.cropRect.width - crop.cropRect.height) < 0.5, "the frame is fit to the ratio, not clamped side by side")

        crop.currentZoomScale = 1
        crop.updateImageViewFrame()
        crop.updateCropFrame()
        #expect(abs(crop.cropRect.width - crop.cropRect.height) < 0.5, "back at 1x the 1:1 preset is still square")
        #expect(crop.cropRect.height <= crop.imageView.frame.height + 0.5)
        #expect(crop.cropArea.contains(crop.cropRect.insetBy(dx: 0.5, dy: 0.5)))
    }

    @Test
    func `A view size change keeps the frame over the same part of the photo`() {
        let crop = makeLaidOutCrop(image: makeImage(CGSize(width: 400, height: 300)), initialAspectRatio: .free)
        crop.cropFrame = CGRect(x: crop.imageView.frame.minX, y: crop.imageView.frame.minY, width: crop.imageView.frame.width / 2, height: crop.imageView.frame.height / 2)
        crop.updateCropFrame()
        let before = LMKPhotoCropViewController.cropRect(cropFrame: crop.cropRect, imageFrame: crop.imageView.frame, imageSize: crop.image.size)

        crop.view.frame = CGRect(x: 0, y: 0, width: 812, height: 375)
        crop.view.layoutIfNeeded()

        let after = LMKPhotoCropViewController.cropRect(cropFrame: crop.cropRect, imageFrame: crop.imageView.frame, imageSize: crop.image.size)
        #expect(before != nil)
        #expect(after?.minX == before?.minX)
        #expect(after?.minY == before?.minY)
        #expect(abs((after?.width ?? 0) - (before?.width ?? 1)) <= 1)
        #expect(abs((after?.height ?? 0) - (before?.height ?? 1)) <= 1)
    }

    @Test
    func `The pinch is on the editor's view so it works with the fingers inside the frame`() {
        let crop = makeLaidOutCrop(image: makeImage())
        #expect(crop.view.gestureRecognizers?.contains { $0 is UIPinchGestureRecognizer } == true)
        #expect(crop.imageView.gestureRecognizers?.contains { $0 is UIPinchGestureRecognizer } != true)
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

        #expect(cropped.size.width == cropped.size.height, "a square preset yields a square to the unit")
        #expect(cropped.size.height <= 200)
        #expect(crop.isCropping == false)
    }

    @Test
    func `Cancel during a render drops it, so onCrop never follows onCancel`() async {
        let crop = makeLaidOutCrop(image: makeImage(CGSize(width: 2000, height: 2000)))
        var cropped = false
        var cancelled = false
        crop.onCrop = { _ in cropped = true }
        crop.onCancel = { cancelled = true }

        crop.doneTapped()
        #expect(crop.isCropping)
        crop.cancelTapped()
        #expect(cancelled)
        #expect(crop.isCropping == false)
        await LMKWait.until(timeout: .seconds(1)) { cropped }
        #expect(!cropped)
    }

    @Test
    func `The title and the crop frame's VoiceOver element follow the strings`() {
        let crop = makeLaidOutCrop(image: makeImage())
        #expect(crop.title == crop.strings.title)
        crop.strings = LMKPhotoCropViewController.Strings(title: "Recortar", cropFrameAccessibilityLabel: "Marco", cropFrameAccessibilityValueFormat: "%lld por ciento")
        #expect(crop.title == "Recortar")
        let element = crop.cropFrameAccessibilityElement
        #expect(crop.view.accessibilityElements?.contains { $0 as AnyObject === element } == true)
        #expect(element.accessibilityLabel == "Marco")
        #expect(element.accessibilityTraits.contains(.adjustable))
        #expect(element.accessibilityFrameInContainerSpace == crop.cropRect)
        #expect(element.accessibilityValue == "100 por ciento", "a square preset on a square photo fills the width")
        #expect(element.accessibilityCustomActions?.count == 4)
    }

    @Test
    func `VoiceOver adjustments resize the frame and the actions move it, within the same limits as a drag`() throws {
        let crop = makeLaidOutCrop(image: makeImage(CGSize(width: 400, height: 300)))
        let element = crop.cropFrameAccessibilityElement
        let full = crop.cropRect
        element.accessibilityDecrement()
        #expect(crop.cropRect.width < full.width)
        #expect(abs(crop.cropRect.width - crop.cropRect.height) < 0.5, "the ratio holds")
        #expect(abs(crop.cropRect.midX - full.midX) < 0.5, "resized around the center")
        let shrunk = crop.cropRect
        element.accessibilityIncrement()
        #expect(crop.cropRect.width > shrunk.width)
        for _ in 0 ..< 5 {
            element.accessibilityIncrement()
        }
        #expect(crop.cropRect.width <= crop.cropArea.width + 0.5, "never past the crop area")
        #expect(crop.cropRect.height <= crop.cropArea.height + 0.5)

        element.accessibilityDecrement()
        element.accessibilityDecrement()
        let centered = crop.cropRect
        let moveLeft = try #require(element.accessibilityCustomActions?.first { $0.name == crop.strings.moveLeft })
        #expect(moveLeft.actionHandler?(moveLeft) == true)
        #expect(crop.cropRect.minX < centered.minX)
        #expect(crop.cropRect.minX >= crop.cropArea.minX - 0.5)
        #expect(crop.accessibilityPerformEscape())
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
    func `The handle hit area is at least the minimum touch target`() {
        let theme = LMKTheme.default
        #expect(LMKPhotoCropViewController.Style().handleHitSide(theme: theme) >= theme.layout.minimumTouchTarget)
        #expect(LMKPhotoCropViewController.Style(handleSize: 60).handleHitSide(theme: theme) == 60 + theme.spacing.medium)
        #expect(LMKPhotoCropViewController.Style(handleHitSize: 50).handleHitSide(theme: theme) == 50)
    }

    @Test
    func `Every Style field reaches the view it styles`() throws {
        let style = LMKPhotoCropViewController.Style(
            cropFrameBorder: .solid(.orange, width: 4),
            handleSize: 30,
            handleColor: .magenta,
            handleHitSize: 70,
            gridColor: .cyan,
            gridAlpha: 0.25,
            gridLineWidth: 3,
            gridLineCount: 3,
            aspectControl: LMKSegmentedControl.Style(textColor: .yellow),
            overlayButton: LMKButton.Style(foregroundColor: .orange),
            overlayButtonSize: 60,
            contentInset: 40,
            minimumCropSize: 100
        )
        let crop = LMKPhotoCropViewController(image: makeImage(), style: style)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 375, height: 812))
        window.rootViewController = crop
        window.makeKeyAndVisible()
        crop.view.layoutIfNeeded()

        #expect(crop.cropFrameView.layer.borderWidth == 4)
        #expect(crop.cropFrameView.layer.borderColor == UIColor.orange.cgColor)
        let handle = try #require(crop.cropFrameView.subviews.first)
        #expect(handle.bounds.width == 30)
        #expect(handle.backgroundColor == .magenta)
        #expect(crop.resolvedStyle.handleHitSide(theme: crop.traitCollection.lmkTheme) == 70)
        #expect(crop.gridLayer.strokeColor?.alpha == 0.25)
        #expect(crop.gridLayer.lineWidth == 3)
        #expect(crop.resolvedStyle.gridCount == 3)
        #expect(crop.aspectRatioControl.style.textColor == .yellow)
        #expect(crop.doneButton.style.foregroundColor == .orange)
        #expect(crop.doneButton.bounds.width == 60)
        #expect(crop.cancelButton.frame.minX == crop.view.safeAreaInsets.left + crop.traitCollection.lmkTheme.spacing.large)
        #expect(crop.aspectRatioControl.frame.minX == 40)
        #expect(crop.resolvedStyle.minimumCropSide(theme: crop.traitCollection.lmkTheme) == 100)
        crop.cropFrame = CGRect(x: 0, y: 0, width: 10, height: 10)
        crop.updateCropFrame()
        #expect(crop.cropRect.width >= 100)
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
    func `cropRect rounds the origin and size on their own and keeps a locked ratio square`() throws {
        // A 1:1 frame at a fractional position: rounding each edge outward gave 3019 x 3020.
        let imageFrame = CGRect(x: 0, y: 0, width: 100, height: 100)
        let imageSize = CGSize(width: 4000, height: 4000)
        let frame = CGRect(x: 10.3, y: 10.3, width: 75.49, height: 75.49)
        let free = try #require(LMKPhotoCropViewController.cropRect(cropFrame: frame, imageFrame: imageFrame, imageSize: imageSize))
        #expect(free == CGRect(x: 412, y: 412, width: 3020, height: 3020))
        let square = try #require(LMKPhotoCropViewController.cropRect(cropFrame: CGRect(x: 10.3, y: 10.3, width: 75.49, height: 75.51), imageFrame: imageFrame, imageSize: imageSize, ratio: 1))
        #expect(square.width == square.height)
        let wide = try #require(LMKPhotoCropViewController.cropRect(cropFrame: CGRect(x: 0, y: 0, width: 50, height: 37.6), imageFrame: imageFrame, imageSize: imageSize, ratio: 4 / 3))
        #expect(wide.height == (wide.width / (4 / 3)).rounded())
    }

    @Test
    func `render crops to the pixel rect, at the image scale, without keeping the source bitmap`() async {
        let image = makeImage(CGSize(width: 100, height: 60))
        let cropped = await LMKPhotoCropViewController.render(image: image, cropRect: CGRect(x: 10, y: 10, width: 40, height: 20))
        #expect(cropped?.size == CGSize(width: 40, height: 20))
        #expect(cropped?.scale == image.scale)
        #expect(cropped?.cgImage?.width == Int(40 * image.scale))
        #expect(cropped?.cgImage?.bytesPerRow == Int(40 * image.scale) * 4, "one bitmap the size of the crop, not a window into the source")
        let empty = await LMKPhotoCropViewController.render(image: image, cropRect: CGRect(x: 500, y: 500, width: 10, height: 10))
        #expect(empty == nil)
    }

    @Test
    func `render honors a non-up orientation without a second full-size bitmap`() async throws {
        // A 200 x 100 bitmap tagged `.right` is a 100 x 200 image; its top-left 30 x 60 is what
        // the oriented crop rect names.
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let bitmap = UIGraphicsImageRenderer(size: CGSize(width: 200, height: 100), format: format).image { context in
            UIColor.red.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 200, height: 100))
            UIColor.blue.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 200, height: 50))
        }
        let rotated = try UIImage(cgImage: #require(bitmap.cgImage), scale: 1, orientation: .right)
        #expect(rotated.size == CGSize(width: 100, height: 200))
        let cropped = try #require(await LMKPhotoCropViewController.render(image: rotated, cropRect: CGRect(x: 0, y: 0, width: 30, height: 60)))
        #expect(cropped.size == CGSize(width: 30, height: 60))
        #expect(cropped.imageOrientation == .up)
        #expect(cropped.cgImage?.width == 30)
        #expect(cropped.cgImage?.height == 60)
    }

    @Test
    func `remapped keeps the frame over the same part of the image`() {
        let frame = CGRect(x: 10, y: 20, width: 50, height: 50)
        let moved = LMKPhotoCropViewController.remapped(frame, from: CGRect(x: 0, y: 0, width: 100, height: 100), to: CGRect(x: 100, y: 50, width: 200, height: 200))
        #expect(moved == CGRect(x: 120, y: 90, width: 100, height: 100))
        #expect(LMKPhotoCropViewController.remapped(frame, from: .zero, to: CGRect(x: 0, y: 0, width: 10, height: 10)) == frame)
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
        #expect(tiny.maxX == 200, "the opposite corner never moves")
        #expect(tiny.maxY == 200)

        // An edge dragged past the opposite edge stops at the minimum instead of growing again.
        let crossed = LMKPhotoCropViewController.resized(CGRect(x: 0, y: 0, width: 300, height: 300), handle: .right, deltaX: -500, deltaY: 0, ratio: nil, within: bounds, minimumSize: 44)
        #expect(crossed == CGRect(x: 0, y: 0, width: 44, height: 300))
        let top = LMKPhotoCropViewController.resized(frame, handle: .top, deltaX: 0, deltaY: 500, ratio: nil, within: bounds, minimumSize: 44)
        #expect(top == CGRect(x: 100, y: 156, width: 100, height: 44))
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

        // A corner dragged past the anchor collapses to the minimum at the anchor, never regrows.
        let crossed = LMKPhotoCropViewController.resized(frame, handle: .bottomRight, deltaX: -300, deltaY: -300, ratio: 1, within: bounds, minimumSize: 44)
        #expect(crossed == CGRect(x: 100, y: 100, width: 44, height: 44))
        let topLeft = LMKPhotoCropViewController.resized(frame, handle: .topLeft, deltaX: 300, deltaY: 300, ratio: 1, within: bounds, minimumSize: 44)
        #expect(topLeft == CGRect(x: 156, y: 156, width: 44, height: 44), "anchored at the bottom-right corner")
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
