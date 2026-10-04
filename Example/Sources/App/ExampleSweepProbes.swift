//
//  ExampleSweepProbes.swift
//  LumiKitExample
//
//  What the sweep taps on a page after auditing it, so presented UI (sheets,
//  pickers, toasts, tips, panels, pushed screens) is laid out, screenshotted,
//  and audited too. A probe is a path of control titles or accessibility
//  labels, tapped in order through `sendActions(for: .touchUpInside)`; it
//  exercises presentation, not the gesture that would trigger it. The step
//  `@end` scrolls the page to its end instead, for rows below the fold;
//  `@dismiss` dismisses the front-most presentation and `@pop` pops the
//  front-most stack, for what a screen looks like after coming back.
//

import LumiKitUI
import UIKit

@MainActor
enum ExampleSweepProbes {
    /// Probes per catalog page title. `-lmk-tap <title>` (repeatable) runs one more on a
    /// single `-lmk-page`.
    static let byPage: [String: [[String]]] = [
        "Floating Button": [["Show Floating Button"]],
        "Card Page": [["Show Multi-Page", "Push Settings Page", "Back"], ["Show No Items"]],
        "Navigation Controller": [["Present Demo Stack", "Push Screen 2"]],
        "Segmented Pages": [["Present Segmented Pages"]],
        "Tab Bar": [["Present Tab Bar"]],
        "Split View Inspector": [["Present Split View", "Toggle Inspector"]],
        "Glass": [["@end"]],
        "Text Field": [["@end"]],
        "Detail Cards": [["@end"]],
        "Loading State": [["@end"]],
        "Date Picker": [["Pick a Date"], ["Pick Date Range"], ["Pick Calendar Range"], ["Pick Date with Notes"]],
        "Toast": [["Show Success Toast"], ["Persistent toast at the bottom"], ["Toast over a sheet", "Show Toast Here"]],
        "Banners": [["Show Info Banner"]],
        "Alerts & Errors": [["Delete All (3s countdown)"], ["Show Text Input"]],
        "Progress": [["Show Determinate Progress"]],
        "Empty State": [["Toggle Action"]],
        "Tip View": [["Show Centered Tip"], ["Default"]],
        "Bottom Sheet": [["Show Sheet with Text Field"], ["Show Minimal Sheet"]],
        "Action Sheet": [["Show Action Sheet"], ["Show with Sub-Pages", "Edit Category"], ["Show with Date Picker"]],
        "Enum Picker": [["Theme: System"], ["Filters: 2 active"]],
        "Card Panel": [["Show Card Panel"], ["Show Combined", "Push Settings"]],
        "Photo Browser": [["Open Photo Browser"]],
        "Photo Crop": [["Open Photo Crop"]],
        "Share": [["Show Share Preview"]],
        "Network History": [["Open Network History"]],
    ]

    /// The step that scrolls instead of tapping.
    static let scrollToEnd = "@end"
    /// The step that dismisses the front-most presented controller, as its Close button would.
    static let dismissPresented = "@dismiss"
    /// The step that pops the front-most navigation stack, as its back button would.
    static let pop = "@pop"

    /// Runs a navigation step (`@dismiss`, `@pop`); `false` when `step` is not one or had nothing to act on.
    static func performNavigationStep(_ step: String, navigation: UINavigationController) -> Bool {
        var top = navigation.presentedViewController
        while let next = top?.presentedViewController {
            top = next
        }
        switch step {
        case dismissPresented:
            guard let top else { return false }
            top.dismiss(animated: true)
            return true
        case pop:
            let stack = (top as? UINavigationController) ?? top?.navigationController ?? (top == nil ? navigation : nil)
            return stack?.popViewController(animated: true) != nil
        default:
            return false
        }
    }

    /// Scrolls the first vertically scrolling view under `view` to its end; `false` when there is none.
    @discardableResult
    static func scrollToEnd(in view: UIView) -> Bool {
        if let scrollView = view as? UIScrollView, scrollView.contentSize.height > scrollView.bounds.height {
            let insets = scrollView.adjustedContentInset
            let bottom = scrollView.contentSize.height - scrollView.bounds.height + insets.bottom
            scrollView.setContentOffset(CGPoint(x: scrollView.contentOffset.x, y: max(-insets.top, bottom)), animated: false)
            return true
        }
        return view.subviews.contains { scrollToEnd(in: $0) }
    }

