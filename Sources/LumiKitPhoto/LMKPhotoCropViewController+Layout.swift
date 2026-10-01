//
//  LMKPhotoCropViewController+Layout.swift
//  LumiKit
//
//  Frame-driven layout of the crop editor: image fitting, the crop frame and
//  its bounds, the dimming mask, handles, and the grid.
//

import LumiKitUI
import UIKit

extension LMKPhotoCropViewController {
    /// The rect the crop frame may occupy: inside the padding, above the aspect ratio control.
    var boundaryRect: CGRect {
        let padding = resolvedStyle.padding(theme: traitCollection.lmkTheme)
        let controlTop = aspectRatioControl.frame.height > 0 ? aspectRatioControl.frame.minY : view.bounds.height - padding
        return CGRect(
            x: padding,
            y: padding,
            width: max(0, view.bounds.width - padding * 2),
            height: max(0, controlTop - padding * 2)
        )
    }

    /// Where the crop frame may sit: the boundary rect, narrowed to the image when the image
    /// does not fill it (a landscape photo under a square preset crops a square of the photo,
    /// not of the stage).
    var cropArea: CGRect {
        let bounds = boundaryRect
        let imageFrame = imageView.frame
        guard !imageFrame.isEmpty else { return bounds }
        let area = bounds.intersection(imageFrame)
        return area.isEmpty ? bounds : area
    }

    func updateLayout() {
        guard view.bounds.width > 0, view.bounds.height > 0 else { return }
        // A new view size (a rotation, a window resize, another padding) moves the image; the
        // crop frame follows the part of the photo it covered, instead of staying put over
        // another part of it.
        let imageMoved = view.bounds.size != lastViewSize
        let previousImageFrame = imageView.frame
        updateImageViewFrame()
        if needsInitialLayout {
            needsInitialLayout = false
            createInitialCropFrame()
        } else {
            if imageMoved, !previousImageFrame.isEmpty {
                cropFrame = Self.remapped(cropFrame, from: previousImageFrame, to: imageView.frame)
            }
            updateCropFrame()
        }
        updateOverlayMask()
        updateHandlePositions()
        updateGridLines()
        bringChromeToFront()
    }

    func updateImageViewFrame() {
        guard image.size.width > 0, image.size.height > 0 else { return }
        let viewSize = view.bounds.size
        if viewSize != lastViewSize {
            lastViewSize = viewSize
            let padding = resolvedStyle.padding(theme: traitCollection.lmkTheme)
            let available = CGSize(width: max(1, viewSize.width - padding * 2), height: max(1, viewSize.height - padding * 2))
            cachedBaseScale = min(available.width / image.size.width, available.height / image.size.height)
        }
        let scaledWidth = image.size.width * cachedBaseScale * currentZoomScale
        let scaledHeight = image.size.height * cachedBaseScale * currentZoomScale
        imageView.frame = CGRect(
            x: (viewSize.width - scaledWidth) / 2,
            y: (viewSize.height - scaledHeight) / 2,
            width: scaledWidth,
            height: scaledHeight
        )
    }

    func createInitialCropFrame() {
        let area = cropArea
        let size = Self.initialCropSize(ratio: currentAspectRatio.ratio, in: area.size)
        cropFrame = CGRect(
            x: area.midX - size.width / 2,
            y: area.midY - size.height / 2,
            width: size.width,
            height: size.height
        )
        updateCropFrame()
    }

    /// Fits the crop frame into the crop area (keeping a locked ratio: the frame shrinks as a
    /// whole when the area shrinks, never one side alone) and above the minimum size, then
    /// moves the view.
    func updateCropFrame(updateHandles: Bool = true) {
        let bounds = cropArea
        let minimum = resolvedStyle.minimumCropSide(theme: traitCollection.lmkTheme)
        var frame = cropFrame
        if let ratio = currentAspectRatio.ratio {
            frame = Self.reshaped(frame, toRatio: ratio, maximum: bounds.size)
        }
        cropFrame = Self.clamped(frame, within: bounds, minimumSize: minimum)
        cropFrameView.frame = cropFrame
        cropFrameAccessibilityElement.update()
        if updateHandles {
            updateHandlePositions()
            updateGridLines()
        }
    }

    /// Reshapes the crop frame around its center to the current preset.
    func applyAspectRatioToCropFrame() {
        guard let ratio = currentAspectRatio.ratio else { return }
        cropFrame = Self.reshaped(cropFrame, toRatio: ratio, maximum: cropArea.size)
    }

    /// Scales the crop frame by `factor` around its center, for the VoiceOver adjustments;
    /// the crop area and the minimum size apply as for a drag.
    func scaleCropFrame(by factor: CGFloat) {
        guard factor > 0 else { return }
        let center = CGPoint(x: cropFrame.midX, y: cropFrame.midY)
        let size = CGSize(width: cropFrame.width * factor, height: cropFrame.height * factor)
        cropFrame = CGRect(x: center.x - size.width / 2, y: center.y - size.height / 2, width: size.width, height: size.height)
        updateCropFrame()
        updateOverlayMask()
    }

