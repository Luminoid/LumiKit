//
//  LMKProgressViewController.swift
//  LumiKit
//
//  Blocking progress modal for long-running operations: a spinner or a
//  progress bar with a task line, an optional subtitle, terminal states, and
//  a cancel button, styled from `theme.progress`.
//

import LumiKitCore
import SnapKit
import UIKit

/// Blocking progress modal with an activity indicator, an optional progress bar, and a cancel button.
///
/// ```swift
/// let hud = LMKProgressViewController(title: "Importing")
/// hud.onCancel = { [weak hud] in importTask.cancel(); hud?.dismiss() }
/// hud.present(from: self)
/// hud.observe(importProgress)          // or hud.updateProgress(0.4, task: "Reading files")
/// hud.setState(.succeeded)             // checkmark; then hud.dismiss()
/// ```
///
/// The cancel button renders only while `onCancel` is set; wire it to dismiss as well as
/// cancel, since an early-exit path may never reach the flow's own dismiss. The VoiceOver
/// escape gesture and the Escape key (iPad, Mac) run `onCancel` too.
public final class LMKProgressViewController: UIViewController, LMKThemeApplying {
    // MARK: - Vocabulary

    /// Display mode.
    public nonisolated enum Mode: Sendable, Hashable, CaseIterable {
        /// A progress bar with a percentage and a task line.
        case determinate
        /// A spinner with the title (and an optional subtitle).
        case indeterminate
    }

    /// Where the operation stands.
    public nonisolated enum State: Sendable, Hashable, CaseIterable {
        case running
        case succeeded
        case failed
    }

    // MARK: - Style

    public nonisolated struct Style: Sendable, Equatable, LMKThemeExtension {
        /// Container background (`backgroundPrimary`), corners (large), shadow (`level3`), content insets.
        public var surface: LMKSurfaceStyle
        /// `nil` = 280.
        public var containerWidth: CGFloat?
        /// `nil` = 4.
        public var barHeight: CGFloat?
        /// `nil` = `primary`.
        public var barTint: UIColor?
        /// `nil` = `backgroundSecondary`.
        public var barTrackColor: UIColor?
        /// `nil` = `h3`.
        public var titleTextStyle: LMKTextStyle?
        /// `nil` = `textPrimary`.
        public var titleColor: UIColor?
        /// Subtitle and percentage; `nil` = `caption`.
        public var detailTextStyle: LMKTextStyle?
        /// `nil` = `textSecondary`.
        public var detailColor: UIColor?
        /// The task line; `nil` = `body`.
        public var taskTextStyle: LMKTextStyle?
        /// `nil` = `scrim`.
        public var dimmingColor: UIColor?
        /// `nil` = `alpha.large`.
        public var dimmingAlpha: CGFloat?
        /// Gap between blocks; `nil` = `large`.
        public var spacing: CGFloat?
        /// Layered on the cancel button (ghost, `textPrimary`).
        public var cancelButton: LMKButton.Style
        /// Glyph tint for `.succeeded`; `nil` = `success`.
        public var successColor: UIColor?
        /// Glyph tint for `.failed`; `nil` = `error`.
        public var failureColor: UIColor?

        public init(
            surface: LMKSurfaceStyle = LMKSurfaceStyle(),
            containerWidth: CGFloat? = nil,
            barHeight: CGFloat? = nil,
            barTint: UIColor? = nil,
            barTrackColor: UIColor? = nil,
            titleTextStyle: LMKTextStyle? = nil,
            titleColor: UIColor? = nil,
            detailTextStyle: LMKTextStyle? = nil,
            detailColor: UIColor? = nil,
            taskTextStyle: LMKTextStyle? = nil,
            dimmingColor: UIColor? = nil,
            dimmingAlpha: CGFloat? = nil,
            spacing: CGFloat? = nil,
            cancelButton: LMKButton.Style = LMKButton.Style(),
            successColor: UIColor? = nil,
            failureColor: UIColor? = nil
        ) {
            self.surface = surface
            self.containerWidth = containerWidth
            self.barHeight = barHeight
            self.barTint = barTint
            self.barTrackColor = barTrackColor
            self.titleTextStyle = titleTextStyle
            self.titleColor = titleColor
            self.detailTextStyle = detailTextStyle
            self.detailColor = detailColor
            self.taskTextStyle = taskTextStyle
            self.dimmingColor = dimmingColor
            self.dimmingAlpha = dimmingAlpha
            self.spacing = spacing
            self.cancelButton = cancelButton
            self.successColor = successColor
            self.failureColor = failureColor
        }

        public static let defaultValue = Self()

        /// `other`'s non-nil fields over this style's.
        public func merging(_ other: Self) -> Self {
            Self(
                surface: surface.merging(other.surface),
                containerWidth: other.containerWidth ?? containerWidth,
                barHeight: other.barHeight ?? barHeight,
                barTint: other.barTint ?? barTint,
                barTrackColor: other.barTrackColor ?? barTrackColor,
                titleTextStyle: other.titleTextStyle ?? titleTextStyle,
                titleColor: other.titleColor ?? titleColor,
                detailTextStyle: other.detailTextStyle ?? detailTextStyle,
                detailColor: other.detailColor ?? detailColor,
                taskTextStyle: other.taskTextStyle ?? taskTextStyle,
                dimmingColor: other.dimmingColor ?? dimmingColor,
                dimmingAlpha: other.dimmingAlpha ?? dimmingAlpha,
                spacing: other.spacing ?? spacing,
                cancelButton: cancelButton.merging(other.cancelButton),
                successColor: other.successColor ?? successColor,
                failureColor: other.failureColor ?? failureColor
            )
        }
    }

