//
//  LMKPhotoGridGestureTests.swift
//  LumiKit
//
//  The grid's pinch anchoring, drag-to-select, auto-scroll, and press feedback.
//

import LumiKitUI
import Testing
import UIKit
@testable import LumiKitPhoto

@MainActor
struct LMKPhotoGridGestureTests {
    private func makeGrid(count: Int = 60, columns: Int = 3, selecting: Bool = false) -> (LMKPhotoGridViewController, GridPhotos) {
        let dataSource = GridPhotos(count: count)
        let grid = LMKPhotoGridViewController(columnCount: columns, style: LMKPhotoGridViewController.Style(haptics: false))
        grid.dataSource = dataSource
        grid.allowsMultipleSelection = selecting
        grid.view.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        grid.view.layoutIfNeeded()
        return (grid, dataSource)
    }

    // MARK: - Geometry

    @Test
    func `Grid geometry matches the flow layout`() {
        // 390 wide, 3 columns, 2pt gaps: floor(386 / 3) = 128, the remainder spread over the gaps.
        #expect(LMKPhotoGridViewController.cellSide(columnCount: 3, width: 390, spacing: 2) == 128)
        let last = LMKPhotoGridViewController.frame(ofItem: 5, columnCount: 3, width: 390, spacing: 2)
        #expect(last.maxX == 390, "the last column ends at the edge")
        #expect(last.minY == 130)
        #expect(LMKPhotoGridViewController.item(at: CGPoint(x: 10, y: 10), columnCount: 3, itemCount: 60, width: 390, spacing: 2) == 0)
        #expect(LMKPhotoGridViewController.item(at: CGPoint(x: 380, y: 140), columnCount: 3, itemCount: 60, width: 390, spacing: 2) == 5)
        // Past the last row and outside the grid the nearest photo answers.
        #expect(LMKPhotoGridViewController.item(at: CGPoint(x: 380, y: 90000), columnCount: 3, itemCount: 60, width: 390, spacing: 2) == 59)
        #expect(LMKPhotoGridViewController.item(at: CGPoint(x: -20, y: -20), columnCount: 3, itemCount: 60, width: 390, spacing: 2) == 0)
        #expect(LMKPhotoGridViewController.item(at: CGPoint(x: 380, y: 10), columnCount: 3, itemCount: 2, width: 390, spacing: 2) == 1)

        let (grid, _) = makeGrid()
        let attributes = grid.collectionView.layoutAttributesForItem(at: IndexPath(item: 7, section: 0))
        #expect(attributes?.frame == LMKPhotoGridViewController.frame(ofItem: 7, columnCount: 3, width: 390, spacing: 2))
    }

    // MARK: - Pinch

    @Test
    func `A column step keeps the photo under the fingers where it was`() throws {
        let (grid, _) = makeGrid(count: 300)
        grid.collectionView.contentOffset.y = 1300
        let point = CGPoint(x: 200, y: 400)
        let anchor = try #require(grid.anchor(atViewportPoint: point))
        let before = LMKPhotoGridViewController.frame(ofItem: anchor.item, columnCount: 3, width: 390, spacing: 2)
        #expect(before.contains(CGPoint(x: 200, y: 1700)))

        #expect(grid.setColumnCount(2, animated: false, anchor: anchor))
        #expect(grid.columnCount == 2)
        let after = LMKPhotoGridViewController.frame(ofItem: anchor.item, columnCount: 2, width: 390, spacing: 2)
        let spotY = after.minY + anchor.unitPoint.y * after.height - grid.collectionView.contentOffset.y
        #expect(abs(spotY - point.y) < 0.5, "the pinched photo moved \(spotY - point.y)pt")

        #expect(grid.setColumnCount(5, animated: false, anchor: grid.anchor(atViewportPoint: point)))
        let again = LMKPhotoGridViewController.frame(ofItem: anchor.item, columnCount: 5, width: 390, spacing: 2)
        let spotAgain = again.minY + anchor.unitPoint.y * again.height - grid.collectionView.contentOffset.y
        #expect(abs(spotAgain - point.y) < 0.5)
    }

