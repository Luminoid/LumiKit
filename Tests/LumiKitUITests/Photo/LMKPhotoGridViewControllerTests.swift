//
//  LMKPhotoGridViewControllerTests.swift
//  LumiKit
//

import Foundation
import Testing
import UIKit
@testable import LumiKitUI

@MainActor
struct LMKPhotoGridViewControllerTests {
    // MARK: - Initialization

    @Test
    func `default column count`() {
        let grid = LMKPhotoGridViewController()

        #expect(grid.columnCount == 2)
    }

    @Test
    func `custom column count`() {
        let grid = LMKPhotoGridViewController(columnCount: 4)

        #expect(grid.columnCount == 4)
    }

    @Test
    func `column count clamped to minimum`() {
        let grid = LMKPhotoGridViewController(columnCount: 0)

        #expect(grid.columnCount == 1)
    }

    @Test
    func `default content mode`() {
        let grid = LMKPhotoGridViewController()

        #expect(grid.photoContentMode == .aspectFill)
    }

    @Test
    func `default sort order`() {
        let grid = LMKPhotoGridViewController()

        #expect(grid.sortOrder == .descending)
    }

    // MARK: - View Loading

    @Test
    func `loads view without crashing`() {
        let ds = MockPhotoGridDataSource(photoCount: 5)
        let grid = LMKPhotoGridViewController()
        grid.dataSource = ds

        grid.loadViewIfNeeded()

        #expect(grid.isViewLoaded)
    }

    @Test
    func `handles empty data source`() {
        let ds = MockPhotoGridDataSource(photoCount: 0)
        let grid = LMKPhotoGridViewController()
        grid.dataSource = ds

        grid.loadViewIfNeeded()

        #expect(grid.isViewLoaded)
    }

    @Test
    func `handles nil data source`() {
        let grid = LMKPhotoGridViewController()

        grid.loadViewIfNeeded()

        #expect(grid.isViewLoaded)
    }

    // MARK: - Data Source & Delegate

    @Test
    func `accepts data source assignment`() {
        let grid = LMKPhotoGridViewController()
        let ds = MockPhotoGridDataSource(photoCount: 3)
        grid.dataSource = ds

        #expect(grid.dataSource != nil)
    }

    @Test
    func `accepts delegate assignment`() {
        let grid = LMKPhotoGridViewController()
        let delegate = MockPhotoGridDelegate()
        grid.delegate = delegate

        #expect(grid.delegate != nil)
    }

    // MARK: - Content Mode

    @Test
    func `set content mode updates property`() {
        let grid = LMKPhotoGridViewController()
        grid.loadViewIfNeeded()

        grid.setContentMode(.aspectFit)

        #expect(grid.photoContentMode == .aspectFit)
    }

    @Test
    func `toggle content mode switches between modes`() {
        let grid = LMKPhotoGridViewController()
        grid.loadViewIfNeeded()

        #expect(grid.photoContentMode == .aspectFill)
        grid.toggleContentMode()
        #expect(grid.photoContentMode == .aspectFit)
        grid.toggleContentMode()
        #expect(grid.photoContentMode == .aspectFill)
    }

    @Test
    func `content mode UI content mode mapping`() {
        #expect(LMKPhotoGridContentMode.aspectFit.uiContentMode == .scaleAspectFit)
        #expect(LMKPhotoGridContentMode.aspectFill.uiContentMode == .scaleAspectFill)
    }

    @Test
    func `content mode system image names`() {
        #expect(!LMKPhotoGridContentMode.aspectFit.systemImageName.isEmpty)
        #expect(!LMKPhotoGridContentMode.aspectFill.systemImageName.isEmpty)
        #expect(LMKPhotoGridContentMode.aspectFit.systemImageName != LMKPhotoGridContentMode.aspectFill.systemImageName)
    }

    // MARK: - Sort Order

    @Test
    func `set sort order updates property`() {
        let ds = MockPhotoGridDataSource(photoCount: 3)
        let grid = LMKPhotoGridViewController()
        grid.dataSource = ds
        grid.loadViewIfNeeded()

        grid.setSortOrder(.ascending)

        #expect(grid.sortOrder == .ascending)
    }

    @Test
    func `toggle sort order switches between orders`() {
        let ds = MockPhotoGridDataSource(photoCount: 3)
        let grid = LMKPhotoGridViewController()
        grid.dataSource = ds
        grid.loadViewIfNeeded()

        #expect(grid.sortOrder == .descending)
        grid.toggleSortOrder()
        #expect(grid.sortOrder == .ascending)
        grid.toggleSortOrder()
        #expect(grid.sortOrder == .descending)
    }

    @Test
    func `sort order system image names`() {
        #expect(!LMKPhotoGridSortOrder.ascending.systemImageName.isEmpty)
        #expect(!LMKPhotoGridSortOrder.descending.systemImageName.isEmpty)
        #expect(LMKPhotoGridSortOrder.ascending.systemImageName != LMKPhotoGridSortOrder.descending.systemImageName)
    }

