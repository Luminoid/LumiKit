//
//  LMKPhotoCropViewController+Resize.swift
//  LumiKit
//
//  Pure resize math of the crop frame: fixed-ratio corner drags and free
//  corner or edge drags, kept inside the boundary rect and above the minimum.
//

import UIKit

extension LMKPhotoCropViewController {
    /// `frame` resized by dragging `handle` by (`deltaX`, `deltaY`).
    ///
    /// With a `ratio` the opposite corner anchors and the frame keeps the ratio; without one
    /// the dragged edges move freely. The result stays inside `bounds` and above `minimumSize`.
    nonisolated static func resized(
        _ frame: CGRect,
        handle: ResizeHandle,
        deltaX: CGFloat,
        deltaY: CGFloat,
        ratio: CGFloat?,
        within bounds: CGRect,
        minimumSize: CGFloat
    ) -> CGRect {
        if let ratio, ratio > 0 {
            guard handle.isCorner else { return frame }
            return resizedWithFixedRatio(frame, handle: handle, deltaX: deltaX, deltaY: deltaY, ratio: ratio, bounds: bounds, minimumSize: minimumSize)
        }
        // The bounds and the minimum limit the delta itself, so the dragged edge stops where
        // it should and the opposite edge never moves.
        var result = frame
        if handle.isCorner {
            applyCornerDelta(handle: handle, frame: &result, deltaX: deltaX, deltaY: deltaY, bounds: bounds, minimumSize: minimumSize)
        } else {
            applyEdgeDelta(handle: handle, frame: &result, deltaX: deltaX, deltaY: deltaY, bounds: bounds, minimumSize: minimumSize)
        }
        return result
    }

    // MARK: - Fixed ratio

    private nonisolated static func resizedWithFixedRatio(
        _ frame: CGRect,
        handle: ResizeHandle,
        deltaX: CGFloat,
        deltaY: CGFloat,
        ratio: CGFloat,
        bounds: CGRect,
        minimumSize: CGFloat
    ) -> CGRect {
        // The distance from the anchor in the handle's own direction; a corner dragged past
        // the anchor collapses the frame (to the minimum below) instead of growing it again.
        let anchor = anchorPoint(handle: handle, frame: frame)
        let corner = draggedCorner(handle: handle, frame: frame, deltaX: deltaX, deltaY: deltaY)
        let direction = direction(of: handle)
        var width = max(0, (corner.x - anchor.x) * direction.x)
        var height = max(0, (corner.y - anchor.y) * direction.y)
        if width / ratio <= height {
            height = width / ratio
        } else {
            width = height * ratio
        }
        var origin = origin(handle: handle, anchor: anchor, width: width, height: height)

        // Bounds and minimum, re-anchoring after each correction.
        if origin.x < bounds.minX {
            width = anchor.x - bounds.minX
            height = width / ratio
            origin = self.origin(handle: handle, anchor: anchor, width: width, height: height)
        }
        if origin.x + width > bounds.maxX {
            width = bounds.maxX - origin.x
            height = width / ratio
            origin = self.origin(handle: handle, anchor: anchor, width: width, height: height)
        }
        if origin.y < bounds.minY {
            height = anchor.y - bounds.minY
            width = height * ratio
            origin = self.origin(handle: handle, anchor: anchor, width: width, height: height)
        }
        if origin.y + height > bounds.maxY {
            height = bounds.maxY - origin.y
            width = height * ratio
            origin = self.origin(handle: handle, anchor: anchor, width: width, height: height)
        }
        if width < minimumSize {
            width = minimumSize
            height = width / ratio
            origin = self.origin(handle: handle, anchor: anchor, width: width, height: height)
        }
        if height < minimumSize {
            height = minimumSize
            width = height * ratio
            origin = self.origin(handle: handle, anchor: anchor, width: width, height: height)
        }
        origin.x = max(bounds.minX, min(origin.x, bounds.maxX - width))
        origin.y = max(bounds.minY, min(origin.y, bounds.maxY - height))
        return CGRect(origin: origin, size: CGSize(width: width, height: height))
    }

    /// The corner opposite `handle`, which stays put during a fixed-ratio drag.
    private nonisolated static func anchorPoint(handle: ResizeHandle, frame: CGRect) -> CGPoint {
        switch handle {
        case .topLeft: CGPoint(x: frame.maxX, y: frame.maxY)
        case .topRight: CGPoint(x: frame.minX, y: frame.maxY)
        case .bottomLeft: CGPoint(x: frame.maxX, y: frame.minY)
        case .bottomRight, .top, .bottom, .left, .right: CGPoint(x: frame.minX, y: frame.minY)
        }
    }

    /// The direction the dragged corner grows the frame in, away from the anchor: -1 toward
    /// the left or the top, 1 toward the right or the bottom.
    private nonisolated static func direction(of handle: ResizeHandle) -> CGPoint {
        switch handle {
        case .topLeft: CGPoint(x: -1, y: -1)
        case .topRight: CGPoint(x: 1, y: -1)
        case .bottomLeft: CGPoint(x: -1, y: 1)
        case .bottomRight, .top, .bottom, .left, .right: CGPoint(x: 1, y: 1)
        }
    }

