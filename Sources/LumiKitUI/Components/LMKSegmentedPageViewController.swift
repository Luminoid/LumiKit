//
//  LMKSegmentedPageViewController.swift
//  LumiKit
//
//  Container that pages between child view controllers selected by a top
//  LMKSegmentedControl, with an interactive pan that drags the pages with the
//  finger. Styled from `theme.segmentedPage`; the pan delegate is private.
//

import UIKit

/// Container view controller that hosts child view controllers selected by a top
/// ``LMKSegmentedControl``, with an interactive pan that drags the pages with the finger.
///
/// Pages can take a full-width pan (vertical scrollers) or an edge-only pan (a narrow
/// band at each horizontal edge) so a page that owns horizontal drags (a map, a month
/// grid) keeps its interior. Tapping a segment, or calling ``setPage(_:animated:)``,
/// slides without the drag. Directions follow the layout direction, so a forward
/// page comes from the trailing edge in RTL too.
///
/// Subclasses provide the pages via ``makePages()`` (or call ``setPages(_:titles:)``
/// later), the per-page pan mode via ``usesFullWidthSwipe(forPageAt:)``, and react to
/// page changes via ``didChangePage(to:)``. ``segmentedControlPlacement`` puts the
/// control in the navigation title (default), in a container view of the host's
/// chrome, or leaves it to the host.
///
/// ```swift
/// final class MyContainerViewController: LMKSegmentedPageViewController {
///     init() { super.init(titles: ["List", "Map"]) }
///
///     override func makePages() -> [UIViewController] { [listViewController, mapViewController] }
///
///     /// The map page owns interior pan/zoom, so its tab-swipe is edge-only.
///     override func usesFullWidthSwipe(forPageAt index: Int) -> Bool { index != 1 }
/// }
/// ```
///
/// Inside an `LMKNavigationController`, the interactive pop gesture stays enabled on
/// the first page and yields to the page pan on later pages.
open class LMKSegmentedPageViewController: UIViewController, LMKThemeApplying, LMKPopGestureConfiguring {
    // MARK: - Vocabulary

    /// Where the segmented control goes.
    public enum SegmentedControlPlacement {
        /// The navigation item's title view.
        case navigationTitle
        /// Pinned to the edges of a host-provided view (a slot under a custom navigation bar).
        case container(UIView)
        /// The host places `segmentedControl` itself.
        case manual
    }

    // MARK: - Style

    public nonisolated struct Style: Sendable, Equatable, LMKThemeExtension {
        /// Layered on the segmented control (`itemPadding` = `xl` by default).
        public var segmentedControl: LMKSegmentedControl.Style
        /// `nil` = `backgroundPrimary`.
        public var backgroundColor: UIColor?
        /// Touch band (pt) at each horizontal edge that begins the pan on edge-only pages; `nil` = 24.
        public var edgePanBandWidth: CGFloat?
        /// Horizontal velocity (pt/s) past which a flick commits a page change; `nil` = 800.
        public var commitVelocityThreshold: CGFloat?
        /// `nil` = `animation.slow`.
        public var pageTransitionDuration: TimeInterval?

        public init(
            segmentedControl: LMKSegmentedControl.Style = LMKSegmentedControl.Style(),
            backgroundColor: UIColor? = nil,
            edgePanBandWidth: CGFloat? = nil,
            commitVelocityThreshold: CGFloat? = nil,
            pageTransitionDuration: TimeInterval? = nil
        ) {
            self.segmentedControl = segmentedControl
            self.backgroundColor = backgroundColor
            self.edgePanBandWidth = edgePanBandWidth
            self.commitVelocityThreshold = commitVelocityThreshold
            self.pageTransitionDuration = pageTransitionDuration
        }

        public static let defaultValue = Self()

        /// `other`'s non-nil fields over this style's.
        public func merging(_ other: Self) -> Self {
            Self(
                segmentedControl: segmentedControl.merging(other.segmentedControl),
                backgroundColor: other.backgroundColor ?? backgroundColor,
                edgePanBandWidth: other.edgePanBandWidth ?? edgePanBandWidth,
                commitVelocityThreshold: other.commitVelocityThreshold ?? commitVelocityThreshold,
                pageTransitionDuration: other.pageTransitionDuration ?? pageTransitionDuration
            )
        }
    }