    // MARK: - Strings

    public nonisolated struct Strings: Sendable, Equatable {
        public var cancel: String

        public init(cancel: String = LMKLocalized("progress.cancel")) {
            self.cancel = cancel
        }
    }

    /// Process-wide defaults; set at app launch to override.
    public nonisolated(unsafe) static var strings = Strings()

    /// Per-instance strings (default `Self.strings`).
    public var strings: Strings = LMKProgressViewController.strings {
        didSet { cancelButton.title = strings.cancel }
    }

    // MARK: - Subviews

    public let containerView: UIView = LMKSurfaceView()
    public let contentStack = UIStackView()
    public let activityIndicator = UIActivityIndicatorView(style: .medium)
    /// The checkmark or xmark shown in a terminal state.
    public let statusImageView = UIImageView()
    public let titleLabel = UILabel()
    public let subtitleLabel = UILabel()
    public let taskLabel = UILabel()
    public let progressView = UIProgressView(progressViewStyle: .default)
    public let progressLabel = UILabel()
    public let cancelButton = LMKButton(style: LMKButton.Style())

    // MARK: - State

    public let mode: Mode

    override public var title: String? {
        didSet { titleLabel.lmk_setText(title) }
    }

    /// A secondary line under the title (the home for "this is taking longer than usual").
    /// Announced to VoiceOver when it changes on screen.
    public var subtitle: String? {
        didSet {
            subtitleLabel.lmk_setText(subtitle)
            subtitleLabel.isHidden = subtitle == nil || state != .running
            if let subtitle, isViewLoaded, view.window != nil {
                UIAccessibility.post(notification: .announcement, argument: subtitle)
            }
        }
    }

    /// The current progress (0 to 1).
    public private(set) var progress: Float = 0

    /// The operation's state; `setState(_:message:)` changes it.
    public private(set) var state: State = .running

    /// Called when the cancel button is tapped; the button renders only while this is set.
    public var onCancel: (() -> Void)? {
        didSet { cancelButton.isHidden = onCancel == nil }
    }

    /// Per-instance style; `nil` fields resolve from `theme.progress`, then the built-in look.
    public var style: Style {
        didSet {
            guard style != oldValue, isViewLoaded else { return }
            applyTheme(traitCollection.lmkTheme)
        }
    }

    /// Called at the end of every `applyTheme`, for tweaks the style does not cover.
    public var didApplyStyle: ((LMKProgressViewController) -> Void)?

    /// The style last resolved against the theme.
    public private(set) var resolvedStyle = Style()

    /// `present(from:)` has started and the modal has not appeared yet; a `dismiss` in that
    /// window is deferred, since UIKit drops a dismissal that overlaps its presentation.
    private(set) var isPresentationInFlight = false
    /// Whether a `dismiss` is waiting for the presentation to land.
    private(set) var hasPendingDismiss = false
    private var pendingDismissCompletion: (() -> Void)?

