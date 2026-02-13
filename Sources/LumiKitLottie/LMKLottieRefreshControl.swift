//
//  LMKLottieRefreshControl.swift
//  LumiKit
//
//  Custom pull-to-refresh indicator with circle-spinner Lottie animation.
//  Phase 1: A point grows into a complete circle ring as the user pulls.
//  Phase 2: The ring extends and shrinks while spinning continuously.
//

import Lottie
import LumiKitUI
import UIKit

/// Custom refresh control with circle-spinner Lottie animation.
///
/// Phase 1 (pull): Trim path draws the ring proportional to scroll offset.
/// Phase 2 (loading): Ring arc oscillates (extends/shrinks) while spinning.
///
/// Behaviour:
/// - Refresh is NOT triggered while the user is still dragging.
///   It fires only after they release the scroll past the threshold.
/// - After loading finishes, the spinner fades out smoothly and
///   ignores further scroll-offset changes until the dismiss completes.
public final class LMKLottieRefreshControl: UIRefreshControl {
    // MARK: - Constants

    /// Pull distance (pt) that maps to 100% of Phase 1.
    public static let pullThreshold: CGFloat = 80

    private static let phase1EndFrame: CGFloat = 60
    private static let totalFrames: CGFloat = 180
    private static let dismissDuration: TimeInterval = LMKAnimationHelper.Duration.listUpdate
    private static let minimumSpinDuration: TimeInterval = 0.8

    // MARK: - State

    private var isDismissing = false
    private var passedThreshold = false
    private var spinStartTime: Date?
    private var pendingEndRefresh = false

    // MARK: - Subviews

    private lazy var animationView: LottieAnimationView = {
        let view = LottieAnimationView()
        view.contentMode = .scaleAspectFit
        view.loopMode = .playOnce
        view.animation = loadAnimation()
        return view
    }()

    // MARK: - Initialization

    override public init() {
        super.init()
        setup()
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        if !UIAccessibility.isReduceMotionEnabled {
            tintColor = .clear
            hideDefaultSubviews()
        }
        addSubview(animationView)
    }

    override public func didMoveToWindow() {
        super.didMoveToWindow()
        animationView.isHidden = UIAccessibility.isReduceMotionEnabled
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        if !UIAccessibility.isReduceMotionEnabled {
            hideDefaultSubviews()
        }
        let size = min(bounds.width, bounds.height, LMKSpacing.xxl * 2)
        animationView.frame = CGRect(
            x: (bounds.width - size) / 2,
            y: (bounds.height - size) / 2,
            width: size,
            height: size,
        )
    }

    // MARK: - Public

    /// Call from `scrollViewDidScroll` to drive Phase 1 based on pull offset.
    public func updatePullProgress(scrollView: UIScrollView) {
        guard !isRefreshing, !isDismissing else { return }

        let offset = max(0, -(scrollView.contentOffset.y + scrollView.adjustedContentInset.top))
        let pull = min(offset / Self.pullThreshold, 1)

        if pull >= 1 { passedThreshold = true }

        let phase1Progress = (Self.phase1EndFrame / Self.totalFrames) * pull
        animationView.currentProgress = phase1Progress
        animationView.isHidden = pull <= 0

        if UIAccessibility.isReduceMotionEnabled {
            animationView.isHidden = true
        }
    }

    /// Call from `scrollViewDidEndDragging` to trigger refresh if past threshold.
    /// Returns `true` if refresh was triggered.
    @discardableResult
    public func handleEndDragging(scrollView: UIScrollView) -> Bool {
        guard !isRefreshing, !isDismissing else { return false }

        let shouldRefresh = passedThreshold
        passedThreshold = false

        if shouldRefresh {
            beginRefreshing()
            sendActions(for: .valueChanged)
        }
        return shouldRefresh
    }

    override public func beginRefreshing() {
        super.beginRefreshing()
        isDismissing = false
        passedThreshold = false
        pendingEndRefresh = false
        spinStartTime = Date()
        animationView.isHidden = false
        animationView.alpha = 1
        playPhase2()
    }

    override public func endRefreshing() {
        guard isRefreshing, !isDismissing else { return }

        if let startTime = spinStartTime {
            let elapsed = Date().timeIntervalSince(startTime)
            let remaining = Self.minimumSpinDuration - elapsed
            if remaining > 0 {
                guard !pendingEndRefresh else { return }
                pendingEndRefresh = true
                DispatchQueue.main.asyncAfter(deadline: .now() + remaining) { [weak self] in
                    guard let self, self.pendingEndRefresh else { return }
                    self.pendingEndRefresh = false
                    self.performDismiss()
                }
                return
            }
        }
        performDismiss()
    }

    // MARK: - Dismiss

    private func performDismiss() {
        guard !isDismissing else { return }
        isDismissing = true
        spinStartTime = nil

        let shouldAnimate = !UIAccessibility.isReduceMotionEnabled
        let duration = shouldAnimate ? Self.dismissDuration : 0

        UIView.animate(
            withDuration: duration, delay: 0, options: .curveEaseIn,
        ) { [weak self] in
            self?.animationView.alpha = 0
        } completion: { [weak self] _ in
            guard let self else { return }
            self.stopPhase2()
            self.animationView.alpha = 1
            self.animationView.isHidden = true
            self.isDismissing = false
            self.finishEndRefreshing()
        }
    }

    private func finishEndRefreshing() {
        super.endRefreshing()
    }

    // MARK: - Private

    private func loadAnimation() -> LottieAnimation? {
        LottieAnimation.named("refresh_spinner", bundle: .main, subdirectory: nil, animationCache: nil)
    }

    private func hideDefaultSubviews() {
        subviews.filter { $0 !== animationView }.forEach { $0.alpha = 0 }
    }

    private func playPhase2() {
        guard !UIAccessibility.isReduceMotionEnabled else { return }
        animationView.play(fromFrame: Self.phase1EndFrame, toFrame: Self.totalFrames, loopMode: .loop)
    }

    private func stopPhase2() {
        guard !UIAccessibility.isReduceMotionEnabled else { return }
        animationView.stop()
        animationView.currentProgress = 0
    }
}
