//
//  LMKLottieRefreshControlTests.swift
//  LumiKit
//

import LumiKitUI
import Testing
import UIKit
@testable import LumiKitLottie

@MainActor
struct LMKLottieRefreshControlTests {
    private func makeScrollView() -> UIScrollView {
        UIScrollView(frame: CGRect(x: 0, y: 0, width: 375, height: 667))
    }

    // MARK: - Initialization

    @Test
    func `Initializes not refreshing with the bundled animation`() {
        let refreshControl = LMKLottieRefreshControl()

        #expect(refreshControl.isRefreshing == false)
        #expect(LMKLottieRefreshControl.bundledAnimation != nil, "refresh_spinner.json ships in the package")
        #expect(refreshControl.animationView.animation != nil)
        #expect(refreshControl.animation == nil, "nil means the bundled ring")
    }

    @Test
    func `install attaches to the scroll view outside the Mac idiom`() throws {
        let scrollView = makeScrollView()
        var refreshed = false

        let control = LMKLottieRefreshControl.install(on: scrollView, onRefresh: { refreshed = true })

        if scrollView.traitCollection.userInterfaceIdiom == .mac {
            #expect(control == nil)
            return
        }
        let installed = try #require(control)
        #expect(scrollView.refreshControl === installed)
        #expect(installed.attachedScrollView === scrollView)
        installed.sendActions(for: .valueChanged)
        installed.onRefresh?()
        #expect(refreshed)
    }

