//
//  LMKPhotoBrowserViewController.swift
//  LumiKit
//
//  Full-screen photo browser with swipe navigation, zoom, Live Photos, and
//  swipe-to-dismiss, styled from `theme.photoBrowser`.
//

import LumiKitUI
import PhotosUI
import SnapKit
import UIKit

// MARK: - Protocols

/// Data source for the photo browser. Provides images, dates, and subtitles.
public protocol LMKPhotoBrowserDataSource: AnyObject {
    var numberOfPhotos: Int { get }
    /// Image for the photo at the given index.
    ///
    /// Called on the main actor when a page is configured. Implementations that
    /// decode or fetch should hop off the main actor themselves (e.g.
    /// `Task.detached` plus `UIImage.preparingForDisplay()`) and return a
    /// ready-to-display image; a source that already holds a decoded image just
    /// returns it immediately. The page shows the stage as a placeholder until
    /// the call returns, and a result that lands after the page was recycled is
    /// discarded.
    func photo(at index: Int) async -> UIImage?
    func photoDate(at index: Int) -> Date?
    func photoSubtitle(at index: Int) -> String?
    /// Whether the item at the given index is a Live Photo. Drives the LIVE
    /// capsule immediately on configure, independent of whether the paired
    /// `PHLivePhoto` has loaded yet. Default returns `false`.
    func photoIsLivePhoto(at index: Int) -> Bool
    /// Async load of a paired Live Photo for the given index, asked for every
    /// page; return nil for a still (the default). When non-nil, the browser
    /// upgrades the page to a playable `PHLivePhotoView` on top of the still
    /// image, and a long press anywhere on the page plays it.
    func photoLivePhoto(at index: Int) async -> PHLivePhoto?
}

public extension LMKPhotoBrowserDataSource {
    func photoIsLivePhoto(at _: Int) -> Bool {
        false
    }

    func photoLivePhoto(at _: Int) async -> PHLivePhoto? {
        nil
    }
}

/// Delegate for photo browser actions and dismissal.
public protocol LMKPhotoBrowserDelegate: AnyObject {
    func photoBrowser(_ browser: LMKPhotoBrowserViewController, didRequestActionAt index: Int)
    func photoBrowserDidDismiss(_ browser: LMKPhotoBrowserViewController)
}

// MARK: - LMKPhotoBrowserViewController

/// Full-screen photo browser: horizontal paging, pinch and double-tap zoom, Live Photo
/// playback, a date pill and counter, and a vertical swipe that dismisses.
///
/// ```swift
/// let browser = LMKPhotoBrowserViewController(initialIndex: index)
/// browser.dataSource = self
/// browser.delegate = self
/// browser.zoomSourceView = { [weak self] index in self?.thumbnail(at: index) }   // zooms out of the thumbnail
/// present(browser, animated: true)
/// ```
///
/// The browser forces a dark appearance and draws its chrome from `Style` (per instance or
/// `theme.photoBrowser`). Photos render in HDR where the source and display allow it.
///
/// It presents over the full screen, so the presenting screen stays underneath: a dismiss drag
/// fades the stage and shows that screen through it while the photo follows the finger. A host
/// that sets `modalPresentationStyle = .fullScreen` gets the same motion over black.
public final class LMKPhotoBrowserViewController: UIViewController, LMKThemeApplying {
    // MARK: - Status Bar

    override public var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    // MARK: - Properties

    public weak var dataSource: (any LMKPhotoBrowserDataSource)?
    public weak var delegate: (any LMKPhotoBrowserDelegate)?

    /// Called when the browser dismisses itself (close button, swipe, Escape), alongside
    /// `photoBrowserDidDismiss`.
    public var onDismiss: (() -> Void)?

    /// The view a photo zooms out of and back into, by photo index: the photo travels between
    /// that view and the stage while the stage fades, and the presenting screen stays still.
    /// Set before presenting; the dismiss zooms back to the view of the photo that is current
    /// at that moment (the browser fades out when that view is off screen). `nil` keeps the
    /// plain modal transition.
    public var zoomSourceView: ((Int) -> UIView?)? {
        didSet { updateTransition() }
    }

