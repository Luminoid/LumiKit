//
//  LMKPhotoGridViewController.swift
//  LumiKit
//
//  Photo grid with square cells, pinch-to-zoom column control, sort by date,
//  a content mode toggle, multi-selection, context menus, prefetching, and a
//  zoom transition into the photo browser, styled from `theme.photoGrid`.
//  The pinch and drag-to-select gestures live in +Gestures.
//

import LumiKitUI
import PhotosUI
import SnapKit
import UIKit

// MARK: - Enums

public extension LMKPhotoGridViewController {
    /// How a cell fits its photo.
    nonisolated enum ContentMode: Sendable, Hashable, CaseIterable {
        case aspectFit
        case aspectFill

        var uiContentMode: UIView.ContentMode {
            switch self {
            case .aspectFit: .scaleAspectFit
            case .aspectFill: .scaleAspectFill
            }
        }

        var systemImageName: String {
            switch self {
            case .aspectFit: "arrow.down.right.and.arrow.up.left"
            case .aspectFill: "arrow.up.left.and.arrow.down.right"
            }
        }
    }

    /// Sort order by date.
    nonisolated enum SortOrder: Sendable, Hashable, CaseIterable {
        case ascending
        case descending

        var systemImageName: String {
            switch self {
            case .ascending: "arrow.up.circle"
            case .descending: "arrow.down.circle"
            }
        }
    }
}

// MARK: - Protocols

/// Data source for the photo grid. Provides images and dates.
public protocol LMKPhotoGridDataSource: AnyObject {
    /// Total number of photos.
    var numberOfPhotos: Int { get }
    /// The full-size image for the photo at the given data source index, for the full-screen
    /// browser the grid opens.
    ///
    /// Called on the main actor when a browser page is configured. Implementations that decode
    /// or fetch should hop off the main actor themselves (e.g. `Task.detached` plus
    /// `UIImage.preparingForDisplay()`) and return a ready-to-display image; a source that
    /// already holds a decoded image just returns it immediately. The page shows the stage
    /// until the call returns, and a result that lands after the page was reused for a
    /// different index is discarded.
    func photoGridImage(at index: Int) async -> UIImage?
    /// A thumbnail for the cell at the given data source index, decoded for about
    /// `pixelSize` (the cell's side at the display scale), so the grid never holds a
    /// full-size decode per visible cell.
    ///
    /// Called on the main actor whenever a cell needs its image; the same rules as
    /// `photoGridImage(at:)` apply. The default downsamples `photoGridImage(at:)`'s result
    /// off the main actor (`byPreparingThumbnail(ofSize:)`); a source with its own
    /// thumbnails (a cache, `PHImageManager`) returns them here directly.
    func photoGridThumbnail(at index: Int, pixelSize: CGSize) async -> UIImage?
    /// Date for the photo at the given data source index. Used for sorting.
    func photoGridDate(at index: Int) -> Date?
    /// Whether the item at the given index is a Live Photo (drives the LIVE badge). Default `false`.
    func photoGridIsLivePhoto(at index: Int) -> Bool
    /// Async fetch of the paired `PHLivePhoto` at the given index, forwarded to the browser.
    /// Default `nil`.
    func photoGridLivePhoto(at index: Int) async -> PHLivePhoto?
    /// The grid is about to need these data source indices (`UICollectionViewDataSourcePrefetching`);
    /// warm a cache here. Default does nothing.
    func photoGridPrefetch(indices: [Int])
    /// The indices from a previous `photoGridPrefetch` are no longer needed. Default does nothing.
    func photoGridCancelPrefetch(indices: [Int])
}

public extension LMKPhotoGridDataSource {
    func photoGridThumbnail(at index: Int, pixelSize: CGSize) async -> UIImage? {
        guard let image = await photoGridImage(at: index) else { return nil }
        return await LMKPhotoGridViewController.thumbnail(of: image, pixelSize: pixelSize)
    }

    func photoGridIsLivePhoto(at _: Int) -> Bool {
        false
    }

    func photoGridLivePhoto(at _: Int) async -> PHLivePhoto? {
        nil
    }

    func photoGridPrefetch(indices _: [Int]) {}

