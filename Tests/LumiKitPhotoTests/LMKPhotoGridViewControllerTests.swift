//
//  LMKPhotoGridViewControllerTests.swift
//  LumiKit
//

import Foundation
import LumiKitUI
import Testing
import UIKit
@testable import LumiKitPhoto

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
        #expect(LMKPhotoGridViewController.ContentMode.aspectFit.uiContentMode == .scaleAspectFit)
        #expect(LMKPhotoGridViewController.ContentMode.aspectFill.uiContentMode == .scaleAspectFill)
    }

    @Test
    func `content mode system image names`() {
        #expect(!LMKPhotoGridViewController.ContentMode.aspectFit.systemImageName.isEmpty)
        #expect(!LMKPhotoGridViewController.ContentMode.aspectFill.systemImageName.isEmpty)
        #expect(LMKPhotoGridViewController.ContentMode.aspectFit.systemImageName != LMKPhotoGridViewController.ContentMode.aspectFill.systemImageName)
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
        #expect(!LMKPhotoGridViewController.SortOrder.ascending.systemImageName.isEmpty)
        #expect(!LMKPhotoGridViewController.SortOrder.descending.systemImageName.isEmpty)
        #expect(LMKPhotoGridViewController.SortOrder.ascending.systemImageName != LMKPhotoGridViewController.SortOrder.descending.systemImageName)
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
        let custom = LMKPhotoGridViewController.Strings(
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
        let browserStrings = LMKPhotoBrowserViewController.Strings(emptyText: "Custom Browser Empty")
        grid.browserStrings = browserStrings

        #expect(grid.browserStrings.emptyText == "Custom Browser Empty")
    }

    @Test
    func `browser action button defaults to shown`() {
        let grid = LMKPhotoGridViewController()

        #expect(grid.browserShowsActionButton)
    }

    // MARK: - Sorting

    @Test
    func `sortedIndices puts dated photos first and keeps undated ones in index order`() {
        let base = Date(timeIntervalSince1970: 1_000_000)
        let dates: [Date?] = [base.addingTimeInterval(20), nil, base, base.addingTimeInterval(10), nil, base]
        #expect(LMKPhotoGridViewController.sortedIndices(dates: dates, order: .descending) == [0, 3, 2, 5, 1, 4])
        #expect(LMKPhotoGridViewController.sortedIndices(dates: dates, order: .ascending) == [2, 5, 3, 0, 1, 4])
        #expect(LMKPhotoGridViewController.sortedIndices(dates: [], order: .ascending).isEmpty)
    }

    // MARK: - Selection

    @Test
    func `taps toggle the selection in multi-select mode and report it`() {
        let ds = MockPhotoGridDataSource(photoCount: 3)
        let grid = LMKPhotoGridViewController()
        grid.dataSource = ds
        grid.allowsMultipleSelection = true
        var reported: Set<Int>?
        grid.onSelectionChange = { reported = $0 }
        grid.loadViewIfNeeded()

        grid.collectionView(grid.collectionView, didSelectItemAt: IndexPath(item: 0, section: 0))
        #expect(grid.selectedIndices == [2], "display index 0 is the newest photo (data source index 2)")
        #expect(reported == [2])

        grid.collectionView(grid.collectionView, didSelectItemAt: IndexPath(item: 0, section: 0))
        #expect(grid.selectedIndices.isEmpty)
        #expect(reported?.isEmpty == true)
        #expect(grid.presentedViewController == nil, "multi-select never opens the browser")
    }

    @Test
    func `setSelection is silent, clamps, and clears when multi-select turns off`() {
        let ds = MockPhotoGridDataSource(photoCount: 3)
        let grid = LMKPhotoGridViewController()
        grid.dataSource = ds
        grid.allowsMultipleSelection = true
        var reported = false
        grid.onSelectionChange = { _ in reported = true }
        grid.loadViewIfNeeded()

        grid.setSelection([0, 2, 9], animated: false)
        #expect(grid.selectedIndices == [0, 2])
        #expect(!reported)

        ds.photoCount = 1
        grid.reloadData()
        #expect(grid.selectedIndices == [0], "selections outside the new range drop")

        grid.allowsMultipleSelection = false
        #expect(grid.selectedIndices.isEmpty)
    }

    @Test
    func `context menus come from the provider by data source index`() {
        let ds = MockPhotoGridDataSource(photoCount: 3)
        let grid = LMKPhotoGridViewController()
        grid.dataSource = ds
        grid.loadViewIfNeeded()
        #expect(grid.collectionView(grid.collectionView, contextMenuConfigurationForItemAt: IndexPath(item: 0, section: 0), point: .zero) == nil)

        var requested: Int?
        grid.contextMenuProvider = { index in
            requested = index
            return UIMenu(children: [UIAction(title: "Delete") { _ in }])
        }
        let configuration = grid.collectionView(grid.collectionView, contextMenuConfigurationForItemAt: IndexPath(item: 0, section: 0), point: .zero)
        #expect(configuration != nil)
        #expect(requested == 2)
    }

    @Test
    func `prefetching forwards data source indices`() {
        let ds = MockPhotoGridDataSource(photoCount: 3)
        let grid = LMKPhotoGridViewController()
        grid.dataSource = ds
        grid.loadViewIfNeeded()

        grid.collectionView(grid.collectionView, prefetchItemsAt: [IndexPath(item: 0, section: 0), IndexPath(item: 5, section: 0)])
        grid.collectionView(grid.collectionView, cancelPrefetchingForItemsAt: [IndexPath(item: 1, section: 0)])

        #expect(ds.prefetched == [2])
        #expect(ds.cancelled == [1])
    }

    // MARK: - Style

    @Test
    func `Style resolves through the theme slot and drives the layout`() {
        var theme = LMKTheme.default
        theme.photoGrid = LMKPhotoGridViewController.Style(spacing: 6, showsToolbar: false)
        let ds = MockPhotoGridDataSource(photoCount: 3)
        let grid = LMKPhotoGridViewController()
        grid.dataSource = ds
        grid.traitOverrides.lmkTheme = LMKThemeReference(theme)
        grid.loadViewIfNeeded()

        #expect(grid.resolvedStyle.spacing == 6)
        #expect((grid.collectionView.collectionViewLayout as? UICollectionViewFlowLayout)?.minimumLineSpacing == 6)
        #expect(grid.toolbarView.isHidden)

        grid.style = LMKPhotoGridViewController.Style(showsToolbar: true)
        #expect(grid.toolbarView.isHidden == false)
        #expect(LMKPhotoGridViewController.Style().cellSpacing == 2)
        #expect(LMKPhotoGridViewController.Style(maximumColumnCount: 0).columnCap == 1)
    }

    @Test
    func `browser style is forwarded when presenting`() {
        let ds = MockPhotoGridDataSource(photoCount: 1)
        let grid = LMKPhotoGridViewController()
        grid.dataSource = ds
        grid.browserStyle = LMKPhotoBrowserViewController.Style(chromeTint: .red)

        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 375, height: 812))
        window.rootViewController = grid
        window.makeKeyAndVisible()
        grid.loadViewIfNeeded()

        grid.collectionView(grid.collectionView, didSelectItemAt: IndexPath(item: 0, section: 0))

        let browser = grid.presentedViewController as? LMKPhotoBrowserViewController
        #expect(browser?.style.chromeTint == .red)
        #expect(browser?.transitioningDelegate === browser, "the photo zooms out of the tapped cell")
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
    func `selection state draws the checkmark and the trait`() {
        let cell = LMKPhotoGridCell(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        cell.apply(style: LMKPhotoGridViewController.Style(), theme: .default)
        #expect(cell.showsSelected == false)
        #expect(!cell.accessibilityTraits.contains(.selected))

        cell.setShowsSelected(true)
        #expect(cell.showsSelected)
        #expect(cell.accessibilityTraits.contains(.selected))

        cell.prepareForReuse()
        #expect(cell.showsSelected == false)
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
    var prefetched: [Int] = []
    var cancelled: [Int] = []
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

    func photoGridPrefetch(indices: [Int]) {
        prefetched.append(contentsOf: indices)
    }

    func photoGridCancelPrefetch(indices: [Int]) {
        cancelled.append(contentsOf: indices)
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
