//
//  LMKPhotoBrowserCell.swift
//  LumiKit
//
//  Full-screen photo page with zoom, pinch rubber-banding, Live Photo playback,
//  and the vertical drag that dismisses the browser.
//
//  Gestures on a page:
//  - Pinch zooms around the fingers, with a rubber band under 1x and past the maximum.
//  - Double tap zooms to the tapped point of the photo, or back to 1x.
//  - A vertical drag at 1x (one finger, or a trackpad scroll) moves the photo with the finger
//    and dismisses past the threshold or on a flick; a sideways drag at 1x always pages. Any
//    other drag at 1x (two fingers) coasts back to the center.
//  - Zoomed, a drag pans the photo; a drag past its left or right edge pages the browser.
//  - A long press anywhere on the page plays a Live Photo.
//

import LumiKitUI
import PhotosUI
import SnapKit
import UIKit

// MARK: - Delegate

/// The browser's hooks into a page, set once at dequeue.
@MainActor
protocol LMKPhotoBrowserCellDelegate: AnyObject {
    /// The user released a vertical drag past the dismiss threshold.
    func photoCellDidRequestDismiss(_ cell: LMKPhotoBrowserCell)
    /// Progress of the vertical drag: 0 (no drag) to 1 (at or past the threshold).
    func photoCell(_ cell: LMKPhotoBrowserCell, didUpdateDismissProgress progress: CGFloat)
    /// Whether the browser may page (off while a pinch or zoom animation is running).
    func photoCell(_ cell: LMKPhotoBrowserCell, setPagingEnabled enabled: Bool)
    /// `true` while zooming or zoomed, `false` back at 1x.
    func photoCell(_ cell: LMKPhotoBrowserCell, didChangeZoomState zoomed: Bool)
}

// MARK: - LMKPhotoBrowserCell

final class LMKPhotoBrowserCell: UICollectionViewCell {
    static let identifier = "LMKPhotoBrowserCell"

    // MARK: - Properties

    weak var delegate: (any LMKPhotoBrowserCellDelegate)?

    private let scrollView = UIScrollView()
    private let imageView = UIImageView()
    private lazy var livePhotoView: PHLivePhotoView = {
        let view = PHLivePhotoView()
        view.contentMode = .scaleAspectFit
        view.isHidden = true
        view.delegate = self
        return view
    }()

    /// Capsule in the top-leading corner of a Live Photo page, mirroring the Photos app
    /// indicator. Sits under the browser's action button and fades during playback.
    private let liveBadgeView = UIView()
    private let liveBadgeIcon = UIImageView()
    private let liveBadgeLabel = UILabel()
    private let liveBadgeStack = UIStackView()
    private var liveBadgeTopConstraint: Constraint?
    private var liveBadgeLeadingConstraint: Constraint?
    private var liveBadgeInsets = NSDirectionalEdgeInsets.zero
    /// The badge clears during playback and with the browser's chrome; it shows at the product.
    private var liveBadgePlaybackAlpha: CGFloat = 1
    /// Alpha of the page's own chrome (the LIVE badge), driven with the browser's overlay.
    var chromeAlpha: CGFloat = 1 {
        didSet { updateLiveBadgeAlpha() }
    }

    private var trailingGapConstraint: Constraint?
    /// The photo aspect-fitted to the page at 1x. The photo views are laid out by frame, not
    /// by constraints: a zoom transform and Auto Layout disagree about where a view sits.
    private var fittedSize = CGSize(width: LMKPhotoBrowserMetrics.initialImageViewSide, height: LMKPhotoBrowserMetrics.initialImageViewSide)

    /// Monotonic token identifying the latest configure/reuse cycle, the reuse-safety guard
    /// for the async loads: `Task.cancel()` alone does not stop a body already past its
    /// cancellation checks from delivering; comparing the captured token does.
    private var loadGeneration: UInt64 = 0
    private var imageLoadTask: Task<Void, Never>?
    private var livePhotoLoadTask: Task<Void, Never>?

    /// The dynamic range the still renders with.
    var preferredImageDynamicRange: UIImage.DynamicRange {
        get { imageView.preferredImageDynamicRange }
        set { imageView.preferredImageDynamicRange = newValue }
    }

    private var maximumZoomScale = LMKPhotoBrowserMetrics.maximumZoomScale
    private var doubleTapZoomScale = LMKPhotoBrowserMetrics.doubleTapZoomScale

