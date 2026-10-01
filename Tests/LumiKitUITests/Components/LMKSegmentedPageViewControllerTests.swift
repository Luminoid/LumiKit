//
//  LMKSegmentedPageViewControllerTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

private final class TestSegmentedPageVC: LMKSegmentedPageViewController {
    let page0 = UIViewController()
    let page1 = UIViewController()
    var didChangePageCalls: [Int] = []

    init(style: Style = Style()) {
        super.init(titles: ["A", "B"], style: style)
    }

    override func makePages() -> [UIViewController] {
        [page0, page1]
    }

    override func didChangePage(to index: Int) {
        didChangePageCalls.append(index)
    }
}

private final class EdgeOnlyPageVC: LMKSegmentedPageViewController {
    init() {
        super.init(titles: ["List", "Map"])
    }

    override func usesFullWidthSwipe(forPageAt index: Int) -> Bool {
        index != 1
    }
}

private final class EmptyPagesVC: LMKSegmentedPageViewController {
    init() {
        super.init(titles: ["A", "B"])
    }
}

/// Vetoes page 1 from `setPage`, the way a subclass gating navigation would.
private final class VetoingPageVC: LMKSegmentedPageViewController {
    let page0 = UIViewController()
    let page1 = UIViewController()
    var themedContent: [String] = []

    init() {
        super.init(titles: ["A", "B"])
    }

    override func makePages() -> [UIViewController] {
        [page0, page1]
    }

    override func setPage(_ index: Int, animated: Bool) {
        guard index != 1 else { return }
        super.setPage(index, animated: animated)
    }

    override func applyContentTheme(_ theme: LMKTheme) {
        themedContent.append("content")
    }
}

/// Hosts its pages in a container pinned below custom chrome, the way an app using a custom
/// navigation bar does. The container is built before `super.viewDidLoad()` installs the pages.
private final class ContainerHostedPageVC: LMKSegmentedPageViewController {
    static let chromeHeight: CGFloat = 120

    let page0 = UIViewController()
    let page1 = UIViewController()
    let container = UIView()
    let controlSlot = UIView()

    init() {
        super.init(titles: ["A", "B"])
    }

    override func makePages() -> [UIViewController] {
        [page0, page1]
    }

    override func loadView() {
        view = UIView(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
    }

    override var pageContainerView: UIView { container }

    override func viewDidLoad() {
        view.addSubview(controlSlot)
        view.addSubview(container)
        controlSlot.translatesAutoresizingMaskIntoConstraints = false
        container.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            controlSlot.topAnchor.constraint(equalTo: view.topAnchor),
            controlSlot.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            controlSlot.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            controlSlot.heightAnchor.constraint(equalToConstant: Self.chromeHeight),
            container.topAnchor.constraint(equalTo: controlSlot.bottomAnchor),
            container.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            container.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        segmentedControlPlacement = .container(controlSlot)
        super.viewDidLoad()
    }
}

@MainActor
struct LMKSegmentedPageViewControllerTests {
    @Test
    func `Defaults: title placement, first page installed, style-driven pan tuning`() {
        let vc = TestSegmentedPageVC()
        vc.loadViewIfNeeded()
        #expect(vc.navigationItem.titleView === vc.segmentedControl)
        #expect(vc.page0.parent === vc)
        #expect(vc.page1.parent == nil)
        #expect(vc.page0.view.superview === vc.view)
        #expect(vc.pages.count == 2)
        #expect(vc.currentPageIndex == 0)
        #expect(vc.currentViewController === vc.page0)
        #expect(vc.childForStatusBarStyle === vc.page0)
        #expect(vc.segmentedControl.selectedSegmentIndex == 0)
        #expect(vc.segmentedControl.style.itemPadding == LMKSpacing.xl)
        #expect(vc.view.backgroundColor === LMKColor.backgroundPrimary)
        #expect(vc.edgePanBandWidth == 24)
        #expect(vc.commitVelocityThreshold == 800)
        #expect(vc.usesFullWidthSwipe(forPageAt: 0))
        #expect(vc.didChangePageCalls.isEmpty)
        #expect(!vc.prefersPopGestureDisabled)
        #expect(vc.pageContainerView === vc.view)
    }

