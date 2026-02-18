//
//  LMKPhotoBrowserViewController.swift
//  LumiKit
//
//  Full-screen photo browser with swipe navigation, zoom, and swipe-to-dismiss.
//

import LumiKitCore
import SnapKit
import UIKit

// MARK: - Protocols

/// Data source for the photo browser. Provides images, dates, and subtitles.
public protocol LMKPhotoBrowserDataSource: AnyObject {
    var numberOfPhotos: Int { get }
    func photo(at index: Int) -> UIImage?
    func photoDate(at index: Int) -> Date?
    func photoSubtitle(at index: Int) -> String?
}

/// Delegate for photo browser actions and dismissal.
public protocol LMKPhotoBrowserDelegate: AnyObject {
    func photoBrowser(_ browser: LMKPhotoBrowserViewController, didRequestActionAt index: Int)
    func photoBrowserDidDismiss(_ browser: LMKPhotoBrowserViewController)
}

// MARK: - Configurable Strings

/// Configurable strings for the photo browser, allowing localization without R.swift.
public nonisolated struct LMKPhotoBrowserStrings: Sendable {
    /// Empty state text shown when there are no photos.
    public var emptyText: String
    /// Format string for the photo counter (e.g. "%d of %d").
    public var counterFormat: String
    /// Accessibility hint for tap-to-toggle overlay.
    public var tapToToggleHint: String

    public init(
        emptyText: String = "No photos",
        counterFormat: String = "%d of %d",
        tapToToggleHint: String = "Double-tap to zoom, tap to show or hide controls",
    ) {
        self.emptyText = emptyText
        self.counterFormat = counterFormat
        self.tapToToggleHint = tapToToggleHint
    }
}

// MARK: - LMKPhotoBrowserViewController

public final class LMKPhotoBrowserViewController: UIViewController {
    // MARK: - Properties

    public weak var dataSource: (any LMKPhotoBrowserDataSource)?
    public weak var delegate: (any LMKPhotoBrowserDelegate)?
    public var strings = LMKPhotoBrowserStrings()

