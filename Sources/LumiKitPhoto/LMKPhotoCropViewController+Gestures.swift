//
//  LMKPhotoCropViewController+Gestures.swift
//  LumiKit
//
//  Move, resize, and pinch handling of the crop editor, plus handle hit testing.
//

import LumiKitUI
import UIKit

extension LMKPhotoCropViewController {
    // MARK: - Handlers

    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        switch gesture.state {
        case .began:
            initialCropFrame = cropFrame
            if resolvedStyle.playsHaptics {
                LMKHaptics.light()
            }
        case .changed:
            // No implicit Core Animation while tracking the finger.
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            cropFrame = initialCropFrame.offsetBy(dx: translation.x, dy: translation.y)
            updateCropFrame(updateHandles: false)
            updateOverlayMask()
            CATransaction.commit()
        case .ended, .cancelled:
            updateCropFrame(updateHandles: true)
            updateOverlayMask()
        default:
            break
        }
    }

    @objc func handleResizePan(_ gesture: UIPanGestureRecognizer) {
        let location = gesture.location(in: view)
        switch gesture.state {
        case .began:
            activeResizeHandle = resizeHandle(at: location)
            if activeResizeHandle != nil {
                initialCropFrame = cropFrame
                initialTouchPoint = location
                isResizing = true
                if resolvedStyle.playsHaptics {
                    LMKHaptics.light()
                }
            }
        case .changed:
            guard let handle = activeResizeHandle, isResizing else { return }
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            cropFrame = Self.resized(
                initialCropFrame,
                handle: handle,
                deltaX: location.x - initialTouchPoint.x,
                deltaY: location.y - initialTouchPoint.y,
                ratio: currentAspectRatio.ratio,
                within: cropArea,
                minimumSize: resolvedStyle.minimumCropSide(theme: traitCollection.lmkTheme)
            )
            updateCropFrame(updateHandles: false)
            updateOverlayMask()
            CATransaction.commit()
        case .ended, .cancelled:
            isResizing = false
            activeResizeHandle = nil
            updateCropFrame(updateHandles: true)
            updateOverlayMask()
        default:
            break
        }
    }

    /// Zooms the image under the crop frame. The frame stays where it is on screen and re-fits
    /// the crop area as the image grows or shrinks under it, so a locked ratio holds.
    @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        switch gesture.state {
        case .began:
            initialZoomScale = currentZoomScale
            if resolvedStyle.playsHaptics {
                LMKHaptics.light()
            }
        case .changed:
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            currentZoomScale = max(1, min(resolvedStyle.maximumZoom, initialZoomScale * gesture.scale))
            updateImageViewFrame()
            updateCropFrame(updateHandles: false)
            updateOverlayMask()
            CATransaction.commit()
        case .ended, .cancelled:
            updateCropFrame(updateHandles: true)
            updateOverlayMask()
        default:
            break
        }
    }

    // MARK: - Hit Testing

    /// The handle under `location` (view coordinates); corners win over edges, and edges exist
    /// only for the free ratio.
    func resizeHandle(at location: CGPoint) -> ResizeHandle? {
        let local = view.convert(location, to: cropFrameView)
        return Self.handle(
            at: local,
            frameSize: cropFrame.size,
            hitSide: resolvedStyle.handleHitSide(theme: traitCollection.lmkTheme),
            includesEdges: currentAspectRatio == .free
        )
    }

    /// Distance-based hit test in crop-frame coordinates.
    nonisolated static func handle(at point: CGPoint, frameSize: CGSize, hitSide: CGFloat, includesEdges: Bool) -> ResizeHandle? {
        let width = frameSize.width
        let height = frameSize.height
        let halfHit = hitSide / 2
        func hits(_ anchor: CGPoint) -> Bool {
            abs(point.x - anchor.x) <= halfHit && abs(point.y - anchor.y) <= halfHit
        }
        let corners: [(CGPoint, ResizeHandle)] = [
            (CGPoint(x: 0, y: 0), .topLeft),
            (CGPoint(x: width, y: 0), .topRight),
            (CGPoint(x: 0, y: height), .bottomLeft),
            (CGPoint(x: width, y: height), .bottomRight),
        ]
        for (anchor, handle) in corners where hits(anchor) {
            return handle
        }
        guard includesEdges else { return nil }
        let edges: [(CGPoint, ResizeHandle)] = [
            (CGPoint(x: width / 2, y: 0), .top),
            (CGPoint(x: width / 2, y: height), .bottom),
            (CGPoint(x: 0, y: height / 2), .left),
            (CGPoint(x: width, y: height / 2), .right),
        ]
        for (anchor, handle) in edges where hits(anchor) {
            return handle
        }
        return nil
    }

    /// Gesture arbitration, called by the private gesture delegate.
    func shouldBeginGesture(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        let location = gestureRecognizer.location(in: view)
        // The aspect ratio control keeps its own touches.
        if aspectRatioControl.frame.contains(location) {
            return false
        }
        if gestureRecognizer is UIPinchGestureRecognizer {
            return true
        }
        guard gestureRecognizer.view === cropFrameView || gestureRecognizer.view === view,
              gestureRecognizer is UIPanGestureRecognizer else {
            return true
        }
        // A handle goes to the resize pan (on the view); the frame interior to the move pan.
        if resizeHandle(at: location) != nil {
            return gestureRecognizer.view === view
        }
        if cropFrame.contains(location) {
            return gestureRecognizer.view === cropFrameView
        }
        return false
    }
}

