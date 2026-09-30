//
//  LMKPhotoGridEdgeEffectsTests.swift
//  LumiKit
//

import LumiKitUI
import Testing
import UIKit
@testable import LumiKitPhoto

@MainActor
struct LMKPhotoGridEdgeEffectsTests {
    @Test
    func `The top edge effect follows the style; the bottom band is off unless asked for`() {
        let grid = LMKPhotoGridViewController()
        grid.loadViewIfNeeded()
        if #available(iOS 26, *) {
            #expect(!grid.toolbarView.interactions.contains { $0 is UIScrollEdgeElementContainerInteraction }, "the toolbar floats on its own glass")
            #expect(!grid.collectionView.topEdgeEffect.isHidden)
            #expect(grid.collectionView.bottomEdgeEffect.isHidden, "photos run to the bottom edge")
            grid.style = LMKPhotoGridViewController.Style(showsScrollEdgeEffects: false, showsBottomEdgeEffect: true)
            #expect(grid.collectionView.topEdgeEffect.isHidden)
            #expect(!grid.collectionView.bottomEdgeEffect.isHidden)
        }
        let merged = LMKPhotoGridViewController.Style(showsScrollEdgeEffects: false, showsBottomEdgeEffect: true).merging(LMKPhotoGridViewController.Style(spacing: 4))
        #expect(merged.showsScrollEdgeEffects == false)
        #expect(merged.showsBottomEdgeEffect == true)
    }

    @Test
    func `The grid keeps room at its end for the floating toolbar`() {
        let dataSource = GridPhotos(count: 30)
        let grid = LMKPhotoGridViewController(columnCount: 3)
        grid.dataSource = dataSource
        grid.view.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        grid.view.layoutIfNeeded()
        let room = grid.toolbarView.bounds.height + LMKSpacing.medium * 2
        #expect(grid.toolbarView.bounds.height > 0)
        #expect(grid.collectionView.contentInset.bottom == room)

        // No toolbar, no room.
        grid.style = LMKPhotoGridViewController.Style(showsToolbar: false)
        grid.view.layoutIfNeeded()
        #expect(grid.collectionView.contentInset.bottom == 0)
    }
}

@MainActor
final class GridPhotos: LMKPhotoGridDataSource {
    let numberOfPhotos: Int
    private let base = Date(timeIntervalSince1970: 1_700_000_000)

    init(count: Int) {
        numberOfPhotos = count
    }

    func photoGridImage(at _: Int) async -> UIImage? {
        nil
    }

    /// Newest first in display order means data source index 0 shows first.
    func photoGridDate(at index: Int) -> Date? {
        base.addingTimeInterval(TimeInterval(-index * 60))
    }
}
