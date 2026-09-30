//
//  LMKPhotoBrowserViewControllerTests.swift
//  LumiKit
//

import LumiKitUI
import Testing
import UIKit
@testable import LumiKitPhoto

@MainActor
struct LMKPhotoBrowserViewControllerTests {
    // MARK: - Helpers

    private func makeBrowser(photoCount: Int, initialIndex: Int = 0, inWindow: Bool = false) -> (LMKPhotoBrowserViewController, MockPhotoBrowserDataSource) {
        let dataSource = MockPhotoBrowserDataSource(photoCount: photoCount)
        let browser = LMKPhotoBrowserViewController(initialIndex: initialIndex)
        browser.dataSource = dataSource
        if inWindow {
            let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 375, height: 812))
            window.rootViewController = browser
            window.makeKeyAndVisible()
            browser.loadViewIfNeeded()
            browser.view.layoutIfNeeded()
        }
        return (browser, dataSource)
    }

    // MARK: - Initialization

    @Test
    func `Initializes with a start index and presents over the full screen`() {
        let (browser, dataSource) = makeBrowser(photoCount: 5, initialIndex: 2)
        defer { withExtendedLifetime(dataSource) {} }
        #expect(browser.dataSource != nil)
        #expect(browser.modalPresentationStyle == .overFullScreen, "the presenter stays underneath, for the dismiss drag to show")
        #expect(browser.modalPresentationCapturesStatusBarAppearance)
        #expect(browser.preferredStatusBarStyle == .lightContent)
    }

    @Test
    func `Loads the view for empty, single, and many photos`() {
        for count in [0, 1, 10] {
            let (browser, dataSource) = makeBrowser(photoCount: count, initialIndex: 5)
            defer { withExtendedLifetime(dataSource) {} }
            browser.loadViewIfNeeded()
            browser.viewWillAppear(false)
            browser.viewDidAppear(false)
            #expect(browser.isViewLoaded)
        }
    }

    // MARK: - Rendering

    @Test
    func `An empty data source shows the empty state and hides the pages`() {
        let (browser, dataSource) = makeBrowser(photoCount: 0)
        defer { withExtendedLifetime(dataSource) {} }
        browser.loadViewIfNeeded()

        #expect(browser.emptyStateView.isHidden == false)
        #expect(browser.collectionView.isHidden)
        #expect(browser.pageIndicator.isHidden)
        #expect(browser.actionButton.isHidden)
        #expect(browser.emptyStateView.content?.message == browser.strings.emptyText)
    }

    @Test
    func `Photos hide the empty state and size the page indicator`() {
        let (browser, dataSource) = makeBrowser(photoCount: 5)
        defer { withExtendedLifetime(dataSource) {} }
        browser.loadViewIfNeeded()

        #expect(browser.emptyStateView.isHidden)
        #expect(browser.collectionView.isHidden == false)
        #expect(browser.pageIndicator.numberOfPages == 5)
        #expect(browser.pageIndicator.isHidden == false)
        #expect(browser.counterLabel.text == "1 of 5")

        dataSource.photoCount = 1
        browser.reloadData()
        #expect(browser.pageIndicator.isHidden, "a single photo shows no dots")
        #expect(browser.counterLabel.text == nil, "a single photo shows no counter")

        dataSource.photoCount = 0
        browser.reloadData()
        #expect(browser.emptyStateView.isHidden == false)
    }

    @Test
    func `showPhoto clamps to the data source and updates the counter`() {
        let (browser, dataSource) = makeBrowser(photoCount: 5, inWindow: true)
        defer { withExtendedLifetime(dataSource) {} }

        browser.showPhoto(at: 2, animated: false)
        #expect(browser.currentPhotoIndex == 2)
        #expect(browser.counterLabel.text == "3 of 5")
        #expect(browser.pageIndicator.currentPage == 2)

        browser.showPhoto(at: 99, animated: false)
        #expect(browser.currentPhotoIndex == 4)
        browser.showPhoto(at: -3, animated: false)
        #expect(browser.currentPhotoIndex == 0)
    }

    @Test
    func `The action button follows showsActionButton and the symbol name`() {
        let (browser, dataSource) = makeBrowser(photoCount: 3)
        defer { withExtendedLifetime(dataSource) {} }
        browser.loadViewIfNeeded()
        #expect(browser.actionButton.isHidden == false)

        browser.showsActionButton = false
        #expect(browser.actionButton.isHidden)
        browser.showsActionButton = true
        browser.actionButtonSystemImageName = "trash"
        #expect(browser.actionButton.image != nil)
        #expect(browser.actionButton.accessibilityLabel == browser.strings.actionAccessibilityLabel)
        #expect(browser.dismissButton.accessibilityLabel == browser.strings.dismissAccessibilityLabel)
    }

    // MARK: - Dismissal

    @Test
    func `Dismissing reports to the delegate and onDismiss`() {
        let (browser, dataSource) = makeBrowser(photoCount: 3)
        defer { withExtendedLifetime(dataSource) {} }
        let delegate = MockPhotoBrowserDelegate()
        browser.delegate = delegate
        var dismissed = false
        browser.onDismiss = { dismissed = true }
        browser.loadViewIfNeeded()

        browser.dismissBrowser()

        #expect(delegate.didDismissCalled)
        #expect(dismissed)
    }

    @Test
    func `The action button asks the delegate for the current photo`() {
        let (browser, dataSource) = makeBrowser(photoCount: 3)
        defer { withExtendedLifetime(dataSource) {} }
        let delegate = MockPhotoBrowserDelegate()
        browser.delegate = delegate
        browser.loadViewIfNeeded()

        browser.requestAction()

        #expect(delegate.lastActionIndex == 0)
    }

    @Test
    func `A zoom source view installs the browser's own photo transition`() {
        let (browser, dataSource) = makeBrowser(photoCount: 3)
        defer { withExtendedLifetime(dataSource) {} }
        #expect(browser.transitioningDelegate == nil)

        browser.zoomSourceView = { _ in UIView() }
        #expect(browser.transitioningDelegate === browser)
        // The system zoom transition scales the whole presenting screen; only the photo moves here.
        #expect(browser.preferredTransition == nil)
        #expect(browser.animationController(forPresented: browser, presenting: UIViewController(), source: UIViewController()) is LMKPhotoBrowserZoomAnimator)
        #expect(browser.animationController(forDismissed: browser) is LMKPhotoBrowserZoomAnimator)

        browser.zoomSourceView = nil
        #expect(browser.transitioningDelegate == nil)
    }

    // MARK: - Photo transition geometry

    @Test
    func `The travelling photo fits the stage the way a page does`() {
        let stage = CGRect(x: 0, y: 0, width: 400, height: 800)
        let wide = LMKPhotoBrowserZoomAnimator.aspectFit(CGSize(width: 300, height: 150), in: stage)
        #expect(wide == CGRect(x: 0, y: 300, width: 400, height: 200))
        let tall = LMKPhotoBrowserZoomAnimator.aspectFit(CGSize(width: 100, height: 400), in: stage)
        #expect(tall == CGRect(x: 100, y: 0, width: 200, height: 800))
        #expect(LMKPhotoBrowserZoomAnimator.aspectFit(.zero, in: stage) == stage)
    }

    @Test
    func `The transition leaves from the thumbnail's image`() throws {
        let (browser, dataSource) = makeBrowser(photoCount: 3)
        defer { withExtendedLifetime(dataSource) {} }
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 400, height: 800))
        window.isHidden = false
        defer { window.isHidden = true }
        let image = UIGraphicsImageRenderer(size: CGSize(width: 200, height: 100)).image { _ in }

        // A filled thumbnail: the whole image view, with its corners.
        let thumbnail = UIImageView(image: image)
        thumbnail.frame = CGRect(x: 20, y: 100, width: 80, height: 80)
        thumbnail.contentMode = .scaleAspectFill
        thumbnail.layer.cornerRadius = 6
        window.addSubview(thumbnail)
        browser.zoomSourceView = { _ in thumbnail }
        let filled = try #require(LMKPhotoBrowserZoomAnimator.source(for: browser, in: window))
        #expect(filled.frame == CGRect(x: 20, y: 100, width: 80, height: 80))
        #expect(filled.cornerRadius == 6)
        #expect(filled.image === image)

        // A fitted thumbnail: only where the photo is drawn.
        thumbnail.contentMode = .scaleAspectFit
        let fitted = try #require(LMKPhotoBrowserZoomAnimator.source(for: browser, in: window))
        #expect(fitted.frame == CGRect(x: 20, y: 120, width: 80, height: 40))
        #expect(fitted.cornerRadius == 0)

        // A cell around the image view: the image view is found inside it.
        let cell = UIView(frame: CGRect(x: 200, y: 300, width: 100, height: 100))
        let inner = UIImageView(image: image)
        inner.frame = cell.bounds
        inner.contentMode = .scaleAspectFill
        cell.addSubview(inner)
        window.addSubview(cell)
        browser.zoomSourceView = { _ in cell }
        let wrapped = try #require(LMKPhotoBrowserZoomAnimator.source(for: browser, in: window))
        #expect(wrapped.frame == CGRect(x: 200, y: 300, width: 100, height: 100))
        #expect(wrapped.image === image)
    }

    @Test
    func `A thumbnail that is off screen, hidden, or gone gives no source`() {
        let (browser, dataSource) = makeBrowser(photoCount: 3)
        defer { withExtendedLifetime(dataSource) {} }
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 400, height: 800))
        window.isHidden = false
        defer { window.isHidden = true }

        let detached = UIView(frame: CGRect(x: 0, y: 0, width: 80, height: 80))
        browser.zoomSourceView = { _ in detached }
        #expect(LMKPhotoBrowserZoomAnimator.source(for: browser, in: window) == nil)

        let offscreen = UIView(frame: CGRect(x: 0, y: 2000, width: 80, height: 80))
        window.addSubview(offscreen)
        browser.zoomSourceView = { _ in offscreen }
        #expect(LMKPhotoBrowserZoomAnimator.source(for: browser, in: window) == nil)

        let hidden = UIView(frame: CGRect(x: 0, y: 0, width: 80, height: 80))
        hidden.isHidden = true
        window.addSubview(hidden)
        browser.zoomSourceView = { _ in hidden }
        #expect(LMKPhotoBrowserZoomAnimator.source(for: browser, in: window) == nil)

        browser.zoomSourceView = { _ in nil }
        #expect(LMKPhotoBrowserZoomAnimator.source(for: browser, in: window) == nil)

        // A plain view with nothing to show an image from travels as a snapshot of itself.
        let plain = UIView(frame: CGRect(x: 10, y: 10, width: 80, height: 80))
        plain.backgroundColor = .red
        window.addSubview(plain)
        browser.zoomSourceView = { _ in plain }
        #expect(LMKPhotoBrowserZoomAnimator.source(for: browser, in: window)?.image != nil)
    }

    @Test
    func `Overlay visibility toggles the chrome alpha`() {
        let (browser, dataSource) = makeBrowser(photoCount: 3)
        defer { withExtendedLifetime(dataSource) {} }
        browser.loadViewIfNeeded()
        #expect(browser.isOverlayHidden == false)

        browser.setOverlayHidden(true, animated: false)
        #expect(browser.isOverlayHidden)
        #expect(browser.dismissButton.isUserInteractionEnabled == false)

        browser.setOverlayHidden(false, animated: false)
        #expect(browser.isOverlayHidden == false)
        #expect(browser.dismissButton.isUserInteractionEnabled)
    }

    // MARK: - Dismiss drag

    @Test
    func `A dismiss drag fades the stage and leaves the view and the photos solid`() {
        let (browser, dataSource) = makeBrowser(photoCount: 3, inWindow: true)
        defer { withExtendedLifetime(dataSource) {} }
        #expect(browser.view.backgroundColor == .clear)
        #expect(browser.collectionView.backgroundColor == .clear)
        #expect(browser.stageView.backgroundColor == browser.resolvedStyle.stageColor)
        #expect(browser.stageView.superview === browser.view)
        #expect(browser.view.subviews.first === browser.stageView, "the stage sits behind the pages")

        browser.updateDismissProgress(0.6)
        #expect(browser.stageView.alpha < 1)
        #expect(browser.view.alpha == 1, "fading the whole view would fade the photo with it")
        #expect(browser.collectionView.alpha == 1)
        #expect(browser.dismissButton.alpha == 0, "the chrome clears first")
        for case let cell as LMKPhotoBrowserCell in browser.collectionView.visibleCells {
            #expect(cell.chromeAlpha == 0, "the LIVE badge goes with the rest of the chrome")
        }

        let nearThreshold = browser.stageView.alpha
        browser.updateDismissProgress(1)
        #expect(browser.stageView.alpha < nearThreshold)
        #expect(abs(browser.stageView.alpha - browser.resolvedStyle.dismissFloorAlpha) < 0.0001)
    }

    @Test
    func `The stage only clears as the drag goes further`() {
        var previous: CGFloat = 1
        for step in 0 ... 30 {
            let alpha = LMKPhotoBrowserViewController.stageAlpha(progress: CGFloat(step) / 20, minimumAlpha: 0.1)
            #expect(alpha <= previous + 0.0001, "progress \(CGFloat(step) / 20)")
            #expect(alpha >= 0.1 - 0.0001)
            previous = alpha
        }
    }

    @Test
    func `A committed drag clears the stage and never brings it back`() {
        let (browser, dataSource) = makeBrowser(photoCount: 3, inWindow: true)
        defer { withExtendedLifetime(dataSource) {} }
        var dismissed = 0
        browser.onDismiss = { dismissed += 1 }
        // With a zoom source the photo travels back to it while the transition clears what is left of the stage.
        let source = UIView(frame: CGRect(x: 20, y: 200, width: 80, height: 80))
        browser.zoomSourceView = { _ in source }
        browser.updateDismissProgress(1)
        let stageAlpha = browser.stageView.alpha
        browser.performDismissWithSnapTiming()
        #expect(browser.stageView.alpha <= stageAlpha, "the old path animated the stage back to opaque before zooming out")
        #expect(browser.dismissButton.alpha == 0)
        #expect(dismissed == 1)
    }

    // MARK: - Appearance

    @Test
    func `A later appearance keeps the photo the user paged to`() {
        let (browser, dataSource) = makeBrowser(photoCount: 5, initialIndex: 1, inWindow: true)
        defer { withExtendedLifetime(dataSource) {} }
        browser.viewWillAppear(false)
        browser.view.layoutIfNeeded()
        browser.viewDidAppear(false)
        #expect(browser.currentPhotoIndex == 1)

        browser.showPhoto(at: 3, animated: false)
        #expect(browser.currentPhotoIndex == 3)
        // A sheet presented over the browser went away.
        browser.viewWillAppear(false)
        browser.viewDidAppear(false)
        #expect(browser.currentPhotoIndex == 3, "the initial index applies once")
        let pageWidth = browser.collectionView.bounds.width
        #expect(abs(browser.collectionView.contentOffset.x - 3 * pageWidth) < 0.5)
    }

    @Test
    func `Pure dismiss helpers`() {
        #expect(LMKPhotoBrowserViewController.stageAlpha(progress: 0, minimumAlpha: 0.3) == 1)
        #expect(LMKPhotoBrowserViewController.stageAlpha(progress: 0.1, minimumAlpha: 0.3) == 1, "tiny drags never flicker")
        #expect(abs(LMKPhotoBrowserViewController.stageAlpha(progress: 1, minimumAlpha: 0.3) - 0.3) < 0.0001)
        #expect(abs(LMKPhotoBrowserViewController.stageAlpha(progress: 2, minimumAlpha: 0.3) - 0.3) < 0.0001, "past the threshold the stage holds its floor")
        #expect(LMKPhotoBrowserViewController.overlayAlpha(progress: 0) == 1)
        #expect(LMKPhotoBrowserViewController.overlayAlpha(progress: 0.5) == 0)
        #expect(LMKPhotoBrowserViewController.verticalDismissThreshold(pageHeight: 100) == 80, "the minimum wins on short pages")
        #expect(LMKPhotoBrowserViewController.verticalDismissThreshold(pageHeight: 1000) == 200)
        #expect(LMKPhotoBrowserViewController.shouldDismiss(offset: 250, velocity: 0, threshold: 200))
        #expect(LMKPhotoBrowserViewController.shouldDismiss(offset: -50, velocity: 900, threshold: 200), "a flick past the minimum distance")
        #expect(!LMKPhotoBrowserViewController.shouldDismiss(offset: 10, velocity: 900, threshold: 200), "a flick that barely moved")
        #expect(!LMKPhotoBrowserViewController.shouldDismiss(offset: 100, velocity: 100, threshold: 200))
    }

    // MARK: - Style

    @Test
    func `Style resolves through the theme slot and the instance style wins`() {
        var theme = LMKTheme.default
        theme.photoBrowser = LMKPhotoBrowserViewController.Style(chromeTint: .red, interPageSpacing: 30)
        let (browser, dataSource) = makeBrowser(photoCount: 3)
        defer { withExtendedLifetime(dataSource) {} }
        browser.traitOverrides.lmkTheme = LMKThemeReference(theme)
        browser.loadViewIfNeeded()

        #expect(browser.resolvedStyle.chromeTint == .red)
        #expect(browser.resolvedStyle.interPageSpacing == 30)

        browser.style = LMKPhotoBrowserViewController.Style(chromeTint: .blue)
        #expect(browser.resolvedStyle.chromeTint == .blue)
        #expect(browser.resolvedStyle.interPageSpacing == 30, "unset fields keep the theme value")
    }

    @Test
    func `Style merging layers non-nil fields`() {
        let base = LMKPhotoBrowserViewController.Style(chromeTint: .red, counterAlpha: 0.5, prefersHDR: false)
        let merged = base.merging(LMKPhotoBrowserViewController.Style(counterAlpha: 0.8, locksOrientation: true))
        #expect(merged.chromeTint == .red)
        #expect(merged.counterAlpha == 0.8)
        #expect(merged.prefersHDR == false)
        #expect(merged.locksOrientation == true)
        #expect(LMKPhotoBrowserViewController.Style().maximumZoom == 3)
        #expect(LMKPhotoBrowserViewController.Style(maximumZoomScale: 0.5).maximumZoom == 1, "never below 1x")
    }

    @Test
    func `Effective dynamic range follows prefersHDR`() {
        let (browser, dataSource) = makeBrowser(photoCount: 3)
        defer { withExtendedLifetime(dataSource) {} }
        browser.loadViewIfNeeded()
        #expect(browser.effectiveDynamicRange != .standard)

        browser.style = LMKPhotoBrowserViewController.Style(prefersHDR: false)
        #expect(browser.effectiveDynamicRange == .standard)
    }

    @Test
    func `Orientation lock follows the style on iOS 26`() {
        guard #available(iOS 26, *) else { return }
        let (browser, dataSource) = makeBrowser(photoCount: 3)
        defer { withExtendedLifetime(dataSource) {} }
        browser.loadViewIfNeeded()
        #expect(browser.prefersInterfaceOrientationLocked == false)

        browser.style = LMKPhotoBrowserViewController.Style(locksOrientation: true)
        #expect(browser.prefersInterfaceOrientationLocked)
    }

    // MARK: - Strings

    @Test
    func `Default strings are localized and custom strings apply`() {
        let (browser, dataSource) = makeBrowser(photoCount: 3)
        defer { withExtendedLifetime(dataSource) {} }
        #expect(!browser.strings.emptyText.isEmpty)
        #expect(browser.strings.counterFormat.contains("%lld"))
        #expect(!browser.strings.dismissAccessibilityLabel.isEmpty)
        #expect(!browser.strings.previousPhoto.isEmpty)

        browser.strings = LMKPhotoBrowserViewController.Strings(emptyText: "Custom Empty", counterFormat: "%d/%d", tapToToggleHint: "Custom Hint")
        browser.loadViewIfNeeded()
        #expect(browser.strings.emptyText == "Custom Empty")
        #expect(browser.counterLabel.text == "1/3")
        #expect(browser.collectionView.accessibilityHint == "Custom Hint")
    }

    // MARK: - Key Commands

    @Test
    func `Key commands cover paging, dismissal, and the action`() {
        let (browser, dataSource) = makeBrowser(photoCount: 3)
        defer { withExtendedLifetime(dataSource) {} }
        browser.loadViewIfNeeded()
        #expect(browser.canBecomeFirstResponder)
        let inputs = (browser.keyCommands ?? []).map(\.input)
        #expect(inputs.contains(UIKeyCommand.inputLeftArrow))
        #expect(inputs.contains(UIKeyCommand.inputRightArrow))
        #expect(inputs.contains(UIKeyCommand.inputEscape))
        #expect(inputs.contains(" "), "space triggers the action")
        #expect(browser.keyCommands?.count == 6)

        browser.showsActionButton = false
        #expect(browser.keyCommands?.count == 4)
    }
}

// MARK: - Mock Data Source

private final class MockPhotoBrowserDataSource: LMKPhotoBrowserDataSource {
    var photoCount: Int

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
