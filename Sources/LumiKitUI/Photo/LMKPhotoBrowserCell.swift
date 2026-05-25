//
//  LMKPhotoBrowserCell.swift
//  LumiKit
//
//  Full-screen photo browser cell with zoom, pinch, and swipe-to-dismiss support.
//

import PhotosUI
import SnapKit
import UIKit

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
    /// Fixed height of the LIVE capsule badge; corner radius is half this.
    private static let liveBadgeHeight: CGFloat = 22
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
    /// Called when the cell needs to enable/disable parent collection view scrolling.
    /// true = enable scrolling, false = disable scrolling.
    public var onPagingScrollEnabled: ((Bool) -> Void)?

    private let scrollView = UIScrollView()
    private let imageView = UIImageView()
    private lazy var livePhotoView: PHLivePhotoView = {
        let view = PHLivePhotoView()
        view.contentMode = .scaleAspectFit
        view.isHidden = true
        view.isAccessibilityElement = true
        view.accessibilityLabel = "Live Photo"
        view.delegate = self
        return view
    }()

    /// Capsule shown in the top-leading corner when the cell is displaying a
    /// Live Photo, mirroring the iOS Photos app indicator. Sits to the right
    /// of the browser's action button so it doesn't overlap the existing
    /// overlay. Fades out during active playback to match the system behavior.
    private lazy var liveBadge: UIView = {
        let container = UIView()
        container.backgroundColor = UIColor.black.withAlphaComponent(LMKAlpha.overlayStrong)
        // Capsule shape, set directly because layoutSubviews on the cell can fire
        // before the badge's own bounds resolve, leaving a deferred bounds.height/2
        // stuck at 0 on the first pass.
        container.layer.cornerRadius = Self.liveBadgeHeight / 2
        container.clipsToBounds = true
        container.isHidden = true

        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 12, weight: .semibold)
        let icon = UIImageView(image: UIImage(systemName: "livephoto", withConfiguration: symbolConfig))
        icon.tintColor = LMKColor.white
        icon.contentMode = .scaleAspectFit

        let label = UILabel()
        label.text = "LIVE"
        label.textColor = LMKColor.white
        label.font = LMKTypography.extraSmallSemibold

        let stack = UIStackView(arrangedSubviews: [icon, label])
        stack.axis = .horizontal
        stack.spacing = LMKSpacing.xs
        stack.alignment = .center
        stack.isUserInteractionEnabled = false

        container.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(
                UIEdgeInsets(top: LMKSpacing.xs, left: LMKSpacing.small, bottom: LMKSpacing.xs, right: LMKSpacing.small)
            )
        }

        #if targetEnvironment(macCatalyst)
            // On Mac there's no long-press to trigger PHLivePhotoView playback;
            // hover the LIVE badge to play, exit to stop. Matches the cursor-
            // discoverable toggle pattern on macOS Photos.
            container.isUserInteractionEnabled = true
            let hover = UIHoverGestureRecognizer(target: self, action: #selector(handleLiveBadgeHover(_:)))
            container.addGestureRecognizer(hover)
            container.addInteraction(UIPointerInteraction(delegate: self))
        #else
            container.isUserInteractionEnabled = false
        #endif
        return container
    }()

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
            make.trailing.equalToSuperview().offset(-LMKPhotoBrowserConfig.interPageSpacing)
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

        // Live photo view mirrors imageView's frame so the still → live swap
        // lines up pixel-perfectly. Hidden until a PHLivePhoto is configured.
        scrollView.addSubview(livePhotoView)
        livePhotoView.snp.makeConstraints { make in
            make.edges.equalTo(imageView)
        }

        // Live badge sits on the contentView (above the scroll view) so it
        // stays anchored to the corner regardless of zoom. Stacked directly
        // below the browser VC's action button, same leading edge so they
        // align vertically.
        contentView.addSubview(liveBadge)
        liveBadge.snp.makeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide.snp.top).offset(
                LMKSpacing.large + LMKPhotoBrowserConfig.overlayButtonSize + LMKSpacing.small
            )
            make.leading.equalToSuperview().offset(LMKSpacing.large)
            make.height.equalTo(Self.liveBadgeHeight)
        }

        // Pinch gesture to track zoom anchor (center of pinch); zoom is still done by scroll view.
        // Mac Catalyst: trackpad pinch wasn't reaching the scroll view's native zoom while this
        // custom recognizer was attached (zoom-in stayed at 1x). The custom recognizer only adds
        // sub-1x / over-3x rubber-band, which trackpad users don't expect anyway, so it's
        // dropped on Mac to let the scroll view's built-in pinch handle zoom unimpeded.
        #if !targetEnvironment(macCatalyst)
            let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
            pinchGesture.delegate = self
            scrollView.addGestureRecognizer(pinchGesture)
        #endif
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
                        options: [.allowUserInteraction, .beginFromCurrentState]
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

    public func configure(with image: UIImage, screenSize: CGSize, isLive: Bool = false) {
        imageView.image = image
        livePhotoView.livePhoto = nil
        livePhotoView.isHidden = true
        imageView.isHidden = false
        // Badge visibility is driven by the synchronous `isLive` flag so it
        // appears immediately on grid-to-browser transitions, independent of
        // the async `PHLivePhoto` load that drives playback.
        liveBadge.isHidden = !isLive
        liveBadge.alpha = 1
        updateImageSize(image: image, screenSize: screenSize)
        resetZoom()
    }

    /// Upgrades a cell already showing the still image to a playable Live Photo.
    /// Keeps the same layout — the PHLivePhotoView is positioned on top of the
    /// imageView with identical constraints. PHLivePhotoView has its own
    /// long-press recognizer, so no extra gesture wiring is required. The
    /// badge is already visible from `configure(... isLive: true)` — this just
    /// enables playback.
    public func configureLivePhoto(_ livePhoto: PHLivePhoto) {
        livePhotoView.livePhoto = livePhoto
        livePhotoView.isHidden = false
        imageView.isHidden = true
        liveBadge.isHidden = false
        liveBadge.alpha = 1
        // Active content view just changed (imageView → livePhotoView), so reset zoom
        // to drop any transform on the previous viewForZooming and let the scroll view
        // re-query for the new active view on the next pinch.
        resetZoom()
    }

    public func updateImageSize(image: UIImage, screenSize: CGSize) {
        let fittedSize = calculateFittedSize(imageSize: image.size, screenSize: screenSize)
        widthConstraint?.update(offset: fittedSize.width)
        heightConstraint?.update(offset: fittedSize.height)

        // Force layout then recalculate content size
        setNeedsLayout()
        layoutIfNeeded()
        updateScrollViewContentSize()
    }

    public func resetZoom() {
        scrollView.setZoomScale(Self.minimumZoomScale, animated: false)
        scrollView.transform = .identity
        scrollView.contentOffset = .zero
        // setZoomScale only clears the current viewForZooming's transform; clear both
        // explicitly so a reused cell that switches between still and live state doesn't
        // leak a transform from the previous active view.
        imageView.transform = .identity
        livePhotoView.transform = .identity
        setNeedsLayout()
        layoutIfNeeded()
    }

    public var isZoomed: Bool {
        scrollView.zoomScale > Self.zoomThreshold
    }

    /// The currently visible content view — `livePhotoView` when displaying a Live Photo,
    /// otherwise `imageView`. UIScrollView zooms whatever this returns from `viewForZooming`,
    /// so swapping it lets the scroll view's native zoom anchor track the actually-visible
    /// view (PHLivePhotoView's internal layers don't render correctly under a manually
    /// mirrored transform on a sibling view).
    private var activeContentView: UIView {
        livePhotoView.isHidden ? imageView : livePhotoView
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
            height: imageSize.height * zoomScale
        )

        scrollView.contentSize = CGSize(
            width: max(scrollViewSize.width, scaledImageSize.width),
            height: max(scrollViewSize.height, scaledImageSize.height)
        )

        // Center the image
        centerImageView()
    }

    private func centerImageView() {
        let scrollViewSize = scrollView.bounds.size
        // Use the active content view so the inset reflects the actually-zoomed view
        // (livePhotoView for live photos — imageView is un-transformed in that case
        // since viewForZooming returns livePhotoView).
        let imageViewSize = activeContentView.frame.size

        guard scrollViewSize.width > 0, scrollViewSize.height > 0,
              imageViewSize.width > 0, imageViewSize.height > 0 else {
            return
        }

        // contentInset serves two roles, and `abs` covers both:
        //   * image smaller than scroll view → inset = (scrollSize - imageSize)/2 centers it.
        //   * image larger than scroll view (zoomed in) → inset = (imageSize - scrollSize)/2
        //     enables negative contentOffset so the user can pan to the image edges.
        // The image view is centered in the scroll view via Auto Layout, so a zoomed-in
        // image overflows symmetrically into negative content space — without this inset,
        // contentOffset is clamped at 0 and the top/leading edges become unreachable.
        // Most visible on vertical live photos at 2x+: both dimensions overflow.
        let horizontalInset = abs(scrollViewSize.width - imageViewSize.width) / 2
        let verticalInset = abs(scrollViewSize.height - imageViewSize.height) / 2

        scrollView.contentInset = UIEdgeInsets(
            top: verticalInset,
            left: horizontalInset,
            bottom: verticalInset,
            right: horizontalInset
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
                UIView.animate(
                    withDuration: LMKAnimationHelper.Duration.cardExpand,
                    delay: 0,
                    usingSpringWithDamping: LMKAnimationHelper.Spring.damping,
                    initialSpringVelocity: 0.5,
                    options: [.allowUserInteraction, .beginFromCurrentState],
                    animations: {
                        self.scrollView.contentOffset = targetOffset
                    },
                    completion: nil
                )
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
                height: screenSize.height
            )
        } else {
            // Otherwise, photo width should be same as screen width
            CGSize(
                width: screenSize.width,
                height: screenSize.width * imageAspectRatio
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
        livePhotoView.livePhoto = nil
        livePhotoView.isHidden = true
        imageView.isHidden = false
        liveBadge.isHidden = true
        liveBadge.alpha = 1
        onVerticalSwipeToDismiss = nil
        onVerticalPanProgressForDismiss = nil
        onZoomStateChanged = nil
        onPagingScrollEnabled = nil
    }
}

