//
//  LMKNavigationControllerTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

// MARK: - LMKNavigationController

@MainActor
struct LMKNavigationControllerTests {
    @Test
    func `Installs self as interactive pop gesture delegate after viewDidLoad`() {
        let nav = LMKNavigationController(rootViewController: UIViewController())
        nav.loadViewIfNeeded()
        #expect(nav.interactivePopGestureRecognizer?.delegate === nav)
    }

    @Test
    func `Gesture should not begin on root view controller`() {
        let nav = LMKNavigationController(rootViewController: UIViewController())
        nav.loadViewIfNeeded()
        let recognizer = UIScreenEdgePanGestureRecognizer()
        #expect(!nav.gestureRecognizerShouldBegin(recognizer))
    }

    @Test
    func `Gesture should begin when a second view controller is pushed`() {
        let nav = LMKNavigationController(rootViewController: UIViewController())
        nav.loadViewIfNeeded()
        nav.pushViewController(UIViewController(), animated: false)
        let recognizer = UIScreenEdgePanGestureRecognizer()
        #expect(nav.gestureRecognizerShouldBegin(recognizer))
    }

    @Test
    func `Gesture should not begin after popping back to root`() {
        let nav = LMKNavigationController(rootViewController: UIViewController())
        nav.loadViewIfNeeded()
        nav.pushViewController(UIViewController(), animated: false)
        nav.popViewController(animated: false)
        let recognizer = UIScreenEdgePanGestureRecognizer()
        #expect(!nav.gestureRecognizerShouldBegin(recognizer))
    }

    @Test
    func `Works when system navigation bar is hidden`() {
        let nav = LMKNavigationController(rootViewController: UIViewController())
        nav.setNavigationBarHidden(true, animated: false)
        nav.loadViewIfNeeded()
        nav.pushViewController(UIViewController(), animated: false)
        let recognizer = UIScreenEdgePanGestureRecognizer()
        #expect(nav.gestureRecognizerShouldBegin(recognizer))
    }
}
