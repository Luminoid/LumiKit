//
//  UIViewController+LMKTopViewController.swift
//  LumiKit
//
//  Extension to find the top-most view controller for presenting errors.
//

import UIKit

extension UIViewController {
    /// Get the top-most view controller in the view hierarchy.
    public static func lmk_topViewController(controller: UIViewController? = nil) -> UIViewController? {
        let rootViewController: UIViewController?
        if let controller {
            rootViewController = controller
        } else {
            rootViewController = UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap(\.windows)
                .first { $0.isKeyWindow }?
                .rootViewController
        }

        guard let root = rootViewController else { return nil }

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
    public func lmk_presentAlertOnTop(_ alert: UIAlertController, animated: Bool = true) {
        let presenter = Self.lmk_topViewController(controller: nil) ?? self
        if alert.preferredStyle == .actionSheet, alert.popoverPresentationController?.sourceView == nil || presenter != self {
            presenter.lmk_configurePopoverForActionSheet(alert)
        }
        presenter.present(alert, animated: animated)
    }
}
