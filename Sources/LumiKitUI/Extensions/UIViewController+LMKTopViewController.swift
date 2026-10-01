//
//  UIViewController+LMKTopViewController.swift
//  LumiKit
//
//  Extension to find the top-most view controller for presenting errors.
//

import UIKit

public extension UIViewController {
    /// The top-most view controller under `controller` (walks navigation and tab containers and
    /// presented controllers); with no `controller`, starts at the key window's root
    /// (`LMKScene.keyWindow`).
    static func lmk_topViewController(controller: UIViewController? = nil) -> UIViewController? {
        guard let root = controller ?? LMKScene.keyWindow?.rootViewController else { return nil }
        return lmk_topViewController(from: root)
    }

    /// Present an alert on the top-most view controller. An action sheet keeps the popover
    /// anchor the caller set; one without an anchor, or whose anchor is not in the presenter's
    /// window, is centered on the presenter.
    func lmk_presentAlertOnTop(_ alert: UIAlertController, animated: Bool = true) {
        let presenter = Self.lmk_topViewController(controller: nil) ?? self
        if alert.preferredStyle == .actionSheet, let popover = alert.popoverPresentationController {
            let isAnchored: Bool = if let sourceView = popover.sourceView {
                sourceView.window != nil && sourceView.window === presenter.viewIfLoaded?.window
            } else {
                popover.barButtonItem != nil || popover.sourceItem != nil
            }
            if !isAnchored {
                presenter.lmk_configurePopoverForActionSheet(alert)
            }
        }
        presenter.present(alert, animated: animated)
    }

    /// The top-most controller under a resolved root: a container with nothing visible or
    /// selected is itself the top (no restart from the key window, which would recurse forever).
    private static func lmk_topViewController(from root: UIViewController) -> UIViewController {
        if let nav = root as? UINavigationController, let visible = nav.visibleViewController {
            return lmk_topViewController(from: visible)
        }
        if let tab = root as? UITabBarController, let selected = tab.selectedViewController {
            return lmk_topViewController(from: selected)
        }
        if let presented = root.presentedViewController {
            return lmk_topViewController(from: presented)
        }
        return root
    }
}
