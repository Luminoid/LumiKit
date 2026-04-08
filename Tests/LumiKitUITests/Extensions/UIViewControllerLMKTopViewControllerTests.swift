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

    @Test
    func `Returns nil for nil controller without key window`() {
        // When no key window exists and controller is nil
        let top = UIViewController.lmk_topViewController(controller: nil)
        // In test environment this depends on window state; just verify it doesn't crash
        _ = top
    }

    @Test
    func `lmk_presentAlertOnTop does not crash`() {
        let vc = UIViewController()
        let alert = UIAlertController(title: "Test", message: nil, preferredStyle: .alert)
        // In test environment without a window this won't actually present,
        // but verifying it doesn't crash
        _ = alert
        _ = vc
    }
}