    /// The point a zoom keeps in place: where it is on the page and which point of the photo
    /// (at 1x) it is. Set for the length of a pinch or a double-tap zoom.
    struct ZoomAnchor: Equatable {
        var pagePoint: CGPoint
        var photoPoint: CGPoint
    }

    private(set) var zoomAnchor: ZoomAnchor?
    private var pinchCenterInContentView: CGPoint = .zero
    private var zoomScaleAtPinchStart: CGFloat = 1
    private var isPinching = false
    /// True once a dismiss has been committed; stops snap-back when deceleration ends.
    private var isDismissing = false
    /// True during a drag at 1x with at most one finger down (a trackpad scroll reports none),
    /// gating every vertical-dismiss path so a two-finger drag never triggers it.
    private var isDismissDragActive = false

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        // The page is the VoiceOver element for its photo; the browser labels it with the
        // counter and date, and the Live Photo view stays inside it.
        isAccessibilityElement = true
        accessibilityTraits = .image

        scrollView.delegate = self
        scrollView.minimumZoomScale = LMKPhotoBrowserMetrics.minimumZoomScale
        scrollView.maximumZoomScale = maximumZoomScale
        scrollView.decelerationRate = .fast
        scrollView.alwaysBounceVertical = true
        scrollView.bouncesZoom = false
        scrollView.contentInsetAdjustmentBehavior = .never
        #if targetEnvironment(macCatalyst)
            scrollView.showsHorizontalScrollIndicator = true
            scrollView.showsVerticalScrollIndicator = true
        #else
            scrollView.showsHorizontalScrollIndicator = false
            scrollView.showsVerticalScrollIndicator = false
        #endif
        contentView.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            // The trailing inset is the inter-page gap: the cell is wider than the page by
            // that much, and the gap shows the stage.
            make.top.bottom.leading.equalToSuperview()
            trailingGapConstraint = make.trailing.equalToSuperview().offset(0).constraint
        }

        // clipsToBounds is deliberately off: aspect-fit keeps the image inside its bounds, the
        // scroll view clips during zoom, and masking would anti-alias the image edge at
        // fractional positions during zoom animations (a white hairline).
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = false
        imageView.preferredImageDynamicRange = .high
        scrollView.addSubview(imageView)
        // The Live Photo view mirrors the image view so the still-to-live swap lines up.
        scrollView.addSubview(livePhotoView)
        // On the page, not the Live Photo view: a long press anywhere plays, the letterbox
        // around a wide photo included. It does nothing while the page shows a still.
        scrollView.addGestureRecognizer(livePhotoView.playbackGestureRecognizer)

        setupLiveBadge()

        // The custom pinch only tracks the anchor and adds the sub-1x / over-max rubber band;
        // zoom itself is the scroll view's. Under Mac Catalyst a trackpad pinch did not reach
        // the scroll view while this recognizer was attached, so the Mac keeps the native zoom.
        #if !targetEnvironment(macCatalyst)
            let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
            pinch.delegate = self
            scrollView.addGestureRecognizer(pinch)
        #endif
    }

    private func setupLiveBadge() {
        liveBadgeView.isHidden = true
        liveBadgeIcon.contentMode = .scaleAspectFit
        liveBadgeStack.lmk_addArrangedSubviews([liveBadgeIcon, liveBadgeLabel])
        liveBadgeStack.axis = .horizontal
        liveBadgeStack.alignment = .center
        liveBadgeStack.isUserInteractionEnabled = false
        liveBadgeView.addSubview(liveBadgeStack)
        liveBadgeStack.snp.makeConstraints { make in
            make.directionalEdges.equalToSuperview().inset(liveBadgeInsets)
        }

        // On the content view (above the scroll view) so it stays anchored under the browser's
        // action button regardless of zoom. The height is a floor: the label scales with
        // Dynamic Type and grows the capsule.
        contentView.addSubview(liveBadgeView)
        liveBadgeView.snp.makeConstraints { make in
            liveBadgeTopConstraint = make.top.equalTo(safeAreaLayoutGuide.snp.top).offset(0).constraint
            liveBadgeLeadingConstraint = make.leading.equalTo(safeAreaLayoutGuide).offset(0).constraint
            make.height.greaterThanOrEqualTo(LMKPhotoBrowserMetrics.liveBadgeHeight)
        }

        #if targetEnvironment(macCatalyst)
            // No long press on the Mac: hovering the badge plays, leaving stops.
            liveBadgeView.isUserInteractionEnabled = true
            liveBadgeView.addGestureRecognizer(UIHoverGestureRecognizer(target: self, action: #selector(handleLiveBadgeHover(_:))))
            liveBadgeView.addInteraction(UIPointerInteraction(delegate: self))
        #else
            liveBadgeView.isUserInteractionEnabled = false
        #endif
    }

    // MARK: - Style

    private func updateLiveBadgeAlpha() {
        liveBadgeView.alpha = liveBadgePlaybackAlpha * chromeAlpha
    }

    /// Applies the browser's resolved style to this page.
    func apply(style: LMKPhotoBrowserViewController.Style, theme: LMKTheme, dynamicRange: UIImage.DynamicRange) {
        // The page is clear: the browser's stage shows through, and fades on its own during
        // a dismiss drag. The photo keeps the stage color behind it, so an image with
        // transparency stays solid while the stage clears around it.
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        scrollView.backgroundColor = .clear
        imageView.backgroundColor = style.stageColor
        imageView.preferredImageDynamicRange = dynamicRange

        trailingGapConstraint?.update(offset: -style.pageGap(theme: theme))
        maximumZoomScale = style.maximumZoom
        doubleTapZoomScale = style.doubleTapZoom
        if !isDismissDragActive {
            scrollView.maximumZoomScale = maximumZoomScale
        }

        let chrome = style.chrome
        let badge = liveBadgeView.lmk_apply(
            surface: style.liveBadge,
            defaults: LMKSurfaceStyle(
                background: .solid(LMKPhotoPalette.badgeBacking.withAlphaComponent(theme.alpha.xl)),
                corners: .capsule,
                contentInsets: .lmk_symmetric(vertical: theme.spacing.xs, horizontal: theme.spacing.small)
            )
        )
        let insets = badge.contentInsets ?? .zero
        if insets != liveBadgeInsets {
            liveBadgeInsets = insets
            liveBadgeStack.snp.remakeConstraints { make in
                make.directionalEdges.equalToSuperview().inset(insets)
            }
        }
        liveBadgeStack.spacing = theme.spacing.xs
        liveBadgeIcon.image = UIImage(systemName: "livephoto", withConfiguration: UIImage.SymbolConfiguration(pointSize: theme.layout.symbolBadge, weight: .semibold))
        liveBadgeIcon.tintColor = chrome
        liveBadgeLabel.lmk_apply(style.liveBadgeTextStyle ?? .extraSmallSemibold, color: chrome)
        liveBadgeTopConstraint?.update(offset: theme.spacing.large + style.buttonSize(theme: theme) + theme.spacing.small)
        liveBadgeLeadingConstraint?.update(offset: theme.spacing.large)
    }

    func apply(strings: LMKPhotoBrowserViewController.Strings) {
        liveBadgeLabel.lmk_setText(strings.liveBadge)
    }

    /// Makes the page the VoiceOver element for its photo: `label` is the browser's counter and
    /// date (plus the Live Photo name when the page has one), `hint` its tap hint.
    func apply(accessibilityLabel label: String?, hint: String?) {
        accessibilityLabel = label
        accessibilityHint = hint
    }

    // MARK: - Configuration

    /// Installs a decoded image synchronously, superseding any in-flight async load.
    /// Test hook: the browser installs through the async overload.
    func configure(with image: UIImage, screenSize: CGSize, isLive: Bool = false) {
        invalidateLoads()
        imageView.image = image
        livePhotoView.livePhoto = nil
        livePhotoView.isHidden = true
        imageView.isHidden = false
        // The badge follows the synchronous flag so it appears immediately, independent of the
        // async `PHLivePhoto` load that drives playback.
        liveBadgeView.isHidden = !isLive
        liveBadgePlaybackAlpha = 1
        updateLiveBadgeAlpha()
        updateImageSize(image: image, screenSize: screenSize)
        resetZoom()
    }

    /// Shows the bare stage as a placeholder, resolves `imageProvider`, and installs the result
    /// through the standard sizing path; the generation token guards the apply so a slow load
    /// never lands on a recycled page.
    ///
    /// - Parameters:
    ///   - screenSize: Fallback fitting size. If the scroll view has resolved bounds when the
    ///     image arrives (the normal case), those win.
    ///   - isLive: Shows the LIVE capsule immediately.
    ///   - imageProvider: Async image source, called once on the main actor.
    func configure(screenSize: CGSize, isLive: Bool = false, imageProvider: @escaping () async -> UIImage?) {
        invalidateLoads()
        let generation = loadGeneration
        imageView.image = nil
        livePhotoView.livePhoto = nil
        livePhotoView.isHidden = true
        imageView.isHidden = false
        liveBadgeView.isHidden = !isLive
        liveBadgePlaybackAlpha = 1
        updateLiveBadgeAlpha()
        resetZoom()

        imageLoadTask = Task { [weak self] in
            guard let image = await imageProvider() else { return }
            guard let self, generation == loadGeneration else { return }
            installLoadedImage(image, fallbackScreenSize: screenSize)
        }
    }

    /// Resolves `provider` and upgrades the page to a playable Live Photo when it returns one;
    /// guarded by the same generation token as the still.
    func loadLivePhoto(using provider: @escaping () async -> PHLivePhoto?) {
        livePhotoLoadTask?.cancel()
        let generation = loadGeneration
        livePhotoLoadTask = Task { [weak self] in
            guard let livePhoto = await provider() else { return }
            guard let self, generation == loadGeneration else { return }
            configureLivePhoto(livePhoto)
        }
    }

    /// Re-fits the installed still to a new page size (rotation, window resize). A no-op while
    /// the async load is in flight: the install path resolves the then-current bounds itself.
    func refitInstalledImage(to screenSize: CGSize) {
        guard let image = imageView.image else { return }
        updateImageSize(image: image, screenSize: screenSize)
    }

    private func invalidateLoads() {
        loadGeneration &+= 1
        imageLoadTask?.cancel()
        imageLoadTask = nil
        livePhotoLoadTask?.cancel()
        livePhotoLoadTask = nil
    }

    /// Zoom is reset to 1x before the new frame goes in (installing a frame under a non-identity
    /// zoom inflates the new bounds by the stale fit factor). A Live Photo upgrade that raced
    /// ahead of the still is preserved: only the still layer is replaced.
    private func installLoadedImage(_ image: UIImage, fallbackScreenSize: CGSize) {
        resetZoom()
        imageView.image = image
        let bounds = scrollView.bounds.size
        let screenSize = (bounds.width > 0 && bounds.height > 0) ? bounds : fallbackScreenSize
        updateImageSize(image: image, screenSize: screenSize)
        resetZoom()
    }

    /// Whether the page shows a playable Live Photo.
    var isShowingLivePhoto: Bool { !livePhotoView.isHidden && livePhotoView.livePhoto != nil }

    /// Upgrades a page to a playable Live Photo, over the still when one is installed. The Live
    /// Photo view shares the image view's frame; its playback long press is on the page. A Live
    /// Photo that lands before the still sizes the page itself, so it is never laid out at the
    /// placeholder size.
    func configureLivePhoto(_ livePhoto: PHLivePhoto) {
        livePhotoView.livePhoto = livePhoto
        livePhotoView.isHidden = false
        imageView.isHidden = true
        liveBadgeView.isHidden = false
        liveBadgePlaybackAlpha = 1
        updateLiveBadgeAlpha()
        if imageView.image == nil, livePhoto.size.width > 0, livePhoto.size.height > 0 {
            let bounds = scrollView.bounds.size
            let page = (bounds.width > 0 && bounds.height > 0) ? bounds : contentView.bounds.size
            fittedSize = Self.fittedSize(imageSize: livePhoto.size, in: page)
        }
        // The zoomed view just changed; drop any transform on the previous one.
        resetZoom()
    }

    func updateImageSize(image: UIImage, screenSize: CGSize) {
        fittedSize = Self.fittedSize(imageSize: image.size, in: screenSize)
        setNeedsLayout()
        layoutIfNeeded()
        layoutPhoto()
    }

    func resetZoom() {
        zoomAnchor = nil
        scrollView.setZoomScale(LMKPhotoBrowserMetrics.minimumZoomScale, animated: false)
        scrollView.transform = .identity
        scrollView.bouncesHorizontally = true
        scrollView.alwaysBounceVertical = true
        // setZoomScale only clears the current zoomed view's transform; clear both so a page
        // that switched between still and live state carries nothing over.
        imageView.transform = .identity
        livePhotoView.transform = .identity
        setNeedsLayout()
        layoutIfNeeded()
        layoutPhoto()
        scrollView.contentOffset = .zero
    }

    var isZoomed: Bool {
        scrollView.zoomScale > LMKPhotoBrowserMetrics.minimumZoomScale
    }

    /// The visible content view: the Live Photo view when playing a Live Photo, else the image
    /// view. The scroll view zooms whatever this returns.
    private var activeContentView: UIView {
        livePhotoView.isHidden ? imageView : livePhotoView
    }

    /// Double tap: zoom to the style's double-tap scale, keeping the tapped point of the photo
    /// under the finger, or back to 1x.
    func zoomAtLocationInCell(_ locationInCell: CGPoint) {
        let animated = LMKAnimation.shouldAnimate
        if isZoomed {
            zoomAnchor = nil
            scrollView.setZoomScale(LMKPhotoBrowserMetrics.minimumZoomScale, animated: animated)
        } else {
            let location = scrollView.convert(locationInCell, from: contentView)
            zoomAnchor = makeZoomAnchor(atPagePoint: CGPoint(x: location.x - scrollView.contentOffset.x, y: location.y - scrollView.contentOffset.y))
            scrollView.setZoomScale(doubleTapZoomScale, animated: animated)
        }
    }

    /// Clears what a dismissal or a drag left on the page, for a browser that is presented
    /// again with its pages in place: the frozen offset, the drag lock on zoom, and any zoom.
    func prepareForReappearance() {
        isDismissing = false
        isDismissDragActive = false
        scrollView.maximumZoomScale = maximumZoomScale
        resetZoom()
    }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()
        layoutPhoto()
        liveBadgeView.lmk_layoutSurfaceIfNeeded()
    }

    /// Where the photo is drawn, in `view`'s coordinates: its zoom, the scroll position, and any
    /// transform on the way up included. `nil` until a photo is installed.
    func photoFrame(in view: UIView) -> CGRect? {
        guard imageView.image != nil || isShowingLivePhoto, fittedSize.width > 0, fittedSize.height > 0 else { return nil }
        let content = activeContentView
        return content.convert(content.bounds, to: view)
    }

    /// The still the page shows (under a Live Photo too); `nil` until one is installed.
    var displayedImage: UIImage? { imageView.image }

    /// Holds the photo where a committed dismiss drag left it, so the way out starts there.
    func freezeForDismissal() {
        isDismissing = true
        guard scrollView.isDecelerating else { return }
        scrollView.setContentOffset(scrollView.contentOffset, animated: false)
    }

    /// Centers the photo views on the page at the current zoom and gives the scroll view the
    /// travel that goes with it. The content area is the page itself; the insets are the travel.
    private func layoutPhoto() {
        let page = scrollView.bounds.size
        guard page.width > 0, page.height > 0, fittedSize.width > 0, fittedSize.height > 0 else { return }
        let center = CGPoint(x: page.width / 2, y: page.height / 2)
        for view in [imageView, livePhotoView] {
            if view.bounds.size != fittedSize {
                view.bounds = CGRect(origin: .zero, size: fittedSize)
            }
            if view.center != center {
                view.center = center
            }
        }
        if scrollView.contentSize != page {
            scrollView.contentSize = page
        }
        let insets = Self.travelInsets(fittedSize: fittedSize, pageSize: page, scale: scrollView.zoomScale)
        if scrollView.contentInset != insets {
            scrollView.contentInset = insets
        }
        if !isZoomed, !isDismissing, !scrollView.isDragging, !scrollView.isDecelerating, scrollView.contentOffset != .zero {
            scrollView.contentOffset = .zero
        }
    }

    /// How far a zoomed photo may scroll either way from its centered rest, along one axis:
    /// until its edge meets the page's, never past it, so a pan cannot leave the photo. A photo
    /// shorter than the page stays centered.
    nonisolated static func travel(photoLength: CGFloat, pageLength: CGFloat) -> CGFloat {
        max(0, (photoLength - pageLength) / 2)
    }

    /// The scroll view's travel as insets around a content area the size of the page.
    ///
    /// - Zoomed, each axis travels to the photo's edges.
    /// - At 1x the page does not move sideways at all, so a sideways drag always pages the
    ///   browser, and it runs a full page up or down: the dismiss drag follows the finger the
    ///   whole way instead of stretching a rubber band.
    nonisolated static func travelInsets(fittedSize: CGSize, pageSize: CGSize, scale: CGFloat) -> UIEdgeInsets {
        guard scale > LMKPhotoBrowserMetrics.minimumZoomScale else {
            return UIEdgeInsets(top: pageSize.height, left: 0, bottom: pageSize.height, right: 0)
        }
        let horizontal = travel(photoLength: fittedSize.width * scale, pageLength: pageSize.width)
        let vertical = travel(photoLength: fittedSize.height * scale, pageLength: pageSize.height)
        return UIEdgeInsets(top: vertical, left: horizontal, bottom: vertical, right: horizontal)
    }

    /// The anchor for a zoom around `pagePoint` (a point of the page, in its own coordinates).
    /// A point on the letterbox anchors the nearest point of the photo.
    func makeZoomAnchor(atPagePoint pagePoint: CGPoint) -> ZoomAnchor {
        let page = scrollView.bounds.size
        let scale = max(scrollView.zoomScale, 0.001)
        let offset = scrollView.contentOffset
        let photoOrigin = CGPoint(x: (page.width - fittedSize.width * scale) / 2, y: (page.height - fittedSize.height * scale) / 2)
        let photoPoint = CGPoint(
            x: min(max((pagePoint.x + offset.x - photoOrigin.x) / scale, 0), fittedSize.width),
            y: min(max((pagePoint.y + offset.y - photoOrigin.y) / scale, 0), fittedSize.height)
        )
        return ZoomAnchor(pagePoint: pagePoint, photoPoint: photoPoint)
    }

    /// The content offset that keeps `anchor`'s photo point under its page point at `scale`,
    /// inside the travel the photo has at that scale.
    nonisolated static func contentOffset(keeping anchor: ZoomAnchor, scale: CGFloat, fittedSize: CGSize, pageSize: CGSize) -> CGPoint {
        let zoomed = scale > LMKPhotoBrowserMetrics.minimumZoomScale
        func offset(photoPoint: CGFloat, pagePoint: CGFloat, photoLength: CGFloat, pageLength: CGFloat) -> CGFloat {
            let origin = (pageLength - photoLength * scale) / 2
            let limit = travel(photoLength: photoLength * scale, pageLength: pageLength)
            return min(max(origin + photoPoint * scale - pagePoint, -limit), limit)
        }
        guard zoomed else { return .zero }
        return CGPoint(
            x: offset(photoPoint: anchor.photoPoint.x, pagePoint: anchor.pagePoint.x, photoLength: fittedSize.width, pageLength: pageSize.width),
            y: offset(photoPoint: anchor.photoPoint.y, pagePoint: anchor.pagePoint.y, photoLength: fittedSize.height, pageLength: pageSize.height)
        )
    }

    private func snapToCenterIfNeeded(animated: Bool) {
        guard scrollView.zoomScale == 1 else { return }
        let offset = scrollView.contentOffset
        let tolerance: CGFloat = 1
        guard abs(offset.y) > tolerance || abs(offset.x) > tolerance else { return }
        if animated, LMKAnimation.shouldAnimate {
            UIView.animate(
                withDuration: LMKAnimation.Duration.moderate,
                delay: 0,
                usingSpringWithDamping: LMKAnimation.spring.damping,
                initialSpringVelocity: 0.5,
                options: [.allowUserInteraction, .beginFromCurrentState]
            ) {
                self.scrollView.contentOffset = .zero
            }
        } else {
            scrollView.contentOffset = .zero
        }
    }

    /// Aspect-fits `imageSize` in `screenSize`.
    nonisolated static func fittedSize(imageSize: CGSize, in screenSize: CGSize) -> CGSize {
        guard imageSize.width > 0, imageSize.height > 0, screenSize.width > 0, screenSize.height > 0 else { return screenSize }
        let imageAspect = imageSize.height / imageSize.width
        let screenAspect = screenSize.height / screenSize.width
        var fitted = if imageAspect > screenAspect {
            CGSize(width: screenSize.height / imageAspect, height: screenSize.height)
        } else {
            CGSize(width: screenSize.width, height: screenSize.width * imageAspect)
        }
        fitted.width = min(fitted.width, screenSize.width)
        fitted.height = min(fitted.height, screenSize.height)
        return fitted
    }

    // MARK: - Pinch

    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        switch gesture.state {
        case .began:
            isPinching = true
            pinchCenterInContentView = gesture.location(in: contentView)
            zoomScaleAtPinchStart = scrollView.zoomScale
            zoomAnchor = makeZoomAnchor(atPagePoint: pagePoint(of: gesture))
        case .changed:
            // The scroll view clamps at min/max (bouncesZoom is off); the rubber band beyond
            // those limits is a transform on the scroll view around the pinch center.
            let intendedScale = zoomScaleAtPinchStart * gesture.scale
            if intendedScale < LMKPhotoBrowserMetrics.minimumZoomScale {
                let scale = max(LMKPhotoBrowserMetrics.pinchShrinkFloor, pow(max(0.001, intendedScale), 0.5))
                applyRubberBand(scale: scale)
            } else if intendedScale > maximumZoomScale {
                let scale = min(LMKPhotoBrowserMetrics.pinchOvershootCeiling, pow(intendedScale / maximumZoomScale, 0.5))
                applyRubberBand(scale: scale)
            } else if !scrollView.transform.isIdentity {
                scrollView.transform = .identity
            }
        case .ended, .cancelled:
            finishPinch()
        default:
            break
        }
    }

    /// The end of a pinch: the rubber band snaps back, and the page reports whether it is
    /// still zoomed (a pinch released past the maximum leaves it at 3x, and the chrome must
    /// not return over that).
    func finishPinch() {
        isPinching = false
        zoomAnchor = nil
        guard !scrollView.transform.isIdentity else { return }
        if LMKAnimation.shouldAnimate {
            UIView.animate(
                withDuration: LMKAnimation.Duration.normal,
                delay: 0,
                usingSpringWithDamping: LMKAnimation.spring.damping,
                initialSpringVelocity: 0,
                options: [.allowUserInteraction, .beginFromCurrentState]
            ) {
                self.scrollView.transform = .identity
            } completion: { [weak self] _ in
                guard let self else { return }
                delegate?.photoCell(self, didChangeZoomState: isZoomed)
            }
        } else {
            scrollView.transform = .identity
            delegate?.photoCell(self, didChangeZoomState: isZoomed)
        }
    }

    /// A gesture's location on the page: in the scroll view's frame, whatever it has scrolled to.
    private func pagePoint(of gesture: UIGestureRecognizer) -> CGPoint {
        let location = gesture.location(in: scrollView)
        return CGPoint(x: location.x - scrollView.contentOffset.x, y: location.y - scrollView.contentOffset.y)
    }

    private func applyRubberBand(scale: CGFloat) {
        let wasIdentity = scrollView.transform.isIdentity
        let center = CGPoint(x: contentView.bounds.midX, y: contentView.bounds.midY)
        let tx = (pinchCenterInContentView.x - center.x) * (1 - scale)
        let ty = (pinchCenterInContentView.y - center.y) * (1 - scale)
        scrollView.transform = CGAffineTransform(a: scale, b: 0, c: 0, d: scale, tx: tx, ty: ty)
        if wasIdentity {
            delegate?.photoCell(self, didChangeZoomState: true)
        }
    }

    // MARK: - Reuse

    override func prepareForReuse() {
        super.prepareForReuse()
        invalidateLoads()
        imageView.image = nil
        resetZoom()
        isDismissing = false
        isDismissDragActive = false
        scrollView.maximumZoomScale = maximumZoomScale
        livePhotoView.livePhoto = nil
        livePhotoView.isHidden = true
        imageView.isHidden = false
        liveBadgeView.isHidden = true
        liveBadgePlaybackAlpha = 1
        chromeAlpha = 1
    }

    deinit {
        imageLoadTask?.cancel()
        livePhotoLoadTask?.cancel()
    }
}

