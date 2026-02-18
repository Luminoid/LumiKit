//
//  LMKPhotoBrowserCell.swift
//  LumiKit
//
//  Full-screen photo browser cell with zoom, pinch, and swipe-to-dismiss support.
//

import SnapKit
import UIKit

/// Inter-page gap between photos in the photo browser. The spacing is included within each
/// cell (cell width = screen width + this value) rather than as layout-level minimumLineSpacing,
/// because UICollectionViewFlowLayout doesn't add spacing after the last cell — causing an
/// accumulated offset bug on the final page.
let lmkPhotoBrowserInterPageSpacing: CGFloat = 16


// MARK: - LMKPhotoBrowserCell

public final class LMKPhotoBrowserCell: UICollectionViewCell {
    public static let identifier = "LMKPhotoBrowserCell"

    // MARK: - Constants

    /// Minimum zoom scale for photo preview
    private static let minimumZoomScale: CGFloat = 1.0

    /// Maximum zoom scale for photo preview
    private static let maximumZoomScale: CGFloat = 3.0

    /// Initial image view size (will be updated based on actual image size)
    private static let initialImageViewSize: CGFloat = 100

    /// Zoom threshold to check if image is zoomed
    private static let zoomThreshold: CGFloat = 1.0

    /// Fraction of scroll view height; vertical drag beyond this dismisses the photo browser
    private static let verticalDismissThresholdFraction: CGFloat = 0.2
    /// Minimum vertical distance (pt) to trigger dismiss
    private static let verticalDismissMinimumPoints: CGFloat = 80
    /// Minimum vertical velocity (pt/s) to trigger dismiss (quick flick)
    private static let verticalDismissVelocityThreshold: CGFloat = 700
    /// Minimum vertical distance (pt) before velocity-based dismiss kicks in (prevents accidental flick dismiss)
    private static let verticalDismissMinDistanceForVelocity: CGFloat = 20

    /// Called when user releases after a large vertical swipe (dismiss photo browser)
    public var onVerticalSwipeToDismiss: (() -> Void)?
    /// Called during vertical pan: progress 0 (no drag) to 1 (at or past dismiss threshold)
    public var onVerticalPanProgressForDismiss: ((CGFloat) -> Void)?
    /// Called when zoom state changes: true = zooming in / zoomed, false = back to 1x
    public var onZoomStateChanged: ((Bool) -> Void)?

    private let scrollView = UIScrollView()
    private let imageView = UIImageView()
    private var widthConstraint: Constraint?
    private var heightConstraint: Constraint?

    /// Pinch gesture: anchor zoom to gesture center at start (fixed for the whole gesture).
    private var pinchCenterInScrollView: CGPoint = .zero
    /// Pinch center in contentView coordinates for sub-1x shrink transform
    private var pinchCenterInContentView: CGPoint = .zero
    private var zoomScaleAtPinchStart: CGFloat = 1.0
    private var contentOffsetAtPinchStart: CGPoint = .zero
    private var contentInsetAtPinchStart: UIEdgeInsets = .zero
    private var isPinching: Bool = false
    /// True once dismiss has been triggered; prevents snap-back when deceleration ends
    private var isDismissing: Bool = false
    /// True only during a single-finger drag at 1x zoom — gates all vertical-dismiss logic
    /// so that two-finger gestures (pinch, two-finger drag) never trigger the dismiss flow.
    private var isDismissDragActive: Bool = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = LMKColor.photoBrowserBackground
        contentView.backgroundColor = LMKColor.photoBrowserBackground

        // Setup scroll view for zooming
        scrollView.delegate = self
        scrollView.minimumZoomScale = Self.minimumZoomScale
        scrollView.maximumZoomScale = Self.maximumZoomScale
        scrollView.decelerationRate = .fast
        scrollView.alwaysBounceVertical = true
        scrollView.bouncesZoom = false
        scrollView.contentInsetAdjustmentBehavior = .never

        #if targetEnvironment(macCatalyst)
            // Show scroll indicators on Mac when zoomed
            scrollView.showsHorizontalScrollIndicator = true
            scrollView.showsVerticalScrollIndicator = true
        #else
            scrollView.showsHorizontalScrollIndicator = false
            scrollView.showsVerticalScrollIndicator = false
        #endif

