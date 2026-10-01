//
//  SceneDelegate.swift
//  LumiKitExample
//
//  Minimal example app demonstrating LumiKit design system, components, and controls.
//

import LumiKitCore
import LumiKitUI
import UIKit

@MainActor
final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }
        // A no-op on iOS; on Mac Catalyst it hides the title bar and floors the window size.
        LMKScene.configureMacWindow(for: windowScene, minimumSize: CGSize(width: 600, height: 700))
        // The theme was applied once in the AppDelegate; every scene shares it.
        let window = UIWindow(windowScene: windowScene)
        // LMKNavigationController keeps the edge swipe back working on pages that hide the system bar.
        let navigation = LMKNavigationController(rootViewController: ExampleViewController())
        window.rootViewController = navigation
        window.makeKeyAndVisible()
        self.window = window
        // Re-tier layouts when the window resizes (iPad multitasking, Mac window drags, iPhone Duo).
        geometryObservation = LMKDevice.observeScreenSize(of: window) { tier in
            LMKLogger.debug("Screen size tier: \(tier)", category: .ui)
        }
        // Window-level launch options (`-lmk-rtl`) and the scripted sweep, which runs in the first
        // scene only (see ExampleLaunchOptions).
        ExampleSweepRunner.start(ExampleLaunchOptions.current, window: window, navigation: navigation)
    }

    private var geometryObservation: LMKSceneGeometryObservation?
}
