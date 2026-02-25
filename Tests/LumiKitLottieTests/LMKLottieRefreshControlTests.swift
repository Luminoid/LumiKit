//
//  LMKLottieRefreshControlTests.swift
//  LumiKit
//

import Testing
import UIKit

@testable import LumiKitLottie

@Suite("LMKLottieRefreshControl")
@MainActor
struct LMKLottieRefreshControlTests {
    // MARK: - Initialization

    @Test("Initializes successfully")
    func initializesSuccessfully() {
        let refreshControl = LMKLottieRefreshControl()

        #expect(refreshControl.isRefreshing == false)
    }

    // MARK: - Refresh State

    @Test("Begins refreshing completes without crashing")
    func beginsRefreshing() {
        let scrollView = UIScrollView(frame: CGRect(x: 0, y: 0, width: 375, height: 667))
        let refreshControl = LMKLottieRefreshControl()
        scrollView.refreshControl = refreshControl

        refreshControl.beginRefreshing()

        // Test completes successfully (actual refresh state requires visible hierarchy)
    }

    @Test("Ends refreshing")
    func endsRefreshing() {
        let scrollView = UIScrollView(frame: CGRect(x: 0, y: 0, width: 375, height: 667))
        let refreshControl = LMKLottieRefreshControl()
        scrollView.refreshControl = refreshControl

        refreshControl.beginRefreshing()
        refreshControl.endRefreshing()

        #expect(refreshControl.isRefreshing == false)
    }

    @Test("Initial state is not refreshing")
    func initialStateNotRefreshing() {
        let refreshControl = LMKLottieRefreshControl()

        #expect(refreshControl.isRefreshing == false)
    }

    // MARK: - Scroll View Integration

    @Test("Can be added to scroll view")
    func canBeAddedToScrollView() {
        let scrollView = UIScrollView(frame: CGRect(x: 0, y: 0, width: 375, height: 667))
        let refreshControl = LMKLottieRefreshControl()

        scrollView.refreshControl = refreshControl

        #expect(scrollView.refreshControl != nil)
    }

    @Test("Can be added to table view")
    func canBeAddedToTableView() {
        let tableView = UITableView(frame: CGRect(x: 0, y: 0, width: 375, height: 667))
        let refreshControl = LMKLottieRefreshControl()

        tableView.refreshControl = refreshControl

        #expect(tableView.refreshControl != nil)
    }

    // MARK: - Multiple Cycles

    @Test("Handles multiple refresh cycles")
    func handlesMultipleRefreshCycles() {
        let scrollView = UIScrollView(frame: CGRect(x: 0, y: 0, width: 375, height: 667))
        let refreshControl = LMKLottieRefreshControl()
        scrollView.refreshControl = refreshControl

        refreshControl.beginRefreshing()
        refreshControl.endRefreshing()
        refreshControl.beginRefreshing()
        refreshControl.endRefreshing()

        #expect(refreshControl.isRefreshing == false)
    }
}
