//
//  LMKProgressViewController.swift
//  LumiKit
//
//  Blocking progress view controller for long-running operations.
//

import LumiKitCore
import SnapKit
import UIKit

/// Blocking progress view controller with activity indicator, progress bar, and cancel button.
public final class LMKProgressViewController: UIViewController {
    // MARK: - Types

    /// Display style for the progress view.
    /// - `determinate`: Shows progress bar and percentage (for operations with progress tracking).
    /// - `indeterminate`: Shows only spinner and title (for single-shot async operations).
    public enum Style {
        case determinate
        case indeterminate
    }

    // MARK: - Layout Constants

    private static let containerWidth: CGFloat = 280
    private static var activityIndicatorTopOffset: CGFloat { LMKSpacing.xxl }
    private static var activityIndicatorToTitleSpacing: CGFloat { LMKSpacing.large }
    private static var horizontalInsets: CGFloat { LMKSpacing.xl }
    private static var titleToTaskSpacing: CGFloat { LMKSpacing.medium }
    private static var taskToProgressSpacing: CGFloat { LMKSpacing.large }
    private static let progressBarHeight: CGFloat = 4
    private static var progressToLabelSpacing: CGFloat { LMKSpacing.small }
    private static var labelToButtonSpacing: CGFloat { LMKSpacing.large }
    private static var bottomOffset: CGFloat { LMKSpacing.xxl }

    // MARK: - Subviews

    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = LMKColor.backgroundPrimary
        view.layer.cornerRadius = LMKCornerRadius.large
        view.lmk_applyShadow(LMKShadow.card())
        return view
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = LMKTypography.h3
        label.textColor = LMKColor.textPrimary
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = LMKTypography.caption
        label.textColor = LMKColor.textSecondary
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private let taskLabel: UILabel = {
        let label = UILabel()
        label.font = LMKTypography.body
        label.textColor = LMKColor.textSecondary
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private let progressView: UIProgressView = {
        let pv = UIProgressView(progressViewStyle: .default)
        pv.progressTintColor = LMKColor.primary
        pv.trackTintColor = LMKColor.backgroundSecondary
        return pv
    }()

    private let progressLabel: UILabel = {
        let label = UILabel()
        label.font = LMKTypography.caption
        label.textColor = LMKColor.textSecondary
        label.textAlignment = .center
        return label
    }()

    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.color = LMKColor.primary
        indicator.hidesWhenStopped = true
        return indicator
    }()

