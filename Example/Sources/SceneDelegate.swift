//
//  SceneDelegate.swift
//  LumiKitExample
//
//  Minimal example app demonstrating LumiKit design system, components, and controls.
//

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
        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = UINavigationController(rootViewController: ExampleViewController())
        window.makeKeyAndVisible()
        self.window = window
    }
}