        scrollView.backgroundColor = LMKColor.photoBrowserBackground
        contentView.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            // Trailing inset = inter-page spacing. The spacing is part of the cell
            // (cell width = screen width + spacing), so the scroll view fills only
            // the screen-width portion. The trailing gap shows the cell's dark background.
            make.top.bottom.leading.equalToSuperview()
            make.trailing.equalToSuperview().offset(-lmkPhotoBrowserInterPageSpacing)
        }

        // Setup image view — clipsToBounds is intentionally false: scaleAspectFit already
        // keeps the image within bounds, and the scroll view clips during zoom. Removing
        // clipsToBounds prevents CALayer.masksToBounds from anti-aliasing the image edge
        // at fractional pixel positions during zoom animations (white line artifact).
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = false
        imageView.backgroundColor = LMKColor.photoBrowserBackground
        scrollView.addSubview(imageView)

        // Center the image view in the scroll view
        imageView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview()
            widthConstraint = make.width.equalTo(Self.initialImageViewSize).priority(.high).constraint
            heightConstraint = make.height.equalTo(Self.initialImageViewSize).priority(.high).constraint
        }

        // Pinch gesture to track zoom anchor (center of pinch); zoom is still done by scroll view
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        pinchGesture.delegate = self
        scrollView.addGestureRecognizer(pinchGesture)
    }

    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        switch gesture.state {
        case .began:
            isPinching = true
            // Anchor zoom to the center of the pinch at gesture start (fixed for the whole gesture)
            pinchCenterInScrollView = gesture.location(in: scrollView)
            pinchCenterInContentView = gesture.location(in: contentView)
            zoomScaleAtPinchStart = scrollView.zoomScale
            contentOffsetAtPinchStart = scrollView.contentOffset
            contentInsetAtPinchStart = scrollView.contentInset
        case .changed:
            // Scroll view is clamped at min/max (bouncesZoom = false).
            // We apply our own rubber-band transform for pinch beyond those limits.
            let intendedScale = zoomScaleAtPinchStart * gesture.scale
            if intendedScale < 1.0 {
                // Below min: shrink with rubber-band toward pinch center
                let wasIdentity = scrollView.transform.isIdentity
                let scale = max(0.5, pow(max(0.001, intendedScale), 0.5))
                let center = CGPoint(x: contentView.bounds.midX, y: contentView.bounds.midY)
                let tx = (pinchCenterInContentView.x - center.x) * (1 - scale)
                let ty = (pinchCenterInContentView.y - center.y) * (1 - scale)
                scrollView.transform = CGAffineTransform(a: scale, b: 0, c: 0, d: scale, tx: tx, ty: ty)
                if wasIdentity {
                    onZoomStateChanged?(true)
                }
            } else if intendedScale > Self.maximumZoomScale {
                // Above max: overshoot with rubber-band around pinch center
                let wasIdentity = scrollView.transform.isIdentity
                let overshoot = intendedScale / Self.maximumZoomScale
                let scale = min(1.5, pow(overshoot, 0.5))
                let center = CGPoint(x: contentView.bounds.midX, y: contentView.bounds.midY)
                let tx = (pinchCenterInContentView.x - center.x) * (1 - scale)
                let ty = (pinchCenterInContentView.y - center.y) * (1 - scale)
                scrollView.transform = CGAffineTransform(a: scale, b: 0, c: 0, d: scale, tx: tx, ty: ty)
                if wasIdentity {
                    onZoomStateChanged?(true)
                }
            } else if !scrollView.transform.isIdentity {
                // Back within normal range, remove rubber-band transform
                scrollView.transform = .identity
            }
        case .ended, .cancelled:
            isPinching = false
            // Animate sub-1x shrink back to normal
            if !scrollView.transform.isIdentity {
                if LMKAnimationHelper.shouldAnimate {
                    UIView.animate(
                        withDuration: LMKAnimationHelper.Duration.actionSheet,
                        delay: 0,
                        usingSpringWithDamping: LMKAnimationHelper.Spring.damping,
                        initialSpringVelocity: 0,
                        options: [.allowUserInteraction, .beginFromCurrentState],
                    ) {
                        self.scrollView.transform = .identity
                    } completion: { _ in
                        self.onZoomStateChanged?(false)
                    }
                } else {
                    scrollView.transform = .identity
                    onZoomStateChanged?(false)
                }
            }
        default:
            break
        }
    }

    public func configure(with image: UIImage, screenSize: CGSize) {
        imageView.image = image
        updateImageSize(image: image, screenSize: screenSize)
        resetZoom()
    }

    public func updateImageSize(image: UIImage, screenSize: CGSize) {
        let fittedSize = calculateFittedSize(imageSize: image.size, screenSize: screenSize)
        widthConstraint?.update(offset: fittedSize.width)
        heightConstraint?.update(offset: fittedSize.height)

        // Force layout update
        setNeedsLayout()
        layoutIfNeeded()

        // Update scroll view content size after layout
        DispatchQueue.main.async { [weak self] in
            self?.updateScrollViewContentSize()
        }
    }

    public func resetZoom() {
        scrollView.setZoomScale(Self.minimumZoomScale, animated: false)
        scrollView.transform = .identity
        // Reset content offset after a brief delay to ensure layout is complete
        DispatchQueue.main.async { [weak self] in
            self?.scrollView.contentOffset = .zero
            self?.centerImageView()
        }
    }

    public var isZoomed: Bool {
        scrollView.zoomScale > Self.zoomThreshold
    }

    /// Double-tap to zoom: zoom to 2x centered on point (in cell coordinates), or reset to 1x if already zoomed.
    public func zoomAtLocationInCell(_ locationInCell: CGPoint) {
        let locationInScrollView = scrollView.convert(locationInCell, from: contentView)
        if scrollView.zoomScale > Self.zoomThreshold {
            scrollView.setZoomScale(Self.minimumZoomScale, animated: true)
        } else {
            let zoomScale: CGFloat = 2.0
            let scrollViewSize = scrollView.bounds.size
            let w = scrollViewSize.width / zoomScale
            let h = scrollViewSize.height / zoomScale
            let x = locationInScrollView.x - (w / 2.0)
            let y = locationInScrollView.y - (h / 2.0)
            let rect = CGRect(x: x, y: y, width: w, height: h)
            scrollView.zoom(to: rect, animated: true)
        }
    }

    private func updateScrollViewContentSize() {
        // Use the image view's frame size (after constraints are applied)
        let imageSize = imageView.frame.size
        let scrollViewSize = scrollView.bounds.size

        guard imageSize.width > 0, imageSize.height > 0,
              scrollViewSize.width > 0, scrollViewSize.height > 0 else {
            return
        }

        // Set content size to be at least as large as scroll view bounds
        // This ensures the scroll view can scroll if needed when zoomed
        let zoomScale = scrollView.zoomScale
        let scaledImageSize = CGSize(
            width: imageSize.width * zoomScale,
            height: imageSize.height * zoomScale,
        )

        scrollView.contentSize = CGSize(
            width: max(scrollViewSize.width, scaledImageSize.width),
            height: max(scrollViewSize.height, scaledImageSize.height),
        )

        // Center the image
        centerImageView()
    }

    private func centerImageView() {
        let scrollViewSize = scrollView.bounds.size
        let imageViewSize = imageView.frame.size

        guard scrollViewSize.width > 0, scrollViewSize.height > 0,
              imageViewSize.width > 0, imageViewSize.height > 0 else {
            return
        }

        // Calculate insets to center the image when it's smaller than scroll view
        var horizontalInset: CGFloat = 0
        var verticalInset: CGFloat = 0

        if imageViewSize.width < scrollViewSize.width {
            horizontalInset = (scrollViewSize.width - imageViewSize.width) / 2
        }

        if imageViewSize.height < scrollViewSize.height {
            verticalInset = (scrollViewSize.height - imageViewSize.height) / 2
        }

        scrollView.contentInset = UIEdgeInsets(
            top: verticalInset,
            left: horizontalInset,
            bottom: verticalInset,
            right: horizontalInset,
        )

        // Reset content offset to center when not zoomed
        // Since the image view is constrained to center, we just need to reset offset
        if scrollView.zoomScale == 1.0 {
            scrollView.contentOffset = .zero
        }
    }

    private func snapToCenterIfNeeded(animated: Bool) {
        // Only snap to center when not zoomed
        guard scrollView.zoomScale == 1.0 else {
            return
        }

        let currentOffset = scrollView.contentOffset
        let targetOffset = CGPoint(x: 0, y: 0)

        // Only animate if there's a vertical offset (or horizontal, but mainly vertical)
        let tolerance: CGFloat = 1.0
        if abs(currentOffset.y) > tolerance || abs(currentOffset.x) > tolerance {
            if animated, LMKAnimationHelper.shouldAnimate {
                UIView.animate(withDuration: LMKAnimationHelper.Duration.cardExpand, delay: 0, usingSpringWithDamping: LMKAnimationHelper.Spring.damping, initialSpringVelocity: 0.5, options: [.allowUserInteraction, .beginFromCurrentState], animations: {
                    self.scrollView.contentOffset = targetOffset
                }, completion: nil)
            } else {
                scrollView.contentOffset = targetOffset
            }
        }
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        // Force layout of image view first
        imageView.setNeedsLayout()
        imageView.layoutIfNeeded()
        updateScrollViewContentSize()
    }

    /// Calculates the proper size for an image to fit within screen bounds
    private func calculateFittedSize(imageSize: CGSize, screenSize: CGSize) -> CGSize {
        guard imageSize.width > 0, imageSize.height > 0,
              screenSize.width > 0, screenSize.height > 0 else {
            return screenSize
        }

        let imageAspectRatio = imageSize.height / imageSize.width
        let screenAspectRatio = screenSize.height / screenSize.width

        var fittedSize

            // If photo height/width ratio > screen height/width ratio,
            // photo height should be same as screen height
            = if imageAspectRatio > screenAspectRatio {
            CGSize(
                width: screenSize.height / imageAspectRatio,
                height: screenSize.height,
            )
        } else {
            // Otherwise, photo width should be same as screen width
            CGSize(
                width: screenSize.width,
                height: screenSize.width * imageAspectRatio,
            )
        }

        // Ensure size doesn't exceed screen bounds (safety check)
        fittedSize.width = min(fittedSize.width, screenSize.width)
        fittedSize.height = min(fittedSize.height, screenSize.height)

        return fittedSize
    }

    override public func prepareForReuse() {
        super.prepareForReuse()
        resetZoom()
        isDismissing = false
        isDismissDragActive = false
        onVerticalSwipeToDismiss = nil
        onVerticalPanProgressForDismiss = nil
        onZoomStateChanged = nil
    }
}

