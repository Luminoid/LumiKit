//
//  UISplitViewController+LMKInspector.swift
//  LumiKit
//
//  The iOS 26 inspector column behind one API that is inert on the floor.
//

import UIKit

public extension UISplitViewController {
    /// Installs `viewController` as the inspector column (iOS 26): a trailing pane on iPad and
    /// Mac for the selected item's details, shown and hidden with `lmk_setInspectorShown(_:)`.
    ///
    /// Before iOS 26 there is no inspector column; the call stores nothing and
    /// `lmk_isShowingInspector` stays `false`, so a host that wants details on iOS 18 presents
    /// them itself (a sheet, a popover) when `lmk_supportsInspector` is `false`.
    ///
    /// - Parameters:
    ///   - viewController: The inspector's content; `nil` removes the column.
    ///   - preferredWidth: Absolute width of the column; `nil` = the system default.
    func lmk_setInspector(_ viewController: UIViewController?, preferredWidth: CGFloat? = nil) {
        guard #available(iOS 26, *) else { return }
        setViewController(viewController, for: .inspector)
        if let preferredWidth {
            preferredInspectorColumnWidth = preferredWidth
        }
    }

    /// Whether the inspector column exists on this OS (iOS 26 and later).
    var lmk_supportsInspector: Bool {
        if #available(iOS 26, *) { true } else { false }
    }

    /// The inspector column's content, `nil` before iOS 26 or when none is set.
    var lmk_inspector: UIViewController? {
        guard #available(iOS 26, *) else { return nil }
        return viewController(for: .inspector)
    }

    /// Whether the inspector column is currently shown (`false` before iOS 26).
    var lmk_isShowingInspector: Bool {
        guard #available(iOS 26, *) else { return false }
        return isShowing(.inspector)
    }

    /// Shows or hides the inspector column; no-op before iOS 26 or without an inspector.
    func lmk_setInspectorShown(_ shown: Bool) {
        guard #available(iOS 26, *), viewController(for: .inspector) != nil else { return }
        if shown {
            show(.inspector)
        } else {
            hide(.inspector)
        }
    }

    /// Toggles the inspector column; no-op before iOS 26 or without an inspector.
    func lmk_toggleInspector() {
        lmk_setInspectorShown(!lmk_isShowingInspector)
    }
}
