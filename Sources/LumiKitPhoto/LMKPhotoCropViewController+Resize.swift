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
        var result = frame
        if handle.isCorner {
            applyCornerDelta(handle: handle, frame: &result, deltaX: deltaX, deltaY: deltaY, bounds: bounds)
        } else {
            applyEdgeDelta(handle: handle, frame: &result, deltaX: deltaX, deltaY: deltaY, bounds: bounds)
        }
        result.size.width = max(result.width, minimumSize)
        result.size.height = max(result.height, minimumSize)
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
        let anchor = anchorPoint(handle: handle, frame: frame)
        let corner = draggedCorner(handle: handle, frame: frame, deltaX: deltaX, deltaY: deltaY)
        var width = abs(corner.x - anchor.x)
        var height = abs(corner.y - anchor.y)
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

    private nonisolated static func applyCornerDelta(handle: ResizeHandle, frame: inout CGRect, deltaX: CGFloat, deltaY: CGFloat, bounds: CGRect) {
        var limitedX = deltaX
        var limitedY = deltaY
        switch handle {
        case .topLeft:
            if frame.minY + deltaY < bounds.minY { limitedY = bounds.minY - frame.minY }
            if frame.minX + deltaX < bounds.minX { limitedX = bounds.minX - frame.minX }
            frame.origin.x += limitedX
            frame.origin.y += limitedY
            frame.size.width -= limitedX
            frame.size.height -= limitedY
        case .topRight:
            if frame.minY + deltaY < bounds.minY { limitedY = bounds.minY - frame.minY }
            if frame.maxX + deltaX > bounds.maxX { limitedX = bounds.maxX - frame.maxX }
            frame.origin.y += limitedY
            frame.size.width += limitedX
            frame.size.height -= limitedY
        case .bottomLeft:
            if frame.maxY + deltaY > bounds.maxY { limitedY = bounds.maxY - frame.maxY }
            if frame.minX + deltaX < bounds.minX { limitedX = bounds.minX - frame.minX }
            frame.origin.x += limitedX
            frame.size.width -= limitedX
            frame.size.height += limitedY
        case .bottomRight:
            if frame.maxY + deltaY > bounds.maxY { limitedY = bounds.maxY - frame.maxY }
            if frame.maxX + deltaX > bounds.maxX { limitedX = bounds.maxX - frame.maxX }
            frame.size.width += limitedX
            frame.size.height += limitedY
        case .top, .bottom, .left, .right:
            break
        }
    }

    private nonisolated static func applyEdgeDelta(handle: ResizeHandle, frame: inout CGRect, deltaX: CGFloat, deltaY: CGFloat, bounds: CGRect) {
        var limitedX = deltaX
        var limitedY = deltaY
        switch handle {
        case .top:
            if frame.minY + deltaY < bounds.minY { limitedY = bounds.minY - frame.minY }
            frame.origin.y += limitedY
            frame.size.height -= limitedY
        case .bottom:
            if frame.maxY + deltaY > bounds.maxY { limitedY = bounds.maxY - frame.maxY }
            frame.size.height += limitedY
        case .left:
            if frame.minX + deltaX < bounds.minX { limitedX = bounds.minX - frame.minX }
            frame.origin.x += limitedX
            frame.size.width -= limitedX
        case .right:
            if frame.maxX + deltaX > bounds.maxX { limitedX = bounds.maxX - frame.maxX }
            frame.size.width += limitedX
        case .topLeft, .topRight, .bottomLeft, .bottomRight:
            break
        }
    }
}
