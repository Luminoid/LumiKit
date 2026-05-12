//
//  UITableViewCell+LMKHighlight.swift
//  LumiKit
//
//  `selectedBackgroundView`-based highlight for plain `UITableViewCell`
//  instances that aren't worth subclassing — typically cells driven by
//  `defaultContentConfiguration`. For custom cell subclasses (and for
//  `UICollectionViewCell`), use the `LMKHighlightable` protocol API in
//  `LMKHighlightable.swift` instead.
//

import UIKit

public extension UITableViewCell {
    /// Configure a plain `UITableViewCell` with the LumiKit highlight via
    /// `selectedBackgroundView`. Use this on dequeue for cells that aren't
    /// subclassed. `UICollectionViewCell` has no `selectedBackgroundView`,
    /// so this helper is UITableViewCell-only — collection cells must
    /// subclass and route through `lmk_applyCustomHighlight`.
    func lmk_configureCustomHighlight() {
        let selectedBgView = UIView()
        selectedBgView.backgroundColor = LMKHighlightConstants.highlightOverlayColor
        selectedBackgroundView = selectedBgView
    }
}

public extension UITableView {
    /// Configure a standard `UITableViewCell` with custom highlight.
    func lmk_configureCellHighlight(_ cell: UITableViewCell) {
        cell.lmk_configureCustomHighlight()
    }
}
