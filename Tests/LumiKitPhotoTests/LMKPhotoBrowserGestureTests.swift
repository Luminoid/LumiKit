//
//  LMKPhotoBrowserGestureTests.swift
//  LumiKit
//
//  The page's zoom geometry: how far a zoomed photo may travel, which point a
//  zoom keeps in place, and the Live Photo load.
//

import LumiKitUI
import PhotosUI
import Testing
import UIKit
@testable import LumiKitPhoto

@MainActor
struct LMKPhotoBrowserGestureTests {
    private static let page = CGSize(width: 400, height: 800)

    /// A page with a 400 x 200 photo (wider than tall) fitted to a 400 x 800 page.
    private func makePage() throws -> (LMKPhotoBrowserCell, UIScrollView, UIImageView) {
        let theme = LMKTheme.default
        let style = LMKPhotoBrowserViewController.Style()
        let cell = LMKPhotoBrowserCell(frame: CGRect(x: 0, y: 0, width: Self.page.width + style.pageGap(theme: theme), height: Self.page.height))
        cell.apply(style: style, theme: theme, dynamicRange: .standard)
        cell.layoutIfNeeded()
        cell.configure(with: UIImage.lmk_solidColor(.green, size: CGSize(width: 300, height: 150)), screenSize: Self.page)
        let scrollView = try #require(cell.contentView.subviews.compactMap { $0 as? UIScrollView }.first)
        let imageView = try #require(scrollView.subviews.compactMap { $0 as? UIImageView }.first)
        return (cell, scrollView, imageView)
    }

    // MARK: - Travel

    @Test
    func `A zoomed photo travels to its edges and no further`() {
        // 2x of a 400pt photo on a 400pt page: 200pt either way.
        #expect(LMKPhotoBrowserCell.travel(photoLength: 800, pageLength: 400) == 200)
        // Zoomed but still shorter than the page: centered, no travel.
        #expect(LMKPhotoBrowserCell.travel(photoLength: 400, pageLength: 800) == 0)
        let fitted = CGSize(width: 400, height: 200)
        #expect(LMKPhotoBrowserCell.travelInsets(fittedSize: fitted, pageSize: Self.page, scale: 3) == UIEdgeInsets(top: 0, left: 400, bottom: 0, right: 400))
    }

    @Test
    func `At 1x the page runs a full page up and down and never sideways`() {
        // The dismiss drag follows the finger the whole way, whatever the photo's shape.
        for fitted in [CGSize(width: 400, height: 200), CGSize(width: 400, height: 800), CGSize(width: 200, height: 800)] {
            let insets = LMKPhotoBrowserCell.travelInsets(fittedSize: fitted, pageSize: Self.page, scale: 1)
            #expect(insets == UIEdgeInsets(top: 800, left: 0, bottom: 800, right: 0), "a photo narrower than the page must not take the sideways drag from the paging")
        }
    }

    @Test
    func `The page is the content area and the photo sits centered on it`() throws {
        let (_, scrollView, imageView) = try makePage()
        #expect(scrollView.bounds.size == Self.page)
        #expect(scrollView.contentSize == Self.page)
        #expect(imageView.frame == CGRect(x: 0, y: 300, width: 400, height: 200))
        #expect(scrollView.contentOffset == .zero)
        #expect(scrollView.contentInset == UIEdgeInsets(top: 800, left: 0, bottom: 800, right: 0))
    }

    // MARK: - Dismiss drag

    @Test
    func `The photo reports where it is drawn, the drag included`() throws {
        let (cell, scrollView, _) = try makePage()
        #expect(cell.photoFrame(in: cell.contentView) == CGRect(x: 0, y: 300, width: 400, height: 200))
        // Dragged 120pt down: the content offset goes negative, the photo moves with the finger.
        scrollView.contentOffset = CGPoint(x: 0, y: -120)
        #expect(cell.photoFrame(in: cell.contentView) == CGRect(x: 0, y: 420, width: 400, height: 200))
    }