    @Test
    func `setPage swaps the child, syncs the control, reports the change, and rejects bad indices`() {
        let vc = TestSegmentedPageVC()
        vc.loadViewIfNeeded()
        vc.setPage(1, animated: false)
        #expect(vc.currentPageIndex == 1)
        #expect(vc.currentViewController === vc.page1)
        #expect(vc.segmentedControl.selectedSegmentIndex == 1)
        #expect(vc.page1.parent === vc)
        #expect(vc.page0.parent == nil)
        #expect(vc.page0.view.superview == nil)
        #expect(vc.didChangePageCalls == [1])
        #expect(vc.prefersPopGestureDisabled, "later pages own the leading-edge drag")

        vc.setPage(5, animated: false)
        vc.setPage(1, animated: false)
        #expect(vc.currentPageIndex == 1)
        #expect(vc.didChangePageCalls == [1])
        vc.setPage(0, animated: false)
        #expect(vc.currentPageIndex == 0)
        #expect(vc.page0.parent === vc)
        #expect(vc.didChangePageCalls == [1, 0])
    }

    @Test
    func `setPages replaces the pages and titles after load`() {
        let vc = TestSegmentedPageVC()
        vc.loadViewIfNeeded()
        vc.setPage(1, animated: false)
        let a = UIViewController()
        let b = UIViewController()
        let c = UIViewController()
        vc.setPages([a, b, c], titles: ["One", "Two", "Three"])
        #expect(vc.pages.count == 3)
        #expect(vc.segmentedControl.items == ["One", "Two", "Three"])
        #expect(vc.currentPageIndex == 1, "an in-range index survives")
        #expect(vc.currentViewController === b)
        #expect(vc.page1.parent == nil)

        vc.setPages([a])
        #expect(vc.currentPageIndex == 0)
        #expect(vc.currentViewController === a)
        #expect(vc.segmentedControl.selectedSegmentIndex == 0)

        vc.setPages([])
        #expect(vc.currentViewController == nil)
        #expect(vc.children.isEmpty)
        #expect(vc.segmentedControl.selectedSegmentIndex == -1)
    }

    @Test
    func `Empty pages leave no child and ignore setPage`() {
        let vc = EmptyPagesVC()
        vc.loadViewIfNeeded()
        #expect(vc.children.isEmpty)
        #expect(vc.currentPageIndex == 0)
        vc.setPage(1, animated: false)
        #expect(vc.currentPageIndex == 0)
    }

    @Test
    func `Edge-only pages and pop-gesture policy`() {
        let vc = EdgeOnlyPageVC()
        #expect(vc.usesFullWidthSwipe(forPageAt: 0))
        #expect(!vc.usesFullWidthSwipe(forPageAt: 1))

        let pages = TestSegmentedPageVC()
        let navigation = LMKNavigationController(rootViewController: UIViewController())
        navigation.loadViewIfNeeded()
        navigation.pushViewController(pages, animated: false)
        pages.loadViewIfNeeded()
        #expect(navigation.canBeginPopGesture)
        pages.setPage(1, animated: false)
        #expect(!navigation.canBeginPopGesture, "the pop gesture yields to the page pan past the first page")
    }

    @Test
    func `Container placement puts the control in the slot and the pages in the container`() {
        let vc = ContainerHostedPageVC()
        vc.loadViewIfNeeded()
        #expect(vc.container.bounds.isEmpty)
        #expect(vc.page0.view.frame.size == CGSize(width: 390, height: 844), "installed at the controller's size before the container lays out")
        vc.view.layoutIfNeeded()
        #expect(vc.segmentedControl.superview === vc.controlSlot)
        #expect(vc.navigationItem.titleView == nil)
        #expect(vc.page0.view.superview === vc.container)
        #expect(vc.page0.view.frame == vc.container.bounds)
        #expect(vc.page0.view.frame.height == 844 - ContainerHostedPageVC.chromeHeight)

        vc.setPage(1, animated: false)
        #expect(vc.page1.view.superview === vc.container)
        #expect(vc.page1.view.frame == vc.container.bounds)

        vc.view.frame = CGRect(x: 0, y: 0, width: 320, height: 600)
        vc.view.layoutIfNeeded()
        #expect(vc.container.bounds.height == 600 - ContainerHostedPageVC.chromeHeight)
        #expect(vc.page1.view.frame == vc.container.bounds)

        vc.segmentedControlPlacement = .navigationTitle
        #expect(vc.navigationItem.titleView === vc.segmentedControl)
        #expect(vc.segmentedControl.superview !== vc.controlSlot)
        vc.segmentedControlPlacement = .manual
        #expect(vc.navigationItem.titleView == nil)
        #expect(vc.segmentedControl.superview == nil)
    }

