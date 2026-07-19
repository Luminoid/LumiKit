//
//  LMKPhotoGridViewController.swift
//  LumiKit
//
//  Photo grid view controller with square cells, pinch-to-zoom column control,
//  sort by date, content mode toggle, and photo browser integration.
//

import LumiKitCore
import PhotosUI
import SnapKit
import UIKit

// MARK: - Enums

/// Content mode for photo grid cells.
public nonisolated enum LMKPhotoGridContentMode: Sendable {
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

/// Sort order for photo grid by date.
public nonisolated enum LMKPhotoGridSortOrder: Sendable {
    case ascending
    case descending

    var systemImageName: String {
        switch self {
        case .ascending: "arrow.up.circle"
        case .descending: "arrow.down.circle"
        }
    }
}

// MARK: - Protocols

/// Data source for the photo grid. Provides images and dates.
public protocol LMKPhotoGridDataSource: AnyObject {
    /// Total number of photos.
    var numberOfPhotos: Int { get }
    /// Image for the photo at the given data source index.
    func photoGridImage(at index: Int) -> UIImage?
    /// Date for the photo at the given data source index. Used for sorting.
    func photoGridDate(at index: Int) -> Date?
    /// Whether the item at the given index is a Live Photo. Drives the LIVE
    /// badge overlay on the grid cell. Default implementation returns `false`.
    func photoGridIsLivePhoto(at index: Int) -> Bool
    /// Async fetch of the paired `PHLivePhoto` at the given index. Returns nil
    /// for stills or when the paired video can't be loaded. Default impl
    /// returns nil so that non-live data sources don't need to implement it.
    func photoGridLivePhoto(at index: Int) async -> PHLivePhoto?
}

public extension LMKPhotoGridDataSource {
    func photoGridIsLivePhoto(at _: Int) -> Bool {
        false
    }

    func photoGridLivePhoto(at _: Int) async -> PHLivePhoto? {
        nil
    }
}

/// Delegate for photo grid actions.
public protocol LMKPhotoGridDelegate: AnyObject {
    /// Called when the photo browser's action button is tapped.
    /// The index is the data source index (not the sorted display index).
    func photoGrid(_ grid: LMKPhotoGridViewController, didRequestActionForPhotoAt index: Int)
}

// MARK: - Configurable Strings

/// Configurable strings for the photo grid, allowing localization.
public nonisolated struct LMKPhotoGridStrings: Sendable {
    public var emptyText: String
    public var emptyIcon: String?
    public var sortAscendingLabel: String
    public var sortDescendingLabel: String
    public var aspectFitLabel: String
    public var aspectFillLabel: String

    public init(
        emptyText: String = "No Photos",
        emptyIcon: String? = "photo.on.rectangle.angled",
        sortAscendingLabel: String = "Oldest First",
        sortDescendingLabel: String = "Newest First",
        aspectFitLabel: String = "Fit",
        aspectFillLabel: String = "Fill"
    ) {
        self.emptyText = emptyText
        self.emptyIcon = emptyIcon
        self.sortAscendingLabel = sortAscendingLabel
        self.sortDescendingLabel = sortDescendingLabel
        self.aspectFitLabel = aspectFitLabel
        self.aspectFillLabel = aspectFillLabel
    }
}

// MARK: - LMKPhotoGridViewController

public final class LMKPhotoGridViewController: UIViewController {
    // MARK: - Properties

    public weak var dataSource: (any LMKPhotoGridDataSource)?
    public weak var delegate: (any LMKPhotoGridDelegate)?
    public var strings = LMKPhotoGridStrings()
    /// Strings forwarded to the photo browser when presented.
    public var photoBrowserStrings = LMKPhotoBrowserStrings()
    /// Forwarded to the photo browser's `showsActionButton` when presented.
    /// Hosts whose current user has no actions to offer set this to `false`.
    public var browserShowsActionButton = true

    public private(set) var columnCount: Int = 2
    public private(set) var photoContentMode: LMKPhotoGridContentMode = .aspectFill
    public private(set) var sortOrder: LMKPhotoGridSortOrder = .descending

    /// Maps display position to data source index, accounting for sort order.
    private var sortedIndices: [Int] = []
    private var lastLayoutWidth: CGFloat = 0

    // MARK: - Constants

    private static let gridSpacing: CGFloat = 2
    private static let minColumnCount = 1
    private static let maxColumnCountCap = 10
    private static let minCellSize: CGFloat = 36
    /// Pinch scale threshold before triggering a column count change.
    private static let pinchThreshold: CGFloat = 0.3
    private static let toolbarPadding: CGFloat = 10
    private static let toolbarBottomMargin: CGFloat = 12

    // MARK: - UI

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = Self.gridSpacing
        layout.minimumLineSpacing = Self.gridSpacing
        layout.sectionInset = .zero

        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.delegate = self
        cv.dataSource = self
        cv.backgroundColor = LMKColor.backgroundPrimary
        cv.showsVerticalScrollIndicator = true
        cv.alwaysBounceVertical = true
        cv.keyboardDismissMode = .onDrag
        cv.register(LMKPhotoGridCell.self, forCellWithReuseIdentifier: LMKPhotoGridCell.identifier)
        return cv
    }()

    private lazy var emptyStateView: LMKEmptyStateView = {
        let view = LMKEmptyStateView()
        view.configure(
            message: strings.emptyText,
            icon: strings.emptyIcon,
            style: .fullScreen
        )
        view.isHidden = true
        return view
    }()

    private lazy var toolbar: UIVisualEffectView = {
        let blur = UIVisualEffectView(effect: UIBlurEffect(style: .systemChromeMaterial))
        blur.layer.cornerRadius = LMKCornerRadius.large
        blur.clipsToBounds = true
        return blur
    }()

    private lazy var sortButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: sortOrder.systemImageName)
        config.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(
            pointSize: 14, weight: .medium
        )
        let button = UIButton(configuration: config, primaryAction: UIAction { [weak self] _ in
            self?.toggleSortOrder()
        })
        button.tintColor = LMKColor.textPrimary
        button.accessibilityLabel = sortOrder == .descending
            ? strings.sortDescendingLabel
            : strings.sortAscendingLabel
        return button
    }()

    private lazy var contentModeButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: photoContentMode.systemImageName)
        config.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(
            pointSize: 14, weight: .medium
        )
        let button = UIButton(configuration: config, primaryAction: UIAction { [weak self] _ in
            self?.toggleContentMode()
        })
        button.tintColor = LMKColor.textPrimary
        button.accessibilityLabel = photoContentMode == .aspectFill
            ? strings.aspectFillLabel
            : strings.aspectFitLabel
        return button
    }()

    private lazy var pinchGesture: UIPinchGestureRecognizer = .init(target: self, action: #selector(handlePinch(_:)))

    // MARK: - Initialization

    public init(columnCount: Int = 2) {
        self.columnCount = max(Self.minColumnCount, columnCount)
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
    }

    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let currentWidth = view.bounds.width
        if currentWidth != lastLayoutWidth, currentWidth > 0 {
            lastLayoutWidth = currentWidth
            collectionView.collectionViewLayout.invalidateLayout()
        }
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = LMKColor.backgroundPrimary

        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        view.addSubview(emptyStateView)
        emptyStateView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.trailing.equalTo(view.safeAreaLayoutGuide).inset(LMKSpacing.large)
        }

        // Toolbar
        view.addSubview(toolbar)
        let stack = UIStackView(arrangedSubviews: [sortButton, contentModeButton])
        stack.axis = .horizontal
        stack.spacing = LMKSpacing.medium
        toolbar.contentView.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(
                top: LMKSpacing.xs,
                left: Self.toolbarPadding,
                bottom: LMKSpacing.xs,
                right: Self.toolbarPadding
            ))
        }
        toolbar.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-Self.toolbarBottomMargin)
        }

        // Pinch gesture for column count
        collectionView.addGestureRecognizer(pinchGesture)

        // Initial data
        rebuildSortedIndices()
        updateEmptyState()
    }

    // MARK: - Actions

    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        guard gesture.state == .changed else { return }

        if gesture.scale > 1.0 + Self.pinchThreshold {
            // Pinch out → zoom in → fewer columns (larger cells)
            let newCount = max(Self.minColumnCount, columnCount - 1)
            if newCount != columnCount {
                setColumnCount(newCount, animated: true)
            }
            gesture.scale = 1.0
        } else if gesture.scale < 1.0 - Self.pinchThreshold {
            // Pinch in → zoom out → more columns (smaller cells)
            let maxCols = maxColumnCount
            let newCount = min(maxCols, columnCount + 1)
            if newCount != columnCount {
                setColumnCount(newCount, animated: true)
            }
            gesture.scale = 1.0
        }
    }

    /// Toggles between ascending and descending sort order.
    public func toggleSortOrder() {
        let newOrder: LMKPhotoGridSortOrder = sortOrder == .descending ? .ascending : .descending
        setSortOrder(newOrder)
    }

    /// Toggles between aspect fit and aspect fill content mode.
    public func toggleContentMode() {
        let newMode: LMKPhotoGridContentMode = photoContentMode == .aspectFill ? .aspectFit : .aspectFill
        setContentMode(newMode)
    }

    // MARK: - Public API

    /// Sets the column count with optional animation.
    public func setColumnCount(_ count: Int, animated: Bool) {
        let maxCols = maxColumnCount
        let clamped = max(Self.minColumnCount, min(maxCols, count))
        guard clamped != columnCount else { return }
        columnCount = clamped

        if animated, LMKAnimationHelper.shouldAnimate {
            collectionView.performBatchUpdates {
                self.collectionView.collectionViewLayout.invalidateLayout()
            }
        } else {
            collectionView.collectionViewLayout.invalidateLayout()
        }

        LMKHapticFeedbackHelper.light()
    }

    /// Sets the content mode for all grid cells.
    public func setContentMode(_ mode: LMKPhotoGridContentMode) {
        guard mode != photoContentMode else { return }
        photoContentMode = mode
        updateContentModeButton()

        // Update visible cells. `configure(with: nil, ...)` clears the image so
        // the reload picks up the new content mode cleanly; `isLive` must come
        // from the data source so the LIVE badge doesn't flicker off on cells
        // backing Live Photos.
        for cell in collectionView.visibleCells {
            guard let gridCell = cell as? LMKPhotoGridCell,
                  let indexPath = collectionView.indexPath(for: gridCell)
            else { continue }
            let isLive = dataSourceIndex(forDisplayIndex: indexPath.item)
                .flatMap { dataSource?.photoGridIsLivePhoto(at: $0) } ?? false
            gridCell.configure(
                with: nil,
                contentMode: mode.uiContentMode,
                isLive: isLive
            )
        }
        // Reload to update all cells including off-screen
        collectionView.reloadData()
        LMKHapticFeedbackHelper.light()
    }

    /// Sets the sort order and re-sorts the grid.
    public func setSortOrder(_ order: LMKPhotoGridSortOrder) {
        guard order != sortOrder else { return }
        sortOrder = order
        updateSortButton()
        rebuildSortedIndices()

        if LMKAnimationHelper.shouldAnimate {
            UIView.transition(
                with: collectionView,
                duration: LMKAnimationHelper.Duration.actionSheet,
                options: .transitionCrossDissolve
            ) {
                self.collectionView.reloadData()
            }
        } else {
            collectionView.reloadData()
        }

        LMKHapticFeedbackHelper.light()
    }

    /// Reloads the grid data from the data source.
    public func reloadData() {
        rebuildSortedIndices()
        collectionView.reloadData()
        updateEmptyState()
    }

    // MARK: - UI Updates

    private func updateSortButton() {
        sortButton.setImage(
            UIImage(systemName: sortOrder.systemImageName),
            for: .normal
        )
        sortButton.accessibilityLabel = sortOrder == .descending
            ? strings.sortDescendingLabel
            : strings.sortAscendingLabel
    }

    private func updateContentModeButton() {
        contentModeButton.setImage(
            UIImage(systemName: photoContentMode.systemImageName),
            for: .normal
        )
        contentModeButton.accessibilityLabel = photoContentMode == .aspectFill
            ? strings.aspectFillLabel
            : strings.aspectFitLabel
    }

    private func updateEmptyState() {
        let isEmpty = sortedIndices.isEmpty
        emptyStateView.configure(
            message: strings.emptyText,
            icon: strings.emptyIcon,
            style: .fullScreen
        )
        emptyStateView.isHidden = !isEmpty
        toolbar.isHidden = isEmpty
    }

    // MARK: - Helpers

    private var maxColumnCount: Int {
        guard collectionView.bounds.width > 0 else { return Self.maxColumnCountCap }
        let maxFromWidth = Int(collectionView.bounds.width / Self.minCellSize)
        return min(Self.maxColumnCountCap, max(1, maxFromWidth))
    }

    private func rebuildSortedIndices() {
        let count = dataSource?.numberOfPhotos ?? 0
        guard count > 0 else {
            sortedIndices = []
            return
        }

        sortedIndices = Array(0 ..< count).sorted { a, b in
            let dateA = dataSource?.photoGridDate(at: a)
            let dateB = dataSource?.photoGridDate(at: b)

            switch (dateA, dateB) {
            case let (dA?, dB?):
                return sortOrder == .descending ? dA > dB : dA < dB
            case (_?, nil):
                return true
            case (nil, _?):
                return false
            case (nil, nil):
                return a < b
            }
        }
    }

    private func dataSourceIndex(forDisplayIndex displayIndex: Int) -> Int? {
        guard displayIndex >= 0, displayIndex < sortedIndices.count else { return nil }
        return sortedIndices[displayIndex]
    }

    private func itemSize(for collectionView: UICollectionView) -> CGSize {
        let totalSpacing = Self.gridSpacing * CGFloat(columnCount - 1)
        let availableWidth = collectionView.bounds.width - totalSpacing
        let itemWidth = floor(availableWidth / CGFloat(columnCount))
        return CGSize(width: itemWidth, height: itemWidth)
    }

    private func presentPhotoBrowser(startingAt displayIndex: Int) {
        let browser = LMKPhotoBrowserViewController(initialIndex: displayIndex)
        browser.dataSource = self
        browser.delegate = self
        browser.strings = photoBrowserStrings
        browser.showsActionButton = browserShowsActionButton
        browser.modalPresentationStyle = .fullScreen
        present(browser, animated: true)
    }
}