    @Test
    func `A page with no photo yet reports no frame`() {
        let cell = LMKPhotoBrowserCell(frame: CGRect(origin: .zero, size: Self.page))
        #expect(cell.photoFrame(in: cell.contentView) == nil)
    }

    @Test
    func `A committed dismiss keeps the photo where the drag left it`() throws {
        let (cell, scrollView, _) = try makePage()
        scrollView.contentOffset = CGPoint(x: 0, y: -200)
        cell.freezeForDismissal()
        cell.setNeedsLayout()
        cell.layoutIfNeeded()
        #expect(scrollView.contentOffset == CGPoint(x: 0, y: -200), "a layout pass must not send the photo back to the center on the way out")
    }

    @Test
    func `The page is clear and the photo keeps the stage color behind it`() throws {
        let (cell, scrollView, imageView) = try makePage()
        #expect(cell.backgroundColor == .clear)
        #expect(cell.contentView.backgroundColor == .clear)
        #expect(scrollView.backgroundColor == .clear)
        #expect(imageView.backgroundColor == LMKPhotoBrowserViewController.Style().stageColor, "an image with transparency stays solid while the stage fades around it")
    }

    @Test
    func `Zooming keeps the photo centered and the scrollable area inside it`() throws {
        let (cell, scrollView, imageView) = try makePage()
        scrollView.setZoomScale(3, animated: false)
        #expect(cell.isZoomed)
        // 1200 x 600, centered on the 400 x 800 page.
        #expect(imageView.frame == CGRect(x: -400, y: 100, width: 1200, height: 600))
        #expect(scrollView.contentSize == Self.page, "not the photo's size scaled once more")
        #expect(scrollView.contentInset == UIEdgeInsets(top: 0, left: 400, bottom: 0, right: 400))

        // The farthest pan either way shows the photo's edge at the page's edge.
        let leftmost = -scrollView.contentInset.left
        let rightmost = scrollView.contentSize.width - scrollView.bounds.width + scrollView.contentInset.right
        #expect(leftmost == imageView.frame.minX)
        #expect(rightmost + scrollView.bounds.width == imageView.frame.maxX)

        cell.resetZoom()
        #expect(!cell.isZoomed)
        #expect(imageView.frame == CGRect(x: 0, y: 300, width: 400, height: 200))
        #expect(scrollView.contentOffset == .zero)
    }

    // MARK: - Anchor

    @Test
    func `An anchor names the photo point under a page point`() throws {
        let (cell, _, _) = try makePage()
        // The photo occupies y 300...500 of the page.
        let middle = cell.makeZoomAnchor(atPagePoint: CGPoint(x: 300, y: 450))
        #expect(middle.photoPoint == CGPoint(x: 300, y: 150))
        // A point on the letterbox anchors the nearest point of the photo.
        let above = cell.makeZoomAnchor(atPagePoint: CGPoint(x: 100, y: 50))
        #expect(above.photoPoint == CGPoint(x: 100, y: 0))
        let below = cell.makeZoomAnchor(atPagePoint: CGPoint(x: 100, y: 790))
        #expect(below.photoPoint == CGPoint(x: 100, y: 200))
    }

