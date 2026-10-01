//
//  LMKTip.swift
//  LumiKit
//
//  The tip presenter: one `show` entry point that builds and shows an `LMKTipView`.
//

import UIKit

/// Tip presentation.
public enum LMKTip {
    /// Shows a tip over `viewController`'s view.
    @discardableResult
    public static func show(
        title: String? = nil,
        message: String,
        icon: UIImage? = nil,
        placement: LMKTipView.Placement = .center,
        style: LMKTipView.Style = LMKTipView.Style(),
        in viewController: UIViewController,
        onDismiss: (() -> Void)? = nil
    ) -> LMKTipView {
        let tip = LMKTipView(title: title, message: message, icon: icon, style: style)
        tip.onDismiss = onDismiss
        tip.show(placement: placement, in: viewController)
        return tip
    }
}