// MARK: - UIScrollViewDelegate for LMKPhotoBrowserCell

extension LMKPhotoBrowserCell: UIScrollViewDelegate {
    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        activeContentView
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
            scrollView.bounds.height * Self.verticalDismissThresholdFraction
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
        // Notify parent to disable paging while zoomed
        onPagingScrollEnabled?(false)
        // Auto-hide overlay when zooming begins
        onZoomStateChanged?(true)
    }

    public func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        // Re-enable collection view scrolling when zoom ends at scale 1.0
        if scale == 1.0 {
            // Restore vertical bounce for dismiss-drag now that zoom is done
            scrollView.alwaysBounceVertical = true
            onPagingScrollEnabled?(true)
            // Snap to center when zoom returns to 1.0
            snapToCenterIfNeeded(animated: true)
            // Restore overlay when zoom returns to 1x (skip if sub-1x spring animation is in progress)
            if scrollView.transform.isIdentity {
                onZoomStateChanged?(false)
            }
        }
    }
}

// MARK: - PHLivePhotoViewDelegate

extension LMKPhotoBrowserCell: PHLivePhotoViewDelegate {
    public func livePhotoView(_: PHLivePhotoView, willBeginPlaybackWith _: PHLivePhotoViewPlaybackStyle) {
        let duration = LMKAnimationHelper.shouldAnimate ? LMKAnimationHelper.Duration.uiShort : 0
        UIView.animate(withDuration: duration) { [weak self] in
            self?.liveBadge.alpha = 0
        }
    }