    /// Whether the overlay action button is installed. Hosts whose current user has no
    /// actions to offer (a view-only shared album) hide it rather than shipping a visible
    /// button whose taps do nothing.
    public var showsActionButton = true {
        didSet {
            guard isViewLoaded else { return }
            actionButton.isHidden = !showsActionButton || photoCount == 0
        }
    }

    /// SF Symbol for the action button. The default "…" suits an action menu; a host whose sole
    /// action is destructive (remove a receipt) passes "trash" so the button says what it does.
    public var actionButtonSystemImageName = "ellipsis" {
        didSet {
            guard isViewLoaded else { return }
            actionButton.setSymbol(actionButtonSystemImageName)
        }
    }

    /// Process-wide strings, read when a browser is created. Override at app launch to localize.
    public nonisolated(unsafe) static var strings = Strings()

    /// This browser's strings.
    public var strings: Strings = LMKPhotoBrowserViewController.strings {
        didSet {
            guard isViewLoaded else { return }
            applyStrings()
        }
    }

    /// Per-instance style, layered over `theme.photoBrowser`.
    public var style: Style {
        didSet {
            guard style != oldValue, isViewLoaded else { return }
            applyTheme(traitCollection.lmkTheme)
        }
    }

    /// Called at the end of every `applyTheme`, for tweaks the style does not cover.
    public var didApplyStyle: ((LMKPhotoBrowserViewController) -> Void)?

    /// The style in effect after the theme and instance style are merged.
    public private(set) var resolvedStyle = Style()

    /// The index of the currently displayed photo.
    public var currentPhotoIndex: Int { currentIndex }

    /// Whether the chrome is hidden (single tap toggles it).
    public internal(set) var isOverlayHidden = false

    // MARK: - Views

    public private(set) lazy var collectionView: UICollectionView = {
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
        collectionView.contentInsetAdjustmentBehavior = .never
        collectionView.register(LMKPhotoBrowserCell.self, forCellWithReuseIdentifier: LMKPhotoBrowserCell.identifier)
        return collectionView
    }()

    /// The stage behind the photos: the one layer a dismiss drag fades.
    public let stageView = UIView()
    public let pageIndicator = LMKPageIndicator()
    public let counterLabel = UILabel()
    public let dateLabel = UILabel()
    public let datePillView = UIView()
    public let emptyStateView = LMKEmptyStateView(style: .fullScreen)
    public let dismissButton = LMKButton(style: .iconOnly())
    public let actionButton = LMKButton(style: .iconOnly())

    // MARK: - State

    let initialIndex: Int
    var currentIndex = 0
    var hasScrolledToInitialIndex = false
    /// Whether the delegate and `onDismiss` have heard about the dismissal under way; a
    /// key command during a swipe's exit animation would otherwise report it twice.
    var didNotifyDismiss = false
    /// The presentation's zoom-in while it runs. A dismissal that starts before it ends
    /// finishes it first, so the thumbnail's alpha and the pages' mask are restored before
    /// the way out captures them.
    var presentationAnimator: UIViewPropertyAnimator?
    /// The photo travelling in during the presentation, removed when a dismissal cuts in.
    var presentationPhoto: UIView?
    var collectionWidthConstraint: Constraint?
    /// The page width the offset was last aligned to; a rotation or a window resize changes it.
    private var alignedPageWidth: CGFloat = 0
    private var dismissButtonSizeConstraint: Constraint?
    private var actionButtonSizeConstraint: Constraint?
    private var dismissButtonTopConstraint: Constraint?
    private var dismissButtonTrailingConstraint: Constraint?
    private var actionButtonTopConstraint: Constraint?
    private var actionButtonLeadingConstraint: Constraint?
    private var pageIndicatorBottomConstraint: Constraint?
    private var counterBottomConstraint: Constraint?
    private var datePillBottomConstraint: Constraint?
    private var datePillLeadingConstraint: Constraint?
    private var emptyStateInsetConstraint: Constraint?
    private var datePillInsets = NSDirectionalEdgeInsets.zero
    #if targetEnvironment(macCatalyst)
        lazy var scrollWheelDelegate = LMKPhotoBrowserScrollWheelDelegate(collectionView: collectionView)
    #endif

    // MARK: - Initialization