    private let initialIndex: Int

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.isPagingEnabled = true
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.backgroundColor = LMKColor.photoBrowserBackground
        collectionView.contentInsetAdjustmentBehavior = .never
        collectionView.register(LMKPhotoBrowserCell.self, forCellWithReuseIdentifier: LMKPhotoBrowserCell.identifier)
        return collectionView
    }()

    private let pageControl = UIPageControl()
    private let dateLabel = UILabel()
    private let dateLabelContainer = UIView()
    private let counterLabel = UILabel()
    private var currentIndex: Int = 0
    private var isOverlayHidden: Bool = false

    private static let counterLabelAlpha: CGFloat = 0.9
    /// Minimum alpha when vertical pan reaches dismiss threshold (transparency effect)
    private static let dismissProgressMinAlpha: CGFloat = 0.3
    /// Scale-down factor at full dismiss progress (1.0 -> 1 - value)
    private static let dismissScaleEffect: CGFloat = 0.15
    /// Fraction of progress before opacity starts fading (prevents flicker from tiny drags)
    private static let dismissOpacityStartThreshold: CGFloat = 0.15
    // Store button references for Mac optimizations
    private var dismissButton: UIButton?
    private var actionButton: UIButton?

    // MARK: - Initialization

    public init(initialIndex: Int = 0) {
        self.initialIndex = max(0, initialIndex)
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override public func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .dark
        setupUI()
        setupMacOptimizations()
    }

    private func setupMacOptimizations() {
        #if targetEnvironment(macCatalyst)
            // Enable keyboard navigation
            becomeFirstResponder()

            // Show scroll indicators on Mac for better UX
            collectionView.showsHorizontalScrollIndicator = true
            collectionView.showsVerticalScrollIndicator = true

            // Enable mouse/trackpad wheel scrolling
            collectionView.isScrollEnabled = true

            /// Add gesture recognizer for mouse wheel scrolling (only for discrete scroll events)
            /// This won't interfere with normal collection view scrolling
            let scrollWheelGesture = UIPanGestureRecognizer(target: self, action: #selector(handleScrollWheel(_:)))
            scrollWheelGesture.allowedScrollTypesMask = .discrete
            scrollWheelGesture.delegate = self
            scrollWheelGesture.cancelsTouchesInView = false
            collectionView.addGestureRecognizer(scrollWheelGesture)
        #endif
    }

    override public var canBecomeFirstResponder: Bool {
        #if targetEnvironment(macCatalyst)
            return true
        #else
            return false
        #endif
    }

    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Prepare haptic generators for responsive feedback
        LMKHapticFeedbackHelper.prepare()

        let photoCount = dataSource?.numberOfPhotos ?? 0
        guard photoCount > 0 else { return }
        let safeIndex = max(0, min(initialIndex, photoCount - 1))
        scrollToPhoto(at: safeIndex, animated: false)
        updatePhotoAccessibility()

        #if targetEnvironment(macCatalyst)
            // Become first responder after view appears for keyboard handling
            DispatchQueue.main.async { [weak self] in
                _ = self?.becomeFirstResponder()
            }
        #endif
    }

    // MARK: - Keyboard Navigation

    #if targetEnvironment(macCatalyst)
        override public var keyCommands: [UIKeyCommand]? {
            [
                UIKeyCommand(input: " ", modifierFlags: [], action: #selector(handleSpacebar)),
                UIKeyCommand(input: "w", modifierFlags: .command, action: #selector(handleCommandW)),
                UIKeyCommand(input: "e", modifierFlags: .command, action: #selector(handleCommandE)),
            ]
        }

        override public func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
            var handled = false

            for press in presses {
                guard let key = press.key else { continue }

                // Handle arrow keys and escape (not well supported by UIKeyCommand)
                switch key.keyCode {
                case .keyboardLeftArrow:
                    navigateToPreviousPhoto()
                    handled = true
                case .keyboardRightArrow:
                    navigateToNextPhoto()
                    handled = true
                case .keyboardEscape:
                    dismissBrowser()
                    handled = true
                default:
                    break
                }
            }

            if !handled {
                super.pressesBegan(presses, with: event)
            }
        }

        @objc private func handleSpacebar() {
            let photoCount = dataSource?.numberOfPhotos ?? 0
            if currentIndex < photoCount {
                actionButtonTapped()
            }
        }

        @objc private func handleCommandW() {
            dismissBrowser()
        }

        @objc private func handleCommandE() {
            let photoCount = dataSource?.numberOfPhotos ?? 0
            if currentIndex < photoCount {
                actionButtonTapped()
            }
        }
    #endif

    private func navigateToPreviousPhoto() {
        let photoCount = dataSource?.numberOfPhotos ?? 0
        guard photoCount > 0 else { return }
        let newIndex = max(0, currentIndex - 1)
        if newIndex != currentIndex {
            scrollToPhoto(at: newIndex, animated: true)
        }
    }

    private func navigateToNextPhoto() {
        let photoCount = dataSource?.numberOfPhotos ?? 0
        guard photoCount > 0 else { return }
        let newIndex = min(photoCount - 1, currentIndex + 1)
        if newIndex != currentIndex {
            scrollToPhoto(at: newIndex, animated: true)
        }
    }

    // MARK: - Mac Button Hover Effects

    #if targetEnvironment(macCatalyst)
        private static let hoverDuration = LMKAnimationHelper.Duration.uiShort

        private static let hoverScale = CGAffineTransform(scaleX: 1.1, y: 1.1)

        private func applyHover(to button: UIButton?) {
            guard LMKAnimationHelper.shouldAnimate else { return }
            UIView.animate(withDuration: Self.hoverDuration) {
                button?.backgroundColor = LMKColor.photoBrowserBackground.withAlphaComponent(LMKAlpha.overlayStrong)
                button?.transform = Self.hoverScale
            }
        }

        private func removeHover(from button: UIButton?) {
            guard LMKAnimationHelper.shouldAnimate else { return }
            UIView.animate(withDuration: Self.hoverDuration) {
                button?.backgroundColor = LMKColor.photoBrowserBackground.withAlphaComponent(LMKAlpha.overlay)
                button?.transform = .identity
            }
        }

        @objc private func dismissButtonHover() { applyHover(to: dismissButton) }
        @objc private func dismissButtonUnhover() { removeHover(from: dismissButton) }
        @objc private func actionButtonHover() { applyHover(to: actionButton) }
        @objc private func actionButtonUnhover() { removeHover(from: actionButton) }

        // MARK: - Mouse/Trackpad Wheel Support

        @objc private func handleScrollWheel(_ gesture: UIPanGestureRecognizer) {
            // Only handle discrete scroll wheel events, not continuous panning
            guard gesture.state == .ended else { return }

            let velocity = gesture.velocity(in: collectionView)
            let photoCount = dataSource?.numberOfPhotos ?? 0

            // Only trigger navigation on significant horizontal scroll velocity
            // This prevents interference with normal collection view scrolling
            let horizontalThreshold: CGFloat = 300

            if velocity.x < -horizontalThreshold, currentIndex < photoCount - 1 {
                // Swipe left / scroll right = next photo
                navigateToNextPhoto()
            } else if velocity.x > horizontalThreshold, currentIndex > 0 {
                // Swipe right / scroll left = previous photo
                navigateToPreviousPhoto()
            }
        }
    #endif

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        view.alpha = 1
        let photoCount = dataSource?.numberOfPhotos ?? 0
        let safeIndex = max(0, min(initialIndex, photoCount - 1))
        currentIndex = safeIndex
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = LMKColor.photoBrowserBackground

        let photoCount = dataSource?.numberOfPhotos ?? 0

        // Guard against empty data source
        guard photoCount > 0 else {
            // Show empty state and dismiss button
            let emptyLabel = UILabel()
            emptyLabel.text = strings.emptyText
            emptyLabel.textColor = LMKColor.white
            emptyLabel.textAlignment = .center
            view.addSubview(emptyLabel)
            emptyLabel.snp.makeConstraints { make in
                make.center.equalToSuperview()
            }

            let dismissButton = UIButton(type: .system)
            dismissButton.setImage(UIImage(systemName: "xmark"), for: .normal)
            dismissButton.tintColor = LMKColor.white
            dismissButton.backgroundColor = LMKColor.photoBrowserBackground.withAlphaComponent(LMKAlpha.overlay)
            dismissButton.layer.cornerRadius = LMKCornerRadius.xl
            dismissButton.addTarget(self, action: #selector(dismissTapped), for: .touchUpInside)
            view.addSubview(dismissButton)

            #if targetEnvironment(macCatalyst)
                let buttonSize: CGFloat = 48
            #else
                let buttonSize: CGFloat = LMKLayout.minimumTouchTarget
            #endif

            dismissButton.snp.makeConstraints { make in
                make.top.equalTo(view.safeAreaLayoutGuide).offset(LMKSpacing.large)
                make.trailing.equalToSuperview().offset(-LMKSpacing.large)
                make.width.height.equalTo(buttonSize)
            }
            return
        }

        // Collection view — wider than the view by interPageSpacing so each cell
        // (which includes the spacing) pages correctly. The trailing overflow is
        // clipped by the view.
        view.clipsToBounds = true
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.top.bottom.leading.equalToSuperview()
            make.width.equalToSuperview().offset(lmkPhotoBrowserInterPageSpacing)
        }

        // Tap: single = toggle overlay, double = zoom (single requires double to fail)
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTapOnCollection(_:)))
        doubleTap.numberOfTapsRequired = 2
        collectionView.addGestureRecognizer(doubleTap)

        let singleTap = UITapGestureRecognizer(target: self, action: #selector(handleSingleTapToToggleOverlay))
        singleTap.numberOfTapsRequired = 1
        singleTap.require(toFail: doubleTap)
        collectionView.addGestureRecognizer(singleTap)

        // Dismiss button (add after collectionView so it's on top)
        let dismissButton = UIButton(type: .system)
        dismissButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        dismissButton.tintColor = LMKColor.white
        dismissButton.backgroundColor = LMKColor.photoBrowserBackground.withAlphaComponent(LMKAlpha.overlay)
        dismissButton.layer.cornerRadius = LMKCornerRadius.xl
        dismissButton.addTarget(self, action: #selector(dismissTapped), for: .touchUpInside)
        view.addSubview(dismissButton)
        view.bringSubviewToFront(dismissButton)
        self.dismissButton = dismissButton

        #if targetEnvironment(macCatalyst)
            let buttonSize: CGFloat = 48
        #else
            let buttonSize: CGFloat = LMKLayout.minimumTouchTarget
        #endif

        dismissButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(LMKSpacing.large)
            make.trailing.equalToSuperview().offset(-LMKSpacing.large)
            make.width.height.equalTo(buttonSize)
        }

        #if targetEnvironment(macCatalyst)
            // Add hover effect for Mac
            dismissButton.addTarget(self, action: #selector(dismissButtonHover), for: [.touchDown, .touchDragEnter])
            dismissButton.addTarget(self, action: #selector(dismissButtonUnhover), for: [.touchUpInside, .touchUpOutside, .touchDragExit, .touchCancel])
        #endif

        // Action button (add after collectionView so it's on top)
        let actionButton = UIButton(type: .system)
        actionButton.setImage(UIImage(systemName: "ellipsis"), for: .normal)
        actionButton.tintColor = LMKColor.white
        actionButton.backgroundColor = LMKColor.photoBrowserBackground.withAlphaComponent(LMKAlpha.overlay)
        actionButton.layer.cornerRadius = LMKCornerRadius.xl
        actionButton.addTarget(self, action: #selector(actionButtonTapped), for: .touchUpInside)
        view.addSubview(actionButton)
        view.bringSubviewToFront(actionButton)
        self.actionButton = actionButton

        actionButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(LMKSpacing.large)
            make.leading.equalToSuperview().offset(LMKSpacing.large)
            make.width.height.equalTo(buttonSize)
        }

        #if targetEnvironment(macCatalyst)
            // Add hover effect for Mac
            actionButton.addTarget(self, action: #selector(actionButtonHover), for: [.touchDown, .touchDragEnter])
            actionButton.addTarget(self, action: #selector(actionButtonUnhover), for: [.touchUpInside, .touchUpOutside, .touchDragExit, .touchCancel])
        #endif

        // Page control (add after collectionView so it's on top)
        pageControl.numberOfPages = photoCount
        pageControl.currentPage = max(0, min(initialIndex, photoCount - 1))
        pageControl.pageIndicatorTintColor = LMKColor.graySoft
        pageControl.currentPageIndicatorTintColor = LMKColor.white
        view.addSubview(pageControl)
        view.bringSubviewToFront(pageControl)
        pageControl.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-LMKSpacing.xl)
            make.centerX.equalToSuperview()
        }

        // Photo counter ("3 of 12")
        counterLabel.font = LMKTypography.caption
        counterLabel.textColor = LMKColor.white.withAlphaComponent(Self.counterLabelAlpha)
        counterLabel.textAlignment = .center
        view.addSubview(counterLabel)
        view.bringSubviewToFront(counterLabel)
        counterLabel.snp.makeConstraints { make in
            make.bottom.equalTo(pageControl.snp.top).offset(-LMKSpacing.xs)
            make.centerX.equalToSuperview()
        }

        // Date label container (add after collectionView so it's on top)
        dateLabelContainer.backgroundColor = LMKColor.photoBrowserBackground.withAlphaComponent(LMKAlpha.overlay)
        dateLabelContainer.layer.cornerRadius = LMKCornerRadius.small
        dateLabelContainer.clipsToBounds = true
        view.addSubview(dateLabelContainer)
        view.bringSubviewToFront(dateLabelContainer)
        dateLabelContainer.snp.makeConstraints { make in
            make.bottom.equalTo(counterLabel.snp.top).offset(-LMKSpacing.medium)
            make.centerX.equalToSuperview()
        }

        // Date label
        dateLabel.textColor = LMKColor.white
        dateLabel.font = LMKTypography.bodyMedium
        dateLabel.textAlignment = .center
        dateLabelContainer.addSubview(dateLabel)
        dateLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: LMKSpacing.small, left: LMKSpacing.medium, bottom: LMKSpacing.small, right: LMKSpacing.medium))
        }

        // Update date and counter with initial photo
        updateDateLabel()
        updateCounterLabel()
    }

    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard view.bounds.width > 0, view.bounds.height > 0 else {
            return
        }

        let photoCount = dataSource?.numberOfPhotos ?? 0
        guard photoCount > 0 else { return }

        // Cell width = screen width + spacing. The spacing is part of the cell
        // (trailing gap), so minimumLineSpacing can be 0 and paging works perfectly.
        let screenSize = view.bounds.size
        let cellSize = CGSize(width: screenSize.width + lmkPhotoBrowserInterPageSpacing,
                              height: screenSize.height)
        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.itemSize = cellSize
        }

        // Update visible cells with new screen size
        for cell in collectionView.visibleCells {
            if let photoCell = cell as? LMKPhotoBrowserCell,
               let indexPath = collectionView.indexPath(for: cell),
               indexPath.item < photoCount,
               let image = dataSource?.photo(at: indexPath.item) {
                photoCell.updateImageSize(image: image, screenSize: screenSize)
            }
        }

        // Scroll to current photo (only if not already scrolled)
        if currentIndex == initialIndex, collectionView.contentOffset.x == 0 {
            scrollToPhoto(at: currentIndex, animated: false)
        }
    }

    // MARK: - Navigation

    private func scrollToPhoto(at index: Int, animated: Bool) {
        let photoCount = dataSource?.numberOfPhotos ?? 0
        guard photoCount > 0,
              collectionView.bounds.width > 0,
              index >= 0,
              index < photoCount else {
            return
        }

        // Each page = collectionView.bounds.width (= view.width + interPageSpacing)
        let pageWidth = collectionView.bounds.width
        collectionView.setContentOffset(CGPoint(x: CGFloat(index) * pageWidth, y: 0), animated: animated)
        updateCurrentIndex(index)
    }

    private func updateCurrentIndex(_ index: Int) {
        let photoCount = dataSource?.numberOfPhotos ?? 0
        guard index >= 0,
              index < photoCount else {
            return
        }

        let previousIndex = currentIndex
        currentIndex = index
        pageControl.currentPage = index
        updateDateLabel()
        updateCounterLabel()

        if index != previousIndex {
            LMKHapticFeedbackHelper.selection()
        }
        updatePhotoAccessibility()
    }

    private func updateCounterLabel() {
        let photoCount = dataSource?.numberOfPhotos ?? 0
        guard photoCount > 0 else {
            counterLabel.text = nil
            return
        }
        counterLabel.text = String(format: strings.counterFormat, currentIndex + 1, photoCount)
    }

    private func updatePhotoAccessibility() {
        let photoCount = dataSource?.numberOfPhotos ?? 0
        guard photoCount > 0 else { return }
        collectionView.accessibilityLabel = String(format: strings.counterFormat, currentIndex + 1, photoCount)
        collectionView.accessibilityHint = strings.tapToToggleHint
    }

    private func updateDateLabel() {
        let photoCount = dataSource?.numberOfPhotos ?? 0
        guard currentIndex >= 0,
              currentIndex < photoCount else {
            dateLabel.text = nil
            return
        }

        if let date = dataSource?.photoDate(at: currentIndex) {
            dateLabel.text = LMKDateFormatterHelper.formatDate(date, includeTime: false)
        } else {
            dateLabel.text = dataSource?.photoSubtitle(at: currentIndex)
        }
    }

    // MARK: - Actions

    @objc private func handleSingleTapToToggleOverlay() {
        toggleOverlay(animated: true)
    }

    @objc private func handleDoubleTapOnCollection(_ gesture: UITapGestureRecognizer) {
        guard gesture.state == .ended else { return }
        let location = gesture.location(in: collectionView)
        let photoCount = dataSource?.numberOfPhotos ?? 0
        guard let indexPath = collectionView.indexPathForItem(at: location),
              let cell = collectionView.cellForItem(at: indexPath) as? LMKPhotoBrowserCell,
              indexPath.item < photoCount else { return }
        let locationInCell = gesture.location(in: cell)
        cell.zoomAtLocationInCell(locationInCell)
        LMKHapticFeedbackHelper.light()
    }

    private func setOverlayAlpha(_ alpha: CGFloat) {
        dismissButton?.alpha = alpha
        actionButton?.alpha = alpha
        pageControl.alpha = alpha
        dateLabelContainer.alpha = alpha
        counterLabel.alpha = alpha
    }

    private func toggleOverlay(animated: Bool) {
        isOverlayHidden.toggle()
        let visible = !isOverlayHidden
        let alpha: CGFloat = visible ? 1 : 0
        let duration = (animated && LMKAnimationHelper.shouldAnimate) ? LMKAnimationHelper.Duration.alert : 0
        UIView.animate(withDuration: duration, delay: 0, options: .curveEaseInOut) {
            self.setOverlayAlpha(alpha)
        }
        dismissButton?.isUserInteractionEnabled = visible
        actionButton?.isUserInteractionEnabled = visible
        pageControl.isUserInteractionEnabled = visible
    }

    @objc private func dismissTapped() {
        dismissBrowser()
    }

    private func dismissBrowser() {
        delegate?.photoBrowserDidDismiss(self)
        dismiss(animated: true)
    }

    /// Dismiss with fast ease-out when finger lifts past threshold
    private func performDismissWithSnapTiming() {
        let duration = LMKAnimationHelper.shouldAnimate ? LMKAnimationHelper.Duration.uiShort : 0
        UIView.animate(
            withDuration: duration,
            delay: 0,
            options: [.curveEaseOut, .allowUserInteraction, .beginFromCurrentState],
        ) {
            self.view.alpha = 0
            self.collectionView.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
        } completion: { [weak self] _ in
            guard let self else { return }
            self.collectionView.transform = .identity
            self.delegate?.photoBrowserDidDismiss(self)
            self.dismiss(animated: false)
        }
    }

    /// Update whole photo browser VC transparency and scale: progress 0 (no drag) to 1 (at dismiss threshold); animate back when progress resets to 0
    public func updateDismissProgress(_ progress: CGFloat) {
        if progress > 0 {
            // Opacity stays at 1.0 for the first bit of drag, then fades (prevents flicker from tiny drags)
            let opacityProgress = max(0, (progress - Self.dismissOpacityStartThreshold) / (1 - Self.dismissOpacityStartThreshold))
            view.alpha = 1 - opacityProgress * (1 - Self.dismissProgressMinAlpha)
            // Scale reacts immediately for tactile feedback
            let scale = 1 - progress * Self.dismissScaleEffect
            collectionView.transform = CGAffineTransform(scaleX: scale, y: scale)
            // Fade overlay out faster than background for a cleaner dismiss
            if !isOverlayHidden {
                let overlayAlpha = max(0, 1 - progress * 2.5)
                setOverlayAlpha(overlayAlpha)
            }
        } else {
            let duration = LMKAnimationHelper.shouldAnimate ? LMKAnimationHelper.Duration.actionSheet : 0
            UIView.animate(withDuration: duration, delay: 0, options: .curveEaseOut) {
                self.view.alpha = 1
                self.collectionView.transform = .identity
                // Restore overlay to its intended state
                if !self.isOverlayHidden {
                    self.setOverlayAlpha(1)
                }
            }
        }
    }

    @objc private func actionButtonTapped() {
        let photoCount = dataSource?.numberOfPhotos ?? 0
        guard currentIndex < photoCount else { return }
        delegate?.photoBrowser(self, didRequestActionAt: currentIndex)
    }

    // MARK: - Public API

    /// Reloads the photo browser data. Call after data source content changes.
    public func reloadData() {
        let photoCount = dataSource?.numberOfPhotos ?? 0
        pageControl.numberOfPages = photoCount
        collectionView.reloadData()
        updateDateLabel()
        updateCounterLabel()
    }

    /// The index of the currently displayed photo.
    public var currentPhotoIndex: Int {
        currentIndex
    }
}

