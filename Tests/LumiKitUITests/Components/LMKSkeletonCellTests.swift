//
//  LMKSkeletonCellTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

// MARK: - LMKSkeletonCell (reuse)

@MainActor
struct LMKSkeletonCellReuseTests {
    @Test
    func `prepareForReuse stops shimmer without crash`() {
        let cell = LMKSkeletonCell(style: .default, reuseIdentifier: "test")
        cell.startShimmer()
        cell.prepareForReuse()
        // No crash = success; shimmer should be stopped
    }

    @Test
    func `prepareForReuse on fresh cell doesn't crash`() {
        let cell = LMKSkeletonCell(style: .default, reuseIdentifier: "test")
        cell.prepareForReuse()
        // No crash = success
    }
}

// MARK: - LMKSkeletonCell (startShimmers)

@MainActor
struct LMKSkeletonCellStartShimmersTests {
    @Test
    func `startShimmers does not crash on empty table view`() {
        let tableView = UITableView()
        LMKSkeletonCell.startShimmers(in: tableView)
        // No crash = success
    }

    @Test
    func `startShimmers ignores non-skeleton cells`() {
        let tableView = UITableView()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "plain")
        LMKSkeletonCell.startShimmers(in: tableView)
        // No crash = success
    }
}