    // MARK: - Column Count

    @Test
    func `set column count updates property`() {
        let grid = LMKPhotoGridViewController()
        grid.loadViewIfNeeded()

        grid.setColumnCount(3, animated: false)

        #expect(grid.columnCount == 3)
    }

    @Test
    func `set column count clamped to minimum`() {
        let grid = LMKPhotoGridViewController()
        grid.loadViewIfNeeded()

        grid.setColumnCount(0, animated: false)

        #expect(grid.columnCount == 1)
    }

    @Test
    func `same column count does not change`() {
        let grid = LMKPhotoGridViewController()
        grid.loadViewIfNeeded()
        let initial = grid.columnCount

        grid.setColumnCount(initial, animated: false)

        #expect(grid.columnCount == initial)
    }

    // MARK: - Strings Configuration

    @Test
    func `default strings are set`() {
        let grid = LMKPhotoGridViewController()

        #expect(!grid.strings.emptyText.isEmpty)
        #expect(!grid.strings.sortAscendingLabel.isEmpty)
        #expect(!grid.strings.sortDescendingLabel.isEmpty)
        #expect(!grid.strings.aspectFitLabel.isEmpty)
        #expect(!grid.strings.aspectFillLabel.isEmpty)
    }

    @Test
    func `custom strings can be set`() {
        let grid = LMKPhotoGridViewController()
        let custom = LMKPhotoGridStrings(
            emptyText: "Empty",
            sortAscendingLabel: "Asc",
            sortDescendingLabel: "Desc",
            aspectFitLabel: "Fit",
            aspectFillLabel: "Fill"
        )
        grid.strings = custom

        #expect(grid.strings.emptyText == "Empty")
        #expect(grid.strings.sortAscendingLabel == "Asc")
        #expect(grid.strings.sortDescendingLabel == "Desc")
        #expect(grid.strings.aspectFitLabel == "Fit")
        #expect(grid.strings.aspectFillLabel == "Fill")
    }

    // MARK: - Photo Browser Integration

    @Test
    func `conforms to photo browser data source`() async {
        let ds = MockPhotoGridDataSource(photoCount: 5)
        let grid = LMKPhotoGridViewController()
        grid.dataSource = ds
        grid.loadViewIfNeeded()

        let browserDS: any LMKPhotoBrowserDataSource = grid

        #expect(browserDS.numberOfPhotos == 5)
        let photo = await browserDS.photo(at: 0)
        #expect(photo != nil)
        #expect(browserDS.photoSubtitle(at: 0) == nil)
    }

    @Test
    func `browser data source maps dates through sorted indices`() {
        let ds = MockPhotoGridDataSource(photoCount: 3, datesDescending: true)
        let grid = LMKPhotoGridViewController()
        grid.dataSource = ds
        grid.loadViewIfNeeded()

        let browserDS: any LMKPhotoBrowserDataSource = grid

        // In descending order (default), the dates should be mapped through sorted indices
        let date0 = browserDS.photoDate(at: 0)
        let date1 = browserDS.photoDate(at: 1)
        #expect(date0 != nil)
        #expect(date1 != nil)
        if let d0 = date0, let d1 = date1 {
            #expect(d0 >= d1)
        }
    }

    @Test
    func `browser data source returns nil for out of bounds index`() async {
        let ds = MockPhotoGridDataSource(photoCount: 3)
        let grid = LMKPhotoGridViewController()
        grid.dataSource = ds
        grid.loadViewIfNeeded()

        let browserDS: any LMKPhotoBrowserDataSource = grid

        let photo = await browserDS.photo(at: 10)
        #expect(photo == nil)
        #expect(browserDS.photoDate(at: -1) == nil)
    }

    @Test
    func `conforms to photo browser delegate`() {
        let grid = LMKPhotoGridViewController()
        let gridDelegate = MockPhotoGridDelegate()
        let ds = MockPhotoGridDataSource(photoCount: 3)
        grid.dataSource = ds
        grid.delegate = gridDelegate
        grid.loadViewIfNeeded()

        let browserDelegate: any LMKPhotoBrowserDelegate = grid
        let mockBrowser = LMKPhotoBrowserViewController(initialIndex: 0)
        browserDelegate.photoBrowser(mockBrowser, didRequestActionAt: 0)

        #expect(gridDelegate.didRequestActionCalled)
    }

    // MARK: - Reload Data

    @Test
    func `reload data updates counts`() {
        let ds = MockPhotoGridDataSource(photoCount: 3)
        let grid = LMKPhotoGridViewController()
        grid.dataSource = ds
        grid.loadViewIfNeeded()

        let browserDS: any LMKPhotoBrowserDataSource = grid
        #expect(browserDS.numberOfPhotos == 3)

        ds.photoCount = 5
        grid.reloadData()

        #expect(browserDS.numberOfPhotos == 5)
    }

    // MARK: - Lifecycle