// MARK: - UIScrollViewDelegate for LMKPhotoBrowserCell

extension LMKPhotoBrowserCell: UIScrollViewDelegate {
    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        imageView
    }

    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        // Only a single-finger drag at 1x zoom may trigger vertical dismiss.
        // Two-finger drags (zoom, two-finger pan) are excluded.
        isDismissDragActive = scrollView.panGestureRecognizer.numberOfTouches == 1
            && scrollView.zoomScale == 1.0

        if isDismissDragActive {
            // Lock zoom while dismiss-drag is active so pinch can't fire simultaneously
            scrollView.maximumZoomScale = Self.minimumZoomScale
        }
    }

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // Stop updating progress once dismiss has been triggered (prevents fighting the dismiss animation)
        guard !isDismissing else { return }
        // Skip when sub-1x pinch transform is active (prevents transparent background during pinch)
        guard scrollView.transform.isIdentity else { return }
        // Only single-finger vertical drags may drive dismiss progress
        guard isDismissDragActive,
              scrollView.isDragging || scrollView.isDecelerating else { return }
        let threshold = verticalDismissThreshold(for: scrollView)
        let offsetY = abs(scrollView.contentOffset.y)
        // Continuous progress from 0 (no drag) to 1 (at dismiss threshold) for immediate visual feedback
        let progress = min(1, offsetY / threshold)
        onVerticalPanProgressForDismiss?(progress)
    }

    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        // Only commit dismiss for a single-finger drag session
        if isDismissDragActive {
            commitVerticalDrag(scrollView: scrollView, willDecelerate: decelerate)
            if !decelerate {
                isDismissDragActive = false
                // Restore zoom capability after dismiss-drag ends
                scrollView.maximumZoomScale = Self.maximumZoomScale
            }
        }
    }

    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        // Deceleration phase of a single-finger drag: check dismiss, then reset
        if isDismissDragActive {
            commitVerticalDrag(scrollView: scrollView, willDecelerate: false)
            isDismissDragActive = false
            // Restore zoom capability after dismiss-drag ends
            scrollView.maximumZoomScale = Self.maximumZoomScale
        }
    }

    private func verticalDismissThreshold(for scrollView: UIScrollView) -> CGFloat {
        max(
            Self.verticalDismissMinimumPoints,
            scrollView.bounds.height * Self.verticalDismissThresholdFraction,
        )
    }

    /// On gesture end: dismiss if threshold reached or velocity is high enough; otherwise snap back and reset transparency
    private func commitVerticalDrag(scrollView: UIScrollView, willDecelerate: Bool) {
        let threshold = verticalDismissThreshold(for: scrollView)
        let offsetY = abs(scrollView.contentOffset.y)
        let velocity = abs(scrollView.panGestureRecognizer.velocity(in: scrollView).y)

        let distanceReached = offsetY >= threshold
        let velocityReached = velocity >= Self.verticalDismissVelocityThreshold
            && offsetY >= Self.verticalDismissMinDistanceForVelocity

        if distanceReached || velocityReached {
            isDismissing = true
            onVerticalSwipeToDismiss?()
        } else if !isDismissing {
            onVerticalPanProgressForDismiss?(0)
            if !willDecelerate {
                snapToCenterIfNeeded(animated: true)
            }
        }
    }

    public func scrollViewDidZoom(_ scrollView: UIScrollView) {
        // Update content size when zooming
        updateScrollViewContentSize()
        if isPinching {
            // Keep the point under the pinch center fixed so the image zooms in all directions from that point
            let newScale = scrollView.zoomScale
            let oldScale = zoomScaleAtPinchStart
            let p = pinchCenterInScrollView
            let oldOffset = contentOffsetAtPinchStart
            let oldInsets = contentInsetAtPinchStart
            let currentInsets = scrollView.contentInset
            // Content point under p at start: (oldOffset + p - oldInsets); keep it under p after zoom using current insets
            let contentX = (oldOffset.x + p.x - oldInsets.left) / oldScale * newScale - p.x + currentInsets.left
            let contentY = (oldOffset.y + p.y - oldInsets.top) / oldScale * newScale - p.y + currentInsets.top
            scrollView.contentOffset = CGPoint(x: contentX, y: contentY)
        } else {
            centerImageView()
        }
    }

    public func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        // A zoom gesture means multi-finger — cancel any dismiss tracking
        isDismissDragActive = false
        // Disable vertical bounce so dismiss-drag can't start during zoom
        scrollView.alwaysBounceVertical = false
        // Notify parent collection view to disable scrolling
        if let collectionView = findCollectionView() {
            collectionView.isScrollEnabled = false
        }
        // Auto-hide overlay when zooming begins
        onZoomStateChanged?(true)
    }

    public func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        // Re-enable collection view scrolling when zoom ends at scale 1.0
        if scale == 1.0 {
            // Restore vertical bounce for dismiss-drag now that zoom is done
            scrollView.alwaysBounceVertical = true
            if let collectionView = findCollectionView() {
                collectionView.isScrollEnabled = true
            }
            // Snap to center when zoom returns to 1.0
            snapToCenterIfNeeded(animated: true)
            // Restore overlay when zoom returns to 1x (skip if sub-1x spring animation is in progress)
            if scrollView.transform.isIdentity {
                onZoomStateChanged?(false)
            }
        }
    }

    private func findCollectionView() -> UICollectionView? {
        var superview = self.superview
        while superview != nil {
            if let collectionView = superview as? UICollectionView {
                return collectionView
            }
            superview = superview?.superview
        }
        return nil
    }
}

// MARK: - UIGestureRecognizerDelegate (LMKPhotoBrowserCell)

extension LMKPhotoBrowserCell: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // Allow our pinch (for anchor point) to run with the scroll view's pinch (for zoom)
        true
    }
}