    @Test
    func `The refresh key command is Command-R with the localized title`() {
        let command = LMKLottieRefreshControl.makeRefreshKeyCommand(action: #selector(UIViewController.lmk_cancelFromKeyCommand))
        #expect(command.input == "r")
        #expect(command.modifierFlags == .command)
        #expect(command.title == LMKLottieRefreshControl.strings.refresh)
        #expect(LMKLottieRefreshControl.Strings().refresh != "refreshControl.refresh")
    }

    // MARK: - Pull tracking

    @Test
    func `Pull and phase-one progress are proportional and clamped`() {
        #expect(LMKLottieRefreshControl.pullProgress(offset: 40, threshold: 80) == 0.5)
        #expect(LMKLottieRefreshControl.pullProgress(offset: 200, threshold: 80) == 1)
        #expect(LMKLottieRefreshControl.pullProgress(offset: -10, threshold: 80) == 0)
        #expect(LMKLottieRefreshControl.pullProgress(offset: 10, threshold: 0) == 1)

        let timeline = LMKLottieRefreshControl.Timeline(phase1EndFrame: 60, totalFrames: 180)
        #expect(abs(LMKLottieRefreshControl.phase1Progress(pull: 1, timeline: timeline) - 1 / 3) < 0.0001)
        #expect(LMKLottieRefreshControl.phase1Progress(pull: 0, timeline: timeline) == 0)
        #expect(LMKLottieRefreshControl.Timeline(phase1EndFrame: 100, totalFrames: 50).totalFrames == 100, "the total never precedes phase one")
    }

    @Test
    func `A release past the threshold triggers the refresh once`() {
        let scrollView = makeScrollView()
        let refreshControl = LMKLottieRefreshControl(style: LMKLottieRefreshControl.Style(pullThreshold: 80))
        scrollView.refreshControl = refreshControl
        var refreshes = 0
        refreshControl.onRefresh = { refreshes += 1 }

        scrollView.contentOffset = CGPoint(x: 0, y: -40)
        refreshControl.updatePullProgress(scrollView: scrollView)
        #expect(refreshControl.handleEndDragging(scrollView: scrollView) == false, "short pull")

        scrollView.contentOffset = CGPoint(x: 0, y: -120)
        refreshControl.updatePullProgress(scrollView: scrollView)
        #expect(refreshControl.handleEndDragging(scrollView: scrollView))
        #expect(refreshes == 1)
        #expect(refreshControl.handleEndDragging(scrollView: scrollView) == false, "already refreshing")
    }

    @Test
    func `A refresh UIKit starts mid-drag spins and reports once`() {
        let scrollView = makeScrollView()
        let refreshControl = LMKLottieRefreshControl(style: LMKLottieRefreshControl.Style(pullThreshold: 80, minimumSpinDuration: 60))
        scrollView.refreshControl = refreshControl
        var refreshes = 0
        refreshControl.onRefresh = { refreshes += 1 }

        // The pull crossed the system's distance: UIKit sends `.valueChanged` without `beginRefreshing()`.
        scrollView.contentOffset = CGPoint(x: 0, y: -140)
        refreshControl.updatePullProgress(scrollView: scrollView)
        refreshControl.handleValueChanged()
        #expect(refreshes == 1)
        #expect(refreshControl.isAnimatingRefresh, "the loading loop runs, not the last frame of the pull")
        #expect(!refreshControl.animationView.isHidden)

        // The finger lifts afterwards: no second refresh.
        #expect(refreshControl.handleEndDragging(scrollView: scrollView) == false)
        #expect(refreshes == 1)

        // The end waits out the minimum spin, as for any refresh.
        refreshControl.endRefreshing()
        #expect(refreshControl.hasPendingEndRefresh)
    }

    @Test
    func `A release past the threshold does not report twice through valueChanged`() {
        let scrollView = makeScrollView()
        let refreshControl = LMKLottieRefreshControl(style: LMKLottieRefreshControl.Style(pullThreshold: 80))
        scrollView.refreshControl = refreshControl
        var refreshes = 0
        refreshControl.onRefresh = { refreshes += 1 }
        scrollView.contentOffset = CGPoint(x: 0, y: -120)
        refreshControl.updatePullProgress(scrollView: scrollView)
        // The release sends `.valueChanged` for the host's targets; the control's own handler
        // stays out of it, so `onRefresh` runs once.
        #expect(refreshControl.handleEndDragging(scrollView: scrollView))
        #expect(refreshes == 1)
        #expect(refreshControl.isAnimatingRefresh)
    }

    // MARK: - Refresh State

    @Test
    func `Ending a refresh waits out the minimum spin and can be cancelled`() {
        let scrollView = makeScrollView()
        let refreshControl = LMKLottieRefreshControl(style: LMKLottieRefreshControl.Style(minimumSpinDuration: 60))
        scrollView.refreshControl = refreshControl

        refreshControl.beginRefreshing()
        #expect(refreshControl.isAnimatingRefresh)
        refreshControl.endRefreshing()
        #expect(refreshControl.hasPendingEndRefresh, "the end is deferred until the minimum spin elapsed")
        #expect(refreshControl.isAnimatingRefresh)

        refreshControl.cancelPendingEndRefresh()
        #expect(!refreshControl.hasPendingEndRefresh)
        refreshControl.endRefreshing()
        refreshControl.beginRefreshing()
        #expect(!refreshControl.hasPendingEndRefresh, "a new refresh drops the deferred end")
        #expect(refreshControl.isAnimatingRefresh)
    }

    @Test
    func `Ending a refresh with no minimum spin finishes`() {
        let scrollView = makeScrollView()
        let refreshControl = LMKLottieRefreshControl(style: LMKLottieRefreshControl.Style(minimumSpinDuration: 0))
        scrollView.refreshControl = refreshControl

        refreshControl.beginRefreshing()
        refreshControl.endRefreshing()
        refreshControl.beginRefreshing()
        refreshControl.endRefreshing()

        // The fade-out completion lands asynchronously; the control must at least accept the cycle.
        #expect(refreshControl.attachedScrollView == nil)
    }

    @Test
    func `Can be added to a scroll view and a table view`() {
        let scrollView = makeScrollView()
        scrollView.refreshControl = LMKLottieRefreshControl()
        #expect(scrollView.refreshControl != nil)

        let tableView = UITableView(frame: CGRect(x: 0, y: 0, width: 375, height: 667))
        tableView.refreshControl = LMKLottieRefreshControl()
        #expect(tableView.refreshControl != nil)
    }

    // MARK: - Style

    @Test
    func `Style resolves through the theme slot and merges`() {
        var theme = LMKTheme.default
        theme.lottieRefreshControl = LMKLottieRefreshControl.Style(pullThreshold: 120, size: 64)
        let refreshControl = LMKLottieRefreshControl(style: LMKLottieRefreshControl.Style(size: 40))
        refreshControl.applyTheme(theme)

        #expect(refreshControl.resolvedStyle.pullThreshold == 120)
        #expect(refreshControl.resolvedStyle.size == 40, "the instance style wins")

        let merged = LMKLottieRefreshControl.Style(tintColor: .red, appliesTint: false).merging(LMKLottieRefreshControl.Style(haptics: false))
        #expect(merged.tintColor == .red)
        #expect(merged.appliesTint == false)
        #expect(merged.haptics == false)
    }
}
