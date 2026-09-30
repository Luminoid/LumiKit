//
//  LMKPhotoGridViewController+Gestures.swift
//  LumiKit
//
//  The grid's pinch (column steps anchored under the fingers) and the
//  drag-to-select pan with edge auto-scroll.
//

import LumiKitUI
import UIKit

extension LMKPhotoGridViewController {
    // MARK: - Anchor

    /// A photo and the spot inside it that a layout change keeps in place on screen.
    struct GridAnchor: Equatable {
        /// Display index of the photo.
        var item: Int
        /// The spot inside the photo's cell, 0...1 on both axes.
        var unitPoint: CGPoint
        /// Where that spot sits in the grid's viewport.
        var viewportPoint: CGPoint
    }

    /// The photo under `viewportPoint` (the nearest one when the point is in a gap or past the
    /// last row), or `nil` while the grid is empty.
    func anchor(atViewportPoint viewportPoint: CGPoint) -> GridAnchor? {
        guard !sortedIndices.isEmpty, collectionView.bounds.width > 0 else { return nil }
        let contentPoint = CGPoint(x: viewportPoint.x + collectionView.contentOffset.x, y: viewportPoint.y + collectionView.contentOffset.y)
        let item = Self.item(at: contentPoint, columnCount: columnCount, itemCount: sortedIndices.count, width: collectionView.bounds.width, spacing: resolvedStyle.cellSpacing)
        let frame = Self.frame(ofItem: item, columnCount: columnCount, width: collectionView.bounds.width, spacing: resolvedStyle.cellSpacing)
        guard frame.width > 0, frame.height > 0 else { return nil }
        let unit = CGPoint(
            x: min(max((contentPoint.x - frame.minX) / frame.width, 0), 1),
            y: min(max((contentPoint.y - frame.minY) / frame.height, 0), 1)
        )
        return GridAnchor(item: item, unitPoint: unit, viewportPoint: viewportPoint)
    }

    /// The content offset that puts `anchor`'s spot back at its viewport point in the current
    /// layout, clamped to the scrollable range.
    func contentOffset(keeping anchor: GridAnchor) -> CGPoint? {
        guard collectionView.bounds.width > 0, anchor.item < sortedIndices.count else { return nil }
        let frame = Self.frame(ofItem: anchor.item, columnCount: columnCount, width: collectionView.bounds.width, spacing: resolvedStyle.cellSpacing)
        let target = frame.minY + anchor.unitPoint.y * frame.height - anchor.viewportPoint.y
        let insets = collectionView.adjustedContentInset
        let rows = ceil(CGFloat(sortedIndices.count) / CGFloat(columnCount))
        let contentHeight = rows * frame.height + max(0, rows - 1) * resolvedStyle.cellSpacing
        let minimum = -insets.top
        let maximum = max(minimum, contentHeight + insets.bottom - collectionView.bounds.height)
        return CGPoint(x: collectionView.contentOffset.x, y: min(max(target, minimum), maximum))
    }

    // MARK: - Grid geometry

    /// Side of a square cell.
    nonisolated static func cellSide(columnCount: Int, width: CGFloat, spacing: CGFloat) -> CGFloat {
        let columns = max(1, columnCount)
        return max(1, floor((width - spacing * CGFloat(columns - 1)) / CGFloat(columns)))
    }

    /// Frame of the cell at a display index, in content coordinates.
    nonisolated static func frame(ofItem item: Int, columnCount: Int, width: CGFloat, spacing: CGFloat) -> CGRect {
        let columns = max(1, columnCount)
        let side = cellSide(columnCount: columns, width: width, spacing: spacing)
        let row = item / columns
        let column = item % columns
        // The flow layout spreads the rounding remainder over the gaps; the last column ends at the edge.
        let gap = columns > 1 ? (width - side * CGFloat(columns)) / CGFloat(columns - 1) : 0
        return CGRect(x: CGFloat(column) * (side + gap), y: CGFloat(row) * (side + spacing), width: side, height: side)
    }

    /// Display index of the cell at (or nearest to) a content point.
    nonisolated static func item(at point: CGPoint, columnCount: Int, itemCount: Int, width: CGFloat, spacing: CGFloat) -> Int {
        guard itemCount > 0 else { return 0 }
        let columns = max(1, columnCount)
        let side = cellSide(columnCount: columns, width: width, spacing: spacing)
        let gap = columns > 1 ? (width - side * CGFloat(columns)) / CGFloat(columns - 1) : 0
        let lastRow = (itemCount - 1) / columns
        let row = min(max(Int(floor(point.y / (side + spacing))), 0), lastRow)
        let column = min(max(Int(floor(point.x / (side + gap))), 0), columns - 1)
        return min(row * columns + column, itemCount - 1)
    }

    // MARK: - Pinch