    func photoGridCancelPrefetch(indices _: [Int]) {}
}

/// Delegate for photo grid actions.
public protocol LMKPhotoGridDelegate: AnyObject {
    /// Called when the photo browser's action button is tapped.
    /// The index is the data source index (not the sorted display index).
    func photoGrid(_ grid: LMKPhotoGridViewController, didRequestActionForPhotoAt index: Int)
}

// MARK: - LMKPhotoGridViewController

/// Photo grid with pinch-to-zoom columns, date sorting, a fit / fill toggle, and the browser
/// one tap away (zooming out of the tapped cell).
///
/// ```swift
/// let grid = LMKPhotoGridViewController(columnCount: 3)
/// grid.dataSource = self
/// grid.delegate = self
/// grid.contextMenuProvider = { [weak self] index in self?.menu(forPhotoAt: index) }
/// ```
///
/// Selection: set `allowsMultipleSelection` and taps toggle cells instead of opening the
/// browser; `selectedIndices` (data source indices) reports through `onSelectionChange`.
///
/// Gestures:
/// - **Pinch** steps the column count. The photo under the fingers stays under them, the
///   grid leans into the pinch before each step, and scrolling waits until the fingers lift.
/// - **Drag sideways** across cells while selecting to select (or, starting on a selected
///   cell, deselect) every photo between the first cell and the finger; the grid scrolls
///   when the drag nears its top or bottom edge. A vertical drag still scrolls.
/// - **Touch down** dims the photo, so a tap is acknowledged before the browser opens.
/// - **Long press** (or a secondary click) opens `contextMenuProvider`'s menu.
public final class LMKPhotoGridViewController: UIViewController, LMKThemeApplying {
    // MARK: - Properties

    public weak var dataSource: (any LMKPhotoGridDataSource)?
    public weak var delegate: (any LMKPhotoGridDelegate)?

    /// Process-wide strings, read when a grid is created. Override at app launch to localize.
    public nonisolated(unsafe) static var strings = Strings()

    /// This grid's strings.
    public var strings: Strings = LMKPhotoGridViewController.strings {
        didSet {
            guard isViewLoaded else { return }
            applyStrings()
        }
    }

    /// Strings forwarded to the photo browser when presented; defaults to the browser's
    /// process-wide strings, so an app-level override reaches the grid's browser too.
    public var browserStrings = LMKPhotoBrowserViewController.strings
    /// Style forwarded to the photo browser when presented; `nil` leaves `theme.photoBrowser`.
    public var browserStyle: LMKPhotoBrowserViewController.Style?
    /// Forwarded to the photo browser's `showsActionButton` when presented.
    public var browserShowsActionButton = true
    /// The photo browser the grid has presented, while it is up: the controller to present an
    /// action sheet or a toast from in `photoGrid(_:didRequestActionForPhotoAt:)`. The grid's
    /// `reloadData()` reloads it as well.
    public private(set) weak var browser: LMKPhotoBrowserViewController?

    /// Per-instance style, layered over `theme.photoGrid`.
    public var style: Style {
        didSet {
            guard style != oldValue, isViewLoaded else { return }
            applyTheme(traitCollection.lmkTheme)
        }
    }

    /// Called at the end of every `applyTheme`, for tweaks the style does not cover.
    public var didApplyStyle: ((LMKPhotoGridViewController) -> Void)?

    /// The style in effect after the theme and instance style are merged.
    public private(set) var resolvedStyle = Style()

    public private(set) var columnCount: Int
    public private(set) var photoContentMode: ContentMode = .aspectFill
    public private(set) var sortOrder: SortOrder = .descending

    /// When set, taps toggle cells instead of opening the browser.
    public var allowsMultipleSelection = false {
        didSet {
            guard allowsMultipleSelection != oldValue, !allowsMultipleSelection else { return }
            setSelection([], animated: false)
        }
    }

    /// Selected photos as data source indices.
    public private(set) var selectedIndices: Set<Int> = []

    /// Called when the user changes the selection (not for `setSelection`).
    public var onSelectionChange: ((Set<Int>) -> Void)?

