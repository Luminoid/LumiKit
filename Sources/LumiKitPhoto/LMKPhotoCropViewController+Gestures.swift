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
            isMoving = true
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
            isMoving = false
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
            updateOverlayMask()
            CATransaction.commit()
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
        if gestureRecognizer is UIPinchGestureRecognizer {
            return true
        }
        guard gestureRecognizer.view === cropFrameView || gestureRecognizer.view === view,
              let pan = gestureRecognizer as? UIPanGestureRecognizer else {
            return true
        }
        let location = pan.location(in: view)
        // The aspect ratio control keeps its own touches.
        if aspectRatioControl.frame.contains(location) {
            return false
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