    @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        switch gesture.state {
        case .began:
            guard dragSelection == nil else {
                gesture.state = .cancelled
                return
            }
            pinchAnchor = anchor(atViewportPoint: viewportPoint(of: gesture))
            // The two fingers also drag: the scroll view would slide the grid out from under the pinch.
            scrollWasEnabledBeforePinch = collectionView.isScrollEnabled
            collectionView.isScrollEnabled = false
        case .changed:
            let threshold = resolvedStyle.pinchStep
            var stepped = false
            if gesture.scale > 1 + threshold {
                // Pinch out: larger cells, fewer columns.
                stepped = setColumnCount(columnCount - 1, animated: true, anchor: pinchAnchor)
                gesture.scale = 1
            } else if gesture.scale < 1 - threshold {
                stepped = setColumnCount(columnCount + 1, animated: true, anchor: pinchAnchor)
                gesture.scale = 1
            }
            if stepped {
                // The fingers moved since the pinch began: re-anchor where they are now.
                pinchAnchor = anchor(atViewportPoint: viewportPoint(of: gesture))
            }
            applyPinchLean(scale: gesture.scale)
        case .ended, .cancelled, .failed:
            pinchAnchor = nil
            collectionView.isScrollEnabled = scrollWasEnabledBeforePinch
            releasePinchLean()
        default:
            break
        }
    }

    private func viewportPoint(of gesture: UIGestureRecognizer) -> CGPoint {
        let location = gesture.location(in: collectionView)
        return CGPoint(x: location.x - collectionView.contentOffset.x, y: location.y - collectionView.contentOffset.y)
    }

    /// Scales the grid a little around the pinch between steps, so the pinch answers at once.
    /// At the first or last column count the lean is all the pinch does.
    private func applyPinchLean(scale: CGFloat) {
        let lean = resolvedStyle.pinchLean
        guard lean > 0, LMKAnimation.shouldAnimate, let anchor = pinchAnchor else { return }
        let factor = 1 + (scale - 1) * lean
        let center = CGPoint(x: collectionView.bounds.width / 2, y: collectionView.bounds.height / 2)
        let tx = (anchor.viewportPoint.x - center.x) * (1 - factor)
        let ty = (anchor.viewportPoint.y - center.y) * (1 - factor)
        collectionView.transform = CGAffineTransform(a: factor, b: 0, c: 0, d: factor, tx: tx, ty: ty)
    }

    private func releasePinchLean() {
        guard !collectionView.transform.isIdentity else { return }
        guard LMKAnimation.shouldAnimate else {
            collectionView.transform = .identity
            return
        }
        UIView.animate(
            withDuration: LMKAnimation.Duration.normal,
            delay: 0,
            usingSpringWithDamping: LMKAnimation.spring.damping,
            initialSpringVelocity: 0,
            options: [.allowUserInteraction, .beginFromCurrentState]
        ) {
            self.collectionView.transform = .identity
        }
    }

    // MARK: - Drag to select

    /// One drag across the grid while selecting.
    struct DragSelection: Equatable {
        /// Display index where the drag began.
        var origin: Int
        /// Whether the drag selects (it began on an unselected photo) or deselects.
        var selects: Bool
        /// The selection when the drag began, as data source indices.
        var baseline: Set<Int>
        /// Display index under the finger.
        var current: Int
    }

    /// The selection a drag from `origin` to `current` produces: every photo between the two
    /// (in display order) selected or deselected on top of the baseline.
    nonisolated static func selection(baseline: Set<Int>, origin: Int, current: Int, selects: Bool, sortedIndices: [Int]) -> Set<Int> {
        guard !sortedIndices.isEmpty else { return baseline }
        let lower = max(0, min(origin, current))
        let upper = min(sortedIndices.count - 1, max(origin, current))
        guard lower <= upper else { return baseline }
        let swept = Set(sortedIndices[lower ... upper])
        return selects ? baseline.union(swept) : baseline.subtracting(swept)
    }

    /// Whether a pan that moved by `translation` so far is a selection drag: selecting is on
    /// and the finger moves more sideways than up or down (a vertical drag scrolls).
    func shouldBeginSelectionDrag(translation: CGPoint) -> Bool {
        allowsMultipleSelection && pinchAnchor == nil && !sortedIndices.isEmpty && abs(translation.x) > abs(translation.y)
    }

    @objc func handleSelectionPan(_ gesture: UIPanGestureRecognizer) {
        let location = gesture.location(in: collectionView)
        switch gesture.state {
        case .began:
            let start = CGPoint(x: location.x - gesture.translation(in: collectionView).x, y: location.y - gesture.translation(in: collectionView).y)
            beginDragSelection(atContentPoint: start)
            updateDragSelection(toContentPoint: location)
        case .changed:
            updateDragSelection(toContentPoint: location)
            updateAutoScroll(forViewportY: location.y - collectionView.contentOffset.y)
        case .ended, .cancelled, .failed:
            endDragSelection()
        default:
            break
        }
    }

    func beginDragSelection(atContentPoint point: CGPoint) {
        guard !sortedIndices.isEmpty else { return }
        let origin = Self.item(at: point, columnCount: columnCount, itemCount: sortedIndices.count, width: collectionView.bounds.width, spacing: resolvedStyle.cellSpacing)
        let selects = !selectedIndices.contains(sortedIndices[origin])
        dragSelection = DragSelection(origin: origin, selects: selects, baseline: selectedIndices, current: origin)
        applyUserSelection(Self.selection(baseline: selectedIndices, origin: origin, current: origin, selects: selects, sortedIndices: sortedIndices))
    }

    func updateDragSelection(toContentPoint point: CGPoint) {
        guard var drag = dragSelection, !sortedIndices.isEmpty else { return }
        let current = Self.item(at: point, columnCount: columnCount, itemCount: sortedIndices.count, width: collectionView.bounds.width, spacing: resolvedStyle.cellSpacing)
        guard current != drag.current else { return }
        drag.current = current
        dragSelection = drag
        applyUserSelection(Self.selection(baseline: drag.baseline, origin: drag.origin, current: current, selects: drag.selects, sortedIndices: sortedIndices))
    }

    func endDragSelection() {
        dragSelection = nil
        stopAutoScroll()
    }

    // MARK: - Auto-scroll

    /// Points per second at the very edge, and the band near each edge where scrolling starts.
    private static let autoScrollMaximumSpeed: CGFloat = 900
    private static let autoScrollBand: CGFloat = 72

    /// Scroll speed for a finger at `viewportY`: zero in the middle, rising toward each edge.
    nonisolated static func autoScrollVelocity(viewportY: CGFloat, height: CGFloat, topInset: CGFloat, bottomInset: CGFloat, band: CGFloat, maximumSpeed: CGFloat) -> CGFloat {
        guard height > 0, band > 0 else { return 0 }
        let top = topInset + band
        let bottom = height - bottomInset - band
        if viewportY < top {
            return -maximumSpeed * min(1, (top - viewportY) / band)
        }
        if viewportY > bottom {
            return maximumSpeed * min(1, (viewportY - bottom) / band)
        }
        return 0
    }

    private func updateAutoScroll(forViewportY viewportY: CGFloat) {
        let insets = collectionView.adjustedContentInset
        autoScrollVelocity = Self.autoScrollVelocity(
            viewportY: viewportY,
            height: collectionView.bounds.height,
            topInset: insets.top,
            bottomInset: insets.bottom,
            band: Self.autoScrollBand,
            maximumSpeed: Self.autoScrollMaximumSpeed
        )
        if autoScrollVelocity == 0 {
            stopAutoScroll()
        } else if autoScrollLink == nil {
            let link = CADisplayLink(target: LMKPhotoGridDisplayLinkTarget(owner: self), selector: #selector(LMKPhotoGridDisplayLinkTarget.tick(_:)))
            link.add(to: .main, forMode: .common)
            autoScrollLink = link
        }
    }

    func stopAutoScroll() {
        autoScrollLink?.invalidate()
        autoScrollLink = nil
        autoScrollVelocity = 0
    }

    /// One display frame of auto-scroll: moves the grid and extends the selection to the photo
    /// now under the finger.
    func autoScrollTick(duration: CFTimeInterval) {
        guard dragSelection != nil, autoScrollVelocity != 0 else {
            stopAutoScroll()
            return
        }
        let insets = collectionView.adjustedContentInset
        let minimum = -insets.top
        let maximum = max(minimum, collectionView.contentSize.height + insets.bottom - collectionView.bounds.height)
        let target = min(max(collectionView.contentOffset.y + autoScrollVelocity * CGFloat(duration), minimum), maximum)
        guard target != collectionView.contentOffset.y else { return }
        collectionView.contentOffset.y = target
        updateDragSelection(toContentPoint: selectionPanGesture.location(in: collectionView))
    }
}

// MARK: - Helpers

/// The selection pan's delegate, kept off the grid's public surface.
final class LMKPhotoGridGestureDelegate: NSObject, UIGestureRecognizerDelegate {
    private weak var owner: LMKPhotoGridViewController?

    init(owner: LMKPhotoGridViewController) {
        self.owner = owner
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let owner, let pan = gestureRecognizer as? UIPanGestureRecognizer, pan === owner.selectionPanGesture else { return true }
        return owner.shouldBeginSelectionDrag(translation: pan.translation(in: owner.collectionView))
    }
}

/// A display link retains its target; this one holds the grid weakly.
final class LMKPhotoGridDisplayLinkTarget: NSObject {
    private weak var owner: LMKPhotoGridViewController?

    init(owner: LMKPhotoGridViewController) {
        self.owner = owner
    }

    @objc func tick(_ link: CADisplayLink) {
        guard let owner else {
            link.invalidate()
            return
        }
        owner.autoScrollTick(duration: link.targetTimestamp - link.timestamp)
    }
}