    private var progressObservation: NSKeyValueObservation?
    private var descriptionObservation: NSKeyValueObservation?
    private var lastAnnouncementTime: Date = .distantPast
    private var containerWidthConstraint: Constraint?
    private var barHeightConstraint: Constraint?
    private var contentInsetsConstraint: Constraint?
    private var horizontalSafeAreaInsetConstraints: [Constraint] = []
    private var verticalSafeAreaInsetConstraints: [Constraint] = []

    static let defaultContainerWidth: CGFloat = 280
    static let defaultBarHeight: CGFloat = 4
    private static let announcementThrottleInterval: TimeInterval = 2

    // MARK: - Initialization

    public init(title: String, subtitle: String? = nil, mode: Mode = .determinate, style: Style = Style()) {
        self.mode = mode
        self.style = style
        super.init(nibName: nil, bundle: nil)
        self.title = title
        self.subtitle = subtitle
        titleLabel.text = title
        subtitleLabel.text = subtitle
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
        isModalInPresentation = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        progressObservation?.invalidate()
        descriptionObservation?.invalidate()
    }

    // MARK: - Lifecycle

    override public func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        lmk_startApplyingTheme()
    }

    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIAccessibility.post(notification: .screenChanged, argument: titleLabel)
        // Hardware keyboards matter on the iPad and the Mac; claiming first responder on a phone
        // buys nothing (and stalls the xctest host).
        if traitCollection.userInterfaceIdiom != .phone {
            becomeFirstResponder()
        }
        presentationDidLand()
    }

    override public var canBecomeFirstResponder: Bool { onCancel != nil }

    override public var keyCommands: [UIKeyCommand]? {
        guard onCancel != nil else { return nil }
        let escape = UIKeyCommand(input: UIKeyCommand.inputEscape, modifierFlags: [], action: #selector(escapePressed))
        escape.discoverabilityTitle = strings.cancel
        return [escape]
    }

    override public func accessibilityPerformEscape() -> Bool {
        guard let onCancel else { return false }
        onCancel()
        return true
    }

    // MARK: - Presentation

    /// Presents the modal over `host`. A `dismiss` before the presentation lands is deferred,
    /// not dropped. A host that is already presenting cannot take it; the call is logged and skipped.
    public func present(from host: UIViewController) {
        guard host.presentedViewController == nil else {
            LMKLogger.warning("Progress modal not presented: \(type(of: host)) is already presenting", category: .ui)
            return
        }
        isPresentationInFlight = true
        host.present(self, animated: true) { [weak self] in
            self?.presentationDidLand()
        }
    }

    /// Stops observing and dismisses the modal; `completion` runs after the dismissal, at once
    /// for a modal that was never presented, and once the presentation lands for a call made
    /// while it is still animating.
    public func dismiss(completion: (() -> Void)? = nil) {
        progressObservation?.invalidate()
        progressObservation = nil
        descriptionObservation?.invalidate()
        descriptionObservation = nil
        guard !isPresentationInFlight else {
            hasPendingDismiss = true
            pendingDismissCompletion = completion
            return
        }
        guard presentingViewController != nil else {
            completion?()
            return
        }
        dismiss(animated: true, completion: completion)
    }

    /// Clears the in-flight presentation and runs a dismiss that waited for it.
    private func presentationDidLand() {
        guard isPresentationInFlight else { return }
        isPresentationInFlight = false
        guard hasPendingDismiss else { return }
        let completion = pendingDismissCompletion
        hasPendingDismiss = false
        pendingDismissCompletion = nil
        dismiss(completion: completion)
    }

    // MARK: - Setup

    private func setupUI() {
        view.accessibilityViewIsModal = true
        view.addSubview(containerView)
        containerView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            // Below required, so a container taller than the safe area keeps its top and bottom
            // (the cancel button) on screen instead of centering off it.
            make.centerY.equalToSuperview().priority(.high)
            containerWidthConstraint = make.width.equalTo(Self.defaultContainerWidth).constraint
            horizontalSafeAreaInsetConstraints = [
                make.leading.greaterThanOrEqualTo(view.safeAreaLayoutGuide).inset(0).constraint,
                make.trailing.lessThanOrEqualTo(view.safeAreaLayoutGuide).inset(0).constraint,
            ]
            verticalSafeAreaInsetConstraints = [
                make.top.greaterThanOrEqualTo(view.safeAreaLayoutGuide).inset(0).constraint,
                make.bottom.lessThanOrEqualTo(view.safeAreaLayoutGuide).inset(0).constraint,
            ]
        }
        containerWidthConstraint?.update(priority: .high)

        activityIndicator.hidesWhenStopped = true
        statusImageView.contentMode = .scaleAspectFit
        statusImageView.isHidden = true
        for label in [titleLabel, subtitleLabel, taskLabel, progressLabel] {
            label.textAlignment = .center
            label.numberOfLines = 0
        }
        titleLabel.accessibilityTraits = .header
        subtitleLabel.isHidden = subtitle == nil
        progressView.snp.makeConstraints { make in
            barHeightConstraint = make.height.equalTo(Self.defaultBarHeight).constraint
        }
        cancelButton.title = strings.cancel
        cancelButton.onTap = { [weak self] in self?.onCancel?() }
        cancelButton.isHidden = onCancel == nil

        contentStack.axis = .vertical
        contentStack.alignment = .fill
        let indicatorRow = UIStackView(arrangedSubviews: [activityIndicator, statusImageView])
        indicatorRow.axis = .horizontal
        indicatorRow.alignment = .center
        indicatorRow.distribution = .equalCentering
        let centered = UIStackView(arrangedSubviews: [indicatorRow])
        centered.axis = .vertical
        centered.alignment = .center
        contentStack.addArrangedSubview(centered)
        contentStack.addArrangedSubview(titleLabel)
        contentStack.addArrangedSubview(subtitleLabel)
        if mode == .determinate {
            contentStack.addArrangedSubview(taskLabel)
            contentStack.addArrangedSubview(progressView)
            contentStack.addArrangedSubview(progressLabel)
            progressView.progress = progress
            progressLabel.text = LMKFormat.progressPercent(progress)
        }
        contentStack.addArrangedSubview(cancelButton)
        containerView.addSubview(contentStack)
        contentStack.snp.makeConstraints { make in
            contentInsetsConstraint = make.directionalEdges.equalToSuperview().inset(0).constraint
        }
        activityIndicator.startAnimating()
    }

    // MARK: - Theme

    public func applyTheme(_ theme: LMKTheme) {
        resolvedStyle = theme.progress.merging(style)
        let resolved = resolvedStyle
        view.backgroundColor = (resolved.dimmingColor ?? LMKColor.scrim).withAlphaComponent(resolved.dimmingAlpha ?? theme.alpha.large)
        let applied = containerView.lmk_apply(
            surface: resolved.surface,
            defaults: LMKSurfaceStyle(
                background: .solid(LMKColor.backgroundPrimary),
                corners: .fixed(theme.cornerRadius.large),
                shadow: .level(.level3),
                contentInsets: NSDirectionalEdgeInsets(top: theme.spacing.xxl, leading: theme.spacing.xl, bottom: theme.spacing.xxl, trailing: theme.spacing.xl)
            )
        )
        let insets = applied.contentInsets ?? .lmk_all(theme.spacing.xl)
        contentInsetsConstraint?.update(inset: insets)
        containerWidthConstraint?.update(offset: resolved.containerWidth ?? Self.defaultContainerWidth)
        for constraint in horizontalSafeAreaInsetConstraints + verticalSafeAreaInsetConstraints {
            constraint.update(inset: theme.spacing.large)
        }

        let spacing = resolved.spacing ?? theme.spacing.large
        contentStack.spacing = spacing
        contentStack.setCustomSpacing(theme.spacing.medium, after: titleLabel)
        contentStack.setCustomSpacing(theme.spacing.small, after: progressView)

        let detailColor = resolved.detailColor ?? LMKColor.textSecondary
        titleLabel.lmk_apply(resolved.titleTextStyle ?? .h3, color: resolved.titleColor ?? LMKColor.textPrimary)
        subtitleLabel.lmk_apply(resolved.detailTextStyle ?? .caption, color: detailColor)
        progressLabel.lmk_apply(resolved.detailTextStyle ?? .caption, color: detailColor)
        taskLabel.lmk_apply(resolved.taskTextStyle ?? .body, color: detailColor)
        progressView.progressTintColor = resolved.barTint ?? LMKColor.primary
        progressView.trackTintColor = resolved.barTrackColor ?? LMKColor.backgroundSecondary
        barHeightConstraint?.update(offset: resolved.barHeight ?? Self.defaultBarHeight)
        activityIndicator.color = resolved.barTint ?? LMKColor.primary
        cancelButton.style = LMKButton.Style(variant: .ghost, foregroundColor: LMKColor.textPrimary, textStyle: .body, pressAnimation: false)
            .merging(resolved.cancelButton)
        applyState()
        didApplyStyle?(self)
    }

    // MARK: - Progress

    /// Updates the bar, the task line, and the percentage; announces the task now and then.
    public func updateProgress(_ progress: Float, task: String) {
        updateProgress(progress)
        taskLabel.lmk_setText(task)
        let now = Date()
        if now.timeIntervalSince(lastAnnouncementTime) >= Self.announcementThrottleInterval {
            lastAnnouncementTime = now
            UIAccessibility.post(notification: .announcement, argument: "\(task) \(LMKFormat.progressPercent(progress))")
        }
    }

    /// Updates the bar and the percentage (kept for the load when called before the view exists).
    public func updateProgress(_ progress: Float) {
        self.progress = min(max(progress, 0), 1)
        progressView.setProgress(self.progress, animated: isViewLoaded && view.window != nil && LMKAnimation.shouldAnimate)
        progressLabel.lmk_setText(LMKFormat.progressPercent(self.progress))
    }

    /// Mirrors a `Progress` until dismissal: its fraction drives the bar and its
    /// `localizedDescription` the task line.
    public func observe(_ progress: Progress) {
        progressObservation?.invalidate()
        descriptionObservation?.invalidate()
        progressObservation = progress.observe(\.fractionCompleted, options: [.initial, .new]) { [weak self] progress, _ in
            let fraction = Float(progress.fractionCompleted)
            Task { @MainActor [weak self] in
                self?.updateProgress(fraction)
            }
        }
        descriptionObservation = progress.observe(\.localizedDescription, options: [.initial, .new]) { [weak self] progress, _ in
            let description = progress.localizedDescription ?? ""
            Task { @MainActor [weak self] in
                guard !description.isEmpty else { return }
                self?.taskLabel.lmk_setText(description)
            }
        }
    }

    /// Moves to a terminal state: the spinner and bar give way to a checkmark or xmark, with
    /// `message` on the task line. `.running` restores the live layout.
    public func setState(_ state: State, message: String? = nil) {
        self.state = state
        if let message {
            taskLabel.lmk_setText(message)
        }
        guard isViewLoaded else { return }
        applyState()
        if state != .running, let announcement = message ?? title {
            UIAccessibility.post(notification: .announcement, argument: announcement)
        }
    }

    @objc private func escapePressed() {
        onCancel?()
    }

    private func applyState() {
        let theme = traitCollection.lmkTheme
        let symbolSize = theme.layout.symbolLarge
        switch state {
        case .running:
            statusImageView.isHidden = true
            activityIndicator.startAnimating()
            subtitleLabel.isHidden = subtitle == nil
            progressView.isHidden = false
            progressLabel.isHidden = false
            // The spinner layout has no task line; a failure message from an earlier state goes away.
            taskLabel.isHidden = mode == .indeterminate
        case .succeeded, .failed:
            activityIndicator.stopAnimating()
            let name = state == .succeeded ? "checkmark.circle.fill" : "xmark.circle.fill"
            statusImageView.image = UIImage(systemName: name, withConfiguration: UIImage.SymbolConfiguration(pointSize: symbolSize, weight: .medium))
            statusImageView.tintColor = state == .succeeded ? (resolvedStyle.successColor ?? LMKColor.success) : (resolvedStyle.failureColor ?? LMKColor.error)
            statusImageView.isHidden = false
            subtitleLabel.isHidden = true
            progressView.isHidden = true
            progressLabel.isHidden = true
            taskLabel.isHidden = mode == .indeterminate && taskLabel.text == nil
        }
        if mode == .indeterminate, state != .running, taskLabel.superview == nil, taskLabel.text != nil {
            contentStack.insertArrangedSubview(taskLabel, at: min(3, contentStack.arrangedSubviews.count))
        }
    }
}

public nonisolated extension LMKTheme {
    /// App-wide default style for `LMKProgressViewController`.
    var progress: LMKProgressViewController.Style {
        get { self[LMKProgressViewController.Style.self] }
        set { self[LMKProgressViewController.Style.self] = newValue }
    }
}