    /// Moves the crop frame by `delta`, for the VoiceOver actions; the crop area applies.
    func moveCropFrame(by delta: CGPoint) {
        cropFrame = cropFrame.offsetBy(dx: delta.x, dy: delta.y)
        updateCropFrame()
        updateOverlayMask()
    }

    // MARK: - Overlay, handles, grid

    func updateOverlayMask() {
        let path = UIBezierPath(rect: overlayView.bounds)
        path.append(UIBezierPath(rect: cropFrame).reversing())
        overlayMaskLayer.path = path.cgPath
    }

    func updateHandlePositions() {
        let width = cropFrame.width
        let height = cropFrame.height
        let half = resolvedStyle.handleSide / 2

        cornerHandleViews[.topLeft]?.frame.origin = CGPoint(x: -half, y: -half)
        cornerHandleViews[.topRight]?.frame.origin = CGPoint(x: width - half, y: -half)
        cornerHandleViews[.bottomLeft]?.frame.origin = CGPoint(x: -half, y: height - half)
        cornerHandleViews[.bottomRight]?.frame.origin = CGPoint(x: width - half, y: height - half)

        // Edge handles exist only for the free ratio.
        let showsEdges = currentAspectRatio == .free
        edgeHandleViews[.top]?.frame.origin = CGPoint(x: width / 2 - half, y: -half)
        edgeHandleViews[.bottom]?.frame.origin = CGPoint(x: width / 2 - half, y: height - half)
        edgeHandleViews[.left]?.frame.origin = CGPoint(x: -half, y: height / 2 - half)
        edgeHandleViews[.right]?.frame.origin = CGPoint(x: width - half, y: height / 2 - half)
        for handleView in edgeHandleViews.values {
            handleView.isHidden = !showsEdges
        }
    }

    func updateGridLines() {
        let width = cropFrame.width
        let height = cropFrame.height
        let count = resolvedStyle.gridCount
        guard width > 0, height > 0, resolvedStyle.drawsGrid else {
            gridLayer.path = nil
            return
        }
        let path = UIBezierPath()
        let divisions = CGFloat(count + 1)
        for line in 1 ... count {
            let x = width * CGFloat(line) / divisions
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: height))
            let y = height * CGFloat(line) / divisions
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: width, y: y))
        }
        gridLayer.frame = cropFrameView.bounds
        gridLayer.path = path.cgPath
    }

    // MARK: - Pure geometry

    /// The largest crop size of `ratio` (nil = the whole area) that fits in `area`.
    nonisolated static func initialCropSize(ratio: CGFloat?, in area: CGSize) -> CGSize {
        guard let ratio, ratio > 0 else { return area }
        if ratio >= 1 {
            let width = min(area.width, area.height * ratio)
            return CGSize(width: width, height: width / ratio)
        }
        let height = min(area.height, area.width / ratio)
        return CGSize(width: height * ratio, height: height)
    }

    /// `size` reshaped to `ratio` (keeping the larger dimension), capped to `maximum`.
    nonisolated static func reshaped(_ size: CGSize, toRatio ratio: CGFloat, maximum: CGSize) -> CGSize {
        guard ratio > 0, size.width > 0, size.height > 0 else { return size }
        var width = size.width
        var height = size.height
        if width / height > ratio {
            height = width / ratio
        } else {
            width = height * ratio
        }
        if width > maximum.width {
            width = maximum.width
            height = width / ratio
        }
        if height > maximum.height {
            height = maximum.height
            width = height * ratio
        }
        return CGSize(width: width, height: height)
    }

    /// `frame` reshaped around its center to `ratio`, capped to `maximum`.
    nonisolated static func reshaped(_ frame: CGRect, toRatio ratio: CGFloat, maximum: CGSize) -> CGRect {
        let size = reshaped(frame.size, toRatio: ratio, maximum: maximum)
        return CGRect(x: frame.midX - size.width / 2, y: frame.midY - size.height / 2, width: size.width, height: size.height)
    }

    /// `frame`, given in the same coordinates as `source`, over the same part of the image once
    /// the image sits at `target` (the image moved or changed size under it).
    nonisolated static func remapped(_ frame: CGRect, from source: CGRect, to target: CGRect) -> CGRect {
        guard source.width > 0, source.height > 0, target.width > 0, target.height > 0 else { return frame }
        let scaleX = target.width / source.width
        let scaleY = target.height / source.height
        return CGRect(
            x: target.minX + (frame.minX - source.minX) * scaleX,
            y: target.minY + (frame.minY - source.minY) * scaleY,
            width: frame.width * scaleX,
            height: frame.height * scaleY
        )
    }

    /// `frame` moved and shrunk into `bounds`, never below `minimumSize` on either side.
    nonisolated static func clamped(_ frame: CGRect, within bounds: CGRect, minimumSize: CGFloat) -> CGRect {
        var result = frame
        result.size.width = max(minimumSize, min(result.width, bounds.width))
        result.size.height = max(minimumSize, min(result.height, bounds.height))
        result.origin.x = max(bounds.minX, min(result.origin.x, bounds.maxX - result.width))
        result.origin.y = max(bounds.minY, min(result.origin.y, bounds.maxY - result.height))
        return result
    }
}
