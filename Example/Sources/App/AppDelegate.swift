//
//  AppDelegate.swift
//  LumiKitExample
//
//  Minimal example app demonstrating LumiKit design system, components, and controls.
//

import LumiKitDebug
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
        // The brand theme is registered once here, before any scene connects, so a second window
        // (iPad, Mac) never resets a theme picked in Theme Switcher. `-lmk-theme` and `-lmk-rtl`
        // override it for a scripted run (see ExampleLaunchOptions).
        ExampleSweepRunner.applyLaunchAppearance(ExampleLaunchOptions.current)
        #if DEBUG
            // LMKNetworkLogger is configured once at launch; the Network History page only sends
            // traffic through it.
            LMKNetworkLogger.configure(LMKNetworkLogger.Configuration(maxRecords: 50))
            LMKNetworkLogger.enable()
        #endif
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