// MARK: - Accessibility

/// The crop frame as a VoiceOver element: adjustable (up and down resize it around its
/// center) with custom actions that move it, the same clamps as a drag.
final class LMKPhotoCropFrameAccessibilityElement: UIAccessibilityElement {
    /// How much of the frame's size one adjustment adds or removes.
    static let adjustmentFactor: CGFloat = 0.1
    /// How far one move action shifts the frame, as a fraction of its size.
    static let moveFraction: CGFloat = 0.1

    private weak var controller: LMKPhotoCropViewController?
    private var strings = LMKPhotoCropViewController.strings

    init(controller: LMKPhotoCropViewController) {
        self.controller = controller
        super.init(accessibilityContainer: controller.view as Any)
        accessibilityTraits = .adjustable
    }

    func apply(strings: LMKPhotoCropViewController.Strings) {
        self.strings = strings
        accessibilityLabel = strings.cropFrameAccessibilityLabel
        accessibilityHint = strings.cropFrameAccessibilityHint
        accessibilityCustomActions = [
            UIAccessibilityCustomAction(name: strings.moveUp) { [weak self] _ in self?.move(dx: 0, dy: -1) ?? false },
            UIAccessibilityCustomAction(name: strings.moveDown) { [weak self] _ in self?.move(dx: 0, dy: 1) ?? false },
            UIAccessibilityCustomAction(name: strings.moveLeft) { [weak self] _ in self?.move(dx: -1, dy: 0) ?? false },
            UIAccessibilityCustomAction(name: strings.moveRight) { [weak self] _ in self?.move(dx: 1, dy: 0) ?? false },
        ]
        update()
    }

    /// Follows the crop frame: its place on screen and its size as a share of the photo's width.
    func update() {
        guard let controller else { return }
        accessibilityFrameInContainerSpace = controller.cropFrame
        let area = controller.cropArea
        let share = area.width > 0 ? Int((controller.cropFrame.width / area.width * 100).rounded()) : 0
        accessibilityValue = String(format: strings.cropFrameAccessibilityValueFormat, share)
    }

    override func accessibilityIncrement() {
        controller?.scaleCropFrame(by: 1 + Self.adjustmentFactor)
    }

    override func accessibilityDecrement() {
        controller?.scaleCropFrame(by: 1 - Self.adjustmentFactor)
    }

    private func move(dx: CGFloat, dy: CGFloat) -> Bool {
        guard let controller else { return false }
        let frame = controller.cropFrame
        controller.moveCropFrame(by: CGPoint(x: dx * frame.width * Self.moveFraction, y: dy * frame.height * Self.moveFraction))
        return true
    }
}

// MARK: - Gesture Delegate

/// Delegate of the crop editor's recognizers, kept off the public surface.
final class LMKPhotoCropGestureDelegate: NSObject, UIGestureRecognizerDelegate {
    private weak var controller: LMKPhotoCropViewController?

    init(controller: LMKPhotoCropViewController) {
        self.controller = controller
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // Pinch and pan run together.
        (gestureRecognizer is UIPinchGestureRecognizer && otherGestureRecognizer is UIPanGestureRecognizer)
            || (gestureRecognizer is UIPanGestureRecognizer && otherGestureRecognizer is UIPinchGestureRecognizer)
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        controller?.shouldBeginGesture(gestureRecognizer) ?? false
    }
}