    public init(initialIndex: Int = 0, style: Style = Style()) {
        self.initialIndex = max(0, initialIndex)
        self.style = style
        super.init(nibName: nil, bundle: nil)
        // Over the presenter, not in place of it: the stage fades to it during a dismiss drag.
        modalPresentationStyle = .overFullScreen
        modalPresentationCapturesStatusBarAppearance = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override public func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .dark
        setupViews()
        applyStrings()
        lmk_startApplyingTheme()
        if #available(iOS 26, *) {
            registerForTraitChanges([UITraitHDRHeadroomUsageLimit.self]) { (browser: Self, _: UITraitCollection) in
                browser.applyDynamicRangeToVisibleCells()
            }
        }
        installMacBehaviors()
        render()
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Whatever a dismissal left behind (a fade, a snap's shrink, a frozen page) clears: the
        // same instance can be presented again.
        view.alpha = 1
        stageView.alpha = 1
        collectionView.alpha = 1
        collectionView.transform = .identity
        didNotifyDismiss = false
        for case let cell as LMKPhotoBrowserCell in collectionView.visibleCells {
            cell.prepareForReappearance()
        }
        let count = photoCount
        // The initial index applies once; a later appearance (a sheet over the browser went
        // away) keeps the photo the user paged to.
        let index = hasScrolledToInitialIndex ? currentIndex : initialIndex
        currentIndex = count > 0 ? max(0, min(index, count - 1)) : 0
    }

    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if resolvedStyle.playsHaptics {
            LMKHaptics.prepare()
        }
        becomeFirstResponder()
        guard photoCount > 0 else { return }
        alignToCurrentPageIfIdle()
        updatePhotoAccessibility()
    }

    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard view.bounds.width > 0, view.bounds.height > 0, photoCount > 0 else { return }

        // Cell width = page width + the inter-page gap. The gap is part of the cell (trailing
        // padding), so minimumLineSpacing stays 0 and paging has no offset drift.
        let pageSize = view.bounds.size
        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.itemSize = CGSize(width: pageSize.width + resolvedStyle.pageGap(theme: traitCollection.lmkTheme), height: pageSize.height)
        }

        // Pages re-fit their own installed image; pages still loading resolve
        // their size at install time instead.
        for case let cell as LMKPhotoBrowserCell in collectionView.visibleCells {
            cell.refitInstalledImage(to: pageSize)
        }

        // The offset is aligned once at first, then again whenever the page width changes (a
        // rotation, a window resize, a theme with another page gap): the old offset would land
        // between two pages of the new width, and a page zoomed at that moment would keep an
        // offset outside its new travel. `viewDidAppear` alone re-aligns for a swipe under way.
        let pageWidth = collectionView.bounds.width
        guard pageWidth > 0 else { return }
        if !hasScrolledToInitialIndex {
            hasScrolledToInitialIndex = true
            alignedPageWidth = pageWidth
            scrollToPhoto(at: currentIndex, animated: false)
        } else if pageWidth != alignedPageWidth {
            alignedPageWidth = pageWidth
            for case let cell as LMKPhotoBrowserCell in collectionView.visibleCells {
                cell.resetZoom()
            }
            // The collection view first consumes its own bounds change, which keeps the page
            // sizes its delegate gave it; only an invalidation after that re-measures them.
            collectionView.layoutIfNeeded()
            invalidatePageLayout()
            collectionView.layoutIfNeeded()
            scrollToPhoto(at: currentIndex, animated: false)
        }
    }

    /// Re-measures every page on the collection view's next layout pass.
    func invalidatePageLayout() {
        collectionView.collectionViewLayout.invalidateLayout()
        collectionView.setNeedsLayout()
    }

    override public var canBecomeFirstResponder: Bool { true }

    /// The VoiceOver escape gesture closes the browser, like the close button.
    override public func accessibilityPerformEscape() -> Bool {
        dismissBrowser()
        return true
    }

    // MARK: - Setup

    private func setupViews() {
        view.clipsToBounds = true

        stageView.isUserInteractionEnabled = false
        view.addSubview(stageView)
        stageView.snp.makeConstraints { $0.edges.equalToSuperview() }

        // The collection view is wider than the view by the inter-page gap so each cell
        // (which includes the gap) pages correctly; the trailing overflow is clipped.
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.top.bottom.leading.equalToSuperview()
            collectionWidthConstraint = make.width.equalToSuperview().offset(0).constraint
        }

        // Tap: single toggles the overlay, double zooms (single waits for double to fail).
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2
        collectionView.addGestureRecognizer(doubleTap)
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(handleSingleTap))
        singleTap.require(toFail: doubleTap)
        collectionView.addGestureRecognizer(singleTap)

        // Spacing constraints start at zero and take their values from the theme handed to
        // `applyTheme`, so a scoped or later theme applies to them too.
        emptyStateView.isHidden = true
        view.addSubview(emptyStateView)
        emptyStateView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            emptyStateInsetConstraint = make.leading.trailing.equalTo(view.safeAreaLayoutGuide).inset(0).constraint
        }

        dismissButton.setSymbol("xmark")
        dismissButton.onTap = { [weak self] in self?.dismissBrowser() }
        view.addSubview(dismissButton)
        dismissButton.snp.makeConstraints { make in
            dismissButtonTopConstraint = make.top.equalTo(view.safeAreaLayoutGuide).offset(0).constraint
            dismissButtonTrailingConstraint = make.trailing.equalTo(view.safeAreaLayoutGuide).offset(0).constraint
            // 999: the button's own minimum height is required, and `applyTheme` sets both to
            // the same side; until then the floor wins without a conflict.
            dismissButtonSizeConstraint = make.size.equalTo(0).priority(999).constraint
        }

        actionButton.setSymbol(actionButtonSystemImageName)
        actionButton.onTap = { [weak self] in self?.requestAction() }
        view.addSubview(actionButton)
        actionButton.snp.makeConstraints { make in
            actionButtonTopConstraint = make.top.equalTo(view.safeAreaLayoutGuide).offset(0).constraint
            actionButtonLeadingConstraint = make.leading.equalTo(view.safeAreaLayoutGuide).offset(0).constraint
            actionButtonSizeConstraint = make.size.equalTo(0).priority(999).constraint
        }

        pageIndicator.onPageChange = { [weak self] page in
            self?.showPhoto(at: page, animated: true)
        }
        view.addSubview(pageIndicator)
        pageIndicator.snp.makeConstraints { make in
            pageIndicatorBottomConstraint = make.bottom.equalTo(view.safeAreaLayoutGuide).offset(0).constraint
            make.centerX.equalToSuperview()
        }

        counterLabel.textAlignment = .center
        view.addSubview(counterLabel)
        counterLabel.snp.makeConstraints { make in
            counterBottomConstraint = make.bottom.equalTo(pageIndicator.snp.top).offset(0).constraint
            make.centerX.equalToSuperview()
        }

        datePillView.isAccessibilityElement = false
        view.addSubview(datePillView)
        datePillView.snp.makeConstraints { make in
            datePillBottomConstraint = make.bottom.equalTo(counterLabel.snp.top).offset(0).constraint
            make.centerX.equalToSuperview()
            datePillLeadingConstraint = make.leading.greaterThanOrEqualTo(view.safeAreaLayoutGuide).offset(0).constraint
        }
        dateLabel.textAlignment = .center
        dateLabel.numberOfLines = 2
        datePillView.addSubview(dateLabel)
        dateLabel.snp.makeConstraints { make in
            make.directionalEdges.equalToSuperview().inset(datePillInsets)
        }
    }

    private func applyStrings() {
        dismissButton.accessibilityLabel = strings.dismissAccessibilityLabel
        actionButton.accessibilityLabel = strings.actionAccessibilityLabel
        emptyStateView.configure(LMKEmptyStateView.Content(message: strings.emptyText, icon: .system("photo")))
        for case let cell as LMKPhotoBrowserCell in collectionView.visibleCells {
            cell.apply(strings: strings)
        }
        updateCounterLabel()
        updatePhotoAccessibility()
    }

    // MARK: - Theme

    public func applyTheme(_ theme: LMKTheme) {
        resolvedStyle = theme.photoBrowser.merging(style)
        let resolved = resolvedStyle
        let stage = resolved.stageColor
        let chrome = resolved.chrome

        // The stage is its own layer so a dismiss drag can fade it under the photo.
        view.backgroundColor = .clear
        stageView.backgroundColor = stage
        collectionView.backgroundColor = .clear

        let buttonStyle = resolved.overlayButtonStyle(theme: theme)
        dismissButton.style = buttonStyle
        actionButton.style = buttonStyle
        let buttonSide = resolved.buttonSize(theme: theme)
        dismissButtonSizeConstraint?.update(offset: buttonSide)
        actionButtonSizeConstraint?.update(offset: buttonSide)
        let margin = theme.spacing.large
        dismissButtonTopConstraint?.update(offset: margin)
        dismissButtonTrailingConstraint?.update(offset: -margin)
        actionButtonTopConstraint?.update(offset: margin)
        actionButtonLeadingConstraint?.update(offset: margin)
        emptyStateInsetConstraint?.update(inset: margin)
        datePillLeadingConstraint?.update(offset: margin)
        pageIndicatorBottomConstraint?.update(offset: -theme.spacing.xl)
        counterBottomConstraint?.update(offset: -theme.spacing.xs)
        datePillBottomConstraint?.update(offset: -theme.spacing.medium)

        pageIndicator.style = LMKPageIndicator.Style(
            activeColor: chrome,
            inactiveColor: chrome.withAlphaComponent(theme.alpha.medium)
        ).merging(resolved.pageIndicator)

        counterLabel.lmk_apply(resolved.counterTextStyle ?? .caption, color: chrome.withAlphaComponent(resolved.counterAlpha ?? LMKPhotoBrowserMetrics.counterAlpha))

        let pill = datePillView.lmk_apply(
            surface: resolved.datePill,
            defaults: LMKSurfaceStyle(
                background: .solid(stage.withAlphaComponent(theme.alpha.large)),
                corners: .fixed(theme.cornerRadius.small),
                contentInsets: .lmk_symmetric(vertical: theme.spacing.small, horizontal: theme.spacing.medium)
            )
        )
        let insets = pill.contentInsets ?? .zero
        if insets != datePillInsets {
            datePillInsets = insets
            dateLabel.snp.remakeConstraints { make in
                make.directionalEdges.equalToSuperview().inset(insets)
            }
        }
        dateLabel.lmk_apply(resolved.dateTextStyle ?? .bodyMedium, color: chrome)

        emptyStateView.style = LMKEmptyStateView.Style(
            iconTint: chrome.withAlphaComponent(theme.alpha.xl),
            messageColor: chrome
        ).merging(resolved.emptyState)

        collectionWidthConstraint?.update(offset: resolved.pageGap(theme: theme))
        invalidatePageLayout()
        for case let cell as LMKPhotoBrowserCell in collectionView.visibleCells {
            cell.apply(style: resolved, theme: theme, dynamicRange: effectiveDynamicRange)
        }
        if #available(iOS 26, *) {
            setNeedsUpdateOfPrefersInterfaceOrientationLocked()
        }
        didApplyStyle?(self)
    }

    /// The dynamic range pages render with: `.high` when the style wants HDR, constrained
    /// while the iOS 26 headroom usage limit is active, `.standard` otherwise.
    var effectiveDynamicRange: UIImage.DynamicRange {
        guard resolvedStyle.wantsHDR else { return .standard }
        if #available(iOS 26, *), traitCollection.hdrHeadroomUsageLimit == .active {
            return .constrainedHigh
        }
        return .high
    }

    func applyDynamicRangeToVisibleCells() {
        let range = effectiveDynamicRange
        for case let cell as LMKPhotoBrowserCell in collectionView.visibleCells {
            cell.preferredImageDynamicRange = range
        }
    }

    /// iOS 26 only: earlier systems have no per-controller lock, so the browser rotates there
    /// and re-aligns its page to the new width.
    @available(iOS 26.0, *)
    override public var prefersInterfaceOrientationLocked: Bool {
        resolvedStyle.locksOrientation ?? false
    }

    // MARK: - Rendering

    var photoCount: Int { dataSource?.numberOfPhotos ?? 0 }

    /// Shows the empty state or the pages, and refreshes the counter, dots, and date pill.
    func render() {
        let count = photoCount
        let isEmpty = count == 0
        emptyStateView.isHidden = !isEmpty
        collectionView.isHidden = isEmpty
        actionButton.isHidden = isEmpty || !showsActionButton
        pageIndicator.numberOfPages = count
        pageIndicator.isHidden = count <= 1
        counterLabel.isHidden = isEmpty
        updateDateLabel()
        updateCounterLabel()
        updatePhotoAccessibility()
    }

    // MARK: - Public API

    /// Reloads the pages from the data source. Call after the data source's content changes.
    /// The current index is clamped to the new count (zero when nothing is left).
    public func reloadData() {
        collectionView.reloadData()
        render()
        let count = photoCount
        guard count > 0 else {
            currentIndex = 0
            return
        }
        updateCurrentIndex(max(0, min(currentIndex, count - 1)))
    }

    /// Pages to `index` (clamped to the data source), keeping the chrome as is.
    public func showPhoto(at index: Int, animated: Bool) {
        let count = photoCount
        guard count > 0 else { return }
        scrollToPhoto(at: max(0, min(index, count - 1)), animated: animated)
    }

    /// Hides or shows the chrome (buttons, dots, counter, date pill).
    public func setOverlayHidden(_ hidden: Bool, animated: Bool) {
        guard hidden != isOverlayHidden else { return }
        toggleOverlay(animated: animated)
    }

    // MARK: - Actions

    @objc private func handleSingleTap() {
        toggleOverlay(animated: true)
    }

    @objc private func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        guard gesture.state == .ended else { return }
        let location = gesture.location(in: collectionView)
        guard let indexPath = collectionView.indexPathForItem(at: location),
              let cell = collectionView.cellForItem(at: indexPath) as? LMKPhotoBrowserCell,
              indexPath.item < photoCount else { return }
        cell.zoomAtLocationInCell(gesture.location(in: cell))
        if resolvedStyle.playsHaptics {
            LMKHaptics.light()
        }
    }

    @objc func requestAction() {
        guard currentIndex < photoCount else { return }
        delegate?.photoBrowser(self, didRequestActionAt: currentIndex)
    }

    @objc func dismissFromKeyCommand() {
        dismissBrowser()
    }

    @objc func showPreviousFromKeyCommand() {
        showPhoto(at: currentIndex - 1, animated: true)
    }

    @objc func showNextFromKeyCommand() {
        showPhoto(at: currentIndex + 1, animated: true)
    }

    // MARK: - Key Commands

    /// Whether the pages run right to left (the flow layout mirrors them), so the next photo
    /// sits on the left.
    var isRightToLeft: Bool {
        collectionView.effectiveUserInterfaceLayoutDirection == .rightToLeft
    }

    override public var keyCommands: [UIKeyCommand]? {
        // The arrows follow the pages: in a right-to-left layout the next photo is on the left.
        let rightToLeft = isRightToLeft
        let previous = UIKeyCommand(
            title: strings.previousPhoto,
            action: #selector(showPreviousFromKeyCommand),
            input: rightToLeft ? UIKeyCommand.inputRightArrow : UIKeyCommand.inputLeftArrow,
            modifierFlags: []
        )
        let next = UIKeyCommand(title: strings.nextPhoto, action: #selector(showNextFromKeyCommand), input: rightToLeft ? UIKeyCommand.inputLeftArrow : UIKeyCommand.inputRightArrow, modifierFlags: [])
        previous.wantsPriorityOverSystemBehavior = true
        next.wantsPriorityOverSystemBehavior = true
        var commands = [
            previous,
            next,
            UIKeyCommand(title: strings.dismissAccessibilityLabel, action: #selector(dismissFromKeyCommand), input: UIKeyCommand.inputEscape, modifierFlags: []),
            UIKeyCommand(title: strings.dismissAccessibilityLabel, action: #selector(dismissFromKeyCommand), input: "w", modifierFlags: .command),
        ]
        if showsActionButton, photoCount > 0 {
            commands.append(UIKeyCommand(title: strings.actionAccessibilityLabel, action: #selector(requestAction), input: " ", modifierFlags: []))
            commands.append(UIKeyCommand(title: strings.actionAccessibilityLabel, action: #selector(requestAction), input: "e", modifierFlags: .command))
        }
        return commands
    }
}
