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
    /// Offset 0 is the resting position; positive offsets slide the sheet
    /// down and off-screen, negative offsets lift it (keyboard avoidance).
    ///
    /// While ``avoidsKeyboard`` is `true` (the default) the controller owns
    /// the keyboard portion of this offset — subclasses must not also drive it
    /// from their own keyboard observers, or the two writers will fight.
    /// Return `false` from ``avoidsKeyboard`` to restore fully manual control.
    public var containerBottomConstraint: Constraint?

    /// Whether the sheet lifts itself above the software keyboard. Default `true`.
    ///
    /// When enabled, keyboard frame changes raise the container by the actual
    /// overlap between the keyboard and this view (so floating keyboards and
    /// short or side-by-side windows lift only as much as they're covered),
    /// animated with the keyboard's own curve and duration, and restore it on
    /// hide. Composes with drag-to-dismiss: starting a pan resigns the first
    /// responder, the hide restore runs, and pan offsets stay absolute against
    /// the resting position.
    open var avoidsKeyboard: Bool { true }

    private let cancelTitle: String
    private static let dismissVelocityThreshold: CGFloat = 500
    private static let dismissDistanceRatio: CGFloat = 0.3
    /// Stored drag velocity for momentum-based dismiss animation.
    private var pendingDismissVelocity: CGFloat = 0
    /// Guards the slide-in so it runs exactly once whether the trigger is the
    /// appearance callback or `addAsChild`'s explicit kick.
    private var hasAnimatedIn = false
    /// Observer backing ``avoidsKeyboard``; nil when the feature is off.
    private var keyboardObserver: LMKKeyboardObserver?
    /// Current upward keyboard lift applied to `containerBottomConstraint` (>= 0).
    private var keyboardLift: CGFloat = 0

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
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override open func viewDidLoad() {
        super.viewDidLoad()
        setupBaseUI()
        setupSheetContent()
        setupKeyboardAvoidance()
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: Self, _: UITraitCollection) in
            self.refreshBaseColors()
            self.refreshSheetColors()
        }
    }

    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        animateInIfNeeded()
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
        // Cap the container against the hosting view, not the screen: the sheet
        // may live in a view smaller than the screen (child-VC embedding, form
        // sheets, resizable Catalyst windows), and a screen-based cap lets tall
        // content push the sheet's top chrome (drag indicator, back button)
        // above the hosting view's bounds — drawn but unreachable by hit-testing.
        // The screen-based computeMaxHeight() remains only as the initial
        // off-screen offset, which is always >= the resolved container height.
        let maxHeight = computeMaxHeight()
        containerView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.height.lessThanOrEqualTo(view.snp.height).multipliedBy(LMKBottomSheetLayout.maxScreenHeightRatio)
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

    /// Animate the sheet in unless it already has. The appearance-callback and
    /// `addAsChild` triggers can both fire on a regular host; only one slide
    /// should run.
    private func animateInIfNeeded() {
        guard !hasAnimatedIn else { return }
        hasAnimatedIn = true
        animateIn()
    }

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
        // The sheet is leaving: stop tracking the keyboard so a hide
        // notification arriving mid-animation can't fight the slide-out by
        // rewriting the bottom offset it is animating.
        keyboardObserver?.stopObserving()
        keyboardObserver = nil

        let containerHeight = containerView.frame.height
        let currentOffset = containerView.frame.minY - (view.bounds.height - containerHeight)
        let remainingDistance = max(containerHeight - currentOffset, 1)

        let baseDuration = LMKAnimationHelper.Duration.actionSheet
        let duration: TimeInterval = if velocity > 0 {
            min(max(Double(remainingDistance / velocity), 0.1), baseDuration)
        } else {
            baseDuration * (remainingDistance / max(containerHeight, 1))
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

    // MARK: - Keyboard Avoidance

    /// Installs the keyboard observer backing ``avoidsKeyboard``.
    private func setupKeyboardAvoidance() {
        guard avoidsKeyboard else { return }
        let observer = LMKKeyboardObserver()
        observer.onKeyboardChange = { [weak self] info in
            self?.applyKeyboardLift(for: info)
        }
        observer.startObserving()
        keyboardObserver = observer
    }

    /// Raises the container by the keyboard overlap (offset 0 → negative
    /// overlap on `containerBottomConstraint`), or restores it on hide, using
    /// the keyboard's own animation curve and duration.
    private func applyKeyboardLift(for info: LMKKeyboardObserver.KeyboardInfo) {
        let overlap = keyboardOverlap(for: info)
        guard overlap != keyboardLift else { return }
        keyboardLift = overlap
        containerBottomConstraint?.update(offset: -overlap)
        let duration = LMKAnimationHelper.shouldAnimate ? info.animationDuration : 0
        UIView.animate(withDuration: duration, delay: 0, options: info.animationOptions) {
            self.view.layoutIfNeeded()
        }
    }

    /// Actual overlap between the keyboard's end frame and this view — not the
    /// raw keyboard height, which overstates the lift for floating keyboards
    /// and hosts that don't reach the bottom of the screen.
    private func keyboardOverlap(for info: LMKKeyboardObserver.KeyboardInfo) -> CGFloat {
        guard info.isVisible, view.window != nil else { return 0 }
        let frameInView = view.convert(info.frameEnd, from: nil)
        let intersection = view.bounds.intersection(frameInView)
        return intersection.isNull ? 0 : intersection.height
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

    @objc private func cancelTapped() {
        onDismissTapped()
    }

    @objc private func dimmingViewTapped() {
        onDismissTapped()
    }

    @objc private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        let velocity = gesture.velocity(in: view)
        let containerHeight = containerView.frame.height

        switch gesture.state {
        case .began:
            // A drag takes the keyboard down with it. Pan offsets are absolute
            // against the resting position, so a sheet held above the keyboard
            // — by the built-in avoidsKeyboard lift (offset -overlap) or a
            // manual subclass offset — would otherwise snap the full keyboard
            // height on the first changed event while the keyboard stays up
            // covering it. Resigning here lets the keyboard-hide restore bring
            // the offset back to 0 before drag offsets start landing, keeping
            // both writers in the same coordinate space.
            view.endEditing(true)

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
        // Container controllers (UINavigationController & co.) don't forward
        // appearance callbacks to manually-added children, so the viewDidAppear
        // trigger may never arrive — the sheet would sit invisible below the
        // host while its clear dimming view eats every touch. Resolve the
        // off-screen start position, then animate in explicitly; the guard
        // keeps regular hosts (whose viewDidAppear does fire) to one slide.
        sheet.view.layoutIfNeeded()
        sheet.animateInIfNeeded()
    }
}