    // MARK: - Properties

    /// The segmented control driving page selection.
    public let segmentedControl: LMKSegmentedControl

    /// Where the control is installed. Default `.navigationTitle`.
    public var segmentedControlPlacement: SegmentedControlPlacement = .navigationTitle {
        didSet {
            guard isViewLoaded else { return }
            installSegmentedControl()
        }
    }

    /// Index of the visible page.
    public private(set) var currentPageIndex = 0

    /// The visible page.
    public var currentViewController: UIViewController? { currentChild }

    /// The pages, in segment order.
    public private(set) var pages: [UIViewController] = []

    /// Per-instance style; `nil` fields resolve from `theme.segmentedPage`, then the built-in look.
    public var style: Style {
        didSet {
            guard style != oldValue, isViewLoaded else { return }
            applyTheme(traitCollection.lmkTheme)
        }
    }

    /// Called at the end of every `applyTheme`, for tweaks the style does not cover.
    public var didApplyStyle: ((LMKSegmentedPageViewController) -> Void)?

    /// The style last resolved against the theme.
    public private(set) var resolvedStyle = Style()

    /// The resolved edge band width (also the reserved band a month calendar keeps clear).
    public var edgePanBandWidth: CGFloat { resolvedStyle.edgePanBandWidth ?? Self.defaultEdgePanBandWidth }

    /// The resolved flick velocity.
    public var commitVelocityThreshold: CGFloat { resolvedStyle.commitVelocityThreshold ?? Self.defaultCommitVelocityThreshold }

    /// The pop gesture stays with the first page; later pages own the leading-edge drag.
    public var prefersPopGestureDisabled: Bool { currentPageIndex > 0 }

    /// The view that hosts the pages. Defaults to the controller's own `view`. Override to
    /// return a container pinned below custom chrome; build and constrain it before calling
    /// `super.viewDidLoad()`. A zero-size container at that point is fine: page frames are
    /// re-applied in `viewDidLayoutSubviews` once layout resolves.
    open var pageContainerView: UIView { view }