    @Test
    func `The anchored offset stays inside the scrollable range`() throws {
        let (grid, _) = makeGrid(count: 9)
        // Nine photos in three rows do not fill the page: nothing to scroll to.
        let anchor = try #require(grid.anchor(atViewportPoint: CGPoint(x: 100, y: 700)))
        grid.setColumnCount(2, animated: false, anchor: anchor)
        let minimum = -grid.collectionView.adjustedContentInset.top
        #expect(grid.collectionView.contentOffset.y >= minimum - 0.5)
        #expect(grid.anchor(atViewportPoint: .zero) != nil)

        let (empty, _) = makeGrid(count: 0)
        #expect(empty.anchor(atViewportPoint: CGPoint(x: 100, y: 100)) == nil)
    }

    @Test
    func `The public column setter anchors the middle of the grid and respects the limits`() {
        let (grid, _) = makeGrid(count: 300)
        grid.collectionView.contentOffset.y = 2000
        grid.setColumnCount(4, animated: false)
        #expect(grid.columnCount == 4)
        #expect(grid.collectionView.contentOffset.y != 2000, "the offset follows the photo, not the number")
        #expect(!grid.setColumnCount(4, animated: false, anchor: nil), "no change, no step")
        grid.setColumnCount(99, animated: false)
        #expect(grid.columnCount == grid.maximumColumnCount)
    }

    // MARK: - Drag to select

    @Test
    func `A drag selects every photo between its first cell and the finger`() {
        let sorted = Array(0 ..< 12)
        #expect(LMKPhotoGridViewController.selection(baseline: [], origin: 1, current: 4, selects: true, sortedIndices: sorted) == [1, 2, 3, 4])
        // Backwards works the same; the baseline outside the sweep is kept.
        #expect(LMKPhotoGridViewController.selection(baseline: [9], origin: 4, current: 1, selects: true, sortedIndices: sorted) == [1, 2, 3, 4, 9])
        // Shrinking the sweep gives photos back to the baseline.
        #expect(LMKPhotoGridViewController.selection(baseline: [9], origin: 4, current: 3, selects: true, sortedIndices: sorted) == [3, 4, 9])
        // A drag that began on a selected photo deselects.
        #expect(LMKPhotoGridViewController.selection(baseline: [1, 2, 3, 9], origin: 2, current: 9, selects: false, sortedIndices: sorted) == [1])
        // Display order maps through the sort.
        #expect(LMKPhotoGridViewController.selection(baseline: [], origin: 0, current: 1, selects: true, sortedIndices: [7, 3, 5]) == [7, 3])
        #expect(LMKPhotoGridViewController.selection(baseline: [2], origin: 0, current: 5, selects: true, sortedIndices: []) == [2])
    }

    @Test
    func `A sideways drag selects while selecting; a vertical one scrolls`() {
        let (grid, _) = makeGrid(selecting: true)
        #expect(grid.shouldBeginSelectionDrag(translation: CGPoint(x: 12, y: 3)))
        #expect(grid.shouldBeginSelectionDrag(translation: CGPoint(x: -12, y: 3)))
        #expect(!grid.shouldBeginSelectionDrag(translation: CGPoint(x: 3, y: 12)))
        grid.allowsMultipleSelection = false
        #expect(!grid.shouldBeginSelectionDrag(translation: CGPoint(x: 12, y: 3)), "outside selection a drag is a scroll")
        let (empty, _) = makeGrid(count: 0, selecting: true)
        #expect(!empty.shouldBeginSelectionDrag(translation: CGPoint(x: 12, y: 3)))
    }

    @Test
    func `Dragging across cells selects, reports, and shrinks back`() {
        let (grid, _) = makeGrid(selecting: true)
        var reports: [Set<Int>] = []
        grid.onSelectionChange = { reports.append($0) }

        grid.beginDragSelection(atContentPoint: CGPoint(x: 10, y: 10))
        #expect(grid.selectedIndices == [0])
        grid.updateDragSelection(toContentPoint: CGPoint(x: 380, y: 10))
        #expect(grid.selectedIndices == [0, 1, 2])
        grid.updateDragSelection(toContentPoint: CGPoint(x: 200, y: 140))
        #expect(grid.selectedIndices == [0, 1, 2, 3, 4], "down a row: everything in between in display order")
        grid.updateDragSelection(toContentPoint: CGPoint(x: 200, y: 10))
        #expect(grid.selectedIndices == [0, 1], "back up: the sweep shrinks")
        grid.updateDragSelection(toContentPoint: CGPoint(x: 210, y: 12))
        #expect(reports.count == 4, "moving inside one cell reports nothing")
        grid.endDragSelection()
        #expect(grid.dragSelection == nil)

        // A second drag starting on a selected photo deselects.
        grid.beginDragSelection(atContentPoint: CGPoint(x: 140, y: 10))
        grid.updateDragSelection(toContentPoint: CGPoint(x: 10, y: 10))
        #expect(grid.selectedIndices.isEmpty)
        grid.endDragSelection()
        #expect(grid.autoScrollLink == nil)
    }

