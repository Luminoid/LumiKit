//
//  LMKPhotoBrowserViewController+CollectionView.swift
//  LumiKit
//
//  Paging, the collection view data source and delegate, and the page cell
//  callbacks of the photo browser.
//

import LumiKitCore
import LumiKitUI
import UIKit

// MARK: - Navigation

extension LMKPhotoBrowserViewController {
    func scrollToPhoto(at index: Int, animated: Bool) {
        let count = photoCount
        guard count > 0, collectionView.bounds.width > 0, index >= 0, index < count else { return }
        // Each page = collectionView.bounds.width (= view.width + the inter-page gap).
        let pageWidth = collectionView.bounds.width
        collectionView.setContentOffset(CGPoint(x: CGFloat(index) * pageWidth, y: 0), animated: animated)
        updateCurrentIndex(index)
    }

    /// Re-aligns to the current page unless a swipe is under way. A zoom presentation takes
    /// touches about a second before it reports the appearance, and a swipe still moving at
    /// that point must not be sent back to the photo it left.
    func alignToCurrentPageIfIdle() {
        guard !collectionView.isTracking, !collectionView.isDragging, !collectionView.isDecelerating else { return }
        scrollToPhoto(at: currentIndex, animated: false)
    }

    /// The page showing the current photo, when it is loaded.
    var currentCell: LMKPhotoBrowserCell? {
        collectionView.cellForItem(at: IndexPath(item: currentIndex, section: 0)) as? LMKPhotoBrowserCell
    }

    func updateCurrentIndex(_ index: Int) {
        let count = photoCount
        guard index >= 0, index < count else { return }
        let previousIndex = currentIndex
        currentIndex = index
        pageIndicator.currentPage = index
        updateDateLabel()
        updateCounterLabel()
        if index != previousIndex, resolvedStyle.playsHaptics {
            LMKHaptics.selection()
        }
        updatePhotoAccessibility()
    }

    func updateCounterLabel() {
        let count = photoCount
        // A single photo needs no position ("1 of 1" is noise).
        guard count > 1 else {
            counterLabel.text = nil
            return
        }
        counterLabel.text = String(format: strings.counterFormat, currentIndex + 1, count)
    }

    func updatePhotoAccessibility() {
        let count = photoCount
        guard count > 0 else {
            collectionView.accessibilityLabel = nil
            collectionView.accessibilityHint = nil
            return
        }
        collectionView.accessibilityLabel = String(format: strings.counterFormat, currentIndex + 1, count)
        collectionView.accessibilityHint = strings.tapToToggleHint
    }

    func updateDateLabel() {
        guard currentIndex >= 0, currentIndex < photoCount else {
            dateLabel.text = nil
            datePillView.isHidden = true
            return
        }
        if let date = dataSource?.photoDate(at: currentIndex) {
            dateLabel.text = LMKDateFormat.string(date)
        } else {
            dateLabel.text = dataSource?.photoSubtitle(at: currentIndex)
        }
        // With no date and no subtitle the pill would render as an empty floating blob.
        datePillView.isHidden = (dateLabel.text ?? "").isEmpty
    }

    func resetZoomOnNonCurrentCells() {
        for case let cell as LMKPhotoBrowserCell in collectionView.visibleCells {
            if let indexPath = collectionView.indexPath(for: cell), indexPath.item != currentIndex {
                cell.resetZoom()
            }
        }
    }
}

// MARK: - UICollectionViewDataSource

extension LMKPhotoBrowserViewController: UICollectionViewDataSource {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        photoCount
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: LMKPhotoBrowserCell.identifier, for: indexPath) as? LMKPhotoBrowserCell else {
            return UICollectionViewCell()
        }
        cell.delegate = self
        cell.apply(style: resolvedStyle, theme: traitCollection.lmkTheme, dynamicRange: effectiveDynamicRange)
        cell.apply(strings: strings)
        cell.chromeAlpha = dismissButton.alpha

        let photoIndex = indexPath.item
        guard photoIndex < photoCount else { return cell }

        let isLive = dataSource?.photoIsLivePhoto(at: photoIndex) ?? false
        // Placeholder first; the cell's generation token guards both async applies.
        cell.configure(screenSize: view.bounds.size, isLive: isLive) { [weak self] in
            await self?.dataSource?.photo(at: photoIndex)
        }
        // Always asked: `photoIsLivePhoto` only shows the badge before the load lands, and a
        // source that vends a Live Photo without it still plays.
        cell.loadLivePhoto { [weak self] in
            await self?.dataSource?.photoLivePhoto(at: photoIndex)
        }
        return cell
    }
}

// MARK: - UICollectionViewDelegate

extension LMKPhotoBrowserViewController: UICollectionViewDelegate {
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        handleScrollEnd(scrollView)
    }

    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        handleScrollEnd(scrollView)
    }

    private func handleScrollEnd(_ scrollView: UIScrollView) {
        let count = photoCount
        guard scrollView === collectionView, collectionView.bounds.width > 0, count > 0 else { return }
        let pageIndex = Int((collectionView.contentOffset.x / collectionView.bounds.width).rounded())
        updateCurrentIndex(max(0, min(pageIndex, count - 1)))
        resetZoomOnNonCurrentCells()
        restoreOverlayAfterPaging()
    }

    /// A page left while zoomed took the chrome with it; the page that arrived at 1x gets it back.
    private func restoreOverlayAfterPaging() {
        guard !isOverlayHidden, dismissButton.alpha < 1 else { return }
        guard currentCell?.isZoomed != true else { return }
        let duration = LMKAnimation.shouldAnimate ? LMKAnimation.Duration.normal : 0
        UIView.animate(withDuration: duration, delay: 0, options: .curveEaseOut) { [weak self] in
            self?.setOverlayAlpha(1)
        }
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension LMKPhotoBrowserViewController: UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        // Cell width includes the inter-page gap (trailing padding inside the cell).
        CGSize(width: view.bounds.width + resolvedStyle.pageGap(theme: traitCollection.lmkTheme), height: view.bounds.height)
    }
}

// MARK: - LMKPhotoBrowserCellDelegate

extension LMKPhotoBrowserViewController: LMKPhotoBrowserCellDelegate {
    func photoCellDidRequestDismiss(_ cell: LMKPhotoBrowserCell) {
        performDismissWithSnapTiming(from: cell)
    }

    func photoCell(_ cell: LMKPhotoBrowserCell, didUpdateDismissProgress progress: CGFloat) {
        updateDismissProgress(progress)
    }

    func photoCell(_ cell: LMKPhotoBrowserCell, setPagingEnabled enabled: Bool) {
        collectionView.isScrollEnabled = enabled
    }

    func photoCell(_ cell: LMKPhotoBrowserCell, didChangeZoomState zoomed: Bool) {
        if zoomed {
            // The chrome gets out of the way while zoomed.
            let duration = LMKAnimation.shouldAnimate ? LMKAnimation.Duration.fast : 0
            UIView.animate(withDuration: duration, delay: 0, options: .curveEaseOut) { [weak self] in
                self?.setOverlayAlpha(0)
            }
        } else if !isOverlayHidden {
            let duration = LMKAnimation.shouldAnimate ? LMKAnimation.Duration.normal : 0
            UIView.animate(withDuration: duration, delay: 0, options: .curveEaseOut) { [weak self] in
                self?.setOverlayAlpha(1)
            }
        }
    }
}