    private var currentChild: UIViewController?
    private var isAnimatingPageChange = false
    private var isInteractiveDragActive = false
    private var interactiveDirection = 0
    private var interactiveNeighborIndex: Int?
    private var interactiveNeighborVC: UIViewController?
    private lazy var panDelegate = LMKSegmentedPagePanDelegate(owner: self)
    private lazy var pagePanGesture: UIPanGestureRecognizer = {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePagePan(_:)))
        pan.delegate = panDelegate
        return pan
    }()

    static let defaultEdgePanBandWidth: CGFloat = 24
    static let defaultCommitVelocityThreshold: CGFloat = 800
    private static let rubberBandFactor: CGFloat = 0.3

    private var isRightToLeft: Bool {
        view.effectiveUserInterfaceLayoutDirection == .rightToLeft
    }

    // MARK: - Initialization

    /// A container with one segment title per page, in segment order.
    public init(titles: [String], style: Style = Style()) {
        self.style = style
        segmentedControl = LMKSegmentedControl(items: titles)
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Overridable hooks

    /// The child view controllers, in segment order. Called once during `viewDidLoad`.
    open func makePages() -> [UIViewController] {
        []
    }

    /// Whether the page accepts a full-width pan (`true`, the default) or only an edge pan.
    open func usesFullWidthSwipe(forPageAt _: Int) -> Bool {
        true
    }

    /// Called after the visible page changes (not for the initial page).
    open func didChangePage(to _: Int) {}

    // MARK: - Lifecycle

    override open func viewDidLoad() {
        super.viewDidLoad()
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.onValueChange = { [weak self] index in
            self?.setPage(index, animated: true)
        }
        installSegmentedControl()
        view.addGestureRecognizer(pagePanGesture)
        lmk_startApplyingTheme()
        setPages(makePages())
    }

    override open var childForStatusBarStyle: UIViewController? {
        currentChild
    }

    /// Re-seats the visible page on the container's resolved bounds (a constraint-laid-out
    /// container has zero bounds during `viewDidLoad`). Skipped mid-drag and mid-animation.
    override open func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard !isInteractiveDragActive, !isAnimatingPageChange else { return }
        currentChild?.view.frame = pageContainerView.bounds
    }

    // MARK: - Theme

    open func applyTheme(_ theme: LMKTheme) {
        resolvedStyle = theme.segmentedPage.merging(style)
        view.backgroundColor = resolvedStyle.backgroundColor ?? LMKColor.backgroundPrimary
        segmentedControl.style = LMKSegmentedControl.Style(itemPadding: theme.spacing.xl).merging(resolvedStyle.segmentedControl)
        didApplyStyle?(self)
    }

    // MARK: - Placement

    private func installSegmentedControl() {
        segmentedControl.removeFromSuperview()
        if navigationItem.titleView === segmentedControl {
            navigationItem.titleView = nil
        }
        switch segmentedControlPlacement {
        case .navigationTitle:
            navigationItem.titleView = segmentedControl
        case let .container(container):
            container.addSubview(segmentedControl)
            segmentedControl.snp.makeConstraints { $0.edges.equalToSuperview() }
        case .manual:
            break
        }
    }

    // MARK: - Pages

    /// Replaces the pages (and, when given, the segment titles). The current index is kept
    /// when still in range, else the first page shows.
    public func setPages(_ pages: [UIViewController], titles: [String]? = nil) {
        guard !isInteractiveDragActive, !isAnimatingPageChange else { return }
        if let titles {
            segmentedControl.setItems(titles)
        }
        let previous = currentChild
        previous?.willMove(toParent: nil)
        previous?.view.removeFromSuperview()
        previous?.removeFromParent()
        self.pages = pages
        currentChild = nil
        let index = pages.indices.contains(currentPageIndex) ? currentPageIndex : 0
        currentPageIndex = 0
        guard !pages.isEmpty else {
            segmentedControl.selectedSegmentIndex = -1
            return
        }
        install(pages[index])
        currentPageIndex = index
        segmentedControl.selectedSegmentIndex = index
    }

    /// Moves to `index`, sliding when `animated`. Keeps the segmented control in sync without
    /// re-entering its handler. Safe to call programmatically (deep links).
    open func setPage(_ index: Int, animated: Bool) {
        guard pages.indices.contains(index), index != currentPageIndex, !isAnimatingPageChange, !isInteractiveDragActive else { return }
        let direction = index > currentPageIndex ? 1 : -1
        transition(to: index, direction: direction, animated: animated)
        segmentedControl.setSelectedSegmentIndex(index, animated: true)
    }

    private func install(_ page: UIViewController) {
        addChild(page)
        page.view.frame = initialPageFrame()
        page.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        pageContainerView.addSubview(page.view)
        page.didMove(toParent: self)
        currentChild = page
    }

    private func transition(to index: Int, direction: Int, animated: Bool) {
        let container = pageContainerView
        let newVC = pages[index]
        let oldVC = currentChild
        addChild(newVC)
        newVC.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        let width = container.bounds.width
        let slide = visual(CGFloat(direction) * width)

        if animated, LMKAnimation.shouldAnimate, let oldVC, view.window != nil {
            isAnimatingPageChange = true
            newVC.view.frame = container.bounds.offsetBy(dx: slide, dy: 0)
            container.addSubview(newVC.view)
            let duration = resolvedStyle.pageTransitionDuration ?? LMKAnimation.Duration.slow
            let animator = UIViewPropertyAnimator(duration: duration, curve: .easeInOut) {
                newVC.view.frame = container.bounds
                oldVC.view.frame = container.bounds.offsetBy(dx: -slide, dy: 0)
            }
            let once = LMKOnceCompletion(after: duration) { [weak self] in
                oldVC.willMove(toParent: nil)
                oldVC.view.removeFromSuperview()
                oldVC.removeFromParent()
                newVC.didMove(toParent: self)
                self?.isAnimatingPageChange = false
            }
            animator.addCompletion { _ in once.fire() }
            animator.startAnimation()
        } else {
            oldVC?.willMove(toParent: nil)
            oldVC?.view.removeFromSuperview()
            oldVC?.removeFromParent()
            newVC.view.frame = container.bounds
            container.addSubview(newVC.view)
            newVC.didMove(toParent: self)
        }

        currentChild = newVC
        currentPageIndex = index
        setNeedsStatusBarAppearanceUpdate()
        didChangePage(to: index)
    }

    /// The frame to install a page with: the container's bounds, or the controller's own size
    /// while a constraint-laid-out container is still zero (a page laid out once at zero width
    /// trips UIKit's unsatisfiable-constraint dump for any inset it carries).
    private func initialPageFrame() -> CGRect {
        let containerBounds = pageContainerView.bounds
        guard containerBounds.isEmpty else { return containerBounds }
        return CGRect(origin: .zero, size: view.bounds.size)
    }

    /// A logical (leading-to-trailing) horizontal distance as a visual x offset.
    private func visual(_ logical: CGFloat) -> CGFloat {
        isRightToLeft ? -logical : logical
    }

    // MARK: - Interactive paging

    @objc private func handlePagePan(_ gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .changed:
            handlePagePanChanged(gesture)
        case .ended, .cancelled, .failed:
            handlePagePanEnded(gesture)
        default:
            break
        }
    }

    /// The pan's translation along the leading-to-trailing axis (negative = toward the leading edge).
    private func logicalTranslation(of gesture: UIPanGestureRecognizer) -> CGFloat {
        visual(gesture.translation(in: view).x)
    }

    private func handlePagePanChanged(_ gesture: UIPanGestureRecognizer) {
        guard let currentChild, !isAnimatingPageChange else { return }
        let container = pageContainerView
        let translation = logicalTranslation(of: gesture)
        let width = container.bounds.width

        if !isInteractiveDragActive {
            guard abs(translation) > 2 else { return }
            beginInteractiveDrag(translation: translation, width: width)
        }

        let offset = interactiveOffset(for: translation, width: width)
        currentChild.view.frame = container.bounds.offsetBy(dx: visual(offset), dy: 0)
        interactiveNeighborVC?.view.frame = container.bounds.offsetBy(dx: visual(offset + CGFloat(interactiveDirection) * width), dy: 0)
    }

    /// Locks the drag direction on first movement and attaches the neighbor page offscreen on
    /// the side it slides in from. No neighbor at the first or last page.
    private func beginInteractiveDrag(translation: CGFloat, width: CGFloat) {
        isInteractiveDragActive = true
        interactiveDirection = translation < 0 ? 1 : -1
        let neighborIndex = currentPageIndex + interactiveDirection
        guard pages.indices.contains(neighborIndex) else {
            interactiveNeighborIndex = nil
            interactiveNeighborVC = nil
            return
        }
        let neighbor = pages[neighborIndex]
        addChild(neighbor)
        neighbor.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        neighbor.view.frame = pageContainerView.bounds.offsetBy(dx: visual(CGFloat(interactiveDirection) * width), dy: 0)
        pageContainerView.addSubview(neighbor.view)
        interactiveNeighborIndex = neighborIndex
        interactiveNeighborVC = neighbor
    }

    /// Tracks the finger toward the locked neighbor; resists the wrong way and at the ends.
    private func interactiveOffset(for translation: CGFloat, width: CGFloat) -> CGFloat {
        guard interactiveNeighborVC != nil else {
            return translation * Self.rubberBandFactor
        }
        if interactiveDirection > 0 {
            return max(min(translation, 0), -width)
        }
        return min(max(translation, 0), width)
    }

    private func handlePagePanEnded(_ gesture: UIPanGestureRecognizer) {
        guard isInteractiveDragActive else { return }
        let width = pageContainerView.bounds.width
        let translation = logicalTranslation(of: gesture)
        let velocity = visual(gesture.velocity(in: view).x)

        let movedEnough = abs(translation) > width * 0.5
        let flicked = abs(velocity) > commitVelocityThreshold && (velocity < 0) == (interactiveDirection > 0)
        let shouldCommit = interactiveNeighborVC != nil && gesture.state == .ended && (movedEnough || flicked)
        if shouldCommit {
            commitInteractiveDrag(width: width)
        } else {
            revertInteractiveDrag(width: width)
        }
    }

    private func commitInteractiveDrag(width: CGFloat) {
        guard let neighbor = interactiveNeighborVC, let neighborIndex = interactiveNeighborIndex else {
            revertInteractiveDrag(width: width)
            return
        }
        let outgoing = currentChild
        let direction = interactiveDirection
        let container = pageContainerView
        isAnimatingPageChange = true
        animateSettle {
            outgoing?.view.frame = container.bounds.offsetBy(dx: self.visual(CGFloat(-direction) * width), dy: 0)
            neighbor.view.frame = container.bounds
        } completion: { [weak self] in
            guard let self else { return }
            outgoing?.willMove(toParent: nil)
            outgoing?.view.removeFromSuperview()
            outgoing?.removeFromParent()
            neighbor.didMove(toParent: self)
            currentChild = neighbor
            currentPageIndex = neighborIndex
            segmentedControl.setSelectedSegmentIndex(neighborIndex, animated: true)
            clearInteractiveState()
            isAnimatingPageChange = false
            setNeedsStatusBarAppearanceUpdate()
            didChangePage(to: neighborIndex)
        }
    }

    private func revertInteractiveDrag(width: CGFloat) {
        let neighbor = interactiveNeighborVC
        let direction = interactiveDirection
        let container = pageContainerView
        isAnimatingPageChange = true
        animateSettle {
            self.currentChild?.view.frame = container.bounds
            neighbor?.view.frame = container.bounds.offsetBy(dx: self.visual(CGFloat(direction) * width), dy: 0)
        } completion: { [weak self] in
            neighbor?.willMove(toParent: nil)
            neighbor?.view.removeFromSuperview()
            neighbor?.removeFromParent()
            self?.clearInteractiveState()
            self?.isAnimatingPageChange = false
        }
    }

    private func animateSettle(_ animations: @escaping () -> Void, completion: @escaping () -> Void) {
        let duration = resolvedStyle.pageTransitionDuration ?? LMKAnimation.Duration.slow
        guard LMKAnimation.shouldAnimate, view.window != nil else {
            animations()
            completion()
            return
        }
        let animator = UIViewPropertyAnimator(duration: duration, curve: .easeOut, animations: animations)
        let once = LMKOnceCompletion(after: duration, completion)
        animator.addCompletion { _ in once.fire() }
        animator.startAnimation()
    }

    private func clearInteractiveState() {
        isInteractiveDragActive = false
        interactiveDirection = 0
        interactiveNeighborIndex = nil
        interactiveNeighborVC = nil
    }

    // MARK: - Pan policy

    /// Whether the page pan may begin for a touch at `startX` (in the controller's view).
    func shouldBeginPagePan(startX: CGFloat) -> Bool {
        guard !isAnimatingPageChange, !pages.isEmpty else { return false }
        let velocity = pagePanGesture.velocity(in: view)
        // Horizontal intent only; vertical drags stay with the child.
        guard abs(velocity.x) > abs(velocity.y) else { return false }
        let width = view.bounds.width
        let logicalX = isRightToLeft ? width - startX : startX
        let inLeadingBand = logicalX <= edgePanBandWidth
        let inTrailingBand = logicalX >= width - edgePanBandWidth
        // A leading-edge drag toward the previous page on the first page is the navigation
        // controller's pop gesture, when one is available.
        if currentPageIndex == 0, inLeadingBand, visual(velocity.x) > 0,
           (navigationController as? LMKNavigationController)?.canBeginPopGesture == true {
            return false
        }
        if !usesFullWidthSwipe(forPageAt: currentPageIndex) {
            return inLeadingBand || inTrailingBand
        }
        return true
    }

    var pagePanRecognizer: UIPanGestureRecognizer { pagePanGesture }
}

/// The page pan's delegate, kept off the controller's public surface.
private final class LMKSegmentedPagePanDelegate: NSObject, UIGestureRecognizerDelegate {
    private weak var owner: LMKSegmentedPageViewController?
    private var startX: CGFloat = 0

    init(owner: LMKSegmentedPageViewController) {
        self.owner = owner
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if let owner, gestureRecognizer === owner.pagePanRecognizer {
            startX = touch.location(in: owner.view).x
        }
        return true
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let owner, gestureRecognizer === owner.pagePanRecognizer else { return true }
        return owner.shouldBeginPagePan(startX: startX)
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith _: UIGestureRecognizer) -> Bool {
        // Coexist with a child's vertical scroll view; shouldBegin already rejects vertical drags.
        gestureRecognizer === owner?.pagePanRecognizer
    }
}

public nonisolated extension LMKTheme {
    /// App-wide default style for `LMKSegmentedPageViewController`.
    var segmentedPage: LMKSegmentedPageViewController.Style {
        get { self[LMKSegmentedPageViewController.Style.self] }
        set { self[LMKSegmentedPageViewController.Style.self] = newValue }
    }
}