    /// A context menu for the photo at a data source index (long press, secondary click).
    public var contextMenuProvider: ((Int) -> UIMenu?)?

    /// Maps display position to data source index, accounting for sort order.
    var sortedIndices: [Int] = []
    private var lastLayoutWidth: CGFloat = 0
    private var toolbarInsets = NSDirectionalEdgeInsets.zero
    private var toolbarBottomConstraint: Constraint?
    private var emptyStateInsetConstraint: Constraint?
    /// The browser's data source and delegate, mapping its display indices to the data
    /// source's, kept off the grid's public surface.
    lazy var browserBridge = LMKPhotoGridBrowserBridge(grid: self)

    /// Whether rows run right to left (the flow layout starts each row at the right).
    var isRightToLeft: Bool { collectionView.effectiveUserInterfaceLayoutDirection == .rightToLeft }
    /// Room at the end of the grid for the floating toolbar, so the last row scrolls clear of it.
    private var toolbarContentInset: CGFloat = 0

    // Gesture state (see +Gestures).
    var pinchAnchor: GridAnchor?
    var scrollWasEnabledBeforePinch = true
    var dragSelection: DragSelection?
    var autoScrollLink: CADisplayLink?
    var autoScrollVelocity: CGFloat = 0

    // MARK: - Views

