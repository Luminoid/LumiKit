//
//  LMKSegmentedPageController.swift
//  LumiKit
//
//  Container that pages between child view controllers selected by a top
//  LMKSegmentedControl, with an interactive pan that drags the pages with the finger.
//

import UIKit

/// Container view controller that hosts two (or more) child view controllers selected by a
/// top ``LMKSegmentedControl``, with an interactive pan that drags the pages with the finger.
///
/// Pages can opt into a full-width pan (conflict-free vertical scrollers) or an edge-only pan
/// (a narrow screen-edge band) so a page that owns horizontal drags (an `MKMapView`, a custom
/// month-pan grid) keeps its interior. Tapping a segment, or calling ``setPage(_:animated:)``,
/// performs a non-interactive slide.
///
/// Subclasses provide the pages via ``makePages()``, the per-page pan mode via
/// ``usesFullWidthSwipe(forPageAt:)``, and react to page changes via ``didChangePage(to:)``.
///
/// ```swift
/// final class MyContainerViewController: LMKSegmentedPageController {
///     init() { super.init(titles: ["List", "Map"]) }
///
///     override func makePages() -> [UIViewController] {
///         [listViewController, mapViewController]
///     }
///
///     /// The map page owns interior pan/zoom, so its tab-swipe is edge-only.
///     override func usesFullWidthSwipe(forPageAt index: Int) -> Bool { index != 1 }
/// }
/// ```
open class LMKSegmentedPageController: UIViewController, UIGestureRecognizerDelegate {
    // MARK: - Configuration

    /// Touch band (pts) at each horizontal edge that begins the pan on edge-only pages
    /// (pages where ``usesFullWidthSwipe(forPageAt:)`` returns `false`). Default `24`.
    open var edgePanBandWidth: CGFloat { 24 }

    /// Horizontal velocity (pts/s) past which a flick commits a page change regardless of
    /// distance. Default `800`.
    open var commitVelocityThreshold: CGFloat { 800 }

    // MARK: - Properties

    /// The segmented control driving page selection. Installed by ``installSegmentedControl()``.
    public let segmentedControl: LMKSegmentedControl

    /// Index of the currently visible page.
    public private(set) var currentPageIndex = 0

    private var pages: [UIViewController] = []
    private var currentChild: UIViewController?
    private var isAnimatingPageChange = false

    // Interactive paging state (valid only while a drag is in flight)
    private var dragStartTouchX: CGFloat = 0
    private var isInteractiveDragActive = false
    private var interactiveDirection = 0
    private var interactiveNeighborIndex: Int?
    private var interactiveNeighborVC: UIViewController?

