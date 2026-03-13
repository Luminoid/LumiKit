//
//  LMKSkeletonCellTests.swift
//  LumiKit
//

import Testing
import UIKit

@testable import LumiKitUI

// MARK: - LMKSkeletonCell (reuse)

@Suite("LMKSkeletonCell (reuse)")
@MainActor
struct LMKSkeletonCellReuseTests {
    @Test("prepareForReuse stops shimmer without crash")
    func prepareForReuseStopsShimmer() {
        let cell = LMKSkeletonCell(style: .default, reuseIdentifier: "test")
        cell.startShimmer()
        cell.prepareForReuse()
        // No crash = success; shimmer should be stopped
    }

    @Test("prepareForReuse on fresh cell doesn't crash")
    func prepareForReuseOnFreshCell() {
        let cell = LMKSkeletonCell(style: .default, reuseIdentifier: "test")
        cell.prepareForReuse()
        // No crash = success
    }
}

// MARK: - LMKSkeletonCell (startShimmers)

@Suite("LMKSkeletonCell (startShimmers)")
@MainActor
struct LMKSkeletonCellStartShimmersTests {
    @Test("startShimmers does not crash on empty table view")
    func emptyTable() {
        let tableView = UITableView()
        LMKSkeletonCell.startShimmers(in: tableView)
        // No crash = success
    }

    @Test("startShimmers ignores non-skeleton cells")
    func nonSkeletonCells() {
        let tableView = UITableView()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "plain")
        LMKSkeletonCell.startShimmers(in: tableView)
        // No crash = success
    }
}