    /// The visible windows of `window`'s scene, front-most first.
    static func windows(of window: UIWindow) -> [UIWindow] {
        (window.windowScene?.windows ?? [window])
            .filter { !$0.isHidden }
            .sorted { $0.windowLevel > $1.windowLevel }
    }

    /// The windows a probe searches, front-most first: the scene's, then the windows of
    /// presented controllers that live outside it (a page sheet under the Mac idiom).
    static func searchWindows(from window: UIWindow, navigation: UINavigationController) -> [UIWindow] {
        var result = windows(of: window)
        var presented = navigation.presentedViewController
        while let controller = presented {
            if let presentedWindow = controller.viewIfLoaded?.window, !result.contains(presentedWindow) {
                result.insert(presentedWindow, at: 0)
            }
            presented = controller.presentedViewController
        }
        return result
    }

    /// The front-most enabled, visible control whose title or accessibility label is `title`.
    static func control(titled title: String, in windows: [UIWindow]) -> UIControl? {
        for window in windows {
            if let control = control(titled: title, under: window) { return control }
        }
        return nil
    }

    private static func control(titled title: String, under view: UIView) -> UIControl? {
        guard !view.isHidden, view.alpha > 0.01 else { return nil }
        // Later subviews draw on top, so they are searched first.
        for subview in view.subviews.reversed() {
            if let found = control(titled: title, under: subview) { return found }
        }
        guard let control = view as? UIControl, control.isEnabled else { return nil }
        let button = control as? UIButton
        let titles = [(control as? LMKButton)?.title, button?.configuration?.title, button?.currentTitle, control.accessibilityLabel]
        return titles.contains(title) ? control : nil
    }

    /// What a probe left on screen above `page`, for the audit: the top presented controller,
    /// an overlay window's content, a bottom sheet hosted as a child, a tip, or a toast.
    static func presentedContent(above page: UIViewController, navigation: UINavigationController, windows: [UIWindow]) -> UIView? {
        var top = navigation.presentedViewController
        while let next = top?.presentedViewController {
            top = next
        }
        if let top { return top.view }
        if let overlay = windows.first(where: { $0.windowLevel > .normal && $0.rootViewController != nil })?.rootViewController {
            return overlay.view
        }
        if navigation.topViewController !== page, let pushed = navigation.topViewController {
            return pushed.view
        }
        if let sheet = bottomSheet(in: page) {
            return sheet.view
        }
        for window in windows {
            if let tip = firstView(of: LMKTipView.self, under: window) { return tip }
            if let toast = firstView(of: LMKToastView.self, under: window) { return toast }
        }
        return nil
    }

    /// Dismisses what a probe presented, so the next probe (and the next page) starts clean.
    static func tearDown(page: UIViewController, navigation: UINavigationController, window: UIWindow) async {
        LMKToast.dismissAll()
        for candidate in windows(of: window) {
            if let panel = candidate.rootViewController as? LMKCardPanelViewController {
                panel.dismiss()
            }
            allViews(of: LMKTipView.self, under: candidate).forEach { $0.dismiss() }
        }
        if navigation.presentedViewController != nil {
            await withCheckedContinuation { continuation in
                navigation.dismiss(animated: false) { continuation.resume() }
            }
        }
        if let sheet = bottomSheet(in: page) {
            sheet.dismiss()
        }
        if navigation.topViewController !== page {
            navigation.popToViewController(page, animated: false)
        }
        try? await Task.sleep(for: .milliseconds(700))
    }

    // MARK: - Helpers

    private static func bottomSheet(in controller: UIViewController) -> LMKBottomSheetViewController? {
        for child in controller.children {
            if let sheet = child as? LMKBottomSheetViewController { return sheet }
            if let nested = bottomSheet(in: child) { return nested }
        }
        return nil
    }

    private static func firstView<View: UIView>(of type: View.Type, under view: UIView) -> View? {
        allViews(of: type, under: view).first
    }

    private static func allViews<View: UIView>(of type: View.Type, under view: UIView) -> [View] {
        var found: [View] = []
        if let match = view as? View, !match.isHidden { found.append(match) }
        for subview in view.subviews {
            found += allViews(of: type, under: subview)
        }
        return found
    }
}