// MARK: - UICollectionViewDataSource

extension LMKPhotoBrowserViewController: UICollectionViewDataSource {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        dataSource?.numberOfPhotos ?? 0
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: LMKPhotoBrowserCell.identifier, for: indexPath) as? LMKPhotoBrowserCell else {
            return UICollectionViewCell()
        }

        let photoCount = dataSource?.numberOfPhotos ?? 0
        guard indexPath.item < photoCount,
              let image = dataSource?.photo(at: indexPath.item) else {
            return cell
        }

        let screenSize = view.bounds.size
        cell.configure(with: image, screenSize: screenSize)
        cell.onVerticalSwipeToDismiss = { [weak self] in
            self?.performDismissWithSnapTiming()
        }
        cell.onVerticalPanProgressForDismiss = { [weak self] progress in
            self?.updateDismissProgress(progress)
        }
        cell.onZoomStateChanged = { [weak self] zoomed in
            guard let self else { return }
            if zoomed {
                // Auto-hide overlay during zoom
                let duration = LMKAnimationHelper.shouldAnimate ? LMKAnimationHelper.Duration.uiShort : 0
                UIView.animate(withDuration: duration, delay: 0, options: .curveEaseOut) {
                    self.setOverlayAlpha(0)
                }
            } else {
                // Restore overlay when zoom returns to 1x (only if not manually hidden)
                if !self.isOverlayHidden {
                    let duration = LMKAnimationHelper.shouldAnimate ? LMKAnimationHelper.Duration.alert : 0
                    UIView.animate(withDuration: duration, delay: 0, options: .curveEaseOut) {
                        self.setOverlayAlpha(1)
                    }
                }
            }
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
        let photoCount = dataSource?.numberOfPhotos ?? 0
        guard scrollView === collectionView,
              collectionView.bounds.width > 0,
              photoCount > 0 else {
            return
        }

        let pageIndex = Int(round(collectionView.contentOffset.x / collectionView.bounds.width))
        let safeIndex = max(0, min(pageIndex, photoCount - 1))
        updateCurrentIndex(safeIndex)

        resetZoomOnVisibleCells()
    }

    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        // Disable collection view scrolling when a cell is zoomed
        if scrollView === collectionView {
            checkAndDisableCollectionViewScrolling()
        }
    }

    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        // Re-enable collection view scrolling when dragging ends (if not zoomed)
        if scrollView === collectionView, !decelerate {
            checkAndDisableCollectionViewScrolling()
        }
    }

    private func checkAndDisableCollectionViewScrolling() {
        // Check if any visible cell is zoomed
        for cell in collectionView.visibleCells {
            if let photoCell = cell as? LMKPhotoBrowserCell, photoCell.isZoomed {
                collectionView.isScrollEnabled = false
                return
            }
        }
        collectionView.isScrollEnabled = true
    }

    private func resetZoomOnVisibleCells() {
        // Reset zoom on cells that are not currently visible
        for cell in collectionView.visibleCells {
            if let photoCell = cell as? LMKPhotoBrowserCell,
               let indexPath = collectionView.indexPath(for: cell),
               indexPath.item != currentIndex {
                photoCell.resetZoom()
            }
        }
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension LMKPhotoBrowserViewController: UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        // Cell width includes the inter-page gap (trailing padding inside the cell).
        // minimumLineSpacing is 0, so cells are contiguous and paging has no offset drift.
        CGSize(width: view.bounds.width + lmkPhotoBrowserInterPageSpacing,
               height: view.bounds.height)
    }
}

// MARK: - UIGestureRecognizerDelegate

#if targetEnvironment(macCatalyst)
    extension LMKPhotoBrowserViewController: UIGestureRecognizerDelegate {
        public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            // Allow simultaneous recognition with collection view pan gestures
            true
        }

        public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            // Don't interfere with zoom gestures or collection view scrolling
            if otherGestureRecognizer is UIPinchGestureRecognizer {
                return true
            }
            // Let collection view handle its own pan gestures first
            if otherGestureRecognizer is UIPanGestureRecognizer,
               otherGestureRecognizer.view === collectionView {
                return true
            }
            return false
        }

        public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            // Only handle scroll wheel gestures, not regular pan gestures
            guard let panGesture = gestureRecognizer as? UIPanGestureRecognizer else {
                return true
            }
            // Check if this is a discrete scroll event (scroll wheel)
            return panGesture.allowedScrollTypesMask.contains(.discrete)
        }
    }
#endif