    @Test
    func `The anchored point stays under the finger, inside the photo's travel`() {
        let fitted = CGSize(width: 400, height: 200)
        let anchor = LMKPhotoBrowserCell.ZoomAnchor(pagePoint: CGPoint(x: 300, y: 450), photoPoint: CGPoint(x: 300, y: 150))
        // 2x: the photo is 800 x 400 at (-200, 200); photo x 300 sits at content x 400.
        let twice = LMKPhotoBrowserCell.contentOffset(keeping: anchor, scale: 2, fittedSize: fitted, pageSize: Self.page)
        #expect(twice.x == 100)
        #expect(twice.y == 0, "400pt of photo on an 800pt page: centered, no vertical travel")
        // 3x: photo 1200 x 600 at (-400, 100); photo x 300 sits at content x 500 -> offset 200.
        let thrice = LMKPhotoBrowserCell.contentOffset(keeping: anchor, scale: 3, fittedSize: fitted, pageSize: Self.page)
        #expect(thrice.x == 200)

        // An anchor at the photo's edge cannot pull the page past the photo.
        let corner = LMKPhotoBrowserCell.ZoomAnchor(pagePoint: CGPoint(x: 10, y: 400), photoPoint: CGPoint(x: 400, y: 100))
        let clamped = LMKPhotoBrowserCell.contentOffset(keeping: corner, scale: 2, fittedSize: fitted, pageSize: Self.page)
        #expect(clamped.x == 200, "the photo's right edge meets the page's")
        // Back at 1x the page rests centered.
        #expect(LMKPhotoBrowserCell.contentOffset(keeping: anchor, scale: 1, fittedSize: fitted, pageSize: Self.page) == .zero)
    }

    @Test
    func `A double tap zooms around the tapped point and a second one zooms back`() async throws {
        let (cell, scrollView, imageView) = try makePage()
        cell.zoomAtLocationInCell(CGPoint(x: 300, y: 450))
        // The zoom animates unless Reduce Motion is on; either way it lands at the double-tap scale.
        await LMKWait.until { scrollView.zoomScale == LMKPhotoBrowserMetrics.doubleTapZoomScale }
        #expect(scrollView.zoomScale == LMKPhotoBrowserMetrics.doubleTapZoomScale)
        // The tapped photo point (300, 150) is still under the finger at (300, 450).
        let tapped = imageView.convert(CGPoint(x: 300, y: 150), to: scrollView)
        #expect(abs(tapped.x - scrollView.contentOffset.x - 300) < 0.5)
        // The photo never leaves the page.
        #expect(scrollView.contentOffset.x <= scrollView.contentInset.right)
        #expect(scrollView.contentOffset.x >= -scrollView.contentInset.left)

        cell.zoomAtLocationInCell(CGPoint(x: 300, y: 450))
        await LMKWait.until { scrollView.zoomScale == 1 && scrollView.contentOffset == .zero }
        #expect(scrollView.zoomScale == 1)
        #expect(cell.zoomAnchor == nil)
        #expect(scrollView.contentOffset == .zero)
    }

    @Test
    func `A double tap on the letterbox zooms toward the photo`() async throws {
        let (cell, scrollView, imageView) = try makePage()
        cell.zoomAtLocationInCell(CGPoint(x: 390, y: 40))
        await LMKWait.until { scrollView.zoomScale == LMKPhotoBrowserMetrics.doubleTapZoomScale }
        #expect(cell.isZoomed)
        // Across the page there is only photo, and the tapped column is still under the finger.
        let visible = CGRect(origin: scrollView.contentOffset, size: scrollView.bounds.size)
        #expect(imageView.frame.minX <= visible.minX)
        #expect(imageView.frame.maxX >= visible.maxX)
        let tapped = imageView.convert(CGPoint(x: 390, y: 0), to: scrollView)
        #expect(abs(tapped.x - visible.minX - 390) < 0.5)
    }

    // MARK: - Paging hand-off

    @Test
    func `Zoomed, the page does not bounce sideways, so a drag past the edge pages`() throws {
        let (cell, scrollView, _) = try makePage()
        #expect(scrollView.bouncesHorizontally)
        scrollView.setZoomScale(2, animated: false)
        cell.scrollViewDidEndZooming(scrollView, with: nil, atScale: 2)
        #expect(!scrollView.bouncesHorizontally)
        scrollView.setZoomScale(1, animated: false)
        cell.scrollViewDidEndZooming(scrollView, with: nil, atScale: 1)
        #expect(scrollView.bouncesHorizontally)
        #expect(scrollView.alwaysBounceVertical, "the dismiss drag is back")
    }

    // MARK: - Drag classification

