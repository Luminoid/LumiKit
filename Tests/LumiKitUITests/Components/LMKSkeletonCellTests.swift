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
