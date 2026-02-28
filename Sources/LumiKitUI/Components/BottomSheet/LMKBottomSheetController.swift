//
//  LMKBottomSheetController.swift
//  LumiKit
//
//  Base class for bottom sheet view controllers. Provides shared
//  dimming, container, drag indicator, cancel button, and animation.
//

import SnapKit
import UIKit

/// Base class for bottom sheet presentation with design-token styling.
///
/// Provides shared UI infrastructure:
/// - Dimming overlay with tap-to-dismiss
/// - Container with rounded top corners
/// - Drag indicator
/// - Cancel button at bottom
/// - Slide-in / slide-out animation
/// - Drag-to-dismiss on the container
/// - Dynamic color refresh on trait changes
///
/// Subclasses override `setupSheetContent()` to build their content
/// inside `containerView`, between `dragIndicator` and `cancelButton`.
///
/// Use `addAsChild(_:in:)` to present a bottom sheet as a child VC.
open class LMKBottomSheetController: UIViewController {
    // MARK: - Properties

    /// Constraint controlling the container's bottom offset for animation.
    public var containerBottomConstraint: Constraint?

    private let cancelTitle: String
    private static let dismissVelocityThreshold: CGFloat = 500
    private static let dismissDistanceRatio: CGFloat = 0.3
    /// Stored drag velocity for momentum-based dismiss animation.
    private var pendingDismissVelocity: CGFloat = 0

    // MARK: - Lazy Views