    public private(set) lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.sectionInset = .zero

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.prefetchDataSource = self
        collectionView.showsVerticalScrollIndicator = true
        collectionView.alwaysBounceVertical = true
        collectionView.keyboardDismissMode = .onDrag
        collectionView.register(LMKPhotoGridCell.self, forCellWithReuseIdentifier: LMKPhotoGridCell.identifier)
        return collectionView
    }()

    public let emptyStateView = LMKEmptyStateView(style: .fullScreen)
    public let toolbarView = UIView()
    public let sortButton = LMKButton(style: .ghost(.neutral))
    public let contentModeButton = LMKButton(style: .ghost(.neutral))
    private let toolbarStack = UIStackView()

    private(set) lazy var pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
    private(set) lazy var selectionPanGesture: UIPanGestureRecognizer = {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handleSelectionPan(_:)))
        pan.maximumNumberOfTouches = 1
        pan.delegate = gestureDelegate
        return pan
    }()

    private lazy var gestureDelegate = LMKPhotoGridGestureDelegate(owner: self)

    // MARK: - Initialization

    public init(columnCount: Int = 2, style: Style = Style()) {
        self.columnCount = max(1, columnCount)
        self.style = style
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override public func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        applyStrings()
        lmk_startApplyingTheme()
        rebuildSortedIndices()
        updateEmptyState()
    }

    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let currentWidth = view.bounds.width
        if currentWidth != lastLayoutWidth, currentWidth > 0 {
            lastLayoutWidth = currentWidth
            collectionView.collectionViewLayout.invalidateLayout()
        }
        updateToolbarContentInset()
    }

    override public func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        endDragSelection()
    }

    /// Keeps the grid's bottom inset at the toolbar's height plus its margins while the toolbar
    /// shows, so the last row can scroll out from under it.
    private func updateToolbarContentInset() {
        let room: CGFloat = toolbarView.isHidden ? 0 : toolbarView.bounds.height + (resolvedStyle.toolbarBottomMargin ?? traitCollection.lmkTheme.spacing.medium) * 2
        guard room != toolbarContentInset else { return }
        collectionView.contentInset.bottom += room - toolbarContentInset
        collectionView.verticalScrollIndicatorInsets.bottom += room - toolbarContentInset
        toolbarContentInset = room
    }

    // MARK: - Setup

    private func setupUI() {
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        // The inset takes its value from the theme in `applyTheme`.
        emptyStateView.isHidden = true
        view.addSubview(emptyStateView)
        emptyStateView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            emptyStateInsetConstraint = make.leading.trailing.equalTo(view.safeAreaLayoutGuide).inset(0).constraint
        }

        sortButton.setSymbol(sortOrder.systemImageName)
        sortButton.onTap = { [weak self] in self?.toggleSortOrder() }
        contentModeButton.setSymbol(photoContentMode.systemImageName)
        contentModeButton.onTap = { [weak self] in self?.toggleContentMode() }
        toolbarStack.axis = .horizontal
        toolbarStack.lmk_addArrangedSubviews([sortButton, contentModeButton])
        toolbarView.addSubview(toolbarStack)
        toolbarStack.snp.makeConstraints { make in
            make.directionalEdges.equalToSuperview().inset(toolbarInsets)
        }
        view.addSubview(toolbarView)
        toolbarView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            toolbarBottomConstraint = make.bottom.equalTo(view.safeAreaLayoutGuide).offset(0).constraint
        }
        collectionView.addGestureRecognizer(pinchGesture)
        collectionView.addGestureRecognizer(selectionPanGesture)
    }

    private func applyStrings() {
        updateSortButton()
        updateContentModeButton()
        updateEmptyState()
        for case let cell as LMKPhotoGridCell in collectionView.visibleCells {
            if let indexPath = collectionView.indexPath(for: cell) {
                applyAccessibility(to: cell, displayIndex: indexPath.item)
            }
        }
    }

    // MARK: - Theme

    public func applyTheme(_ theme: LMKTheme) {
        resolvedStyle = theme.photoGrid.merging(style)
        let resolved = resolvedStyle

        let background = resolved.backgroundColor ?? LMKColor.backgroundPrimary
        view.backgroundColor = background
        collectionView.backgroundColor = background

        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.minimumInteritemSpacing = resolved.cellSpacing
            layout.minimumLineSpacing = resolved.cellSpacing
        }
        collectionView.collectionViewLayout.invalidateLayout()
        if #available(iOS 26, *) {
            // Under the navigation bar by default; never a band across the bottom row unless
            // asked for: the floating toolbar reads on its own glass.
            collectionView.topEdgeEffect.isHidden = !(resolved.showsScrollEdgeEffects ?? true)
            collectionView.bottomEdgeEffect.isHidden = !(resolved.showsBottomEdgeEffect ?? false)
        }

        let toolbar = toolbarView.lmk_apply(
            surface: resolved.toolbar,
            defaults: LMKSurfaceStyle(
                background: .glass(.regular, tint: nil),
                corners: .fixed(theme.cornerRadius.large),
                contentInsets: .lmk_symmetric(vertical: theme.spacing.xs, horizontal: theme.spacing.small)
            )
        )
        let insets = toolbar.contentInsets ?? .zero
        if insets != toolbarInsets {
            toolbarInsets = insets
            toolbarStack.snp.remakeConstraints { make in
                make.directionalEdges.equalToSuperview().inset(insets)
            }
        }
        toolbarStack.spacing = resolved.toolbarSpacing ?? theme.spacing.medium
        toolbarBottomConstraint?.update(offset: -(resolved.toolbarBottomMargin ?? theme.spacing.medium))
        emptyStateInsetConstraint?.update(inset: theme.spacing.large)
        let buttonStyle = LMKButton.Style(
            role: .neutral,
            variant: .ghost,
            symbolPointSize: theme.layout.symbolInline,
            haptics: resolved.haptics
        ).merging(resolved.toolbarButton)
        sortButton.style = buttonStyle
        contentModeButton.style = buttonStyle

        for case let cell as LMKPhotoGridCell in collectionView.visibleCells {
            cell.apply(style: resolved, theme: theme)
        }
        updateEmptyState()
        view.setNeedsLayout()
        didApplyStyle?(self)
    }

    // MARK: - Actions

    /// Toggles between ascending and descending sort order.
    public func toggleSortOrder() {
        setSortOrder(sortOrder == .descending ? .ascending : .descending)
    }

    /// Toggles between aspect fit and aspect fill content mode.
    public func toggleContentMode() {
        setContentMode(photoContentMode == .aspectFill ? .aspectFit : .aspectFill)
    }

    // MARK: - Public API

    /// Sets the column count (clamped between one and the width-derived maximum). The photo at
    /// the middle of the grid keeps its place.
    public func setColumnCount(_ count: Int, animated: Bool) {
        setColumnCount(count, animated: animated, anchor: anchor(atViewportPoint: CGPoint(x: collectionView.bounds.width / 2, y: collectionView.bounds.height / 2)))
    }

    /// Sets the column count and scrolls so `anchor`'s photo stays where it was on screen.
    /// - Returns: Whether the count changed.
    @discardableResult
    func setColumnCount(_ count: Int, animated: Bool, anchor: GridAnchor?) -> Bool {
        let clamped = max(1, min(maximumColumnCount, count))
        guard clamped != columnCount else { return false }
        columnCount = clamped
        let relayout = {
            self.collectionView.collectionViewLayout.invalidateLayout()
            self.collectionView.layoutIfNeeded()
            if let anchor, let offset = self.contentOffset(keeping: anchor) {
                self.collectionView.contentOffset = offset
            }
        }
        if animated, LMKAnimation.shouldAnimate, view.window != nil {
            UIView.animate(withDuration: LMKAnimation.Duration.normal, delay: 0, options: [.curveEaseInOut, .beginFromCurrentState, .allowUserInteraction], animations: relayout)
        } else {
            relayout()
        }
        if resolvedStyle.playsHaptics {
            LMKHaptics.light()
        }
        return true
    }

    /// Sets the content mode for all grid cells.
    public func setContentMode(_ mode: ContentMode) {
        guard mode != photoContentMode else { return }
        photoContentMode = mode
        updateContentModeButton()
        // `configure(with: nil, ...)` clears the image so the reload picks up the new mode
        // cleanly; `isLive` comes from the data source so the badge does not flicker off.
        for case let cell as LMKPhotoGridCell in collectionView.visibleCells {
            guard let indexPath = collectionView.indexPath(for: cell) else { continue }
            let isLive = dataSourceIndex(forDisplayIndex: indexPath.item).flatMap { dataSource?.photoGridIsLivePhoto(at: $0) } ?? false
            cell.configure(with: nil, contentMode: mode.uiContentMode, isLive: isLive)
        }
        collectionView.reloadData()
        if resolvedStyle.playsHaptics {
            LMKHaptics.light()
        }
    }

    /// Sets the sort order and re-sorts the grid.
    public func setSortOrder(_ order: SortOrder) {
        guard order != sortOrder else { return }
        sortOrder = order
        updateSortButton()
        rebuildSortedIndices()
        if LMKAnimation.shouldAnimate {
            UIView.transition(with: collectionView, duration: LMKAnimation.Duration.normal, options: .transitionCrossDissolve) {
                self.collectionView.reloadData()
            }
        } else {
            collectionView.reloadData()
        }
        if resolvedStyle.playsHaptics {
            LMKHaptics.light()
        }
    }

    /// Reloads the grid from the data source, and the browser it has presented; selections
    /// outside the new range are dropped.
    public func reloadData() {
        rebuildSortedIndices()
        let count = photoCount
        selectedIndices = selectedIndices.filter { $0 < count }
        collectionView.reloadData()
        updateEmptyState()
        browser?.reloadData()
    }

    /// Replaces the selection silently (no `onSelectionChange`), by data source indices.
    public func setSelection(_ indices: Set<Int>, animated: Bool) {
        let count = photoCount
        selectedIndices = indices.filter { $0 >= 0 && $0 < count }
        let visible = collectionView.visibleCells.compactMap { cell -> (LMKPhotoGridCell, Int)? in
            guard let gridCell = cell as? LMKPhotoGridCell, let indexPath = collectionView.indexPath(for: gridCell),
                  let dsIndex = dataSourceIndex(forDisplayIndex: indexPath.item) else { return nil }
            return (gridCell, dsIndex)
        }
        let apply = {
            for (cell, dsIndex) in visible {
                cell.setShowsSelected(self.selectedIndices.contains(dsIndex))
            }
        }
        if animated, LMKAnimation.shouldAnimate {
            UIView.transition(with: collectionView, duration: LMKAnimation.Duration.fast, options: .transitionCrossDissolve, animations: apply)
        } else {
            apply()
        }
    }

    /// The visible cell showing the photo at a data source index, if any.
    public func cell(forPhotoAt dataSourceIndex: Int) -> UICollectionViewCell? {
        guard let displayIndex = sortedIndices.firstIndex(of: dataSourceIndex) else { return nil }
        return collectionView.cellForItem(at: IndexPath(item: displayIndex, section: 0))
    }

    // MARK: - UI Updates

    private func updateSortButton() {
        sortButton.setSymbol(sortOrder.systemImageName)
        sortButton.accessibilityLabel = sortOrder == .descending ? strings.sortDescendingLabel : strings.sortAscendingLabel
    }

    private func updateContentModeButton() {
        contentModeButton.setSymbol(photoContentMode.systemImageName)
        contentModeButton.accessibilityLabel = photoContentMode == .aspectFill ? strings.aspectFillLabel : strings.aspectFitLabel
    }

    private func updateEmptyState() {
        let isEmpty = sortedIndices.isEmpty
        emptyStateView.configure(LMKEmptyStateView.Content(message: strings.emptyText, icon: strings.emptyIcon.map { .system($0) }))
        emptyStateView.isHidden = !isEmpty
        toolbarView.isHidden = isEmpty || !(resolvedStyle.showsToolbar ?? true)
        if isViewLoaded {
            view.setNeedsLayout()
        }
    }

    /// The cell's VoiceOver label: its position, and the Live Photo name on a Live Photo cell.
    private func applyAccessibility(to cell: LMKPhotoGridCell, displayIndex: Int) {
        var label = String(format: strings.photoAccessibilityLabelFormat, displayIndex + 1, sortedIndices.count)
        if let dsIndex = dataSourceIndex(forDisplayIndex: displayIndex), dataSource?.photoGridIsLivePhoto(at: dsIndex) == true {
            label += ", " + strings.livePhotoAccessibilityLabel
        }
        cell.accessibilityLabel = label
    }

    // MARK: - Helpers

    var photoCount: Int { dataSource?.numberOfPhotos ?? 0 }

    var maximumColumnCount: Int {
        let cap = resolvedStyle.columnCap
        guard collectionView.bounds.width > 0 else { return cap }
        let maxFromWidth = Int(collectionView.bounds.width / resolvedStyle.minimumCell)
        return min(cap, max(1, maxFromWidth))
    }

    /// Reads every date once, then sorts the cached keys (no data source calls in the comparator).
    private func rebuildSortedIndices() {
        let count = photoCount
        guard count > 0, let dataSource else {
            sortedIndices = []
            return
        }
        let dates = (0 ..< count).map { dataSource.photoGridDate(at: $0) }
        sortedIndices = Self.sortedIndices(dates: dates, order: sortOrder)
    }

    /// Display order for `dates`: dated photos first (newest or oldest first per `order`),
    /// undated photos after them in index order.
    nonisolated static func sortedIndices(dates: [Date?], order: SortOrder) -> [Int] {
        dates.indices.sorted { a, b in
            switch (dates[a], dates[b]) {
            case let (dateA?, dateB?):
                if dateA == dateB { return a < b }
                return order == .descending ? dateA > dateB : dateA < dateB
            case (_?, nil):
                return true
            case (nil, _?):
                return false
            case (nil, nil):
                return a < b
            }
        }
    }

    func dataSourceIndex(forDisplayIndex displayIndex: Int) -> Int? {
        guard displayIndex >= 0, displayIndex < sortedIndices.count else { return nil }
        return sortedIndices[displayIndex]
    }

    private func itemSize(for collectionView: UICollectionView) -> CGSize {
        let spacing = resolvedStyle.cellSpacing
        let totalSpacing = spacing * CGFloat(columnCount - 1)
        let side = floor((collectionView.bounds.width - totalSpacing) / CGFloat(columnCount))
        return CGSize(width: max(1, side), height: max(1, side))
    }

    /// The pixel size cells ask their thumbnails for: the cell side at the display scale. A
    /// grid measured before its first layout asks for the smallest cell the pinch allows, so a
    /// cell that loads early still gets something drawable.
    var thumbnailPixelSize: CGSize {
        let side = max(itemSize(for: collectionView).width, resolvedStyle.minimumCell)
        let scale = LMKScene.displayScale(of: viewIfLoaded) ?? LMKScene.fallbackDisplayScale
        return LMKImage.pixelSize(CGSize(width: side, height: side), scale: scale)
    }

    private func presentPhotoBrowser(startingAt displayIndex: Int) {
        let browser = LMKPhotoBrowserViewController(initialIndex: displayIndex, style: browserStyle ?? LMKPhotoBrowserViewController.Style())
        browser.dataSource = browserBridge
        browser.delegate = browserBridge
        browser.strings = browserStrings
        browser.showsActionButton = browserShowsActionButton
        browser.zoomSourceView = { [weak self] index in
            guard let self, index < sortedIndices.count else { return nil }
            let indexPath = IndexPath(item: index, section: 0)
            if collectionView.cellForItem(at: indexPath) == nil {
                collectionView.scrollToItem(at: indexPath, at: .centeredVertically, animated: false)
                collectionView.layoutIfNeeded()
            }
            return collectionView.cellForItem(at: indexPath)
        }
        self.browser = browser
        present(browser, animated: true)
    }

    /// `image` decoded down to cover `pixelSize` off the main actor, the default thumbnail for a
    /// data source that only vends full-size images. Covering (not fitting) keeps an aspect-fill
    /// cell sharp: a 4:3 photo in a square cell keeps the cell's pixels along its shorter side.
    @concurrent
    nonisolated static func thumbnail(of image: UIImage, pixelSize: CGSize) async -> UIImage? {
        guard pixelSize.width > 0, pixelSize.height > 0, image.size.width > 0, image.size.height > 0 else { return image }
        // The scale of the image is the scale of its pixels, so the target is in its points.
        let scale = max(1, image.scale)
        let target = CGSize(width: pixelSize.width / scale, height: pixelSize.height / scale)
        let ratio = max(target.width / image.size.width, target.height / image.size.height)
        guard ratio < 1 else { return image }
        let covering = CGSize(width: (image.size.width * ratio).rounded(.up), height: (image.size.height * ratio).rounded(.up))
        return await image.byPreparingThumbnail(ofSize: covering) ?? image
    }

    private func toggleSelection(dataSourceIndex: Int, cell: LMKPhotoGridCell?) {
        if selectedIndices.contains(dataSourceIndex) {
            selectedIndices.remove(dataSourceIndex)
        } else {
            selectedIndices.insert(dataSourceIndex)
        }
        cell?.setShowsSelected(selectedIndices.contains(dataSourceIndex))
        if resolvedStyle.playsHaptics {
            LMKHaptics.selection()
        }
        onSelectionChange?(selectedIndices)
    }

    /// Replaces the selection from a gesture: redraws the visible cells and reports the change.
    func applyUserSelection(_ indices: Set<Int>) {
        guard indices != selectedIndices else { return }
        selectedIndices = indices
        for case let cell as LMKPhotoGridCell in collectionView.visibleCells {
            guard let indexPath = collectionView.indexPath(for: cell), let dsIndex = dataSourceIndex(forDisplayIndex: indexPath.item) else { continue }
            if cell.showsSelected != indices.contains(dsIndex) {
                cell.setShowsSelected(indices.contains(dsIndex))
            }
        }
        if resolvedStyle.playsHaptics {
            LMKHaptics.selection()
        }
        onSelectionChange?(selectedIndices)
    }
}

