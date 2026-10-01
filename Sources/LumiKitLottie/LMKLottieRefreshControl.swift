//
//  LMKLottieRefreshControl.swift
//  LumiKit
//
//  Pull-to-refresh control with a two-phase Lottie animation: the ring draws
//  as the user pulls, then spins while loading. Ships its own ring animation
//  and tints it from the theme; hosts inject any Lottie animation instead.
//

import Lottie
import LumiKitUI
import UIKit

/// Pull-to-refresh control driven by a Lottie animation, styled from `theme.lottieRefreshControl`.
///
/// Phase 1 (pull): the animation scrubs to `timeline.phase1EndFrame` proportionally to the pull.
/// Phase 2 (loading): frames `phase1EndFrame...totalFrames` loop until `endRefreshing()`.
/// The bundled ring uses `Timeline.bundled`; an injected animation gets a timeline from its
/// `PHASE2_SPIN_LOOP` marker when it has one (the loop runs from the marker to the last frame),
/// otherwise the whole animation loops and the pull holds its first frame. `Style.timeline` overrides both.
///
/// ```swift
/// refreshControl = LMKLottieRefreshControl.install(on: collectionView) { [weak self] in self?.reload() }
/// // Mac idiom: install returns nil; offer Command-R instead
/// override var keyCommands: [UIKeyCommand]? { [LMKLottieRefreshControl.makeRefreshKeyCommand(action: #selector(reload))] }
/// ```
///
/// `install(on:)` tracks the scroll view itself (offset and drag end). A host that drives the
/// control by hand calls `updatePullProgress(scrollView:)` from `scrollViewDidScroll` and
/// `handleEndDragging(scrollView:)` from `scrollViewDidEndDragging`.
///
/// Behaviour:
/// - A release past `pullThreshold` starts the refresh. UIKit starts one itself when the pull
///   crosses the system's own distance mid-drag; both report through `onRefresh` and
///   `.valueChanged` once, and both spin.
/// - `endRefreshing()` waits out `minimumSpinDuration`, then fades the spinner; a
///   `beginRefreshing()` during that wait cancels it.
/// - Under Reduce Motion the Lottie view stays hidden and the system spinner shows.
public final class LMKLottieRefreshControl: UIRefreshControl, LMKThemeApplying {
    // MARK: - Timeline

    /// Frame layout of the animation: the pull scrubs `0...phase1EndFrame`, loading loops the rest.
    public nonisolated struct Timeline: Sendable, Equatable {
        public var phase1EndFrame: CGFloat
        public var totalFrames: CGFloat

        public init(phase1EndFrame: CGFloat = 60, totalFrames: CGFloat = 180) {
            self.phase1EndFrame = max(0, phase1EndFrame)
            self.totalFrames = max(self.phase1EndFrame, totalFrames)
        }

        /// The bundled ring animation's timeline.
        public static let bundled = Self()

        /// Marker an injected animation carries at the first frame of its loading loop.
        public static let phase2MarkerName = "PHASE2_SPIN_LOOP"

        /// The timeline of `animation`: phase 1 ends at its `phase2MarkerName` marker, or at its
        /// first frame when it has none; the loop always runs to its last frame.
        public init(animation: LottieAnimation) {
            let loopStart = animation.frameTime(forMarker: Self.phase2MarkerName) ?? animation.startFrame
            self.init(phase1EndFrame: min(max(animation.startFrame, loopStart), animation.endFrame), totalFrames: animation.endFrame)
        }
    }

    // MARK: - Style

