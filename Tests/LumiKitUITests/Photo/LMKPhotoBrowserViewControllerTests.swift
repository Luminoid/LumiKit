//
//  LMKPhotoBrowserViewControllerTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

@MainActor
struct LMKPhotoBrowserViewControllerTests {
    // MARK: - Initialization

    @Test
    func `Initializes with start index`() {
        let dataSource = MockPhotoBrowserDataSource(photoCount: 5)
        let browser = LMKPhotoBrowserViewController(initialIndex: 2)
        browser.dataSource = dataSource

        #expect(browser.dataSource != nil)
    }

    @Test
    func `Loads view without crashing`() {
        let dataSource = MockPhotoBrowserDataSource(photoCount: 3)
        let browser = LMKPhotoBrowserViewController(initialIndex: 0)
        browser.dataSource = dataSource

        browser.loadViewIfNeeded()

        #expect(browser.isViewLoaded)
    }

    // MARK: - Data Source

    @Test
    func `Handles empty data source`() {
        let dataSource = MockPhotoBrowserDataSource(photoCount: 0)
        let browser = LMKPhotoBrowserViewController(initialIndex: 0)
        browser.dataSource = dataSource

        browser.loadViewIfNeeded()

        // Should not crash with empty data source
        #expect(browser.isViewLoaded)
    }

    @Test
    func `Handles single photo`() {
        let dataSource = MockPhotoBrowserDataSource(photoCount: 1)
        let browser = LMKPhotoBrowserViewController(initialIndex: 0)
        browser.dataSource = dataSource

        browser.loadViewIfNeeded()

        #expect(browser.isViewLoaded)
    }

    @Test
    func `Handles multiple photos`() {
        let dataSource = MockPhotoBrowserDataSource(photoCount: 10)
        let browser = LMKPhotoBrowserViewController(initialIndex: 5)
        browser.dataSource = dataSource

        browser.loadViewIfNeeded()

        #expect(browser.isViewLoaded)
    }

    // MARK: - Delegate

    @Test
    func `Accepts delegate assignment`() {
        let delegate = MockPhotoBrowserDelegate()
        let browser = LMKPhotoBrowserViewController(initialIndex: 0)
        browser.delegate = delegate

        #expect(browser.delegate != nil)
    }

    // MARK: - Strings Configuration

    @Test
    func `Default strings are set`() {
        let browser = LMKPhotoBrowserViewController(initialIndex: 0)

        #expect(!browser.strings.emptyText.isEmpty)
        #expect(!browser.strings.counterFormat.isEmpty)
        #expect(!browser.strings.tapToToggleHint.isEmpty)
    }

    @Test
    func `Custom strings can be set`() {
        let browser = LMKPhotoBrowserViewController(initialIndex: 0)
        let customStrings = LMKPhotoBrowserStrings(
            emptyText: "Custom Empty",
            counterFormat: "%d/%d",
            tapToToggleHint: "Custom Hint"
        )
        browser.strings = customStrings

        #expect(browser.strings.emptyText == "Custom Empty")
        #expect(browser.strings.counterFormat == "%d/%d")
        #expect(browser.strings.tapToToggleHint == "Custom Hint")
    }

    // MARK: - Status Bar

    @Test
    func `Preferred status bar style is light content`() {
        let browser = LMKPhotoBrowserViewController(initialIndex: 0)

        #expect(browser.preferredStatusBarStyle == .lightContent)
    }

    // MARK: - View Controller Lifecycle

    @Test
    func `View controller can be presented`() {
        let dataSource = MockPhotoBrowserDataSource(photoCount: 3)
        let browser = LMKPhotoBrowserViewController(initialIndex: 0)
        browser.dataSource = dataSource

        browser.loadViewIfNeeded()
        browser.viewWillAppear(false)
        browser.viewDidAppear(false)

        // Should complete without crashing
        #expect(browser.isViewLoaded)
    }
}

// MARK: - Mock Data Source

private final class MockPhotoBrowserDataSource: LMKPhotoBrowserDataSource {
    let photoCount: Int

    init(photoCount: Int) {
        self.photoCount = photoCount
    }

    var numberOfPhotos: Int {
        photoCount
    }

    func photo(at index: Int) async -> UIImage? {
        guard index < photoCount else { return nil }
        return UIImage.lmk_solidColor(.blue, size: CGSize(width: 100, height: 100))
    }

    func photoDate(at index: Int) -> Date? {
        guard index < photoCount else { return nil }
        return Date()
    }

    func photoSubtitle(at index: Int) -> String? {
        guard index < photoCount else { return nil }
        return "Photo \(index + 1)"
    }
}

// MARK: - Mock Delegate

private final class MockPhotoBrowserDelegate: LMKPhotoBrowserDelegate {
    var didRequestActionCalled = false
    var didDismissCalled = false
    var lastActionIndex: Int?

    func photoBrowser(_ browser: LMKPhotoBrowserViewController, didRequestActionAt index: Int) {
        didRequestActionCalled = true
        lastActionIndex = index
    }

    func photoBrowserDidDismiss(_ browser: LMKPhotoBrowserViewController) {
        didDismissCalled = true
    }
}