    private lazy var cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(LMKAlertPresenter.strings.cancel, for: .normal)
        button.titleLabel?.font = LMKTypography.body
        button.setTitleColor(LMKColor.textPrimary, for: .normal)
        button.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        return button
    }()

    /// Callback when the cancel button is tapped. The button renders only
    /// while this is non-nil, so a non-cancellable operation never shows a
    /// dead Cancel; setters must dismiss the controller themselves (an
    /// early-exit path may never reach the flow's own dismiss).
    public var onCancel: (() -> Void)? {
        didSet {
            guard isViewLoaded else { return }
            rebuildBottomChain()
        }
    }

    /// Throttle VoiceOver announcements to avoid flooding.
    private var lastAnnouncementTime: Date = .distantPast
    private static let announcementThrottleInterval: TimeInterval = 2.0

    private let style: Style
    private var subtitle: String?

    // MARK: - Initialization

    public init(title: String, subtitle: String? = nil, style: Style = .determinate) {
        self.style = style
        self.subtitle = subtitle
        super.init(nibName: nil, bundle: nil)
        titleLabel.text = title
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override public func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: Self, _: UITraitCollection) in
            self.refreshDynamicColors()
        }
    }

    private func refreshDynamicColors() {
        view.backgroundColor = LMKColor.black.withAlphaComponent(LMKAlpha.overlay)
        containerView.backgroundColor = LMKColor.backgroundPrimary
        containerView.lmk_applyShadow(LMKShadow.card())
        titleLabel.textColor = LMKColor.textPrimary
        subtitleLabel.textColor = LMKColor.textSecondary
        taskLabel.textColor = LMKColor.textSecondary
        progressView.progressTintColor = LMKColor.primary
        progressView.trackTintColor = LMKColor.backgroundSecondary
        progressLabel.textColor = LMKColor.textSecondary
        activityIndicator.color = LMKColor.primary
        cancelButton.setTitleColor(LMKColor.textPrimary, for: .normal)
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = LMKColor.black.withAlphaComponent(LMKAlpha.overlay)

        view.addSubview(containerView)
        containerView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalTo(Self.containerWidth)
        }

        containerView.addSubview(activityIndicator)
        activityIndicator.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(Self.activityIndicatorTopOffset)
            make.centerX.equalToSuperview()
        }

        containerView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(activityIndicator.snp.bottom).offset(Self.activityIndicatorToTitleSpacing)
            make.leading.trailing.equalToSuperview().inset(Self.horizontalInsets)
        }

        if style == .determinate {
            containerView.addSubview(taskLabel)
            taskLabel.snp.makeConstraints { make in
                make.top.equalTo(titleLabel.snp.bottom).offset(Self.titleToTaskSpacing)
                make.leading.trailing.equalToSuperview().inset(Self.horizontalInsets)
            }

            containerView.addSubview(progressView)
            progressView.snp.makeConstraints { make in
                make.top.equalTo(taskLabel.snp.bottom).offset(Self.taskToProgressSpacing)
                make.leading.trailing.equalToSuperview().inset(Self.horizontalInsets)
                make.height.equalTo(Self.progressBarHeight)
            }

            containerView.addSubview(progressLabel)
            progressLabel.snp.makeConstraints { make in
                make.top.equalTo(progressView.snp.bottom).offset(Self.progressToLabelSpacing)
                make.leading.trailing.equalToSuperview().inset(Self.horizontalInsets)
            }

            lastChainView = progressLabel
        } else {
            lastChainView = titleLabel
            if let subtitle {
                subtitleLabel.text = subtitle
                installSubtitleLabel()
            }
        }

        rebuildBottomChain()
        activityIndicator.startAnimating()
    }

    // MARK: - Bottom chain

    /// The lowest content view; the cancel button (when offered) or the
    /// container's bottom inset hangs off it.
    private weak var lastChainView: UIView?

    /// Closes the container below `lastChainView` while no cancel button is
    /// installed; deactivated when the button takes over the bottom edge.
    private var bottomClosureConstraint: Constraint?

    /// Adds the subtitle label between the title and the bottom chain
    /// (indeterminate style only).
    private func installSubtitleLabel() {
        guard subtitleLabel.superview == nil else { return }
        containerView.addSubview(subtitleLabel)
        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(Self.titleToTaskSpacing)
            make.leading.trailing.equalToSuperview().inset(Self.horizontalInsets)
        }
        lastChainView = subtitleLabel
    }

    /// Re-anchors the container's bottom edge: the cancel button is offered
    /// only while `onCancel` is wired (a rendered Cancel that does nothing
    /// reads as a hang), so the container closes at the button when present
    /// and directly under the last content view otherwise.
    private func rebuildBottomChain() {
        guard let lastChainView else { return }
        bottomClosureConstraint?.deactivate()
        bottomClosureConstraint = nil
        if onCancel != nil {
            if cancelButton.superview == nil {
                containerView.addSubview(cancelButton)
            }
            cancelButton.snp.remakeConstraints { make in
                make.top.equalTo(lastChainView.snp.bottom).offset(Self.labelToButtonSpacing)
                make.centerX.equalToSuperview()
                make.bottom.equalToSuperview().offset(-Self.bottomOffset)
            }
        } else {
            cancelButton.removeFromSuperview()
            lastChainView.snp.makeConstraints { make in
                bottomClosureConstraint = make.bottom.equalToSuperview().offset(-Self.bottomOffset).constraint
            }
        }
    }

    // MARK: - Actions

    @objc private func cancelButtonTapped() {
        onCancel?()
    }

    // MARK: - Public API

    /// Update progress and current task.
    public func updateProgress(_ progress: Float, task: String) {
        progressView.setProgress(progress, animated: true)
        taskLabel.text = task
        let percentText = LMKFormatHelper.progressPercent(progress)
        progressLabel.text = percentText
        let now = Date()
        if now.timeIntervalSince(lastAnnouncementTime) >= Self.announcementThrottleInterval {
            lastAnnouncementTime = now
            UIAccessibility.post(notification: .announcement, argument: "\(task) \(percentText)")
        }
    }

    /// Update only the progress value.
    public func updateProgress(_ progress: Float) {
        progressView.setProgress(progress, animated: true)
        progressLabel.text = LMKFormatHelper.progressPercent(progress)
    }

    /// Sets, updates, or removes the secondary line under the title
    /// (indeterminate style only; the determinate layout drives its own task
    /// line through `updateProgress`). Safe before presentation and
    /// mid-flight: a HUD already on screen grows the line in place, the
    /// intended home for "this is taking longer than usual" notes, with a
    /// VoiceOver announcement so the note isn't sighted-only.
    public func setSubtitle(_ text: String?) {
        subtitle = text
        guard style == .indeterminate, isViewLoaded else { return }
        guard let text else {
            guard subtitleLabel.superview != nil else { return }
            subtitleLabel.removeFromSuperview()
            lastChainView = titleLabel
            rebuildBottomChain()
            return
        }
        let isNew = subtitleLabel.superview == nil
        subtitleLabel.text = text
        subtitleLabel.alpha = 1
        if isNew {
            installSubtitleLabel()
            rebuildBottomChain()
            if LMKAnimationHelper.shouldAnimate, view.window != nil {
                subtitleLabel.alpha = 0
                UIView.animate(withDuration: LMKAnimationHelper.Duration.uiShort) {
                    self.subtitleLabel.alpha = 1
                    self.view.layoutIfNeeded()
                }
            }
        }
        UIAccessibility.post(notification: .announcement, argument: text)
    }
}
