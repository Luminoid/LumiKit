//
//  UIDiffableDataSource+LMKApply.swift
//  LumiKit
//
//  Snapshot application that stays lazy while the list is off screen.
//

import UIKit

public extension UITableViewDiffableDataSource {
    /// Applies `snapshot`, diffing (and optionally animating) only while `view` is in a
    /// window. A detached list still receives data changes — a page its container swapped
    /// out, another tab's root — and `apply(_:animatingDifferences:)` there runs a batch
    /// update that forces layout outside the view hierarchy; UIKit logs
    /// `UITableViewAlertForLayoutOutsideViewHierarchy` once per process and then stays
    /// silent while the wasted passes continue. Off screen, the snapshot lands through
    /// `applySnapshotUsingReloadData`, which defers every layout to the next pass in a window.
    ///
    /// - Parameters:
    ///   - snapshot: The snapshot to apply.
    ///   - animatingDifferences: Whether to animate on-screen changes. Pass
    ///     `LMKAnimationHelper.shouldAnimate` to honor Reduce Motion.
    ///   - view: The table view this data source drives, or any view in its hierarchy.
    func lmk_apply(
        _ snapshot: NSDiffableDataSourceSnapshot<SectionIdentifierType, ItemIdentifierType>,
        animatingDifferences: Bool,
        in view: UIView
    ) {
        if view.window == nil {
            applySnapshotUsingReloadData(snapshot)
        } else {
            apply(snapshot, animatingDifferences: animatingDifferences)
        }
    }
}

public extension UICollectionViewDiffableDataSource {
    /// Collection-view counterpart of the table-view `lmk_apply(_:animatingDifferences:in:)`:
    /// diffs on screen, reloads off screen so a detached list never lays out outside a window.
    func lmk_apply(
        _ snapshot: NSDiffableDataSourceSnapshot<SectionIdentifierType, ItemIdentifierType>,
        animatingDifferences: Bool,
        in view: UIView
    ) {
        if view.window == nil {
            applySnapshotUsingReloadData(snapshot)
        } else {
            apply(snapshot, animatingDifferences: animatingDifferences)
        }
    }
}
