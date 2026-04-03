//
//  LMKLottieRefreshControlTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitLottie

@MainActor
struct LMKLottieRefreshControlTests {
    // MARK: - Initialization

    @Test
    func `Initializes successfully`() {
        let refreshControl = LMKLottieRefreshControl()

        #expect(refreshControl.isRefreshing == false)
    }

    // MARK: - Refresh State

    @Test
    func `Begins refreshing completes without crashing`() {
        let scrollView = UIScrollView(frame: CGRect(x: 0, y: 0, width: 375, height: 667))
        let refreshControl = LMKLottieRefreshControl()
        scrollView.refreshControl = refreshControl

        refreshControl.beginRefreshing()

        // Test completes successfully (actual refresh state requires visible hierarchy)
    }

    @Test
    func `Ends refreshing`() {
        let scrollView = UIScrollView(frame: CGRect(x: 0, y: 0, width: 375, height: 667))
        let refreshControl = LMKLottieRefreshControl()
        scrollView.refreshControl = refreshControl

        refreshControl.beginRefreshing()
        refreshControl.endRefreshing()

        #expect(refreshControl.isRefreshing == false)
    }

    @Test
    func `Initial state is not refreshing`() {
        let refreshControl = LMKLottieRefreshControl()

        #expect(refreshControl.isRefreshing == false)
    }

    // MARK: - Scroll View Integration

    @Test
    func `Can be added to scroll view`() {
        let scrollView = UIScrollView(frame: CGRect(x: 0, y: 0, width: 375, height: 667))
        let refreshControl = LMKLottieRefreshControl()

        scrollView.refreshControl = refreshControl

        #expect(scrollView.refreshControl != nil)
    }

    @Test
    func `Can be added to table view`() {
        let tableView = UITableView(frame: CGRect(x: 0, y: 0, width: 375, height: 667))
        let refreshControl = LMKLottieRefreshControl()

        tableView.refreshControl = refreshControl

        #expect(tableView.refreshControl != nil)
    }

    // MARK: - Multiple Cycles

    @Test
    func `Handles multiple refresh cycles`() {
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
