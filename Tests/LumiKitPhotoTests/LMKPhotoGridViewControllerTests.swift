//
//  LMKPhotoGridViewControllerTests.swift
//  LumiKit
//

import Foundation
import LumiKitUI
import Testing
import UIKit
import UniformTypeIdentifiers
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
    func `the browser bridge serves the grid's photos in display order`() async {
        let ds = MockPhotoGridDataSource(photoCount: 5)
        let grid = LMKPhotoGridViewController()
        grid.dataSource = ds
        grid.loadViewIfNeeded()

        let browserDS: any LMKPhotoBrowserDataSource = grid.browserBridge

        #expect(browserDS.numberOfPhotos == 5)
        let photo = await browserDS.photo(at: 0)
        #expect(photo != nil)
        #expect(ds.fullImageRequests == [4], "display index 0 is the newest photo, and the browser asks for the full-size image")
        #expect(browserDS.photoSubtitle(at: 0) == nil)
        #expect(!(grid is any LMKPhotoBrowserDataSource), "the grid's own members speak data source indices")
        #expect(!(grid is any LMKPhotoBrowserDelegate))
    }

    @Test
    func `the browser bridge maps dates through sorted indices`() {
        let ds = MockPhotoGridDataSource(photoCount: 3, datesDescending: true)
        let grid = LMKPhotoGridViewController()
        grid.dataSource = ds
        grid.loadViewIfNeeded()

        let browserDS: any LMKPhotoBrowserDataSource = grid.browserBridge

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
    func `the browser bridge returns nil for an out of bounds index`() async {
        let ds = MockPhotoGridDataSource(photoCount: 3)
        let grid = LMKPhotoGridViewController()
        grid.dataSource = ds
        grid.loadViewIfNeeded()

        let browserDS: any LMKPhotoBrowserDataSource = grid.browserBridge

        let photo = await browserDS.photo(at: 10)
        #expect(photo == nil)
        #expect(browserDS.photoDate(at: -1) == nil)
    }

    @Test
    func `the browser bridge reports actions by data source index`() {
        let grid = LMKPhotoGridViewController()
        let gridDelegate = MockPhotoGridDelegate()
        let ds = MockPhotoGridDataSource(photoCount: 3)
        grid.dataSource = ds
        grid.delegate = gridDelegate
        grid.loadViewIfNeeded()

        let browserDelegate: any LMKPhotoBrowserDelegate = grid.browserBridge
        let mockBrowser = LMKPhotoBrowserViewController(initialIndex: 0)
        browserDelegate.photoBrowser(mockBrowser, didRequestActionAt: 0)

        #expect(gridDelegate.didRequestActionCalled)
        #expect(gridDelegate.lastActionIndex == 2, "display index 0 is data source index 2")
    }

    @Test
    func `the presented browser is exposed and reloaded with the grid`() {
        let ds = MockPhotoGridDataSource(photoCount: 3)
        let grid = LMKPhotoGridViewController()
        grid.dataSource = ds
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 375, height: 812))
        window.rootViewController = grid
        window.makeKeyAndVisible()
        grid.loadViewIfNeeded()
        #expect(grid.browser == nil)

        grid.collectionView(grid.collectionView, didSelectItemAt: IndexPath(item: 2, section: 0))
        let browser = grid.browser
        #expect(browser != nil)
        #expect(browser === grid.presentedViewController)
        browser?.loadViewIfNeeded()
        browser?.viewWillAppear(false)
        #expect(browser?.pageIndicator.numberOfPages == 3)
        #expect(browser?.currentPhotoIndex == 2)

        // A deletion the host reloads the grid for reaches the browser too.
        ds.photoCount = 2
        grid.reloadData()
        #expect(browser?.pageIndicator.numberOfPages == 2)
        #expect(browser?.currentPhotoIndex == 1, "the browser clamps its page to the new count")
    }

    @Test
    func `cells ask for thumbnails sized for the cell, never the full image`() async {
        let ds = MockPhotoGridDataSource(photoCount: 3)
        let grid = LMKPhotoGridViewController(columnCount: 3)
        grid.dataSource = ds
        grid.view.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        grid.view.layoutIfNeeded()
        grid.collectionView.layoutIfNeeded()

        await LMKWait.until { ds.thumbnailRequests.count == 3 }
        #expect(ds.fullImageRequests.isEmpty)
        let side = LMKPhotoGridViewController.cellSide(columnCount: 3, width: 390, spacing: 2)
        let scale = LMKScene.displayScale(of: grid.view) ?? LMKScene.fallbackDisplayScale
        #expect(ds.thumbnailRequests.allSatisfy { $0.pixelSize == LMKImage.pixelSize(CGSize(width: side, height: side), scale: scale) })
        #expect(grid.thumbnailPixelSize.width == LMKImage.pixelSize(points: side, scale: scale))
    }

    @Test
    func `the default thumbnail covers the pixel size, so an aspect-fill cell is never upscaled, and keeps its shape`() async throws {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let wide = UIGraphicsImageRenderer(size: CGSize(width: 1200, height: 600), format: format).image { context in
            UIColor.red.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 1200, height: 600))
        }
        let thumbnail = try #require(await LMKPhotoGridViewController.thumbnail(of: wide, pixelSize: CGSize(width: 300, height: 300)))
        let pixels = CGSize(width: CGFloat(thumbnail.cgImage?.width ?? 0), height: CGFloat(thumbnail.cgImage?.height ?? 0))
        #expect(min(pixels.width, pixels.height) >= 300, "the shorter side covers the cell")
        #expect(pixels.width < 1200, "it is still a downsample")
        #expect(abs(pixels.width / pixels.height - 2) < 0.05, "the thumbnail keeps the photo's shape")

        let small = UIImage.lmk_solidColor(.blue, size: CGSize(width: 10, height: 10))
        let untouched = await LMKPhotoGridViewController.thumbnail(of: small, pixelSize: CGSize(width: 300, height: 300))
        #expect(untouched === small, "an image already smaller than the cell is not touched")

        let source = OnlyFullImageSource()
        let viaDefault = try #require(await source.photoGridThumbnail(at: 0, pixelSize: CGSize(width: 100, height: 100)))
        #expect(min(viaDefault.cgImage?.width ?? 0, viaDefault.cgImage?.height ?? 0) >= 100)
        #expect(min(viaDefault.cgImage?.width ?? 0, viaDefault.cgImage?.height ?? 0) < 400, "decoded down from the full image")
    }

    @Test
    func `a Live Photo cell says so to VoiceOver`() {
        let ds = MockPhotoGridDataSource(photoCount: 3)
        ds.liveIndices = [2]
        let grid = LMKPhotoGridViewController(columnCount: 3)
        grid.dataSource = ds
        grid.view.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        grid.view.layoutIfNeeded()
        grid.collectionView.layoutIfNeeded()

        // Display index 0 is data source index 2, the Live Photo.
        let live = grid.collectionView.cellForItem(at: IndexPath(item: 0, section: 0))
        let still = grid.collectionView.cellForItem(at: IndexPath(item: 1, section: 0))
        #expect(live?.accessibilityLabel == "Photo 1 of 3, " + grid.strings.livePhotoAccessibilityLabel)
        #expect(still?.accessibilityLabel == "Photo 2 of 3")
    }

    // MARK: - Reload Data

    @Test
    func `reload data updates counts`() {
        let ds = MockPhotoGridDataSource(photoCount: 3)
        let grid = LMKPhotoGridViewController()
        grid.dataSource = ds
        grid.loadViewIfNeeded()

        let browserDS: any LMKPhotoBrowserDataSource = grid.browserBridge
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
    func `photo browser strings default to the browser's process-wide strings and can be customized`() {
        let original = LMKPhotoBrowserViewController.strings
        defer { LMKPhotoBrowserViewController.strings = original }
        LMKPhotoBrowserViewController.strings = LMKPhotoBrowserViewController.Strings(emptyText: "App Empty")
        let grid = LMKPhotoGridViewController()
        #expect(grid.browserStrings.emptyText == "App Empty", "an app-level override reaches the grid's browser")

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
    func `Every Style field reaches the view it styles`() throws {
        let style = LMKPhotoGridViewController.Style(
            minimumCellSize: 100,
            maximumColumnCount: 8,
            cellCorners: .fixed(9),
            toolbarButton: LMKButton.Style(foregroundColor: .orange),
            toolbarSpacing: 30,
            toolbarBottomMargin: 40,
            badgeSize: 30,
            badgeTint: .magenta,
            selectionTint: .cyan,
            selectionOverlayAlpha: 0.5,
            pinchThreshold: 0.6
        )
        let ds = MockPhotoGridDataSource(photoCount: 6)
        ds.liveIndices = [5]
        let grid = LMKPhotoGridViewController(columnCount: 3, style: style)
        grid.dataSource = ds
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        window.rootViewController = grid
        window.makeKeyAndVisible()
        grid.view.layoutIfNeeded()
        grid.collectionView.layoutIfNeeded()

        #expect(grid.maximumColumnCount == 3, "390pt of width holds three 100pt cells")
        #expect(grid.resolvedStyle.columnCap == 8)
        #expect(grid.sortButton.style.foregroundColor == .orange)
        #expect(grid.toolbarView.frame.maxY == grid.view.safeAreaLayoutGuide.layoutFrame.maxY - 40)
        #expect((grid.sortButton.superview as? UIStackView)?.spacing == 30)
        #expect(grid.resolvedStyle.pinchStep == 0.6)

        // Display index 0 is data source index 5, the Live Photo.
        let cell = try #require(grid.collectionView.cellForItem(at: IndexPath(item: 0, section: 0)) as? LMKPhotoGridCell)
        cell.setShowsSelected(true)
        cell.layoutIfNeeded()
        let imageView = try #require(cell.contentView.subviews.compactMap { $0 as? UIImageView }.first)
        #expect(imageView.layer.cornerRadius == 9)
        let overlay = try #require(cell.contentView.subviews.first { !($0 is UIImageView) && $0.backgroundColor != nil && !$0.isHidden && $0.bounds.size == cell.bounds.size })
        #expect(overlay.backgroundColor == UIColor.cyan.withAlphaComponent(0.5))
        let badges = cell.contentView.subviews.filter { $0.bounds.size == CGSize(width: 30, height: 30) }
        #expect(badges.count == 2, "the LIVE badge and the checkmark take the badge size")
        let glyph = try #require(badges.flatMap(\.subviews).compactMap { $0 as? UIImageView }.first)
        #expect(glyph.tintColor == .magenta)
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

        await LMKWait.until { cell.installedImage === image }
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
        await LMKWait.until { cell.installedImage === freshImage }
        #expect(cell.installedImage === freshImage)

        // Release the stale load: its result must be discarded.
        gate.open()
        await LMKWait.until(timeout: .milliseconds(300)) { cell.installedImage === staleImage }
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
        await LMKWait.until(timeout: .milliseconds(300)) { cell.installedImage === staleImage }
        #expect(cell.installedImage == nil)
    }
}

// MARK: - Drag and drop

@MainActor
struct LMKPhotoGridDragDropTests {
    private static func png(_ color: UIColor) throws -> Data {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return try #require(UIGraphicsImageRenderer(size: CGSize(width: 4, height: 4), format: format).image { context in
            color.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 4, height: 4))
        }.pngData())
    }

    @Test
    func `Drag and drop stay off until the consumer opts in, and switch off again`() {
        let grid = LMKPhotoGridViewController()
        grid.loadViewIfNeeded()
        let system = grid.collectionView.dragInteractionEnabled
        #expect(grid.collectionView.dragDelegate == nil)
        #expect(grid.collectionView.dropDelegate == nil)

        grid.allowsDraggingPhotos = true
        #expect(grid.collectionView.dragDelegate === grid)
        #expect(grid.collectionView.dropDelegate == nil)
        #expect(grid.collectionView.dragInteractionEnabled)

        grid.onDropImages = { _ in }
        #expect(grid.collectionView.dropDelegate === grid)

        grid.allowsDraggingPhotos = false
        #expect(grid.collectionView.dragDelegate == nil)
        #expect(grid.collectionView.dragInteractionEnabled, "a drop target still needs it")
        grid.onDropImages = nil
        #expect(grid.collectionView.dropDelegate == nil)
        #expect(grid.collectionView.dragInteractionEnabled == system, "the collection view's own setting is back")
    }

    @Test
    func `Opting in before the view loads applies once it does`() {
        let grid = LMKPhotoGridViewController()
        grid.allowsDraggingPhotos = true
        grid.onDropImages = { _ in }
        grid.loadViewIfNeeded()
        #expect(grid.collectionView.dragDelegate === grid)
        #expect(grid.collectionView.dropDelegate === grid)
    }

    @Test
    func `A dragged photo carries the data source's full image`() async throws {
        let ds = MockPhotoGridDataSource(photoCount: 3)
        let grid = LMKPhotoGridViewController()
        grid.dataSource = ds
        grid.loadViewIfNeeded()
        #expect(grid.dragItems(at: IndexPath(item: 0, section: 0)).isEmpty, "nothing while dragging is off")

        grid.allowsDraggingPhotos = true
        let items = grid.dragItems(at: IndexPath(item: 1, section: 0))
        #expect(items.count == 1)
        let item = try #require(items.first)
        let dsIndex = try #require(grid.dataSourceIndex(forDisplayIndex: 1))
        #expect(item.localObject as? Int == dsIndex)
        #expect(item.itemProvider.canLoadObject(ofClass: UIImage.self))
        let loaded = await withCheckedContinuation { (continuation: CheckedContinuation<CGSize?, Never>) in
            _ = item.itemProvider.loadObject(ofClass: UIImage.self) { object, _ in
                continuation.resume(returning: (object as? UIImage)?.size)
            }
        }
        // The full image (100pt square), not the 10pt thumbnail; a round trip through PNG reads it back at scale 1.
        #expect((loaded?.width ?? 0) >= 100)
        #expect(ds.fullImageRequests.contains(dsIndex))
        #expect(grid.dragItems(at: IndexPath(item: 9, section: 0)).isEmpty, "no photo there")
    }

    @Test
    func `A dragged photo with a file carries the file's bytes, typed by what they hold`() async throws {
        let url = FileManager.default.temporaryDirectory.appending(path: "lmk-drag-\(UUID().uuidString).jpg")
        let jpeg = try #require(UIImage.lmk_solidColor(.red, size: CGSize(width: 8, height: 8)).jpegData(compressionQuality: 0.9))
        try jpeg.write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }
        let ds = MockPhotoGridDataSource(photoCount: 3)
        ds.fileURL = url
        let grid = LMKPhotoGridViewController()
        grid.dataSource = ds
        grid.loadViewIfNeeded()
        grid.allowsDraggingPhotos = true
        let provider = try #require(grid.dragItems(at: IndexPath(item: 1, section: 0)).first?.itemProvider)
        #expect(provider.registeredContentTypes == [.jpeg])
        #expect(provider.suggestedName == url.deletingPathExtension().lastPathComponent)
        let loaded = await withCheckedContinuation { (continuation: CheckedContinuation<Data?, Never>) in
            _ = provider.loadDataRepresentation(for: .image) { data, _ in
                continuation.resume(returning: data)
            }
        }
        #expect(loaded == jpeg, "the stored bytes, metadata and all")
        #expect(ds.fullImageRequests.isEmpty, "no decode")

        // The type comes from the bytes: PNG data in a .jpg file goes as PNG.
        let png = try #require(UIImage.lmk_solidColor(.red, size: CGSize(width: 8, height: 8)).pngData())
        try png.write(to: url)
        let pngProvider = try #require(grid.dragItems(at: IndexPath(item: 1, section: 0)).first?.itemProvider)
        #expect(pngProvider.registeredContentTypes == [.png])

        // A file that is missing, or not an image, falls back to the full image.
        // (The image provider is the one without the file's name.)
        ds.fileURL = url.deletingLastPathComponent().appending(path: "missing.jpg")
        let missing = try #require(grid.dragItems(at: IndexPath(item: 1, section: 0)).first?.itemProvider)
        #expect(missing.canLoadObject(ofClass: UIImage.self))
        #expect(missing.suggestedName == nil)
        ds.fileURL = URL(filePath: "/etc/hosts")
        #expect(grid.dragItems(at: IndexPath(item: 1, section: 0)).first?.itemProvider.suggestedName == nil)
    }

    @Test
    func `A dragged photo is not delivered once the grid reloaded during the drag`() async throws {
        let ds = MockPhotoGridDataSource(photoCount: 3)
        let grid = LMKPhotoGridViewController()
        grid.dataSource = ds
        grid.loadViewIfNeeded()
        grid.allowsDraggingPhotos = true
        let provider = try #require(grid.dragItems(at: IndexPath(item: 1, section: 0)).first?.itemProvider)
        grid.reloadData()
        let loaded = await withCheckedContinuation { (continuation: CheckedContinuation<Bool, Never>) in
            _ = provider.loadObject(ofClass: UIImage.self) { object, _ in
                continuation.resume(returning: object != nil)
            }
        }
        #expect(!loaded, "the index may name another photo after a reload")
        #expect(ds.fullImageRequests.isEmpty)
    }

    @Test
    func `Dropped images arrive in order as their bytes, leaving out what is not an image`() async throws {
        let grid = LMKPhotoGridViewController()
        grid.loadViewIfNeeded()
        var drops: [[Data]] = []
        grid.onDropImages = { drops.append($0) }
        let red = try Self.png(.red)
        let blue = try Self.png(.blue)
        grid.handleDrop(of: [
            NSItemProvider(item: red as NSData, typeIdentifier: UTType.png.identifier),
            NSItemProvider(object: "caption" as NSString),
            NSItemProvider(item: blue as NSData, typeIdentifier: UTType.png.identifier),
        ])
        await LMKWait.until { !drops.isEmpty }
        #expect(drops == [[red, blue]])

        grid.handleDrop(of: [NSItemProvider(object: "caption" as NSString)])
        try await Task.sleep(for: .milliseconds(100))
        #expect(drops.count == 1, "a drop with no image reports nothing")
    }

    @Test
    func `The collector delivers once every load has answered, without the failed ones`() {
        var delivered: [[Data]] = []
        let collector = LMKPhotoGridDropCollector(count: 3) { delivered.append($0) }
        let first = Data([1])
        let third = Data([3])
        collector.receive(third, at: 2)
        collector.receive(nil, at: 1)
        #expect(delivered.isEmpty)
        collector.receive(first, at: 0)
        #expect(delivered == [[first, third]])
        collector.receive(first, at: 0)
        #expect(delivered.count == 1, "late answers are ignored")

        let failed = LMKPhotoGridDropCollector(count: 1) { delivered.append($0) }
        failed.receive(nil, at: 0)
        #expect(delivered.count == 1, "nothing loaded, nothing delivered")
    }
}

