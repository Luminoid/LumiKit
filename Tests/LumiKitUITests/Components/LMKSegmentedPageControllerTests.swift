//
//  LMKSegmentedPageControllerTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

// MARK: - Test Helpers

private final class TestSegmentedPageVC: LMKSegmentedPageController {
    let page0 = UIViewController()
    let page1 = UIViewController()
    var didChangePageCalls: [Int] = []

    init() {
        super.init(titles: ["A", "B"])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func makePages() -> [UIViewController] {
        [page0, page1]
    }

    override func didChangePage(to index: Int) {
        didChangePageCalls.append(index)
    }
}

private final class EdgeOnlyPageVC: LMKSegmentedPageController {
    init() {
        super.init(titles: ["List", "Map"])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func usesFullWidthSwipe(forPageAt index: Int) -> Bool {
        index != 1
    }
}

private final class TunedPageVC: LMKSegmentedPageController {
    init() {
        super.init(titles: ["A", "B"])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var edgePanBandWidth: CGFloat { 40 }
    override var commitVelocityThreshold: CGFloat { 500 }
}

private final class EmptyPagesVC: LMKSegmentedPageController {
    init() {
        super.init(titles: ["A", "B"])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func makePages() -> [UIViewController] {
        []
    }
}

/// Hosts its pages in a container pinned below custom chrome, the way an app using
/// a custom navigation bar does, instead of letting them fill `view`.
private final class ContainerHostedPageVC: LMKSegmentedPageController {
    static let chromeHeight: CGFloat = 120

    let page0 = UIViewController()
    let page1 = UIViewController()
    let container = UIView()

    init() {
        super.init(titles: ["A", "B"])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func makePages() -> [UIViewController] {
        [page0, page1]
    }

    override var pageContainerView: UIView { container }

    override func installSegmentedControl() {
        container.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(container)
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: view.topAnchor, constant: Self.chromeHeight),
            container.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            container.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }
}

// MARK: - LMKSegmentedPageController (defaults)

@MainActor
struct LMKSegmentedPageControllerDefaultTests {
    @Test
    func `default edgePanBandWidth is 24`() {
        #expect(TestSegmentedPageVC().edgePanBandWidth == 24)
    }

    @Test
    func `default commitVelocityThreshold is 800`() {
        #expect(TestSegmentedPageVC().commitVelocityThreshold == 800)
    }

    @Test
    func `default usesFullWidthSwipe returns true`() {
        let vc = TestSegmentedPageVC()
        #expect(vc.usesFullWidthSwipe(forPageAt: 0))
        #expect(vc.usesFullWidthSwipe(forPageAt: 1))
    }

    @Test
    func `initial currentPageIndex is 0`() {
        #expect(TestSegmentedPageVC().currentPageIndex == 0)
    }
}

// MARK: - LMKSegmentedPageController (view hierarchy)

@MainActor
struct LMKSegmentedPageControllerHierarchyTests {
    @Test
    func `segmentedControl is installed as the navigation title view`() {
        let vc = TestSegmentedPageVC()
        vc.loadViewIfNeeded()
        #expect(vc.navigationItem.titleView === vc.segmentedControl)
    }

    @Test
    func `first page is added as a child after loadViewIfNeeded`() {
        let vc = TestSegmentedPageVC()
        vc.loadViewIfNeeded()
        #expect(vc.page0.parent === vc)
        #expect(vc.page1.parent == nil)
    }

    @Test
    func `first page view is added to the container view`() {
        let vc = TestSegmentedPageVC()
        vc.loadViewIfNeeded()
        #expect(vc.page0.view.superview === vc.view)
    }

    @Test
    func `view background is backgroundPrimary`() {
        let vc = TestSegmentedPageVC()
        vc.loadViewIfNeeded()
        #expect(vc.view.backgroundColor == LMKColor.backgroundPrimary)
    }

    @Test
    func `segmentedControl starts on segment 0`() {
        let vc = TestSegmentedPageVC()
        vc.loadViewIfNeeded()
        #expect(vc.segmentedControl.selectedSegmentIndex == 0)
    }

    @Test
    func `didChangePage is not called for the initial page`() {
        let vc = TestSegmentedPageVC()
        vc.loadViewIfNeeded()
        #expect(vc.didChangePageCalls.isEmpty)
    }
}

// MARK: - LMKSegmentedPageController (page management)

@MainActor
struct LMKSegmentedPageControllerPageTests {
    @Test
    func `setPage to a valid index updates currentPageIndex`() {
        let vc = TestSegmentedPageVC()
        vc.loadViewIfNeeded()
        vc.setPage(1, animated: false)
        #expect(vc.currentPageIndex == 1)
    }

    @Test
    func `setPage syncs the segmented control selection`() {
        let vc = TestSegmentedPageVC()
        vc.loadViewIfNeeded()
        vc.setPage(1, animated: false)
        #expect(vc.segmentedControl.selectedSegmentIndex == 1)
    }