    private lazy var pagePanGesture: UIPanGestureRecognizer = {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePagePan(_:)))
        pan.delegate = self
        return pan
    }()

    // MARK: - Initialization

    /// Create a container with one segment title per page, in segment order.
    public init(titles: [String]) {
        segmentedControl = LMKSegmentedControl(items: titles)
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Overridable Hooks

    /// Provide the child view controllers, in segment order. Called once during `viewDidLoad`.
    open func makePages() -> [UIViewController] {
        []
    }

    /// Whether the given page accepts a full-width pan (`true`, default) or only an edge pan
    /// (`false`, for pages that own horizontal drags such as a map or a month-pan grid).
    open func usesFullWidthSwipe(forPageAt _: Int) -> Bool {
        true
    }

    /// Called after the visible page changes (not for the initial page). Override to run
    /// page-specific side effects (e.g. toggling bar buttons).
    open func didChangePage(to _: Int) {}

    /// Install the segmented control into the UI. Default places it as the navigation item's
    /// title view. Override to position it elsewhere (e.g. pinned below a custom nav bar).
    open func installSegmentedControl() {
        navigationItem.titleView = segmentedControl
    }

    /// The view that hosts the child pages. Defaults to the controller's own `view`, which
    /// suits hosts using the system navigation bar. Override to return a container pinned
    /// below custom chrome (e.g. an `LMKNavigationBar` plus the segmented control) so pages
    /// don't render underneath it.
    ///
    /// Called after ``installSegmentedControl()``, so an overriding subclass can build and
    /// constrain the container there. The container may have zero bounds at that point;
    /// page frames are re-applied in `viewDidLayoutSubviews` once layout resolves.
    open var pageContainerView: UIView { view }

    // MARK: - Lifecycle

    override open func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = LMKColor.backgroundPrimary

        segmentedControl.itemPadding = LMKSpacing.xl
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.valueChangedHandler = { [weak self] index in
            self?.setPage(index, animated: true)
        }
        installSegmentedControl()

        view.addGestureRecognizer(pagePanGesture)

        pages = makePages()
        guard !pages.isEmpty else { return }
        showInitialPage()
    }

    // MARK: - Page Management

    /// Move to `index`, animating a horizontal slide. Keeps the segmented control in sync without
    /// re-entering the value-changed handler. Safe to call programmatically (deep links).
    open func setPage(_ index: Int, animated: Bool) {
        guard index >= 0, index < pages.count, index != currentPageIndex,
              !isAnimatingPageChange, !isInteractiveDragActive else { return }
        let direction = index > currentPageIndex ? 1 : -1
        transition(to: index, direction: direction, animated: animated)
        segmentedControl.setSelectedSegmentIndex(index, animated: true)
    }

    private func showInitialPage() {
        let pageVC = pages[0]
        addChild(pageVC)
        pageVC.view.frame = pageContainerView.bounds
        pageVC.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        pageContainerView.addSubview(pageVC.view)
        pageVC.didMove(toParent: self)
        currentChild = pageVC
        currentPageIndex = 0
    }

    private func transition(to index: Int, direction: Int, animated: Bool) {
        let container = pageContainerView
        let newVC = pages[index]
        let oldVC = currentChild
        addChild(newVC)
        newVC.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        let width = container.bounds.width

        if animated, LMKAnimationHelper.shouldAnimate, let oldVC {
            isAnimatingPageChange = true
            newVC.view.frame = container.bounds.offsetBy(dx: CGFloat(direction) * width, dy: 0)
            container.addSubview(newVC.view)
            UIView.animate(withDuration: LMKAnimationHelper.Duration.screenTransition, delay: 0, options: .curveEaseInOut) {
                newVC.view.frame = container.bounds
                oldVC.view.frame = container.bounds.offsetBy(dx: CGFloat(-direction) * width, dy: 0)
            } completion: { _ in
                oldVC.willMove(toParent: nil)
                oldVC.view.removeFromSuperview()
                oldVC.removeFromParent()
                newVC.didMove(toParent: self)
                self.isAnimatingPageChange = false
            }
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
        didChangePage(to: index)
    }

    /// Re-seats the visible page on the container's resolved bounds. Required when
    /// ``pageContainerView`` is a constraint-laid-out container: it has zero bounds
    /// during `viewDidLoad`, and autoresizing cannot scale a page up from zero.
    /// Skipped mid-drag / mid-animation, where the frames are being driven directly.
    override open func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard !isInteractiveDragActive, !isAnimatingPageChange else { return }
        currentChild?.view.frame = pageContainerView.bounds
    }

    // MARK: - Interactive Paging

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

    private func handlePagePanChanged(_ gesture: UIPanGestureRecognizer) {
        guard let currentChild, !isAnimatingPageChange else { return }
        let container = pageContainerView
        let translation = gesture.translation(in: view).x
        let width = container.bounds.width

        if !isInteractiveDragActive {
            guard abs(translation) > 2 else { return }
            beginInteractiveDrag(translation: translation, width: width)
        }

        let offset = interactiveOffset(for: translation, width: width)
        currentChild.view.frame = container.bounds.offsetBy(dx: offset, dy: 0)
        interactiveNeighborVC?.view.frame = container.bounds.offsetBy(dx: offset + CGFloat(interactiveDirection) * width, dy: 0)
    }

    /// Locks the drag direction on first movement and lazily attaches the neighbor page
    /// (offscreen on the side it will slide in from). No neighbor at the first/last page.
    private func beginInteractiveDrag(translation: CGFloat, width: CGFloat) {
        isInteractiveDragActive = true
        interactiveDirection = translation < 0 ? 1 : -1
        let neighborIndex = currentPageIndex + interactiveDirection
        guard neighborIndex >= 0, neighborIndex < pages.count else {
            interactiveNeighborIndex = nil
            interactiveNeighborVC = nil
            return
        }
        let neighbor = pages[neighborIndex]
        addChild(neighbor)
        neighbor.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        neighbor.view.frame = pageContainerView.bounds.offsetBy(dx: CGFloat(interactiveDirection) * width, dy: 0)
        pageContainerView.addSubview(neighbor.view)
        interactiveNeighborIndex = neighborIndex
        interactiveNeighborVC = neighbor
    }

    /// Tracks the finger toward the locked neighbor; resists past 0 (wrong way) and at the ends.
    private func interactiveOffset(for translation: CGFloat, width: CGFloat) -> CGFloat {
        guard interactiveNeighborVC != nil else {
            return translation * 0.3 // rubber-band at the first/last page
        }
        if interactiveDirection > 0 {
            return max(min(translation, 0), -width) // dragging to the next page: leftward only
        }
        return min(max(translation, 0), width) // dragging to the previous page: rightward only
    }

    private func handlePagePanEnded(_ gesture: UIPanGestureRecognizer) {
        guard isInteractiveDragActive else { return }
        let width = pageContainerView.bounds.width
        let translation = gesture.translation(in: view).x
        let velocity = gesture.velocity(in: view).x

        let movedEnough = abs(translation) > width * 0.5
        // Velocity sign must match the drag direction (next → leftward/negative).
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
            outgoing?.view.frame = container.bounds.offsetBy(dx: CGFloat(-direction) * width, dy: 0)
            neighbor.view.frame = container.bounds
        } completion: { _ in
            outgoing?.willMove(toParent: nil)
            outgoing?.view.removeFromSuperview()
            outgoing?.removeFromParent()
            neighbor.didMove(toParent: self)
            self.currentChild = neighbor
            self.currentPageIndex = neighborIndex
            self.segmentedControl.setSelectedSegmentIndex(neighborIndex, animated: true)
            self.clearInteractiveState()
            self.isAnimatingPageChange = false
            self.didChangePage(to: neighborIndex)
        }
    }

    private func revertInteractiveDrag(width: CGFloat) {
        let neighbor = interactiveNeighborVC
        let direction = interactiveDirection
        let container = pageContainerView
        isAnimatingPageChange = true

        animateSettle {
            self.currentChild?.view.frame = container.bounds
            neighbor?.view.frame = container.bounds.offsetBy(dx: CGFloat(direction) * width, dy: 0)
        } completion: { _ in
            neighbor?.willMove(toParent: nil)
            neighbor?.view.removeFromSuperview()
            neighbor?.removeFromParent()
            self.clearInteractiveState()
            self.isAnimatingPageChange = false
        }
    }

    private func animateSettle(_ animations: @escaping () -> Void, completion: @escaping (Bool) -> Void) {
        guard LMKAnimationHelper.shouldAnimate else {
            animations()
            completion(true)
            return
        }
        UIView.animate(withDuration: LMKAnimationHelper.Duration.screenTransition, delay: 0,
                       options: .curveEaseOut, animations: animations, completion: completion)
    }

    private func clearInteractiveState() {
        isInteractiveDragActive = false
        interactiveDirection = 0
        interactiveNeighborIndex = nil
        interactiveNeighborVC = nil
    }

    // MARK: - UIGestureRecognizerDelegate

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if gestureRecognizer === pagePanGesture {
            dragStartTouchX = touch.location(in: view).x
        }
        return true
    }

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard gestureRecognizer === pagePanGesture else { return true }
        guard !isAnimatingPageChange else { return false }
        let velocity = pagePanGesture.velocity(in: view)
        // Horizontal intent only; let vertical scrolling pass through to the child.
        guard abs(velocity.x) > abs(velocity.y) else { return false }
        // Edge-only pages (map / month grid own their interior drags): begin near a screen edge.
        if !usesFullWidthSwipe(forPageAt: currentPageIndex) {
            let x = dragStartTouchX
            guard x <= edgePanBandWidth || x >= view.bounds.width - edgePanBandWidth else { return false }
        }
        return true
    }

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith _: UIGestureRecognizer) -> Bool {
        // Coexist with a child's vertical scroll view; shouldBegin already rejects vertical drags.
        gestureRecognizer === pagePanGesture
    }
}