// MARK: - Mock Data Source

private final class MockPhotoGridDataSource: LMKPhotoGridDataSource {
    var photoCount: Int
    var prefetched: [Int] = []
    var cancelled: [Int] = []
    var fullImageRequests: [Int] = []
    var thumbnailRequests: [(index: Int, pixelSize: CGSize)] = []
    var liveIndices: Set<Int> = []
    var fileURL: URL?
    private let datesDescending: Bool

    init(photoCount: Int, datesDescending: Bool = false) {
        self.photoCount = photoCount
        self.datesDescending = datesDescending
    }

    var numberOfPhotos: Int {
        photoCount
    }

    func photoGridImage(at index: Int) async -> UIImage? {
        fullImageRequests.append(index)
        guard index >= 0, index < photoCount else { return nil }
        return UIImage.lmk_solidColor(.blue, size: CGSize(width: 100, height: 100))
    }

    func photoGridThumbnail(at index: Int, pixelSize: CGSize) async -> UIImage? {
        thumbnailRequests.append((index, pixelSize))
        guard index >= 0, index < photoCount else { return nil }
        return UIImage.lmk_solidColor(.blue, size: CGSize(width: 10, height: 10))
    }

    func photoGridIsLivePhoto(at index: Int) -> Bool {
        liveIndices.contains(index)
    }

    func photoGridFileURL(at _: Int) -> URL? {
        fileURL
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

/// A source with only full-size images, exercising the protocol's default thumbnail.
private final class OnlyFullImageSource: LMKPhotoGridDataSource {
    var numberOfPhotos: Int { 1 }

    func photoGridImage(at _: Int) async -> UIImage? {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: CGSize(width: 800, height: 400), format: format).image { context in
            UIColor.green.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 800, height: 400))
        }
    }

    func photoGridDate(at _: Int) -> Date? {
        nil
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