    @Test
    func `A drag at 1x with at most one finger is the dismiss drag and locks zoom; the end of every drag restores it`() throws {
        let (cell, scrollView, _) = try makePage()
        // A trackpad scroll or a one-finger drag: the pan reports no touches here.
        cell.scrollViewWillBeginDragging(scrollView)
        #expect(scrollView.maximumZoomScale == LMKPhotoBrowserMetrics.minimumZoomScale, "a pinch cannot start mid-drag")
        cell.scrollViewDidEndDragging(scrollView, willDecelerate: false)
        #expect(scrollView.maximumZoomScale == LMKPhotoBrowserMetrics.maximumZoomScale, "the zoom range comes back when the drag ends")

        // A drag that coasts: the range comes back when the coast ends.
        cell.scrollViewWillBeginDragging(scrollView)
        cell.scrollViewDidEndDragging(scrollView, willDecelerate: true)
        #expect(scrollView.maximumZoomScale == LMKPhotoBrowserMetrics.minimumZoomScale)
        cell.scrollViewDidEndDecelerating(scrollView)
        #expect(scrollView.maximumZoomScale == LMKPhotoBrowserMetrics.maximumZoomScale)

        // Zoomed, a drag pans and never locks the zoom.
        scrollView.setZoomScale(2, animated: false)
        cell.scrollViewWillBeginDragging(scrollView)
        #expect(scrollView.maximumZoomScale == LMKPhotoBrowserMetrics.maximumZoomScale)
    }

    @Test
    func `A drag at 1x that does not dismiss targets the center, whatever moved the page`() throws {
        let (cell, scrollView, _) = try makePage()
        cell.scrollViewWillBeginDragging(scrollView)
        scrollView.contentOffset = CGPoint(x: 0, y: -40)
        var target = CGPoint(x: 0, y: -40)
        cell.scrollViewWillEndDragging(scrollView, withVelocity: .zero, targetContentOffset: &target)
        #expect(target == .zero, "short of the threshold the photo coasts home")
        cell.scrollViewDidEndDragging(scrollView, willDecelerate: false)

        // Zoomed, the pan's own target stands.
        scrollView.setZoomScale(2, animated: false)
        #expect(cell.isZoomed)
        cell.scrollViewWillBeginDragging(scrollView)
        var zoomedTarget = CGPoint(x: 120, y: 0)
        cell.scrollViewWillEndDragging(scrollView, withVelocity: .zero, targetContentOffset: &zoomedTarget)
        #expect(zoomedTarget == CGPoint(x: 120, y: 0))
    }

    @Test
    func `The end of a drag at 1x brings the photo back to the center`() async throws {
        let (cell, scrollView, _) = try makePage()
        // The page was moved by something the delegate never classified as a dismiss drag (a
        // two-finger drag): the end of the drag still snaps it home.
        scrollView.contentOffset = CGPoint(x: 0, y: -160)
        cell.scrollViewDidEndDragging(scrollView, willDecelerate: false)
        await LMKWait.until { scrollView.contentOffset == .zero }
        #expect(scrollView.contentOffset == .zero)

        scrollView.contentOffset = CGPoint(x: 0, y: -160)
        cell.scrollViewDidEndScrollingAnimation(scrollView)
        await LMKWait.until { scrollView.contentOffset == .zero }
        #expect(scrollView.contentOffset == .zero)
    }

    @Test
    func `A committed dismiss stays where the drag left it`() throws {
        let (cell, scrollView, _) = try makePage()
        scrollView.contentOffset = CGPoint(x: 0, y: -200)
        cell.freezeForDismissal()
        cell.scrollViewDidEndDragging(scrollView, willDecelerate: false)
        #expect(scrollView.contentOffset == CGPoint(x: 0, y: -200))
        cell.scrollViewDidEndDecelerating(scrollView)
        #expect(scrollView.contentOffset == CGPoint(x: 0, y: -200))
    }

