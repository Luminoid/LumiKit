//
//  UIViewController+LMKPopover.swift
//  LumiKit
//
//  Popover presentation helpers for iPad action sheet support.
//

import UIKit

extension UIViewController {
    /// Centered popover source rect for presenting popovers from the center of the view.
    public var lmk_centeredPopoverSourceRect: CGRect {
        CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
    }

    /// Configures an action-sheet alert for iPad popover presentation.
    /// Call before presenting any `UIAlertController` with `.actionSheet` to avoid crashes on iPad.
    public func lmk_configurePopoverForActionSheet(_ alert: UIAlertController) {
        guard alert.preferredStyle == .actionSheet,
              let popover = alert.popoverPresentationController else { return }
        popover.sourceView = view
        popover.sourceRect = lmk_centeredPopoverSourceRect
        popover.permittedArrowDirections = []
    }
}