    public nonisolated struct Style: Sendable, Equatable, LMKThemeExtension {
        /// Pull distance (pt) that maps to 100% of phase 1; `nil` = `theme.layout.pullThreshold`.
        public var pullThreshold: CGFloat?
        /// Frame layout; `nil` = the bundled animation's (60 / 180), or `Timeline(animation:)` of an injected animation.
        public var timeline: Timeline?
        /// Shortest time the spinner stays up once refreshing; `nil` = 0.8 s.
        public var minimumSpinDuration: TimeInterval?
        /// Side of the animation view; `nil` = `spacing.xxl` × 2.
        public var size: CGFloat?
        /// Color applied to the animation's `tintKeypath` fills and strokes; `nil` = `primary`.
        public var tintColor: UIColor?
        /// Lottie keypath the tint targets; `nil` = every `Color` property (`**.Color`).
        public var tintKeypath: String?
        /// Whether the tint is applied at all (turn off for animations with their own colors); `nil` = true.
        public var appliesTint: Bool?
        /// Impact haptic when the pull crosses the threshold; `nil` = enabled.
        public var haptics: Bool?

        public init(
            pullThreshold: CGFloat? = nil,
            timeline: Timeline? = nil,
            minimumSpinDuration: TimeInterval? = nil,
            size: CGFloat? = nil,
            tintColor: UIColor? = nil,
            tintKeypath: String? = nil,
            appliesTint: Bool? = nil,
            haptics: Bool? = nil
        ) {
            self.pullThreshold = pullThreshold
            self.timeline = timeline
            self.minimumSpinDuration = minimumSpinDuration
            self.size = size
            self.tintColor = tintColor
            self.tintKeypath = tintKeypath
            self.appliesTint = appliesTint
            self.haptics = haptics
        }

        public static let defaultValue = Self()

        /// `other`'s non-nil fields over this style's.
        public func merging(_ other: Self) -> Self {
            Self(
                pullThreshold: other.pullThreshold ?? pullThreshold,
                timeline: other.timeline ?? timeline,
                minimumSpinDuration: other.minimumSpinDuration ?? minimumSpinDuration,
                size: other.size ?? size,
                tintColor: other.tintColor ?? tintColor,
                tintKeypath: other.tintKeypath ?? tintKeypath,
                appliesTint: other.appliesTint ?? appliesTint,
                haptics: other.haptics ?? haptics
            )
        }
    }

    // MARK: - Strings

    public nonisolated struct Strings: Sendable, Equatable {
        /// Title of the Command-R key command.
        public var refresh: String

        public init(refresh: String = LMKLocalized("refreshControl.refresh")) {
            self.refresh = refresh
        }
    }

    /// Process-wide strings. Override at app launch to localize.
    public nonisolated(unsafe) static var strings = Strings()

    // MARK: - Constants

    private static let defaultMinimumSpinDuration: TimeInterval = 0.8
    private static let defaultTintKeypath = "**.Color"

    /// The ring animation shipped with the package (`refresh_spinner.json`), tinted at runtime.
    public static let bundledAnimation: LottieAnimation? = LottieAnimation.named("refresh_spinner", bundle: lmkModuleBundle, subdirectory: nil, animationCache: nil)

    // MARK: - Properties

    /// The animation played; `nil` plays the bundled ring.
    public var animation: LottieAnimation? {
        didSet {
            animationView.animation = animation ?? Self.bundledAnimation
            animationTimeline = animation.map { Timeline(animation: $0) } ?? .bundled
            applyTint()
        }
    }

    /// Per-instance style, layered over `theme.lottieRefreshControl`.
    public var style: Style {
        didSet {
            guard style != oldValue else { return }
            applyTheme(traitCollection.lmkTheme)
        }
    }

    /// Called at the end of every `applyTheme`, for tweaks the style does not cover.
    public var didApplyStyle: ((LMKLottieRefreshControl) -> Void)?

    /// The style in effect after the theme and instance style are merged.
    public private(set) var resolvedStyle = Style()

    /// Called whenever a refresh starts (alongside `.valueChanged`).
    public var onRefresh: (() -> Void)?

    /// The Lottie view; exposed for animation tweaks the style does not cover.
    public let animationView = LottieAnimationView()

    /// The scroll view `install(on:)` attached to, if any.
    public private(set) weak var attachedScrollView: UIScrollView?

    /// Whether the spinner is up: from `beginRefreshing()` until the fade after `endRefreshing()`
    /// completes. Unlike `isRefreshing`, it does not depend on the scroll view being on screen.
    public private(set) var isAnimatingRefresh = false

    /// Whether an `endRefreshing()` is waiting out `minimumSpinDuration`.
    public var hasPendingEndRefresh: Bool { pendingEndRefresh != nil }

    // MARK: - State