    @Test
    func `Auto-scroll speeds up toward the edges and rests in the middle`() {
        func velocity(_ y: CGFloat) -> CGFloat {
            LMKPhotoGridViewController.autoScrollVelocity(viewportY: y, height: 800, topInset: 100, bottomInset: 60, band: 72, maximumSpeed: 900)
        }
        #expect(velocity(400) == 0)
        #expect(velocity(172) == 0)
        #expect(velocity(136) == -450, "halfway into the top band")
        #expect(velocity(100) == -900)
        #expect(velocity(0) == -900, "clamped past the band")
        #expect(velocity(668) == 0)
        #expect(velocity(704) == 450)
        #expect(velocity(800) == 900)
        #expect(LMKPhotoGridViewController.autoScrollVelocity(viewportY: 10, height: 0, topInset: 0, bottomInset: 0, band: 72, maximumSpeed: 900) == 0)
    }

    @Test
    func `An auto-scroll tick moves the grid inside its range`() {
        let (grid, _) = makeGrid(count: 300, selecting: true)
        grid.beginDragSelection(atContentPoint: CGPoint(x: 10, y: 10))
        grid.autoScrollVelocity = 600
        grid.autoScrollTick(duration: 0.5)
        #expect(grid.collectionView.contentOffset.y == 300 - grid.collectionView.adjustedContentInset.top || grid.collectionView.contentOffset.y == 300)
        grid.autoScrollVelocity = -100_000
        grid.autoScrollTick(duration: 1)
        #expect(grid.collectionView.contentOffset.y == -grid.collectionView.adjustedContentInset.top, "never past the top")
        grid.endDragSelection()
        grid.autoScrollVelocity = 600
        grid.autoScrollTick(duration: 0.5)
        #expect(grid.autoScrollVelocity == 0, "no drag, no scroll")
    }

    // MARK: - Press and menus

    @Test
    func `A touch dims the photo and a release restores it`() {
        UIView.setAnimationsEnabled(false)
        defer { UIView.setAnimationsEnabled(true) }
        let cell = LMKPhotoGridCell(frame: CGRect(x: 0, y: 0, width: 120, height: 120))
        cell.apply(style: LMKPhotoGridViewController.Style(), theme: LMKTheme.default)
        #expect(!cell.isPressed)
        cell.setPressed(true, animated: false)
        #expect(cell.isPressed)
        cell.setPressed(false, animated: false)
        #expect(!cell.isPressed)
        cell.setPressed(true, animated: false)
        cell.prepareForReuse()
        #expect(!cell.isPressed, "a recycled cell starts bright")
    }

    @Test
    func `No context menu opens in the middle of a pinch or a selection drag`() {
        let (grid, _) = makeGrid(selecting: true)
        grid.contextMenuProvider = { _ in UIMenu(children: [UIAction(title: "Share") { _ in }]) }
        let indexPath = IndexPath(item: 0, section: 0)
        #expect(grid.collectionView(grid.collectionView, contextMenuConfigurationForItemAt: indexPath, point: .zero) != nil)
        grid.beginDragSelection(atContentPoint: CGPoint(x: 10, y: 10))
        #expect(grid.collectionView(grid.collectionView, contextMenuConfigurationForItemAt: indexPath, point: .zero) == nil)
        grid.endDragSelection()
        grid.pinchAnchor = grid.anchor(atViewportPoint: CGPoint(x: 100, y: 100))
        #expect(grid.collectionView(grid.collectionView, contextMenuConfigurationForItemAt: indexPath, point: .zero) == nil)
    }

    @Test
    func `Style carries the pinch lean and the pressed alpha`() {
        #expect(LMKPhotoGridViewController.Style().pinchLean == 0.12)
        #expect(LMKPhotoGridViewController.Style(pinchFeedback: 0).pinchLean == 0)
        #expect(LMKPhotoGridViewController.Style(pinchFeedback: 4).pinchLean == 1)
        let merged = LMKPhotoGridViewController.Style(pinchFeedback: 0.2, pressedAlpha: 0.5).merging(LMKPhotoGridViewController.Style(spacing: 4))
        #expect(merged.pinchFeedback == 0.2)
        #expect(merged.pressedAlpha == 0.5)
    }
}