// MARK: - UIScrollViewDelegate

extension LMKPhotoBrowserCell: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        activeContentView
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        // A drag at 1x with at most one finger (a trackpad scroll has none) drives the dismiss
        // and locks zoom so a pinch cannot start mid-drag. Every other drag begins with the
        // full zoom range, whatever the last drag left behind.
        isDismissDragActive = scrollView.panGestureRecognizer.numberOfTouches <= 1 && !isZoomed
        scrollView.maximumZoomScale = isDismissDragActive ? LMKPhotoBrowserMetrics.minimumZoomScale : maximumZoomScale
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard !isDismissing, scrollView.transform.isIdentity, isDismissDragActive,
              scrollView.isDragging || scrollView.isDecelerating else { return }
        let threshold = LMKPhotoBrowserViewController.verticalDismissThreshold(pageHeight: scrollView.bounds.height)
        delegate?.photoCell(self, didUpdateDismissProgress: min(1, abs(scrollView.contentOffset.y) / threshold))
    }

    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        // At 1x a drag let go short of a dismissal coasts back to the center, a two-finger drag
        // included; the stage follows the photo home through `scrollViewDidScroll`.
        guard !isZoomed, !isDismissing else { return }
        if isDismissDragActive, shouldDismiss(scrollView) { return }
        targetContentOffset.pointee = .zero
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if isDismissDragActive {
            commitVerticalDrag(scrollView: scrollView)
        }
        if !decelerate {
            finishDrag(scrollView: scrollView)
        }
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if isDismissDragActive {
            commitVerticalDrag(scrollView: scrollView)
        }
        finishDrag(scrollView: scrollView)
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        finishDrag(scrollView: scrollView)
    }

    /// Whether the drag, let go now, dismisses: past the distance threshold, or a flick.
    private func shouldDismiss(_ scrollView: UIScrollView) -> Bool {
        let threshold = LMKPhotoBrowserViewController.verticalDismissThreshold(pageHeight: scrollView.bounds.height)
        let velocity = scrollView.panGestureRecognizer.velocity(in: scrollView).y
        return LMKPhotoBrowserViewController.shouldDismiss(offset: scrollView.contentOffset.y, velocity: velocity, threshold: threshold)
    }

    /// On release: dismiss past the threshold or on a flick.
    private func commitVerticalDrag(scrollView: UIScrollView) {
        guard !isDismissing, shouldDismiss(scrollView) else { return }
        isDismissing = true
        delegate?.photoCellDidRequestDismiss(self)
    }

    /// The end of every drag: the zoom range comes back, and a page still at 1x goes back to
    /// the center with the stage (while the photo was coasting the progress kept following it,
    /// so the stage never jumps). A committed dismiss stays where it is.
    private func finishDrag(scrollView: UIScrollView) {
        isDismissDragActive = false
        scrollView.maximumZoomScale = maximumZoomScale
        guard !isZoomed, !isDismissing else { return }
        delegate?.photoCell(self, didUpdateDismissProgress: 0)
        snapToCenterIfNeeded(animated: true)
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        layoutPhoto()
        let page = scrollView.bounds.size
        guard page.width > 0, page.height > 0 else { return }
        let scale = scrollView.zoomScale
        // The anchored point stays put; with no anchor the view stays where it is, inside the
        // photo's travel at the new scale.
        let anchor = zoomAnchor ?? makeZoomAnchor(atPagePoint: CGPoint(x: page.width / 2, y: page.height / 2))
        scrollView.contentOffset = Self.contentOffset(keeping: anchor, scale: scale, fittedSize: fittedSize, pageSize: page)
    }

    func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        if zoomAnchor == nil, let pinch = scrollView.pinchGestureRecognizer, pinch.numberOfTouches >= 2 {
            // The native pinch (the Mac's trackpad, which has no custom recognizer).
            zoomAnchor = makeZoomAnchor(atPagePoint: pagePoint(of: pinch))
        }
        isDismissDragActive = false
        scrollView.alwaysBounceVertical = false
        delegate?.photoCell(self, setPagingEnabled: false)
        delegate?.photoCell(self, didChangeZoomState: true)
    }

    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        if !isPinching {
            zoomAnchor = nil
        }
        // The pinch is over, so the browser pages again. Zoomed, the page does not bounce
        // sideways: a drag past the photo's left or right edge goes to the browser's paging.
        delegate?.photoCell(self, setPagingEnabled: true)
        scrollView.bouncesHorizontally = scale <= LMKPhotoBrowserMetrics.minimumZoomScale
        guard scale == 1 else { return }
        scrollView.alwaysBounceVertical = true
        snapToCenterIfNeeded(animated: true)
        if scrollView.transform.isIdentity {
            delegate?.photoCell(self, didChangeZoomState: false)
        }
    }
}

