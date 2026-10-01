//
//  ExampleSweepRunner.swift
//  LumiKitExample
//
//  Drives the scripted sweep from the launch options: opens pages, waits for
//  layout, audits, writes screenshots, and exits when every page is done.
//  The exit status is 0 when no page reported an error-level finding, 1 when
//  one did, and 2 for a bad argument, so a script can gate on it.
//

import LumiKitCore
import LumiKitUI
import UIKit

@MainActor
enum ExampleSweepRunner {
    /// The scripted run, once started; a second scene (iPad, Mac) never starts another.
    private static var runTask: Task<Void, Never>?

    /// Applies the launch options that must precede any view: the theme, and the right-to-left
    /// appearance proxy, which a view reads when it is created. Called from the AppDelegate.
    static func applyLaunchAppearance(_ options: ExampleLaunchOptions) {
        // Line-buffer stdout so piped `AUDIT|…` lines survive a crash mid-sweep.
        setvbuf(stdout, nil, _IOLBF, 0)
        if let name = options.theme {
            if let theme = ExampleThemes.theme(named: name) {
                LMKTheme.apply(theme)
            } else if options.isScripted {
                print("AUDIT-ERROR|unknown theme \(name); expected one of \(ExampleThemes.names.joined(separator: ", "))")
                exit(2)
            } else {
                LMKLogger.warning("Unknown -lmk-theme \(name); using the example theme", category: .ui)
                LMKTheme.apply(.example)
            }
        } else {
            LMKTheme.apply(.example)
        }
        if options.rightToLeft {
            UIView.appearance().semanticContentAttribute = .forceRightToLeft
        }
    }

    /// Applies the window-level options to a connected scene and starts the scripted flow, if any,
    /// for the first scene only.
    static func start(_ options: ExampleLaunchOptions, window: UIWindow, navigation: UINavigationController) {
        if options.rightToLeft {
            // The window carries the iOS 26 alignment trait so natural text alignment follows.
            window.lmk_forceLayoutDirection(.rightToLeft)
        }
        guard options.isScripted, runTask == nil else { return }
        runTask = Task {
            await run(options, window: window, navigation: navigation)
        }
    }

    private static func run(_ options: ExampleLaunchOptions, window: UIWindow, navigation: UINavigationController) async {
        try? await Task.sleep(for: .milliseconds(400))
        if options.auditAll {
            var errors = 0
            for page in ExampleCatalog.pages {
                errors += await audit(page: page, options: options, window: window, navigation: navigation)
            }
            print("AUDIT-DONE|\(options.configuration)|\(ExampleCatalog.pages.count) pages|\(errors) errors")
            try? await Task.sleep(for: .milliseconds(200))
            exit(errors > 0 ? 1 : 0)
        }
        guard let title = options.page else {
            print("AUDIT-ERROR|-lmk-audit needs -lmk-page <title>")
            exit(2)
        }
        guard let page = ExampleCatalog.pages.first(where: { $0.title == title }) else {
            print("AUDIT-ERROR|unknown page \(title)")
            exit(2)
        }
        var errors = await audit(page: page, options: options, window: window, navigation: navigation, pops: false)
        if let controller = navigation.topViewController, !options.taps.isEmpty {
            errors += await probe(options.taps, on: controller, page: page, options: options, window: window, navigation: navigation)
        }
        guard options.audit else { return }
        print("AUDIT-DONE|\(options.configuration)|1 page|\(errors) errors")
        try? await Task.sleep(for: .milliseconds(200))
        exit(errors > 0 ? 1 : 0)
    }

