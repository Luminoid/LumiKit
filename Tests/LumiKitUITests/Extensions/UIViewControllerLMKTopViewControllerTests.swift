//
//  UIViewControllerLMKTopViewControllerTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

// MARK: - UIViewController+LMKTopViewController

@MainActor
struct UIViewControllerLMKTopViewControllerTests {
    private func makeWindowed(_ root: UIViewController) -> UIWindow {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 375, height: 812))
        window.rootViewController = root
        window.makeKeyAndVisible()
        return window
    }

    @Test
    func `Returns controller when passed directly`() {
        let vc = UIViewController()
        let top = UIViewController.lmk_topViewController(controller: vc)
        #expect(top === vc)
    }

    @Test
    func `Traverses UINavigationController to visible VC`() {
        let child = UIViewController()
        let nav = UINavigationController(rootViewController: child)
        let top = UIViewController.lmk_topViewController(controller: nav)
        #expect(top === child)
    }

    @Test
    func `Traverses UITabBarController to selected VC`() {
        let tab1 = UIViewController()
        let tab2 = UIViewController()
        let tabBar = UITabBarController()
        tabBar.viewControllers = [tab1, tab2]
        tabBar.selectedIndex = 1

        let top = UIViewController.lmk_topViewController(controller: tabBar)
        #expect(top === tab2)
    }

    @Test
    func `Traverses nested nav inside tab`() {
        let child = UIViewController()
        let nav = UINavigationController(rootViewController: child)
        let tabBar = UITabBarController()
        tabBar.viewControllers = [nav]

        let top = UIViewController.lmk_topViewController(controller: tabBar)
        #expect(top === child)
    }

    /// The regression: an empty navigation controller restarted the walk from the key
    /// window's root and recursed until the stack overflowed.
    @Test
    func `An empty container is its own top, even as the key window's root`() {
        let nav = UINavigationController()
        #expect(UIViewController.lmk_topViewController(controller: nav) === nav)
        let tabBar = UITabBarController()
        #expect(UIViewController.lmk_topViewController(controller: tabBar) === tabBar)

        let window = makeWindowed(nav)
        defer { window.isHidden = true }
        let fromWindow = UIViewController.lmk_topViewController(controller: nil)
        #expect(fromWindow == nil || fromWindow === nav, "no key window in the test host, or the empty root itself")
    }

    @Test
    func `lmk_presentAlertOnTop presents from the top-most controller`() {
        let host = UIViewController()
        let window = makeWindowed(host)
        defer { window.isHidden = true }
        let alert = UIAlertController(title: "Test", message: nil, preferredStyle: .alert)
        host.lmk_presentAlertOnTop(alert)
        #expect(host.presentedViewController === alert)
    }

    /// The regression: a valid anchor (a bar button item, or a source view in the presenter's
    /// window) was replaced by the centered, arrowless configuration.
    @Test
    func `lmk_presentAlertOnTop keeps a bar button anchor`() {
        let host = UIViewController()
        let window = makeWindowed(host)
        defer { window.isHidden = true }
        let anchored = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let item = UIBarButtonItem(systemItem: .action)
        anchored.popoverPresentationController?.barButtonItem = item
        host.lmk_presentAlertOnTop(anchored)
        #expect(anchored.popoverPresentationController?.barButtonItem === item)
        #expect(anchored.popoverPresentationController?.sourceView == nil)
    }

    @Test
    func `lmk_presentAlertOnTop keeps a source view that is in the presenter's window`() {
        let host = UIViewController()
        let window = makeWindowed(host)
        defer { window.isHidden = true }
        window.layoutIfNeeded()
        let sourceView = UIView()
        host.view.addSubview(sourceView)
        #expect(sourceView.window === window)
        let viewAnchored = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        viewAnchored.popoverPresentationController?.sourceView = sourceView
        host.lmk_presentAlertOnTop(viewAnchored)
        // The centered configuration would have replaced the source view with the presenter's view.
        #expect(viewAnchored.popoverPresentationController?.sourceView === sourceView)
        #expect(host.presentedViewController === viewAnchored)
    }

    @Test
    func `lmk_presentAlertOnTop centers a sheet without an anchor`() {
        let host = UIViewController()
        let window = makeWindowed(host)
        defer { window.isHidden = true }
        let bare = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        host.lmk_presentAlertOnTop(bare)
        #expect(bare.popoverPresentationController?.sourceView === host.view)
        #expect(bare.popoverPresentationController?.permittedArrowDirections == [])
    }
}