// MARK: - UICollectionViewDataSource

extension LMKPhotoGridViewController: UICollectionViewDataSource {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        sortedIndices.count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: LMKPhotoGridCell.identifier, for: indexPath) as? LMKPhotoGridCell else {
            return UICollectionViewCell()
        }
        cell.apply(style: resolvedStyle, theme: traitCollection.lmkTheme)
        guard let dsIndex = dataSourceIndex(forDisplayIndex: indexPath.item) else { return cell }

        let isLive = dataSource?.photoGridIsLivePhoto(at: dsIndex) ?? false
        // Placeholder first, then the async load of a thumbnail sized for the cell; the cell's
        // generation token discards results that land after reuse.
        cell.configure(with: nil, contentMode: photoContentMode.uiContentMode, isLive: isLive)
        let pixelSize = thumbnailPixelSize
        cell.loadImage { [weak self] in
            await self?.dataSource?.photoGridThumbnail(at: dsIndex, pixelSize: pixelSize)
        }
        cell.setShowsSelected(selectedIndices.contains(dsIndex))
        applyAccessibility(to: cell, displayIndex: indexPath.item)
        return cell
    }
}

// MARK: - UICollectionViewDataSourcePrefetching

extension LMKPhotoGridViewController: UICollectionViewDataSourcePrefetching {
    public func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        let indices = indexPaths.compactMap { dataSourceIndex(forDisplayIndex: $0.item) }
        guard !indices.isEmpty else { return }
        dataSource?.photoGridPrefetch(indices: indices)
    }

    public func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
        let indices = indexPaths.compactMap { dataSourceIndex(forDisplayIndex: $0.item) }
        guard !indices.isEmpty else { return }
        dataSource?.photoGridCancelPrefetch(indices: indices)
    }
}

