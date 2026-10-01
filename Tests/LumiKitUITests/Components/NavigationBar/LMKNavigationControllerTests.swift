//
//  LMKNavigationControllerTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

@MainActor
struct LMKNavigationControllerTests {
    private final class OptingOutViewController: UIViewController, LMKPopGestureConfiguring {
        var prefersPopGestureDisabled = true
    }

    private func shouldBegin(_ navigation: LMKNavigationController) -> Bool? {
        guard let recognizer = navigation.interactivePopGestureRecognizer, let delegate = recognizer.delegate else { return nil }
        return delegate.gestureRecognizerShouldBegin?(recognizer)
    }

    @Test
    func `Installs a private delegate on the pop gesture after viewDidLoad`() {
        let navigation = LMKNavigationController(rootViewController: UIViewController())
        navigation.loadViewIfNeeded()
        let delegate = navigation.interactivePopGestureRecognizer?.delegate
        #expect(delegate != nil)
        #expect(delegate !== navigation, "the controller exposes no gesture-delegate surface")
    }

    @Test
    func `The gesture begins only with a screen below the top`() {
        let navigation = LMKNavigationController(rootViewController: UIViewController())
        navigation.setNavigationBarHidden(true, animated: false)
        navigation.loadViewIfNeeded()
        #expect(!navigation.canBeginPopGesture)
        #expect(shouldBegin(navigation) == false)

        navigation.pushViewController(UIViewController(), animated: false)
        #expect(navigation.canBeginPopGesture)
        #expect(shouldBegin(navigation) == true)

        navigation.popViewController(animated: false)
        #expect(!navigation.canBeginPopGesture)
    }

    @Test
    func `The gesture waits for a push or pop in flight`() throws {
        let navigation = LMKNavigationController(rootViewController: UIViewController())
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        window.rootViewController = navigation
        window.makeKeyAndVisible()
        defer { window.isHidden = true }
        window.layoutIfNeeded()
        navigation.pushViewController(UIViewController(), animated: true)
        try #require(navigation.transitionCoordinator != nil, "the animated push is in flight")
        #expect(navigation.viewControllers.count == 2)
        #expect(!navigation.canBeginPopGesture)
        #expect(shouldBegin(navigation) == false)
    }

    @Test
    func `The top screen answers for the status bar`() {
        let navigation = LMKNavigationController(rootViewController: UIViewController())
        let top = UIViewController()
        navigation.pushViewController(top, animated: false)
        #expect(navigation.childForStatusBarStyle === top)
        #expect(navigation.childForStatusBarHidden === top)
    }

    @Test
    func `A top screen can opt out through LMKPopGestureConfiguring`() {
        let navigation = LMKNavigationController(rootViewController: UIViewController())
        navigation.loadViewIfNeeded()
        let screen = OptingOutViewController()
        navigation.pushViewController(screen, animated: false)
        #expect(!navigation.canBeginPopGesture)
        #expect(shouldBegin(navigation) == false)
        screen.prefersPopGestureDisabled = false
        #expect(navigation.canBeginPopGesture)
    }

    @Test
    @available(iOS 26, *)
    func `The iOS 26 content pop gesture follows the same rule and leaves a host's own disable alone`() throws {
        let navigation = LMKNavigationController(rootViewController: UIViewController())
        navigation.loadViewIfNeeded()
        let recognizer = try #require(navigation.interactiveContentPopGestureRecognizer)
        #expect(!recognizer.isEnabled, "nothing to pop to on the root")

        let screen = OptingOutViewController()
        navigation.pushViewController(screen, animated: false)
        #expect(!recognizer.isEnabled, "the top screen opts out")
        screen.prefersPopGestureDisabled = false
        navigation.updateContentPopGesture()
        #expect(recognizer.isEnabled)

        recognizer.isEnabled = false
        navigation.updateContentPopGesture()
        #expect(!recognizer.isEnabled, "a host's own disable is respected")
    }
}
