//
//  ExampleSweepRunner.swift
//  LumiKitExample
//
//  Drives the scripted sweep from the launch options: opens pages, waits for
//  layout, audits, writes screenshots, and exits when every page is done.
//

import LumiKitUI
import UIKit

@MainActor
enum ExampleSweepRunner {
    /// Applies the launch options to a connected window and starts the scripted flow, if any.
    static func start(_ options: ExampleLaunchOptions, window: UIWindow, navigation: UINavigationController) {
        if let theme = options.theme {
            LMKTheme.apply(ExampleThemes.theme(named: theme))
        }
        if options.rightToLeft {
            // Views created from here on (every catalog page) lay out right-to-left; the window
            // carries the iOS 26 alignment trait so natural text alignment follows.
            UIView.appearance().semanticContentAttribute = .forceRightToLeft
            window.lmk_forceLayoutDirection(.rightToLeft)
        }
        guard options.isScripted else { return }
        Task {
            await run(options, window: window, navigation: navigation)
        }
    }

    private static func run(_ options: ExampleLaunchOptions, window: UIWindow, navigation: UINavigationController) async {
        try? await Task.sleep(for: .milliseconds(400))
        if options.auditAll {
            for page in ExampleCatalog.pages {
                await audit(page: page, options: options, window: window, navigation: navigation)
            }
            print("AUDIT-DONE|\(options.configuration)|\(ExampleCatalog.pages.count) pages")
            try? await Task.sleep(for: .milliseconds(200))
            exit(0)
        }
        guard let title = options.page, let page = ExampleCatalog.pages.first(where: { $0.title == title }) else {
            if let title = options.page { print("AUDIT-ERROR|unknown page \(title)") }
            return
        }
        await audit(page: page, options: options, window: window, navigation: navigation, pops: false)
        if options.audit {
            print("AUDIT-DONE|\(options.configuration)|1 page")
        }
    }

    private static func audit(page: ExampleCatalog.Page, options: ExampleLaunchOptions, window: UIWindow, navigation: UINavigationController, pops: Bool = true) async {
        let controller = page.make()
        controller.title = page.title
        navigation.pushViewController(controller, animated: false)
        // Two runloop turns: one for the push to lay out, one for async content (images, dates).
        try? await Task.sleep(for: .milliseconds(500))
        controller.view.layoutIfNeeded()
        try? await Task.sleep(for: .milliseconds(150))

        if let directory = options.screenshotDirectory {
            writeScreenshot(of: window, page: page.title, options: options, directory: directory)
        }
        if options.audit || options.auditAll {
            let findings = ExampleAccessibilityAudit.run(on: controller.view, in: window)
            for finding in findings {
                print("AUDIT|\(options.configuration)|\(page.title)|\(finding)")
            }
            print("AUDIT-PAGE|\(options.configuration)|\(page.title)|\(findings.count) findings")
        }
        if pops {
            navigation.popViewController(animated: false)
            try? await Task.sleep(for: .milliseconds(100))
        }
    }

    private static func writeScreenshot(of window: UIWindow, page: String, options: ExampleLaunchOptions, directory: String) {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let image = UIGraphicsImageRenderer(bounds: window.bounds, format: format).image { _ in
            window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
        }
        let folder = URL(fileURLWithPath: directory).appendingPathComponent(options.configuration)
        let name = page.replacingOccurrences(of: "[^A-Za-z0-9]+", with: "-", options: .regularExpression)
        do {
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            try image.pngData()?.write(to: folder.appendingPathComponent("\(name).png"))
        } catch {
            print("AUDIT-ERROR|screenshot \(page): \(error.localizedDescription)")
        }
    }
}