// MARK: - UICollectionViewDelegate

extension LMKPhotoGridViewController: UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: false)
        if allowsMultipleSelection {
            guard let dsIndex = dataSourceIndex(forDisplayIndex: indexPath.item) else { return }
            toggleSelection(dataSourceIndex: dsIndex, cell: collectionView.cellForItem(at: indexPath) as? LMKPhotoGridCell)
        } else {
            presentPhotoBrowser(startingAt: indexPath.item)
        }
    }

    public func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        // A press that turns into a menu must not also pinch or select.
        guard pinchAnchor == nil, dragSelection == nil else { return nil }
        guard let contextMenuProvider, let dsIndex = dataSourceIndex(forDisplayIndex: indexPath.item),
              let menu = contextMenuProvider(dsIndex) else { return nil }
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in menu }
    }

    public func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        (collectionView.cellForItem(at: indexPath) as? LMKPhotoGridCell)?.setPressed(true, animated: true)
    }

    public func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        (collectionView.cellForItem(at: indexPath) as? LMKPhotoGridCell)?.setPressed(false, animated: true)
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension LMKPhotoGridViewController: UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        itemSize(for: collectionView)
    }
}

// MARK: - Browser bridge

/// The grid's browser data source and delegate: the browser pages in display order, and every
/// index crosses here to the data source's. Internal, so the grid's own public members all
/// speak data source indices.
final class LMKPhotoGridBrowserBridge: LMKPhotoBrowserDataSource, LMKPhotoBrowserDelegate {
    private weak var grid: LMKPhotoGridViewController?