    @Test
    func `view controller lifecycle methods`() {
        let ds = MockPhotoGridDataSource(photoCount: 5)
        let grid = LMKPhotoGridViewController()
        grid.dataSource = ds

        grid.loadViewIfNeeded()
        grid.viewWillAppear(false)
        grid.viewDidAppear(false)
        grid.viewDidLayoutSubviews()

        #expect(grid.isViewLoaded)
    }

    @Test
    func `photo browser strings can be customized`() {
        let grid = LMKPhotoGridViewController()
        let browserStrings = LMKPhotoBrowserStrings(emptyText: "Custom Browser Empty")
        grid.photoBrowserStrings = browserStrings

        #expect(grid.photoBrowserStrings.emptyText == "Custom Browser Empty")
    }

    @Test
    func `browser action button defaults to shown`() {
        let grid = LMKPhotoGridViewController()

        #expect(grid.browserShowsActionButton)
    }

    @Test
    func `browser action button visibility is forwarded when presenting`() {
        let ds = MockPhotoGridDataSource(photoCount: 1)
        let grid = LMKPhotoGridViewController()
        grid.dataSource = ds
        grid.browserShowsActionButton = false

        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 375, height: 812))
        window.rootViewController = grid
        window.makeKeyAndVisible()
        grid.loadViewIfNeeded()

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
        grid.collectionView(collectionView, didSelectItemAt: IndexPath(item: 0, section: 0))

        let browser = grid.presentedViewController as? LMKPhotoBrowserViewController
        #expect(browser?.showsActionButton == false)
    }
}

// MARK: - Async Image Loading (LMKPhotoGridCell)

@MainActor
struct LMKPhotoGridCellAsyncImageTests {
    @Test
    func `async load applies the delivered image`() async {
        let cell = LMKPhotoGridCell(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        let image = UIImage.lmk_solidColor(.red, size: CGSize(width: 10, height: 10))

        cell.configure(with: nil, contentMode: .scaleAspectFill)
        #expect(cell.installedImage == nil)
        cell.loadImage { image }

        await settleMainActor()
        #expect(cell.installedImage === image)
    }

    @Test
    func `stale load never lands on a reused cell`() async {
        let cell = LMKPhotoGridCell(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        let staleImage = UIImage.lmk_solidColor(.red, size: CGSize(width: 10, height: 10))
        let freshImage = UIImage.lmk_solidColor(.blue, size: CGSize(width: 10, height: 10))
        let gate = AsyncGate()

        cell.configure(with: nil, contentMode: .scaleAspectFill)
        cell.loadImage {
            await gate.wait()
            return staleImage
        }

        // Reuse the cell for a different item while the first load is in flight.
        cell.prepareForReuse()
        cell.configure(with: nil, contentMode: .scaleAspectFill)
        cell.loadImage { freshImage }
        await settleMainActor()
        #expect(cell.installedImage === freshImage)

        // Release the stale load: its result must be discarded.
        gate.open()
        await settleMainActor()
        #expect(cell.installedImage === freshImage)
    }

    @Test
    func `reconfigure alone invalidates an in-flight load`() async {
        let cell = LMKPhotoGridCell(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        let staleImage = UIImage.lmk_solidColor(.red, size: CGSize(width: 10, height: 10))
        let gate = AsyncGate()

        cell.configure(with: nil, contentMode: .scaleAspectFill)
        cell.loadImage {
            await gate.wait()
            return staleImage
        }

        // A synchronous reconfigure (e.g. the content-mode toggle) supersedes
        // the pending load even without a reuse cycle.
        cell.configure(with: nil, contentMode: .scaleAspectFit)
        gate.open()
        await settleMainActor()
        #expect(cell.installedImage == nil)
    }
}

// MARK: - Mock Data Source

private final class MockPhotoGridDataSource: LMKPhotoGridDataSource {
    var photoCount: Int
    private let datesDescending: Bool

    init(photoCount: Int, datesDescending: Bool = false) {
        self.photoCount = photoCount
        self.datesDescending = datesDescending
    }

    var numberOfPhotos: Int {
        photoCount
    }

    func photoGridImage(at index: Int) async -> UIImage? {
        guard index >= 0, index < photoCount else { return nil }
        return UIImage.lmk_solidColor(.blue, size: CGSize(width: 100, height: 100))
    }

    func photoGridDate(at index: Int) -> Date? {
        guard index >= 0, index < photoCount else { return nil }
        // Generate dates: index 0 is oldest, index N-1 is newest
        let baseDate = Date(timeIntervalSince1970: 1_000_000)
        return baseDate.addingTimeInterval(TimeInterval(index) * 86400)
    }
}

// MARK: - Mock Delegate

private final class MockPhotoGridDelegate: LMKPhotoGridDelegate {
    var didRequestActionCalled = false
    var lastActionIndex: Int?

    func photoGrid(
        _ grid: LMKPhotoGridViewController,
        didRequestActionForPhotoAt index: Int
    ) {
        didRequestActionCalled = true
        lastActionIndex = index
    }
}
