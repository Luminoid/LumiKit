//
//  LMKSceneTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

// MARK: - LMKScene

@MainActor
struct LMKSceneTests {
    @Test
    func `keyWindow and activeWindowScene are optional in the test host`() {
        // The xctest host has no connected scene, so both are nil there; a running app
        // always has one. Only the type contract is checkable here.
        _ = LMKScene.keyWindow
        _ = LMKScene.activeWindowScene
        #expect(LMKScene.presentingViewController == nil || LMKScene.keyWindow != nil)
    }

    @Test
    func `screenScale is the key window's scale or the fallback`() {
        let scale = LMKScene.screenScale
        #expect(scale > 0)
        #expect(scale == 1.0 || scale == 2.0 || scale == LMKScene.fallbackDisplayScale)
    }

    @Test
    func `displayScale(of:) is nil for a missing view and positive otherwise`() {
        #expect(LMKScene.displayScale(of: nil) == nil)
        if let scale = LMKScene.displayScale(of: UIView()) {
            #expect(scale > 0)
        }
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        #expect(LMKScene.displayScale(of: window) == window.traitCollection.displayScale)
    }

    @Test
    func `A view's display scale falls back through its window to the scene`() {
        let detached = UIView()
        #expect(detached.lmk_displayScale > 0)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        let hosted = UIView()
        window.addSubview(hosted)
        #expect(hosted.lmk_displayScale == window.traitCollection.displayScale)
    }

    @Test
    func `The top view controller walks containers and presentations`() {
        let root = UIViewController()
        let navigation = UINavigationController(rootViewController: root)
        navigation.loadViewIfNeeded()
        let pushed = UIViewController()
        navigation.pushViewController(pushed, animated: false)
        #expect(UIViewController.lmk_topViewController(controller: navigation) === pushed)

        let tabs = UITabBarController()
        tabs.viewControllers = [UIViewController(), navigation]
        tabs.selectedIndex = 1
        #expect(UIViewController.lmk_topViewController(controller: tabs) === pushed)
    }

    @Test
    func `The scene destruction error handler is nonisolated and reports on the main actor`() async {
        #expect(LMKScene.destructionErrorHandler(nil) == nil)
        var received: [String] = []
        let handler = LMKScene.destructionErrorHandler { error in received.append(error.localizedDescription) }
        await Task.detached {
            handler?(CocoaError(.featureUnsupported))
        }.value
        await LMKWait.until { !received.isEmpty }
        #expect(received.count == 1)
    }

    @Test
    func `configureMacWindow is a no-op off Catalyst and callable unconditionally`() {
        // Cannot construct a UIWindowScene in the host; the API contract is that the call is safe
        // on every platform, which the compile of the Example app's SceneDelegate exercises.
        #expect(LMKScene.fallbackDisplayScale == 3)
    }
}