    @Test
    func `setPage swaps the visible child`() {
        let vc = TestSegmentedPageVC()
        vc.loadViewIfNeeded()
        vc.setPage(1, animated: false)
        #expect(vc.page1.parent === vc)
        #expect(vc.page0.parent == nil)
        #expect(vc.page0.view.superview == nil)
    }

    @Test
    func `setPage calls didChangePage with the new index`() {
        let vc = TestSegmentedPageVC()
        vc.loadViewIfNeeded()
        vc.setPage(1, animated: false)
        #expect(vc.didChangePageCalls == [1])
    }

    @Test
    func `setPage to an out-of-range index is a no-op`() {
        let vc = TestSegmentedPageVC()
        vc.loadViewIfNeeded()
        vc.setPage(5, animated: false)
        #expect(vc.currentPageIndex == 0)
        #expect(vc.didChangePageCalls.isEmpty)
    }

    @Test
    func `setPage to the current index is a no-op`() {
        let vc = TestSegmentedPageVC()
        vc.loadViewIfNeeded()
        vc.setPage(0, animated: false)
        #expect(vc.currentPageIndex == 0)
        #expect(vc.didChangePageCalls.isEmpty)
    }

    @Test
    func `setPage forward then back returns to page 0`() {
        let vc = TestSegmentedPageVC()
        vc.loadViewIfNeeded()
        vc.setPage(1, animated: false)
        vc.setPage(0, animated: false)
        #expect(vc.currentPageIndex == 0)
        #expect(vc.page0.parent === vc)
        #expect(vc.didChangePageCalls == [1, 0])
    }
}

// MARK: - LMKSegmentedPageController (custom configuration)

@MainActor
struct LMKSegmentedPageControllerCustomTests {
    @Test
    func `custom edgePanBandWidth overrides the default`() {
        #expect(TunedPageVC().edgePanBandWidth == 40)
    }

    @Test
    func `custom commitVelocityThreshold overrides the default`() {
        #expect(TunedPageVC().commitVelocityThreshold == 500)
    }

    @Test
    func `usesFullWidthSwipe override is respected per page`() {
        let vc = EdgeOnlyPageVC()
        #expect(vc.usesFullWidthSwipe(forPageAt: 0))
        #expect(!vc.usesFullWidthSwipe(forPageAt: 1))
    }
}

// MARK: - LMKSegmentedPageController (empty pages)

@MainActor
struct LMKSegmentedPageControllerEmptyTests {
    @Test
    func `empty makePages leaves no child and does not crash`() {
        let vc = EmptyPagesVC()
        vc.loadViewIfNeeded()
        #expect(vc.children.isEmpty)
        #expect(vc.currentPageIndex == 0)
    }

    @Test
    func `setPage on an empty container is a no-op`() {
        let vc = EmptyPagesVC()
        vc.loadViewIfNeeded()
        vc.setPage(1, animated: false)
        #expect(vc.currentPageIndex == 0)
    }
}

// MARK: - LMKSegmentedPageController (pageContainerView)

@MainActor
struct LMKSegmentedPageControllerContainerTests {
    private func makeHosted() -> ContainerHostedPageVC {
        let vc = ContainerHostedPageVC()
        vc.view.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        vc.loadViewIfNeeded()
        vc.view.layoutIfNeeded()
        return vc
    }

    @Test
    func `default pageContainerView is the controllers own view`() {
        let vc = TestSegmentedPageVC()
        #expect(vc.pageContainerView === vc.view)
    }

    @Test
    func `initial page is added to the container, not the root view`() {
        let vc = makeHosted()
        #expect(vc.page0.view.superview === vc.container)
    }

    @Test
    func `page is sized to the container, clearing the custom chrome`() {
        let vc = makeHosted()
        #expect(vc.page0.view.frame == vc.container.bounds)
        #expect(vc.page0.view.frame.height == 844 - ContainerHostedPageVC.chromeHeight)
    }

    @Test
    func `setPage moves the new page into the container at full size`() {
        let vc = makeHosted()
        vc.setPage(1, animated: false)
        #expect(vc.currentPageIndex == 1)
        #expect(vc.page1.view.superview === vc.container)
        #expect(vc.page1.view.frame == vc.container.bounds)
    }

    /// A constraint-laid-out container has zero bounds during `viewDidLoad`, so the
    /// page frame set there is stale until layout resolves — and stale again after
    /// any resize (rotation, window change).
    @Test
    func `layout pass re-seats the page on resolved container bounds`() {
        let vc = makeHosted()
        vc.view.frame = CGRect(x: 0, y: 0, width: 320, height: 600)
        vc.view.layoutIfNeeded()
        #expect(vc.container.bounds.height == 600 - ContainerHostedPageVC.chromeHeight)
        #expect(vc.page0.view.frame == vc.container.bounds)
    }
}
