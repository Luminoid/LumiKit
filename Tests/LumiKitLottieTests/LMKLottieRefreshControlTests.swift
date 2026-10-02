//
//  LMKLottieRefreshControlTests.swift
//  LumiKit
//

import Lottie
import LumiKitUI
import Testing
import UIKit
@testable import LumiKitLottie

/// Polling wait for asynchronous work, as in the UI test target.
@MainActor
enum LMKWait {
    /// Polls `condition` every 20 ms until it holds or `timeout` worth of polls has run.
    /// The budget counts polls, not wall-clock time, so a main-thread stall in another
    /// suite cannot expire it before the awaited work has had its turn.
    static func until(timeout: Duration = .seconds(10), _ condition: () -> Bool) async {
        let interval = Duration.milliseconds(20)
        var polls = Int((timeout / interval).rounded(.up))
        while !condition(), polls > 0 {
            polls -= 1
            try? await Task.sleep(for: interval)
        }
    }
}

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
        #expect(LMKLottieRefreshControl.phase1Frame(pull: 1, timeline: timeline) == 60)
        #expect(LMKLottieRefreshControl.phase1Frame(pull: 0.5, timeline: timeline) == 30)
        #expect(LMKLottieRefreshControl.phase1Frame(pull: 0, timeline: timeline) == 0)
        #expect(LMKLottieRefreshControl.phase1Frame(pull: 2, timeline: timeline) == 60, "clamped")
        #expect(LMKLottieRefreshControl.phase1Frame(pull: 0.5, timeline: timeline, startFrame: 20) == 40, "an animation that starts late scrubs from its first frame")
        #expect(LMKLottieRefreshControl.Timeline(phase1EndFrame: 100, totalFrames: 50).totalFrames == 100, "the total never precedes phase one")
    }

    @Test
    func `An injected animation gets a timeline from its marker, or loops whole`() throws {
        let bundled = try #require(LMKLottieRefreshControl.bundledAnimation)
        #expect(LMKLottieRefreshControl.Timeline(animation: bundled) == .bundled, "the bundled ring's markers describe its own timeline")

        let unmarked = try LottieAnimation.from(data: Data(#"{"v":"5.9.6","fr":30,"ip":10,"op":90,"w":10,"h":10,"nm":"x","ddd":0,"assets":[],"layers":[]}"#.utf8))
        let derived = LMKLottieRefreshControl.Timeline(animation: unmarked)
        #expect(derived.phase1EndFrame == 10, "no marker: the pull holds the first frame")
        #expect(derived.totalFrames == 90, "and the whole animation loops")

        let control = LMKLottieRefreshControl(animation: unmarked, style: LMKLottieRefreshControl.Style(pullThreshold: 80))
        let scrollView = makeScrollView()
        scrollView.refreshControl = control
        scrollView.contentOffset = CGPoint(x: 0, y: -40)
        control.updatePullProgress(scrollView: scrollView)
        #expect(control.animationView.currentFrame == 10, "the pull never runs into the loop")

        control.style = LMKLottieRefreshControl.Style(pullThreshold: 80, timeline: LMKLottieRefreshControl.Timeline(phase1EndFrame: 50, totalFrames: 90))
        control.updatePullProgress(scrollView: scrollView)
        #expect(control.animationView.currentFrame == 30, "a style timeline wins over the derived one")
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
    func `A pull that drops back below the threshold does not refresh on release`() {
        let scrollView = makeScrollView()
        let refreshControl = LMKLottieRefreshControl(style: LMKLottieRefreshControl.Style(pullThreshold: 80, haptics: false))
        scrollView.refreshControl = refreshControl
        var refreshes = 0
        refreshControl.onRefresh = { refreshes += 1 }

        scrollView.contentOffset = CGPoint(x: 0, y: -120)
        refreshControl.updatePullProgress(scrollView: scrollView)
        #expect(!refreshControl.animationView.isHidden)
        scrollView.contentOffset = CGPoint(x: 0, y: -20)
        refreshControl.updatePullProgress(scrollView: scrollView)
        scrollView.contentOffset = .zero
        refreshControl.updatePullProgress(scrollView: scrollView)
        #expect(refreshControl.animationView.isHidden, "the ring goes away at rest")

        #expect(refreshControl.handleEndDragging(scrollView: scrollView) == false, "the threshold is a state, not a latch")
        #expect(refreshes == 0)
    }

    @Test
    func `Plain scrolling with the ring at rest writes nothing to the animation view`() {
        let scrollView = makeScrollView()
        let refreshControl = LMKLottieRefreshControl(style: LMKLottieRefreshControl.Style(pullThreshold: 80))
        scrollView.refreshControl = refreshControl
        #expect(refreshControl.animationView.isHidden)
        refreshControl.animationView.currentFrame = 42

        scrollView.contentOffset = CGPoint(x: 0, y: 200)
        refreshControl.updatePullProgress(scrollView: scrollView)

        #expect(refreshControl.animationView.currentFrame == 42, "no frame write while hidden at rest")
        #expect(refreshControl.animationView.isHidden)
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
    func `Ending a refresh with no minimum spin finishes`() async {
        let scrollView = makeScrollView()
        let refreshControl = LMKLottieRefreshControl(style: LMKLottieRefreshControl.Style(minimumSpinDuration: 0))
        scrollView.refreshControl = refreshControl

        refreshControl.beginRefreshing()
        #expect(refreshControl.isAnimatingRefresh)
        refreshControl.endRefreshing()
        #expect(!refreshControl.hasPendingEndRefresh, "nothing to wait out")
        await LMKWait.until { !refreshControl.isAnimatingRefresh }
        #expect(!refreshControl.isAnimatingRefresh, "the fade completes and the spinner is down")
        #expect(refreshControl.animationView.isHidden)

        refreshControl.beginRefreshing()
        #expect(refreshControl.isAnimatingRefresh, "a new cycle starts cleanly")
        refreshControl.endRefreshing()
        await LMKWait.until { !refreshControl.isAnimatingRefresh }
        #expect(!refreshControl.isAnimatingRefresh)
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

    @Test
    func `Every style field resolves through the control`() {
        let timeline = LMKLottieRefreshControl.Timeline(phase1EndFrame: 10, totalFrames: 20)
        let style = LMKLottieRefreshControl.Style(
            pullThreshold: 55,
            timeline: timeline,
            minimumSpinDuration: 3,
            size: 24,
            tintColor: .systemPink,
            tintKeypath: "Ring.**.Color",
            appliesTint: true,
            haptics: false
        )
        let refreshControl = LMKLottieRefreshControl(style: style)
        refreshControl.applyTheme(.default)

        #expect(refreshControl.resolvedStyle == style)
        #expect(refreshControl.resolvedStyle.timeline == timeline)
        #expect(refreshControl.resolvedStyle.tintKeypath == "Ring.**.Color")
        let merged = LMKLottieRefreshControl.Style().merging(style)
        #expect(merged == style, "merging carries every field")
        #expect(style.merging(LMKLottieRefreshControl.Style()) == style, "nil fields do not clear")

        refreshControl.frame = CGRect(x: 0, y: 0, width: 200, height: 60)
        refreshControl.layoutSubviews()
        #expect(refreshControl.animationView.frame.width == 24, "size drives the animation view")

        let scrollView = makeScrollView()
        scrollView.refreshControl = refreshControl
        scrollView.contentOffset = CGPoint(x: 0, y: -55)
        refreshControl.updatePullProgress(scrollView: scrollView)
        #expect(refreshControl.animationView.currentFrame == 10, "pullThreshold and timeline drive the scrub")
        #expect(refreshControl.handleEndDragging(scrollView: scrollView))
        refreshControl.endRefreshing()
        #expect(refreshControl.hasPendingEndRefresh, "minimumSpinDuration defers the end")
        refreshControl.cancelPendingEndRefresh()
    }
}