    /// Pushes `page`, audits it (in the sweep, also what its probes present), and returns the
    /// number of error-level findings.
    private static func audit(page: ExampleCatalog.Page, options: ExampleLaunchOptions, window: UIWindow, navigation: UINavigationController, pops: Bool = true) async -> Int {
        let controller = page.make()
        controller.title = page.title
        navigation.pushViewController(controller, animated: false)
        // One turn for the push to lay out, then long enough for the pages' async content (the
        // list row's one-second image load, the image utilities' decode) to land.
        try? await Task.sleep(for: .milliseconds(1200))
        controller.view.layoutIfNeeded()
        try? await Task.sleep(for: .milliseconds(150))

        if let directory = options.screenshotDirectory {
            writeScreenshot(of: window, page: page.title, options: options, directory: directory)
        }
        var errors = 0
        if options.audit || options.auditAll {
            errors += report(ExampleAccessibilityAudit.run(on: controller.view, in: window), label: page.title, options: options)
        }
        if pops {
            for path in ExampleSweepProbes.byPage[page.title] ?? [] {
                errors += await probe(path, on: controller, page: page, options: options, window: window, navigation: navigation)
                await ExampleSweepProbes.tearDown(page: controller, navigation: navigation, window: window)
            }
            navigation.popViewController(animated: false)
            try? await Task.sleep(for: .milliseconds(100))
        }
        return errors
    }

    /// Taps `path` in order on `controller`, then screenshots and audits what is on top.
    private static func probe(
        _ path: [String],
        on controller: UIViewController,
        page: ExampleCatalog.Page,
        options: ExampleLaunchOptions,
        window: UIWindow,
        navigation: UINavigationController
    ) async -> Int {
        let label = ([page.title] + path).joined(separator: " > ")
        for step in path {
            if step == ExampleSweepProbes.scrollToEnd {
                ExampleSweepProbes.scrollToEnd(in: controller.view)
                try? await Task.sleep(for: .milliseconds(500))
                continue
            }
            guard let control = ExampleSweepProbes.control(titled: step, in: ExampleSweepProbes.searchWindows(from: window, navigation: navigation)) else {
                print("AUDIT|\(options.configuration)|\(label)|error|probe|\(step)|no enabled control with this title or label")
                return 1
            }
            control.sendActions(for: .touchUpInside)
            // Long enough for a presentation or a push to settle and its content to load.
            try? await Task.sleep(for: .milliseconds(1300))
        }
        let windows = ExampleSweepProbes.searchWindows(from: window, navigation: navigation)
        let content = ExampleSweepProbes.presentedContent(above: controller, navigation: navigation, windows: windows)
        if let directory = options.screenshotDirectory {
            writeScreenshot(of: window, page: label, options: options, directory: directory)
            // A sheet the Mac idiom hosts in a window of its own gets an image of its own.
            if let sheetWindow = content?.window, !ExampleSweepProbes.windows(of: window).contains(sheetWindow) {
                writeScreenshot(of: [sheetWindow], bounds: sheetWindow.bounds, page: label + " (sheet window)", options: options, directory: directory)
            }
        }
        guard options.audit || options.auditAll else { return 0 }
        guard let content, let contentWindow = content.window else {
            print("AUDIT-PAGE|\(options.configuration)|\(label)|nothing presented")
            return 0
        }
        return report(ExampleAccessibilityAudit.run(on: content, in: contentWindow), label: label, options: options)
    }

    /// Prints `findings` under `label` and returns the number of errors among them.
    private static func report(_ findings: [ExampleAccessibilityAudit.Finding], label: String, options: ExampleLaunchOptions) -> Int {
        for finding in findings {
            print("AUDIT|\(options.configuration)|\(label)|\(finding)")
        }
        print("AUDIT-PAGE|\(options.configuration)|\(label)|\(findings.count) findings")
        return findings.count(where: { $0.severity == .error })
    }

    /// Draws every visible window of the scene, back to front, so an overlay window (a card
    /// panel) shows in the image too.
    private static func writeScreenshot(of window: UIWindow, page: String, options: ExampleLaunchOptions, directory: String) {
        writeScreenshot(of: Array(ExampleSweepProbes.windows(of: window).reversed()), bounds: window.bounds, page: page, options: options, directory: directory)
    }

    private static func writeScreenshot(of windows: [UIWindow], bounds: CGRect, page: String, options: ExampleLaunchOptions, directory: String) {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let image = UIGraphicsImageRenderer(bounds: bounds, format: format).image { _ in
            for candidate in windows {
                candidate.drawHierarchy(in: windows.count == 1 ? candidate.bounds : candidate.frame, afterScreenUpdates: true)
            }
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