    private var isTriggeringRefresh = false
    private var isDismissing = false
    private var passedThreshold = false
    /// A finger that stayed down through a refresh must lift before its pull can arm another.
    private var needsRelease = false
    private var spinStartTime: Date?
    private var pendingEndRefresh: Task<Void, Never>?
    private var contentOffsetObservation: NSKeyValueObservation?
    /// The timeline derived from `animation` (the bundled ring's when there is none).
    private var animationTimeline = Timeline.bundled
    /// Whether the Lottie view stands in for the system spinner (`nil` until first applied).
    private var usesLottieSpinner: Bool?

    // MARK: - Initialization

    /// - Parameters:
    ///   - animation: The Lottie animation to play; `nil` plays the bundled ring.
    ///   - style: Per-instance style, layered over `theme.lottieRefreshControl`.
    public init(animation: LottieAnimation? = nil, style: Style = Style()) {
        self.animation = animation
        self.style = style
        animationTimeline = animation.map { Timeline(animation: $0) } ?? .bundled
        super.init()
        setup()
    }

    override public convenience init() {
        self.init(animation: nil)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        pendingEndRefresh?.cancel()
    }

    private func setup() {
        animationView.contentMode = .scaleAspectFit
        animationView.loopMode = .playOnce
        // A spin interrupted by the app leaving the foreground picks up where it stopped.
        animationView.backgroundBehavior = .pauseAndRestore
        animationView.animation = animation ?? Self.bundledAnimation
        animationView.isAccessibilityElement = false
        animationView.isHidden = true
        addSubview(animationView)
        updateSpinnerVisibility()
        addTarget(self, action: #selector(handleValueChanged), for: .valueChanged)
        // The tint is resolved into the animation, so a light/dark or contrast switch re-resolves it.
        registerForTraitChanges([UITraitUserInterfaceStyle.self, UITraitAccessibilityContrast.self]) { (control: Self, _: UITraitCollection) in
            control.applyTint()
        }
        // Selector observers unregister themselves on deallocation.
        NotificationCenter.default.addObserver(self, selector: #selector(reduceMotionStatusDidChange), name: UIAccessibility.reduceMotionStatusDidChangeNotification, object: nil)
        lmk_startApplyingTheme()
    }

    @objc private func reduceMotionStatusDidChange() {
        updateSpinnerVisibility()
    }

    // MARK: - Installation

    /// Installs a control on `scrollView` and tracks its pulls; returns `nil` under Mac
    /// Catalyst's Mac idiom, where `UIRefreshControl` is unsupported (offer
    /// `makeRefreshKeyCommand(action:)` there instead).
    public static func install(
        on scrollView: UIScrollView,
        animation: LottieAnimation? = nil,
        style: Style = Style(),
        onRefresh: (() -> Void)? = nil
    ) -> LMKLottieRefreshControl? {
        guard scrollView.traitCollection.userInterfaceIdiom != .mac else { return nil }
        let control = LMKLottieRefreshControl(animation: animation, style: style)
        control.onRefresh = onRefresh
        scrollView.refreshControl = control
        control.attach(to: scrollView)
        return control
    }

    /// A Command-R key command titled with `strings.refresh`, the Mac idiom's stand-in for the pull.
    public static func makeRefreshKeyCommand(action: Selector, strings: Strings = LMKLottieRefreshControl.strings) -> UIKeyCommand {
        UIKeyCommand(title: strings.refresh, action: action, input: "r", modifierFlags: .command)
    }

    private func attach(to scrollView: UIScrollView) {
        attachedScrollView = scrollView
        contentOffsetObservation = scrollView.observe(\.contentOffset, options: [.new]) { [weak self] scrollView, _ in
            MainActor.assumeIsolated {
                // A bounce or a programmatic offset draws the ring but cannot arm a refresh.
                self?.updatePullProgress(scrollView: scrollView, armsRefresh: scrollView.isTracking)
            }
        }
        scrollView.panGestureRecognizer.addTarget(self, action: #selector(handlePan(_:)))
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard gesture.state == .ended || gesture.state == .cancelled, let attachedScrollView else { return }
        handleEndDragging(scrollView: attachedScrollView)
    }

    /// `.valueChanged` from UIKit: the pull crossed the system's distance and the control is
    /// refreshing without `beginRefreshing()` having run, so the spin starts here.
    /// `handleEndDragging` reports its own trigger itself. Internal so tests can drive it.
    @objc func handleValueChanged() {
        guard !isTriggeringRefresh else { return }
        if !isAnimatingRefresh {
            startSpinning()
        }
        onRefresh?()
    }

    // MARK: - Theme

    public func applyTheme(_ theme: LMKTheme) {
        resolvedStyle = theme.lottieRefreshControl.merging(style)
        applyTint()
        setNeedsLayout()
        didApplyStyle?(self)
    }

    private func applyTint() {
        let keypath = AnimationKeypath(keypath: resolvedStyle.tintKeypath ?? Self.defaultTintKeypath)
        guard resolvedStyle.appliesTint ?? true else {
            animationView.removeValueProvider(for: keypath)
            return
        }
        let tint = (resolvedStyle.tintColor ?? LMKColor.primary).resolvedColor(with: traitCollection)
        animationView.setValueProvider(ColorValueProvider(tint.lottieColorValue), keypath: keypath)
    }

    // MARK: - Layout

    override public func didMoveToWindow() {
        super.didMoveToWindow()
        // Lottie stops a view that leaves its window; a refresh still running spins again.
        if window != nil, isAnimatingRefresh, !isDismissing, LMKAnimation.shouldAnimate {
            animationView.isHidden = false
            if !animationView.isAnimationPlaying {
                playPhase2()
            }
        }
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        // UIKit re-shows its own spinner subviews on layout, so they are re-hidden every pass.
        updateSpinnerVisibility()
        let preferred = resolvedStyle.size ?? traitCollection.lmkTheme.spacing.xxl * 2
        let side = min(bounds.width, bounds.height, preferred)
        animationView.frame = CGRect(x: (bounds.width - side) / 2, y: (bounds.height - side) / 2, width: side, height: side)
    }

    /// Hands the spinner role to the Lottie view, or under Reduce Motion back to UIKit's spinner.
    private func updateSpinnerVisibility() {
        let usesLottie = LMKAnimation.shouldAnimate
        for subview in subviews where subview !== animationView {
            subview.alpha = usesLottie ? 0 : 1
        }
        guard usesLottie != usesLottieSpinner else { return }
        usesLottieSpinner = usesLottie
        tintColor = usesLottie ? .clear : nil
        if usesLottie {
            if isAnimatingRefresh, !isDismissing {
                animationView.isHidden = false
                playPhase2()
            }
        } else {
            stopPhase2()
            animationView.isHidden = true
        }
    }

    // MARK: - Pull tracking

    /// Drives phase 1 from the scroll offset (call from `scrollViewDidScroll` when not installed).
    public func updatePullProgress(scrollView: UIScrollView) {
        updatePullProgress(scrollView: scrollView, armsRefresh: true)
    }

    /// `updatePullProgress(scrollView:)`; `armsRefresh` is false for offsets no finger is driving.
    private func updatePullProgress(scrollView: UIScrollView, armsRefresh: Bool) {
        guard !isRefreshing, !isAnimatingRefresh, !isDismissing else { return }
        if needsRelease, !scrollView.isTracking {
            needsRelease = false
        }
        let offset = -(scrollView.contentOffset.y + scrollView.adjustedContentInset.top)
        let pull = Self.pullProgress(offset: offset, threshold: pullThreshold)

        if armsRefresh, !needsRelease {
            let crossed = pull >= 1
            if crossed, !passedThreshold, resolvedStyle.haptics ?? true {
                LMKHaptics.light()
            }
            passedThreshold = crossed
        }

        let shows = pull > 0 && LMKAnimation.shouldAnimate
        // At rest with the ring already away there is nothing to draw, so plain scrolling costs nothing.
        guard shows || !animationView.isHidden else { return }
        animationView.currentFrame = Self.phase1Frame(pull: pull, timeline: timeline, startFrame: animationView.animation?.startFrame ?? 0)
        animationView.isHidden = !shows
    }

    /// Triggers a refresh when the last drag ended past the threshold (call from
    /// `scrollViewDidEndDragging` when not installed). Returns whether it did.
    @discardableResult
    public func handleEndDragging(scrollView: UIScrollView) -> Bool {
        needsRelease = false
        guard !isRefreshing, !isAnimatingRefresh, !isDismissing else { return false }
        let shouldRefresh = passedThreshold
        passedThreshold = false
        if shouldRefresh {
            beginRefreshing()
            isTriggeringRefresh = true
            sendActions(for: .valueChanged)
            isTriggeringRefresh = false
            onRefresh?()
        }
        return shouldRefresh
    }

    // MARK: - Refreshing

    override public func beginRefreshing() {
        super.beginRefreshing()
        startSpinning()
    }

    /// Shows the animation and loops phase 2, for a refresh started by the host, a release past
    /// the threshold, or UIKit.
    private func startSpinning() {
        cancelPendingEndRefresh()
        isAnimatingRefresh = true
        isDismissing = false
        passedThreshold = false
        needsRelease = trackedScrollView?.isTracking ?? false
        spinStartTime = Date()
        animationView.isHidden = !LMKAnimation.shouldAnimate
        animationView.alpha = 1
        playPhase2()
    }

    override public func endRefreshing() {
        guard isRefreshing || isAnimatingRefresh, !isDismissing else { return }
        if let startTime = spinStartTime {
            let remaining = minimumSpinDuration - Date().timeIntervalSince(startTime)
            if remaining > 0 {
                guard pendingEndRefresh == nil else { return }
                pendingEndRefresh = Task { [weak self] in
                    try? await Task.sleep(for: .seconds(remaining))
                    guard !Task.isCancelled, let self else { return }
                    pendingEndRefresh = nil
                    performDismiss()
                }
                return
            }
        }
        performDismiss()
    }

    /// Drops a deferred `endRefreshing()` (a new refresh started, or the host went away).
    public func cancelPendingEndRefresh() {
        pendingEndRefresh?.cancel()
        pendingEndRefresh = nil
    }

    private func performDismiss() {
        guard !isDismissing else { return }
        isDismissing = true
        spinStartTime = nil
        let duration = LMKAnimation.shouldAnimate ? LMKAnimation.Duration.moderate : 0
        LMKAnimation.fadeOut(animationView, duration: duration) { [weak self] in
            guard let self, isDismissing else { return } // a new refresh started during the fade
            stopPhase2()
            animationView.alpha = 1
            animationView.isHidden = true
            isDismissing = false
            isAnimatingRefresh = false
            finishEndRefreshing()
        }
    }

    private func finishEndRefreshing() {
        super.endRefreshing()
    }

    // MARK: - Private

    private var pullThreshold: CGFloat {
        max(1, resolvedStyle.pullThreshold ?? traitCollection.lmkTheme.layout.pullThreshold)
    }

    private var timeline: Timeline {
        resolvedStyle.timeline ?? animationTimeline
    }

    /// The scroll view whose touches drive the control: the installed one, else the host's.
    private var trackedScrollView: UIScrollView? {
        attachedScrollView ?? superview as? UIScrollView
    }

    private var minimumSpinDuration: TimeInterval {
        max(0, resolvedStyle.minimumSpinDuration ?? Self.defaultMinimumSpinDuration)
    }

    private func playPhase2() {
        guard LMKAnimation.shouldAnimate else { return }
        animationView.play(fromFrame: timeline.phase1EndFrame, toFrame: timeline.totalFrames, loopMode: .loop)
    }

    private func stopPhase2() {
        animationView.stop()
        animationView.currentFrame = animationView.animation?.startFrame ?? 0
    }

    // MARK: - Pure helpers

    /// Pull fraction for a downward `offset` past the top inset, 0...1.
    nonisolated static func pullProgress(offset: CGFloat, threshold: CGFloat) -> CGFloat {
        guard threshold > 0 else { return offset > 0 ? 1 : 0 }
        return min(max(0, offset) / threshold, 1)
    }

    /// The frame a phase-1 `pull` fraction scrubs to: from the animation's `startFrame` to `timeline.phase1EndFrame`.
    nonisolated static func phase1Frame(pull: CGFloat, timeline: Timeline, startFrame: CGFloat = 0) -> CGFloat {
        let start = min(startFrame, timeline.phase1EndFrame)
        return start + (timeline.phase1EndFrame - start) * min(max(0, pull), 1)
    }
}

public nonisolated extension LMKTheme {
    /// App-wide default style for `LMKLottieRefreshControl`.
    var lottieRefreshControl: LMKLottieRefreshControl.Style {
        get { self[LMKLottieRefreshControl.Style.self] }
        set { self[LMKLottieRefreshControl.Style.self] = newValue }
    }
}