    public private(set) lazy var dimmingView: UIView = {
        let view = UIView()
        view.backgroundColor = LMKColor.black.withAlphaComponent(LMKAlpha.dimmingOverlay)
        view.alpha = 0
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dimmingViewTapped)))
        return view
    }()

    public private(set) lazy var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = LMKColor.backgroundPrimary
        view.layer.cornerRadius = LMKCornerRadius.large
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        return view
    }()

    public private(set) lazy var dragIndicator: UIView = {
        let view = UIView()
        view.backgroundColor = LMKColor.divider
        view.layer.cornerRadius = LMKBottomSheetLayout.dragIndicatorCornerRadius
        return view
    }()

    public private(set) lazy var cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(cancelTitle, for: .normal)
        button.titleLabel?.font = LMKTypography.bodyMedium
        button.setTitleColor(LMKColor.textPrimary, for: .normal)
        button.backgroundColor = LMKColor.backgroundSecondary
        button.layer.cornerRadius = LMKCornerRadius.medium
        button.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        return button
    }()

    // MARK: - Initialization

    /// Create a bottom sheet controller.
    /// - Parameter cancelTitle: Title for the cancel button. Defaults to `LMKAlertPresenter.strings.cancel`.
    public init(cancelTitle: String? = nil) {
        self.cancelTitle = cancelTitle ?? LMKAlertPresenter.strings.cancel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - Lifecycle

    override open func viewDidLoad() {
        super.viewDidLoad()
        setupBaseUI()
        setupSheetContent()
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: LMKBottomSheetController, _: UITraitCollection) in
            self.refreshBaseColors()
            self.refreshSheetColors()
        }
    }

    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        animateIn()
    }

    // MARK: - Base UI Setup

    /// Builds the shared bottom sheet UI: dimming, container, drag indicator, cancel button.
    ///
    /// Subclasses should NOT call this directly — it's called automatically in `viewDidLoad`.
    /// Add content to `containerView` in `setupSheetContent()`.
    private func setupBaseUI() {
        view.backgroundColor = .clear

        view.addSubview(dimmingView)
        dimmingView.snp.makeConstraints { make in make.edges.equalToSuperview() }

        view.addSubview(containerView)
        let maxHeight = computeMaxHeight()
        containerView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.height.lessThanOrEqualTo(maxHeight)
            containerBottomConstraint = make.bottom.equalToSuperview().offset(maxHeight).constraint
        }

        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        containerView.addGestureRecognizer(panGesture)

        containerView.addSubview(dragIndicator)
        dragIndicator.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(LMKSpacing.small)
            make.centerX.equalToSuperview()
            make.width.equalTo(LMKBottomSheetLayout.dragIndicatorWidth)
            make.height.equalTo(LMKBottomSheetLayout.dragIndicatorHeight)
        }

        containerView.addSubview(cancelButton)
        cancelButton.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(LMKSpacing.xl)
            make.bottom.equalTo(containerView.safeAreaLayoutGuide.snp.bottom).inset(LMKSpacing.xl)
            make.height.equalTo(LMKBottomSheetLayout.buttonHeight)
        }
    }

    // MARK: - Template Methods (Override in Subclasses)

    /// Override to add sheet-specific content to `containerView`.
    /// Called after `setupBaseUI()` in `viewDidLoad`.
    open func setupSheetContent() {}

    /// Override to refresh sheet-specific dynamic colors on trait changes.
    /// Base colors (dimming, container, indicator, cancel) are refreshed automatically.
    open func refreshSheetColors() {}

    /// Called when the dimming view is tapped or cancel button pressed.
    /// Override to perform additional actions (e.g. call an onDismiss callback).
    /// Default implementation calls `dismissSheet()`.
    open func onDismissTapped() {
        dismissSheet()
    }

    // MARK: - Animation

    /// Animate the sheet into view.
    public func animateIn() {
        containerBottomConstraint?.update(offset: 0)
        animateSheet(
            duration: LMKAnimationHelper.Duration.modalPresentation,
            curve: LMKAnimationHelper.Curve.easeOut,
            animations: {
                self.view.layoutIfNeeded()
                self.dimmingView.alpha = 1
            }
        )
    }

    /// Animate the sheet out of view, then call the completion handler.
    /// - Parameter velocity: Optional downward velocity (points/sec) from a drag gesture for momentum-based duration.
    public func animateOut(velocity: CGFloat = 0, completion: @escaping () -> Void) {
        let containerHeight = containerView.frame.height
        let currentOffset = containerView.frame.minY - (view.bounds.height - containerHeight)
        let remainingDistance = max(containerHeight - currentOffset, 1)

        let baseDuration = LMKAnimationHelper.Duration.actionSheet
        let duration: TimeInterval
        if velocity > 0 {
            duration = min(max(Double(remainingDistance / velocity), 0.1), baseDuration)
        } else {
            duration = baseDuration * (remainingDistance / max(containerHeight, 1))
        }

        containerBottomConstraint?.update(offset: containerHeight)
        animateSheet(
            duration: duration,
            curve: LMKAnimationHelper.Curve.easeIn,
            animations: {
                self.view.layoutIfNeeded()
                self.dimmingView.alpha = 0
            },
            completion: completion
        )
    }

    // MARK: - Dismissal

    /// Animate out and remove from parent. Call this to dismiss the sheet.
    public func dismissSheet() {
        let velocity = pendingDismissVelocity
        pendingDismissVelocity = 0
        animateOut(velocity: velocity) { [weak self] in
            guard let self else { return }
            self.willMove(toParent: nil)
            self.view.removeFromSuperview()
            self.removeFromParent()
        }
    }

    // MARK: - Actions

    @objc private func cancelTapped() { onDismissTapped() }
    @objc private func dimmingViewTapped() { onDismissTapped() }

    @objc private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        let velocity = gesture.velocity(in: view)
        let containerHeight = containerView.frame.height

        switch gesture.state {
        case .changed:
            let offset = max(translation.y, 0)
            containerBottomConstraint?.update(offset: offset)
            let progress = offset / containerHeight
            dimmingView.alpha = 1 - progress

        case .ended, .cancelled:
            let offset = max(translation.y, 0)
            let shouldDismiss = velocity.y > Self.dismissVelocityThreshold
                || offset > containerHeight * Self.dismissDistanceRatio

            if shouldDismiss {
                pendingDismissVelocity = velocity.y
                onDismissTapped()
            } else {
                containerBottomConstraint?.update(offset: 0)
                animateSheet(
                    duration: LMKAnimationHelper.Duration.uiShort,
                    curve: LMKAnimationHelper.Curve.easeOut,
                    animations: {
                        self.view.layoutIfNeeded()
                        self.dimmingView.alpha = 1
                    }
                )
            }

        default:
            break
        }
    }

    // MARK: - Helpers

    /// Compute the maximum container height based on screen size.
    public func computeMaxHeight() -> CGFloat {
        let screenHeight = view.window?.windowScene?.screen.bounds.height
            ?? LMKSceneUtil.getKeyWindow()?.screen.bounds.height
            ?? view.bounds.height
        return screenHeight * LMKBottomSheetLayout.maxScreenHeightRatio
    }

    /// Unified animation wrapper that respects Reduce Motion.
    private func animateSheet(
        duration: TimeInterval,
        curve: UIView.AnimationOptions,
        animations: @escaping () -> Void,
        completion: (() -> Void)? = nil
    ) {
        let effectiveDuration = LMKAnimationHelper.shouldAnimate ? duration : 0
        UIView.animate(withDuration: effectiveDuration, delay: 0, options: curve, animations: animations) { _ in
            completion?()
        }
    }

    private func refreshBaseColors() {
        dimmingView.backgroundColor = LMKColor.black.withAlphaComponent(LMKAlpha.dimmingOverlay)
        containerView.backgroundColor = LMKColor.backgroundPrimary
        dragIndicator.backgroundColor = LMKColor.divider
        cancelButton.setTitleColor(LMKColor.textPrimary, for: .normal)
        cancelButton.backgroundColor = LMKColor.backgroundSecondary
    }

    // MARK: - Static Convenience

    /// Add a bottom sheet as a child view controller of the parent.
    public static func addAsChild(_ sheet: some LMKBottomSheetController, in parent: UIViewController) {
        parent.addChild(sheet)
        sheet.view.frame = parent.view.bounds
        sheet.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        parent.view.addSubview(sheet.view)
        sheet.didMove(toParent: parent)
    }
}