    @Test
    func `Style and theme.segmentedPage tune the container and the control`() {
        let vc = TestSegmentedPageVC(style: LMKSegmentedPageViewController.Style(
            segmentedControl: LMKSegmentedControl.Style(corners: .rounded),
            backgroundColor: .red,
            edgePanBandWidth: 40,
            commitVelocityThreshold: 500,
            pageTransitionDuration: 0.1
        ))
        vc.loadViewIfNeeded()
        #expect(vc.view.backgroundColor == UIColor.red)
        #expect(vc.edgePanBandWidth == 40)
        #expect(vc.commitVelocityThreshold == 500)
        #expect(vc.resolvedStyle.pageTransitionDuration == 0.1)
        #expect(vc.segmentedControl.style.corners == .rounded)
        #expect(vc.segmentedControl.style.itemPadding == LMKSpacing.xl)

        var theme = LMKTheme()
        theme.segmentedPage = LMKSegmentedPageViewController.Style(backgroundColor: .magenta)
        let themed = TestSegmentedPageVC()
        let window = LMKThemeTesting.host(themed.view, theme: theme)
        defer { window.isHidden = true }
        themed.applyTheme(theme)
        #expect(themed.view.backgroundColor == UIColor.magenta)
    }

    @Test
    func `setPages and setPage before the view loads take effect once it does`() {
        let vc = TestSegmentedPageVC()
        let a = UIViewController()
        let b = UIViewController()
        vc.setPages([a, b], titles: ["One", "Two"])
        #expect(vc.isViewLoaded, "setPages loads the view rather than corrupt it")
        #expect(vc.pages == [a, b], "makePages() does not overwrite pages handed over before the load")
        #expect(vc.currentViewController === a)
        #expect(vc.page0.parent == nil)
        #expect(vc.segmentedControl.items == ["One", "Two"])

        let deepLinked = TestSegmentedPageVC()
        deepLinked.setPage(1, animated: false)
        #expect(deepLinked.currentPageIndex == 1)
        #expect(deepLinked.currentViewController === deepLinked.page1)
        #expect(deepLinked.segmentedControl.selectedSegmentIndex == 1)
    }

    @Test
    func `A segment tap the page change rejects snaps the control back`() {
        let vc = VetoingPageVC()
        vc.loadViewIfNeeded()
        vc.segmentedControl.setSelectedSegmentIndex(1, animated: false)
        vc.segmentedControl.onValueChange?(1)
        #expect(vc.currentPageIndex == 0)
        #expect(vc.segmentedControl.selectedSegmentIndex == 0, "the control never shows a segment whose page is not up")
    }

    @Test
    func `Mid-slide: a second tap snaps back and pages handed over are queued until it settles`() async {
        let vc = TestSegmentedPageVC()
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        window.rootViewController = vc
        window.isHidden = false
        defer { window.isHidden = true }
        vc.view.layoutIfNeeded()

        vc.setPage(1, animated: true)
        #expect(vc.currentPageIndex == 1)
        let inFlight = vc.isAnimatingPageChange
        let a = UIViewController()
        let b = UIViewController()
        let c = UIViewController()
        vc.segmentedControl.setSelectedSegmentIndex(0, animated: false)
        vc.segmentedControl.onValueChange?(0)
        vc.setPages([a, b, c], titles: ["One", "Two", "Three"])
        if inFlight {
            #expect(vc.currentPageIndex == 1, "a tap during the slide is rejected")
            #expect(vc.segmentedControl.selectedSegmentIndex == 1, "and the control follows the page")
            #expect(vc.pages == [vc.page0, vc.page1], "new pages wait for the slide")
            #expect(vc.segmentedControl.items == ["A", "B"])
        }
        await LMKWait.until { !vc.isAnimatingPageChange && vc.pages.count == 3 }
        #expect(vc.pages == [a, b, c])
        #expect(vc.segmentedControl.items == ["One", "Two", "Three"])
        #expect(vc.currentPageIndex == (inFlight ? 1 : 0), "the index survives the replacement when in range")
        #expect(vc.currentViewController === (inFlight ? b : a))
        #expect(vc.page1.parent == nil)
        #expect(vc.children.count == 1)
    }