    public func livePhotoView(_: PHLivePhotoView, didEndPlaybackWith _: PHLivePhotoViewPlaybackStyle) {
        let duration = LMKAnimationHelper.shouldAnimate ? LMKAnimationHelper.Duration.uiShort : 0
        UIView.animate(withDuration: duration) { [weak self] in
            self?.liveBadge.alpha = 1
        }
    }
}

// MARK: - UIGestureRecognizerDelegate (LMKPhotoBrowserCell)

extension LMKPhotoBrowserCell: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // Allow our pinch (for anchor point) to run with the scroll view's pinch (for zoom)
        true
    }
}

#if targetEnvironment(macCatalyst)

    // MARK: - Mac Catalyst Live Photo Hover

    fileprivate extension LMKPhotoBrowserCell {
        @objc func handleLiveBadgeHover(_ recognizer: UIHoverGestureRecognizer) {
            guard livePhotoView.livePhoto != nil, !livePhotoView.isHidden else { return }
            switch recognizer.state {
            case .began:
                livePhotoView.startPlayback(with: .full)
            case .ended, .cancelled, .failed:
                livePhotoView.stopPlayback()
            default:
                break
            }
        }
    }

    // MARK: - UIPointerInteractionDelegate

    extension LMKPhotoBrowserCell: UIPointerInteractionDelegate {
        public func pointerInteraction(_ interaction: UIPointerInteraction, styleFor _: UIPointerRegion) -> UIPointerStyle? {
            guard let view = interaction.view else { return nil }
            return UIPointerStyle(effect: .highlight(UITargetedPreview(view: view)))
        }
    }
#endif