// MARK: - UICollectionViewDataSource

extension LMKPhotoGridViewController: UICollectionViewDataSource {
    public func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        sortedIndices.count
    }

    public func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: LMKPhotoGridCell.identifier,
            for: indexPath
        ) as? LMKPhotoGridCell else {
            return UICollectionViewCell()
        }

        guard let dsIndex = dataSourceIndex(forDisplayIndex: indexPath.item) else {
            return cell
        }

        let image = dataSource?.photoGridImage(at: dsIndex)
        let isLive = dataSource?.photoGridIsLivePhoto(at: dsIndex) ?? false
        cell.configure(with: image, contentMode: photoContentMode.uiContentMode, isLive: isLive)
        return cell
    }
}

// MARK: - UICollectionViewDelegate

extension LMKPhotoGridViewController: UICollectionViewDelegate {
    public func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        presentPhotoBrowser(startingAt: indexPath.item)
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension LMKPhotoGridViewController: UICollectionViewDelegateFlowLayout {
    public func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        itemSize(for: collectionView)
    }
}

// MARK: - LMKPhotoBrowserDataSource

extension LMKPhotoGridViewController: LMKPhotoBrowserDataSource {
    public var numberOfPhotos: Int {
        sortedIndices.count
    }

    public func photo(at index: Int) -> UIImage? {
        guard let dsIndex = dataSourceIndex(forDisplayIndex: index) else { return nil }
        return dataSource?.photoGridImage(at: dsIndex)
    }

