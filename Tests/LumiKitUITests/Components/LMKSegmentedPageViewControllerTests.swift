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
            commitVelocityThreshold: 500
        ))
        vc.loadViewIfNeeded()
        #expect(vc.view.backgroundColor == UIColor.red)
        #expect(vc.edgePanBandWidth == 40)
        #expect(vc.commitVelocityThreshold == 500)
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
}