// MARK: - PHLivePhotoViewDelegate

extension LMKPhotoBrowserCell: PHLivePhotoViewDelegate {
    func livePhotoView(_: PHLivePhotoView, willBeginPlaybackWith _: PHLivePhotoViewPlaybackStyle) {
        let duration = LMKAnimation.shouldAnimate ? LMKAnimation.Duration.fast : 0
        UIView.animate(withDuration: duration) { [weak self] in
            self?.liveBadgePlaybackAlpha = 0
            self?.updateLiveBadgeAlpha()
        }
    }

    func livePhotoView(_: PHLivePhotoView, didEndPlaybackWith _: PHLivePhotoViewPlaybackStyle) {
        let duration = LMKAnimation.shouldAnimate ? LMKAnimation.Duration.fast : 0
        UIView.animate(withDuration: duration) { [weak self] in
            self?.liveBadgePlaybackAlpha = 1
            self?.updateLiveBadgeAlpha()
        }
    }
}

// MARK: - UIGestureRecognizerDelegate

extension LMKPhotoBrowserCell: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // The anchor-tracking pinch runs alongside the scroll view's zoom pinch.
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

    extension LMKPhotoBrowserCell: UIPointerInteractionDelegate {
        func pointerInteraction(_ interaction: UIPointerInteraction, styleFor _: UIPointerRegion) -> UIPointerStyle? {
            LMKPointerStyle.highlight(for: interaction.view)
        }
    }
#endif