    public func photoDate(at index: Int) -> Date? {
        guard let dsIndex = dataSourceIndex(forDisplayIndex: index) else { return nil }
        return dataSource?.photoGridDate(at: dsIndex)
    }

    public func photoSubtitle(at index: Int) -> String? {
        nil
    }

    public func photoIsLivePhoto(at index: Int) -> Bool {
        guard let dsIndex = dataSourceIndex(forDisplayIndex: index) else { return false }
        return dataSource?.photoGridIsLivePhoto(at: dsIndex) ?? false
    }

    public func photoLivePhoto(at index: Int) async -> PHLivePhoto? {
        guard let dsIndex = dataSourceIndex(forDisplayIndex: index) else { return nil }
        return await dataSource?.photoGridLivePhoto(at: dsIndex)
    }
}

// MARK: - LMKPhotoBrowserDelegate

extension LMKPhotoGridViewController: LMKPhotoBrowserDelegate {
    public func photoBrowser(
        _ browser: LMKPhotoBrowserViewController,
        didRequestActionAt index: Int
    ) {
        guard let dsIndex = dataSourceIndex(forDisplayIndex: index) else { return }
        delegate?.photoGrid(self, didRequestActionForPhotoAt: dsIndex)
    }

    public func photoBrowserDidDismiss(_ browser: LMKPhotoBrowserViewController) {
        // No-op — browser dismisses itself
    }
}
