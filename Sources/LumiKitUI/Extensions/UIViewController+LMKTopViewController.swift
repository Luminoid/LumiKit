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

        if let nav = root as? UINavigationController {
            return lmk_topViewController(controller: nav.visibleViewController)
        }
        if let tab = root as? UITabBarController, let selected = tab.selectedViewController {
            return lmk_topViewController(controller: selected)
        }
        if let presented = root.presentedViewController {
            return lmk_topViewController(controller: presented)
        }
        return root
    }

    /// Present an alert on the top-most view controller.
    func lmk_presentAlertOnTop(_ alert: UIAlertController, animated: Bool = true) {
        let presenter = Self.lmk_topViewController(controller: nil) ?? self
        if alert.preferredStyle == .actionSheet, alert.popoverPresentationController?.sourceView == nil || presenter != self {
            presenter.lmk_configurePopoverForActionSheet(alert)
        }
        presenter.present(alert, animated: animated)
    }
}
