//
//  LMKListTable.swift
//  LumiKit
//
//  The one list-table setup, so screens cannot drift on background, sizing,
//  or readable-width margins.
//

import UIKit

/// Table view builders for list screens.
public enum LMKListTable {
    /// The reuse identifier `make(style:...)` registers a plain `UITableViewCell` under.
    public static let cellReuseIdentifier = "LMKListTableCell"

    /// An inset-grouped table on `backgroundPrimary` with automatic row heights (estimated at
    /// `LMKLayout.rowHeightEstimated`), readable-width cell margins, and a plain cell registered
    /// under `cellReuseIdentifier` for `lmk_applyListRow` rows.
    public static func makeInsetGrouped(dataSource: UITableViewDataSource? = nil, delegate: UITableViewDelegate? = nil) -> UITableView {
        make(style: .insetGrouped, dataSource: dataSource, delegate: delegate)
    }

    /// `makeInsetGrouped` in any table style.
    public static func make(style: UITableView.Style, dataSource: UITableViewDataSource? = nil, delegate: UITableViewDelegate? = nil, registersDefaultCell: Bool = true) -> UITableView {
        let tableView = UITableView(frame: .zero, style: style)
        tableView.backgroundColor = LMKColor.backgroundPrimary
        tableView.dataSource = dataSource
        tableView.delegate = delegate
        tableView.rowHeight = UITableView.automaticDimension
        // A static builder without a theme argument; the estimate is a layout hint read once at creation.
        // swiftlint:disable:next no_global_token_proxies_in_components
        tableView.estimatedRowHeight = LMKLayout.rowHeightEstimated
        tableView.cellLayoutMarginsFollowReadableWidth = true
        if registersDefaultCell {
            tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellReuseIdentifier)
        }
        return tableView
    }
}