    @Test
    func `A drag commits on the clamped offset and on a flick toward the neighbor`() {
        typealias Pages = LMKSegmentedPageViewController
        // Toward the next page (direction 1) the finger moves toward the leading edge (negative).
        #expect(Pages.interactiveOffset(for: -100, direction: 1, width: 390, hasNeighbor: true) == -100)
        #expect(Pages.interactiveOffset(for: -500, direction: 1, width: 390, hasNeighbor: true) == -390, "one page at most")
        #expect(Pages.interactiveOffset(for: 300, direction: 1, width: 390, hasNeighbor: true) == 0, "the wrong way stays put")
        #expect(Pages.interactiveOffset(for: 300, direction: -1, width: 390, hasNeighbor: true) == 300)
        #expect(Pages.interactiveOffset(for: 100, direction: -1, width: 390, hasNeighbor: false) == 30, "a rubber band at the ends")

        let threshold: CGFloat = 800
        #expect(Pages.commitsInteractiveDrag(offset: -200, velocity: 0, direction: 1, width: 390, commitVelocityThreshold: threshold))
        #expect(!Pages.commitsInteractiveDrag(offset: -100, velocity: 0, direction: 1, width: 390, commitVelocityThreshold: threshold))
        #expect(
            !Pages.commitsInteractiveDrag(offset: 0, velocity: 0, direction: 1, width: 390, commitVelocityThreshold: threshold),
            "reversed past the start: the raw translation would have committed"
        )
        #expect(Pages.commitsInteractiveDrag(offset: -20, velocity: -900, direction: 1, width: 390, commitVelocityThreshold: threshold), "a flick toward the neighbor")
        #expect(!Pages.commitsInteractiveDrag(offset: -20, velocity: 900, direction: 1, width: 390, commitVelocityThreshold: threshold), "a flick back does not")
        #expect(Pages.commitsInteractiveDrag(offset: 20, velocity: 900, direction: -1, width: 390, commitVelocityThreshold: threshold))
    }

    @Test
    func `The page pan leaves the segmented control and sliders alone and coexists only with a scroll view's pan`() {
        let vc = ContainerHostedPageVC()
        vc.loadViewIfNeeded()
        vc.view.layoutIfNeeded()
        #expect(!vc.pagePanShouldReceiveTouch(on: vc.segmentedControl))
        #expect(!vc.pagePanShouldReceiveTouch(on: vc.segmentedControl.subviews.first), "nor a touch on its indicator")
        let slider = UISlider()
        vc.page0.view.addSubview(slider)
        #expect(!vc.pagePanShouldReceiveTouch(on: slider))
        #expect(vc.pagePanShouldReceiveTouch(on: vc.page0.view))
        #expect(vc.pagePanShouldReceiveTouch(on: nil))

        let delegate = vc.pagePanRecognizer.delegate
        let scrollView = UIScrollView()
        #expect(delegate?.gestureRecognizer?(vc.pagePanRecognizer, shouldRecognizeSimultaneouslyWith: scrollView.panGestureRecognizer) == true)
        #expect(delegate?.gestureRecognizer?(vc.pagePanRecognizer, shouldRecognizeSimultaneouslyWith: UIPanGestureRecognizer()) == false)
        let controlPan = vc.segmentedControl.gestureRecognizers?.first { $0 is UIPanGestureRecognizer }
        #expect(controlPan != nil)
        if let controlPan {
            #expect(delegate?.gestureRecognizer?(vc.pagePanRecognizer, shouldRecognizeSimultaneouslyWith: controlPan) == false, "the indicator drag never pages")
        }
    }

    @Test
    func `applyContentTheme runs before didApplyStyle on every theme pass`() {
        let vc = VetoingPageVC()
        var order: [String] = []
        vc.didApplyStyle = { _ in order.append("didApplyStyle") }
        vc.loadViewIfNeeded()
        #expect(vc.themedContent.count >= 1)
        vc.themedContent.removeAll()
        order.removeAll()
        vc.didApplyStyle = { [unowned vc] _ in order.append(contentsOf: vc.themedContent + ["didApplyStyle"]) }
        vc.applyTheme(LMKTheme())
        #expect(order == ["content", "didApplyStyle"])
    }
}