    @Test
    func `Releasing a pinch past the maximum reports the page as still zoomed`() async throws {
        let (cell, scrollView, _) = try makePage()
        let recorder = ZoomStateRecorder()
        cell.delegate = recorder
        scrollView.setZoomScale(LMKPhotoBrowserMetrics.maximumZoomScale, animated: false)
        // The rubber band past the maximum is a transform on the scroll view.
        scrollView.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
        cell.finishPinch()
        await LMKWait.until { !recorder.zoomStates.isEmpty }
        #expect(recorder.zoomStates.last == true, "the chrome must not return over a photo at 3x")
        #expect(scrollView.transform.isIdentity)

        scrollView.setZoomScale(1, animated: false)
        scrollView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        cell.finishPinch()
        await LMKWait.until { recorder.zoomStates.count == 2 }
        #expect(recorder.zoomStates.last == false)
    }

    @Test
    func `Reappearance clears a frozen dismissal and the drag lock`() throws {
        let (cell, scrollView, _) = try makePage()
        cell.scrollViewWillBeginDragging(scrollView)
        scrollView.contentOffset = CGPoint(x: 0, y: -200)
        cell.freezeForDismissal()
        cell.prepareForReappearance()
        #expect(scrollView.contentOffset == .zero)
        #expect(scrollView.maximumZoomScale == LMKPhotoBrowserMetrics.maximumZoomScale)
        cell.setNeedsLayout()
        cell.layoutIfNeeded()
        #expect(scrollView.contentOffset == .zero, "the page is no longer frozen")
    }

    // MARK: - Live Photo

    @Test
    func `A still page has nothing to play, and the long press lives on the page`() throws {
        let (cell, scrollView, _) = try makePage()
        #expect(!cell.isShowingLivePhoto)
        let liveView = try #require(scrollView.subviews.compactMap { $0 as? PHLivePhotoView }.first)
        #expect(liveView.isHidden)
        #expect(scrollView.gestureRecognizers?.contains { $0 === liveView.playbackGestureRecognizer } == true, "a long press anywhere on the page plays")
    }

    @Test
    func `The browser asks for the Live Photo whatever photoIsLivePhoto says`() async {
        let dataSource = LivePhotoCountingSource()
        let browser = LMKPhotoBrowserViewController()
        browser.dataSource = dataSource
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        window.rootViewController = browser
        window.isHidden = false
        defer { window.isHidden = true }
        browser.view.layoutIfNeeded()
        browser.collectionView.layoutIfNeeded()
        await LMKWait.until { !dataSource.livePhotoRequests.isEmpty }
        #expect(dataSource.livePhotoRequests.contains(0), "the default photoIsLivePhoto is false; the Live Photo is asked for anyway")
    }
}

@MainActor
private final class ZoomStateRecorder: LMKPhotoBrowserCellDelegate {
    var zoomStates: [Bool] = []

    func photoCellDidRequestDismiss(_: LMKPhotoBrowserCell) {}
    func photoCell(_: LMKPhotoBrowserCell, didUpdateDismissProgress _: CGFloat) {}
    func photoCell(_: LMKPhotoBrowserCell, setPagingEnabled _: Bool) {}
    func photoCell(_: LMKPhotoBrowserCell, didChangeZoomState zoomed: Bool) {
        zoomStates.append(zoomed)
    }
}

@MainActor
private final class LivePhotoCountingSource: LMKPhotoBrowserDataSource {
    var livePhotoRequests: [Int] = []
    var numberOfPhotos: Int { 2 }

    func photo(at _: Int) async -> UIImage? {
        UIImage.lmk_solidColor(.blue, size: CGSize(width: 100, height: 100))
    }

    func photoDate(at _: Int) -> Date? {
        nil
    }

    func photoSubtitle(at _: Int) -> String? {
        nil
    }

    func photoLivePhoto(at index: Int) async -> PHLivePhoto? {
        livePhotoRequests.append(index)
        return nil
    }
}
