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
}