    private nonisolated static func draggedCorner(handle: ResizeHandle, frame: CGRect, deltaX: CGFloat, deltaY: CGFloat) -> CGPoint {
        switch handle {
        case .topLeft: CGPoint(x: frame.minX + deltaX, y: frame.minY + deltaY)
        case .topRight: CGPoint(x: frame.maxX + deltaX, y: frame.minY + deltaY)
        case .bottomLeft: CGPoint(x: frame.minX + deltaX, y: frame.maxY + deltaY)
        case .bottomRight, .top, .bottom, .left, .right: CGPoint(x: frame.maxX + deltaX, y: frame.maxY + deltaY)
        }
    }

    private nonisolated static func origin(handle: ResizeHandle, anchor: CGPoint, width: CGFloat, height: CGFloat) -> CGPoint {
        switch handle {
        case .topLeft: CGPoint(x: anchor.x - width, y: anchor.y - height)
        case .topRight: CGPoint(x: anchor.x, y: anchor.y - height)
        case .bottomLeft: CGPoint(x: anchor.x - width, y: anchor.y)
        case .bottomRight, .top, .bottom, .left, .right: anchor
        }
    }

    // MARK: - Free

    /// The delta a left or top edge may move by: not past the bounds, not past the point where
    /// the frame would be smaller than the minimum.
    private nonisolated static func leadingDelta(_ delta: CGFloat, edge: CGFloat, boundsEdge: CGFloat, length: CGFloat, minimumSize: CGFloat) -> CGFloat {
        min(max(delta, boundsEdge - edge), length - minimumSize)
    }

    /// The delta a right or bottom edge may move by: not past the bounds, not below the minimum.
    private nonisolated static func trailingDelta(_ delta: CGFloat, edge: CGFloat, boundsEdge: CGFloat, length: CGFloat, minimumSize: CGFloat) -> CGFloat {
        max(min(delta, boundsEdge - edge), minimumSize - length)
    }

    private nonisolated static func applyCornerDelta(handle: ResizeHandle, frame: inout CGRect, deltaX: CGFloat, deltaY: CGFloat, bounds: CGRect, minimumSize: CGFloat) {
        switch handle {
        case .topLeft:
            let dx = leadingDelta(deltaX, edge: frame.minX, boundsEdge: bounds.minX, length: frame.width, minimumSize: minimumSize)
            let dy = leadingDelta(deltaY, edge: frame.minY, boundsEdge: bounds.minY, length: frame.height, minimumSize: minimumSize)
            frame.origin.x += dx
            frame.origin.y += dy
            frame.size.width -= dx
            frame.size.height -= dy
        case .topRight:
            let dx = trailingDelta(deltaX, edge: frame.maxX, boundsEdge: bounds.maxX, length: frame.width, minimumSize: minimumSize)
            let dy = leadingDelta(deltaY, edge: frame.minY, boundsEdge: bounds.minY, length: frame.height, minimumSize: minimumSize)
            frame.origin.y += dy
            frame.size.width += dx
            frame.size.height -= dy
        case .bottomLeft:
            let dx = leadingDelta(deltaX, edge: frame.minX, boundsEdge: bounds.minX, length: frame.width, minimumSize: minimumSize)
            let dy = trailingDelta(deltaY, edge: frame.maxY, boundsEdge: bounds.maxY, length: frame.height, minimumSize: minimumSize)
            frame.origin.x += dx
            frame.size.width -= dx
            frame.size.height += dy
        case .bottomRight:
            let dx = trailingDelta(deltaX, edge: frame.maxX, boundsEdge: bounds.maxX, length: frame.width, minimumSize: minimumSize)
            let dy = trailingDelta(deltaY, edge: frame.maxY, boundsEdge: bounds.maxY, length: frame.height, minimumSize: minimumSize)
            frame.size.width += dx
            frame.size.height += dy
        case .top, .bottom, .left, .right:
            break
        }
    }

    private nonisolated static func applyEdgeDelta(handle: ResizeHandle, frame: inout CGRect, deltaX: CGFloat, deltaY: CGFloat, bounds: CGRect, minimumSize: CGFloat) {
        switch handle {
        case .top:
            let dy = leadingDelta(deltaY, edge: frame.minY, boundsEdge: bounds.minY, length: frame.height, minimumSize: minimumSize)
            frame.origin.y += dy
            frame.size.height -= dy
        case .bottom:
            frame.size.height += trailingDelta(deltaY, edge: frame.maxY, boundsEdge: bounds.maxY, length: frame.height, minimumSize: minimumSize)
        case .left:
            let dx = leadingDelta(deltaX, edge: frame.minX, boundsEdge: bounds.minX, length: frame.width, minimumSize: minimumSize)
            frame.origin.x += dx
            frame.size.width -= dx
        case .right:
            frame.size.width += trailingDelta(deltaX, edge: frame.maxX, boundsEdge: bounds.maxX, length: frame.width, minimumSize: minimumSize)
        case .topLeft, .topRight, .bottomLeft, .bottomRight:
            break
        }
    }
}
