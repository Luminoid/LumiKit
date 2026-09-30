//
//  AppDelegate.swift
//  LumiKitExample
//
//  Minimal example app demonstrating LumiKit design system, components, and controls.
//

import UIKit

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // The scripted sweep runs headless; an uncaught ObjC exception would otherwise die inside
        // AppKit's transaction flush on Mac Catalyst with no reason in the crash report.
        NSSetUncaughtExceptionHandler { exception in
            let report = "AUDIT-EXCEPTION|\(exception.name.rawValue)|\(exception.reason ?? "")\n" + exception.callStackSymbols.prefix(24).joined(separator: "\n")
            FileHandle.standardError.write(Data((report + "\n").utf8))
        }
        return true
    }

    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        let config = UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
        config.delegateClass = SceneDelegate.self
        return config
    }
}