    init(grid: LMKPhotoGridViewController) {
        self.grid = grid
    }

    var numberOfPhotos: Int {
        grid?.sortedIndices.count ?? 0
    }

    func photo(at index: Int) async -> UIImage? {
        guard let grid, let dsIndex = grid.dataSourceIndex(forDisplayIndex: index) else { return nil }
        return await grid.dataSource?.photoGridImage(at: dsIndex)
    }

    func photoDate(at index: Int) -> Date? {
        guard let grid, let dsIndex = grid.dataSourceIndex(forDisplayIndex: index) else { return nil }
        return grid.dataSource?.photoGridDate(at: dsIndex)
    }

    func photoSubtitle(at _: Int) -> String? {
        nil
    }

    func photoIsLivePhoto(at index: Int) -> Bool {
        guard let grid, let dsIndex = grid.dataSourceIndex(forDisplayIndex: index) else { return false }
        return grid.dataSource?.photoGridIsLivePhoto(at: dsIndex) ?? false
    }

    func photoLivePhoto(at index: Int) async -> PHLivePhoto? {
        guard let grid, let dsIndex = grid.dataSourceIndex(forDisplayIndex: index) else { return nil }
        return await grid.dataSource?.photoGridLivePhoto(at: dsIndex)
    }

    func photoBrowser(_: LMKPhotoBrowserViewController, didRequestActionAt index: Int) {
        guard let grid, let dsIndex = grid.dataSourceIndex(forDisplayIndex: index) else { return }
        grid.delegate?.photoGrid(grid, didRequestActionForPhotoAt: dsIndex)
    }

    func photoBrowserDidDismiss(_: LMKPhotoBrowserViewController) {
        // The browser dismisses itself.
    }
}
