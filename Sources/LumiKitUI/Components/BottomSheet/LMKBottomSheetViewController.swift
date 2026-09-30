//
//  LMKBottomSheetViewController.swift
//  LumiKit
//
//  Base class for bottom sheets: dimming, a rounded container, drag indicator,
//  cancel button, slide animation, drag-to-dismiss that cooperates with an
//  inner scroll view, keyboard avoidance, and key commands, styled from
//  `theme.bottomSheet`.
//

import SnapKit
import UIKit

/// Base class for bottom sheet presentation with design-token styling.
///
/// Subclasses override `setupSheetContent()` and pin their content to
/// `contentLayoutGuide` (below the drag indicator, above the cancel button).
/// `present(from:)` adds the sheet as a child of the host and slides it in;
/// `dismiss()` slides it out and removes it. Every way out (cancel button, dimming
/// tap, drag, Esc / ⌘W, or code) reports through `onDismiss` with its reason.
///
/// ```swift
/// final class RenameSheet: LMKBottomSheetViewController {
///     override func setupSheetContent() {
///         containerView.addSubview(field)
///         field.snp.makeConstraints { $0.edges.equalTo(contentLayoutGuide).inset(LMKSpacing.xl) }
///     }
/// }
/// let sheet = RenameSheet()
/// sheet.onDismiss = { reason in ... }
/// sheet.present(from: self)
/// ```
open class LMKBottomSheetViewController: UIViewController, LMKThemeApplying {
    // MARK: - Vocabulary

    /// How a sheet went away.
    public nonisolated enum DismissReason: Sendable, Hashable, CaseIterable {
        case cancelButton
        case dimmingTap
        case drag
        case keyCommand
        case programmatic
    }

    // MARK: - Style

    public nonisolated struct Style: Sendable, Equatable, LMKThemeExtension {
        /// Container background (`backgroundPrimary`), corners (large, top only), border, shadow,
        /// and content insets (`top` = gap between the chrome and the content, `leading` /
        /// `trailing` / `bottom` = cancel button margins).
        public var surface: LMKSurfaceStyle
        /// `nil` = `scrim`.
        public var dimmingColor: UIColor?
        /// `nil` = `alpha.dimming`.
        public var dimmingAlpha: CGFloat?
        /// `nil` = yes.
        public var showsDragIndicator: Bool?
        /// `nil` = 40 × 5.
        public var dragIndicatorSize: CGSize?
        /// `nil` = `divider`.
        public var dragIndicatorColor: UIColor?
        /// `nil` = yes.
        public var showsCancelButton: Bool?
        /// Layered on the default cancel look (filled `backgroundSecondary`, `textPrimary`, 50pt).
        public var cancelButton: LMKButton.Style
        /// Container height cap as a fraction of the host view; `nil` = 0.9.
        public var maxHeightRatio: CGFloat?
        /// Downward drag velocity (pt/s) that dismisses; `nil` = 500.
        public var dismissVelocityThreshold: CGFloat?
        /// Drag distance as a fraction of the container height that dismisses; `nil` = 0.3.
        public var dismissDistanceRatio: CGFloat?

        public init(
            surface: LMKSurfaceStyle = LMKSurfaceStyle(),
            dimmingColor: UIColor? = nil,
            dimmingAlpha: CGFloat? = nil,
            showsDragIndicator: Bool? = nil,
            dragIndicatorSize: CGSize? = nil,
            dragIndicatorColor: UIColor? = nil,
            showsCancelButton: Bool? = nil,
            cancelButton: LMKButton.Style = LMKButton.Style(),
            maxHeightRatio: CGFloat? = nil,
            dismissVelocityThreshold: CGFloat? = nil,
            dismissDistanceRatio: CGFloat? = nil
        ) {
            self.surface = surface
            self.dimmingColor = dimmingColor
            self.dimmingAlpha = dimmingAlpha
            self.showsDragIndicator = showsDragIndicator
            self.dragIndicatorSize = dragIndicatorSize
            self.dragIndicatorColor = dragIndicatorColor
            self.showsCancelButton = showsCancelButton
            self.cancelButton = cancelButton
            self.maxHeightRatio = maxHeightRatio
            self.dismissVelocityThreshold = dismissVelocityThreshold
            self.dismissDistanceRatio = dismissDistanceRatio
        }

        public static let defaultValue = Self()

        /// `other`'s non-nil fields over this style's.
        public func merging(_ other: Self) -> Self {
            Self(
                surface: surface.merging(other.surface),
                dimmingColor: other.dimmingColor ?? dimmingColor,
                dimmingAlpha: other.dimmingAlpha ?? dimmingAlpha,
                showsDragIndicator: other.showsDragIndicator ?? showsDragIndicator,
                dragIndicatorSize: other.dragIndicatorSize ?? dragIndicatorSize,
                dragIndicatorColor: other.dragIndicatorColor ?? dragIndicatorColor,
                showsCancelButton: other.showsCancelButton ?? showsCancelButton,
                cancelButton: cancelButton.merging(other.cancelButton),
                maxHeightRatio: other.maxHeightRatio ?? maxHeightRatio,
                dismissVelocityThreshold: other.dismissVelocityThreshold ?? dismissVelocityThreshold,
                dismissDistanceRatio: other.dismissDistanceRatio ?? dismissDistanceRatio
            )
        }
    }

    // MARK: - Strings

    public nonisolated struct Strings: Sendable, Equatable {
        /// Title of the cancel button.
        public var cancel: String

        public init(cancel: String = LMKLocalized("bottomSheet.cancel")) {
            self.cancel = cancel
        }
    }

    /// Process-wide defaults; set at app launch to override.
    public nonisolated(unsafe) static var strings = Strings()

    /// Per-instance strings (default `Self.strings`).
    public var strings: Strings = LMKBottomSheetViewController.strings {
        didSet { cancelButton.title = strings.cancel }
    }

    // MARK: - Subviews

    public let dimmingView = UIView()
    /// The sheet surface.
    public let containerView: UIView = LMKSurfaceView()
    public let dragIndicator: UIView = LMKSurfaceView()
    public let cancelButton = LMKButton(style: LMKButton.Style())
    /// Where subclass content goes: below the drag indicator, above the cancel button
    /// (or the container's safe-area bottom while the button is hidden).
    public let contentLayoutGuide = UILayoutGuide()

    // MARK: - State

    /// Per-instance style; `nil` fields resolve from `theme.bottomSheet`, then the built-in look.
    public var style: Style {
        didSet {
            guard style != oldValue, isViewLoaded else { return }
            applyTheme(traitCollection.lmkTheme)
        }
    }

    /// Called after the sheet has left the hierarchy, with why.
    public var onDismiss: ((DismissReason) -> Void)?

    /// Called at the end of every `applyTheme`, for tweaks the style does not cover.
    public var didApplyStyle: ((LMKBottomSheetViewController) -> Void)?

    /// Whether the sheet lifts itself above the software keyboard. Default `true`.
    ///
    /// The lift is the keyboard's actual overlap with the sheet's view (so floating
    /// keyboards and short windows lift only what is covered), animated with the
    /// keyboard's own curve, and restored on hide. Starting a drag resigns the first
    /// responder. Override to `false` and use `additionalBottomInset` for manual control.
    open var avoidsKeyboard: Bool { true }

    /// Extra lift above the resting position (a tab bar, a toolbar); adds to the keyboard lift.
    public var additionalBottomInset: CGFloat = 0 {
        didSet {
            guard additionalBottomInset != oldValue, isViewLoaded, hasAnimatedIn else { return }
            containerBottomConstraint?.update(offset: restingOffset)
        }
    }

    /// The style last resolved against the theme.
    public private(set) var resolvedStyle = Style()

    var containerBottomConstraint: Constraint?
    private var maxHeightConstraint: Constraint?
    private var appliedMaxHeightRatio: CGFloat?
    private var dragIndicatorWidthConstraint: Constraint?
    private var dragIndicatorHeightConstraint: Constraint?
    private var cancelHorizontalConstraint: Constraint?
    private var cancelBottomConstraint: Constraint?
    private var contentTopConstraint: Constraint?
    private var contentBottomToCancelConstraint: Constraint?
    private var contentBottomToSafeAreaConstraint: Constraint?
    private var pendingDismissVelocity: CGFloat = 0
    private var hasAnimatedIn = false
    private var isDismissing = false
    private var keyboardObserver: LMKKeyboardObserver?
    private var keyboardLift: CGFloat = 0
    private var animator: UIViewPropertyAnimator?
    private lazy var panDelegate = LMKBottomSheetPanDelegate(owner: self)
    private var isDraggingSheet = false
    private var dragStartTranslation: CGFloat = 0

    static let defaultDragIndicatorSize = CGSize(width: 40, height: 5)
    static let defaultButtonHeight: CGFloat = 50
    static let defaultMaxHeightRatio: CGFloat = 0.9
    static let defaultDismissVelocityThreshold: CGFloat = 500
    static let defaultDismissDistanceRatio: CGFloat = 0.3

    /// The container's resting bottom offset: lifted by the keyboard and the extra inset.
    private var restingOffset: CGFloat {
        -(keyboardLift + additionalBottomInset)
    }

    // MARK: - Initialization

    public init(style: Style = Style()) {
        self.style = style
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
        lmk_startApplyingTheme()
    }

    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupKeyboardAvoidanceIfNeeded()
    }

    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        animateInIfNeeded()
    }

    override open func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        tearDownKeyboardAvoidance()
    }

    // MARK: - Presentation

    /// Adds the sheet as a child of `host`, covering its view, and slides it in.
    public func present(from host: UIViewController) {
        host.addChild(self)
        view.frame = host.view.bounds
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        host.view.addSubview(view)
        didMove(toParent: host)
        setupKeyboardAvoidanceIfNeeded()
        // Container controllers never deliver a manually-added child's viewDidAppear, so
        // resolve the off-screen start position and animate in explicitly; the guard keeps
        // regular hosts (whose callback does fire) to one slide.
        view.layoutIfNeeded()
        animateInIfNeeded()
    }

    // MARK: - Template methods

    /// Override to add content to `containerView`, pinned to `contentLayoutGuide`.
    /// Called from `viewDidLoad` after the base UI exists.
    open func setupSheetContent() {}

    /// Called before the slide-out starts.
    open func willDismiss(reason: DismissReason) {}

    /// Called after the sheet has been removed from its parent (and `onDismiss` ran).
    open func didDismiss(reason: DismissReason) {}

    // MARK: - Theme

    open func applyTheme(_ theme: LMKTheme) {
        resolvedStyle = theme.bottomSheet.merging(style)
        let resolved = resolvedStyle
        dimmingView.backgroundColor = (resolved.dimmingColor ?? LMKColor.scrim).withAlphaComponent(resolved.dimmingAlpha ?? theme.alpha.dimming)

        let applied = containerView.lmk_apply(
            surface: resolved.surface,
            defaults: LMKSurfaceStyle(
                background: .solid(LMKColor.backgroundPrimary),
                corners: .fixed(theme.cornerRadius.large, corners: [.layerMinXMinYCorner, .layerMaxXMinYCorner]),
                shadow: LMKShadowSource.none,
                contentInsets: NSDirectionalEdgeInsets(top: theme.spacing.large, leading: theme.spacing.xl, bottom: theme.spacing.xl, trailing: theme.spacing.xl)
            )
        )
        let insets = applied.contentInsets ?? .lmk_all(theme.spacing.xl)

        let showsIndicator = resolved.showsDragIndicator ?? true
        dragIndicator.isHidden = !showsIndicator
        dragIndicator.lmk_apply(surface: LMKSurfaceStyle(background: .solid(resolved.dragIndicatorColor ?? LMKColor.divider), corners: .capsule))
        let indicatorSize = showsIndicator ? (resolved.dragIndicatorSize ?? Self.defaultDragIndicatorSize) : .zero
        dragIndicatorWidthConstraint?.update(offset: indicatorSize.width)
        dragIndicatorHeightConstraint?.update(offset: indicatorSize.height)

        let showsCancel = resolved.showsCancelButton ?? true
        cancelButton.isHidden = !showsCancel
        cancelButton.style = LMKButton.Style(
            variant: .filled,
            surface: LMKSurfaceStyle(background: .solid(LMKColor.backgroundSecondary), corners: .fixed(theme.cornerRadius.medium)),
            foregroundColor: LMKColor.textPrimary,
            textStyle: .bodyMedium,
            minimumHeight: Self.defaultButtonHeight,
            pressAnimation: false
        ).merging(resolved.cancelButton)
        cancelHorizontalConstraint?.update(inset: UIEdgeInsets(top: 0, left: insets.leading, bottom: 0, right: insets.trailing))
        cancelBottomConstraint?.update(inset: insets.bottom)
        contentTopConstraint?.update(offset: insets.top)
        contentBottomToCancelConstraint?.update(offset: -insets.top)
        contentBottomToSafeAreaConstraint?.update(inset: insets.bottom)
        if showsCancel {
            contentBottomToSafeAreaConstraint?.deactivate()
            contentBottomToCancelConstraint?.activate()
        } else {
            contentBottomToCancelConstraint?.deactivate()
            contentBottomToSafeAreaConstraint?.activate()
        }

        let ratio = resolved.maxHeightRatio ?? Self.defaultMaxHeightRatio
        if appliedMaxHeightRatio != ratio {
            appliedMaxHeightRatio = ratio
            maxHeightConstraint?.deactivate()
            // Cap against the hosting view, not the screen: a sheet in a child controller or a
            // resizable window must keep its top chrome reachable.
            containerView.snp.makeConstraints { make in
                maxHeightConstraint = make.height.lessThanOrEqualTo(view.snp.height).multipliedBy(ratio).constraint
            }
        }
        didApplyStyle?(self)
    }

    // MARK: - Base UI

    private func setupBaseUI() {
        view.backgroundColor = .clear

        dimmingView.alpha = 0
        dimmingView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dimmingViewTapped)))
        view.addSubview(dimmingView)
        dimmingView.snp.makeConstraints { $0.edges.equalToSuperview() }

        view.addSubview(containerView)
        containerView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            containerBottomConstraint = make.bottom.equalToSuperview().offset(initialOffScreenOffset()).constraint
        }
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        pan.delegate = panDelegate
        containerView.addGestureRecognizer(pan)

        dragIndicator.isUserInteractionEnabled = false
        containerView.addSubview(dragIndicator)
        dragIndicator.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(LMKSpacing.small)
            make.centerX.equalToSuperview()
            dragIndicatorWidthConstraint = make.width.equalTo(Self.defaultDragIndicatorSize.width).constraint
            dragIndicatorHeightConstraint = make.height.equalTo(Self.defaultDragIndicatorSize.height).constraint
        }

        cancelButton.title = strings.cancel
        cancelButton.onTap = { [weak self] in self?.dismiss(reason: .cancelButton) }
        containerView.addSubview(cancelButton)
        cancelButton.snp.makeConstraints { make in
            cancelHorizontalConstraint = make.leading.trailing.equalToSuperview().inset(0).constraint
            cancelBottomConstraint = make.bottom.equalTo(containerView.safeAreaLayoutGuide.snp.bottom).inset(0).constraint
        }

        containerView.addLayoutGuide(contentLayoutGuide)
        contentLayoutGuide.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            contentTopConstraint = make.top.equalTo(dragIndicator.snp.bottom).offset(0).constraint
            contentBottomToCancelConstraint = make.bottom.equalTo(cancelButton.snp.top).offset(0).constraint
            contentBottomToSafeAreaConstraint = make.bottom.equalTo(containerView.safeAreaLayoutGuide.snp.bottom).inset(0).constraint
        }
        contentBottomToSafeAreaConstraint?.deactivate()
    }

    /// The off-screen start offset: the largest height the container can take.
    func initialOffScreenOffset() -> CGFloat {
        let height = view.window?.bounds.height ?? LMKScene.keyWindow?.bounds.height ?? view.bounds.height
        return height * (resolvedStyle.maxHeightRatio ?? Self.defaultMaxHeightRatio)
    }

    // MARK: - Animation

    private func animateInIfNeeded() {
        guard !hasAnimatedIn else { return }
        hasAnimatedIn = true
        animateIn()
    }

    /// Slides the sheet into view.
    public func animateIn() {
        containerBottomConstraint?.update(offset: restingOffset)
        animateSheet(duration: LMKAnimation.Duration.moderate, curve: .easeOut) {
            self.view.layoutIfNeeded()
            self.dimmingView.alpha = 1
        } completion: { [weak self] in
            self?.claimFirstResponderIfIdle()
        }
    }

    /// Slides the sheet out of view, then calls `completion`.
    /// - Parameters:
    ///   - velocity: A downward drag velocity (pt/s) for a momentum-matched duration.
    ///   - completion: Called once the sheet is off screen.
    public func animateOut(velocity: CGFloat = 0, completion: @escaping () -> Void) {
        // The sheet is leaving: stop tracking the keyboard so a hide notification arriving
        // mid-animation cannot rewrite the offset being animated.
        tearDownKeyboardAvoidance()

        let containerHeight = containerView.frame.height
        let currentOffset = containerView.frame.minY - (view.bounds.height - containerHeight)
        let remainingDistance = max(containerHeight - currentOffset, 1)
        let baseDuration = LMKAnimation.Duration.normal
        let duration: TimeInterval = if velocity > 0 {
            min(max(Double(remainingDistance / velocity), 0.1), baseDuration)
        } else {
            baseDuration * (remainingDistance / max(containerHeight, 1))
        }

        containerBottomConstraint?.update(offset: containerHeight)
        animateSheet(duration: duration, curve: .easeIn) {
            self.view.layoutIfNeeded()
            self.dimmingView.alpha = 0
        } completion: {
            completion()
        }
    }

    /// Runs `animations` in a property animator, first settling any slide still in flight so
    /// a dismissal during the slide-in (a fast tap on the dimming) completes instead of being
    /// swallowed by the animation it replaces. Immediate without a window or under Reduce Motion.
    private func animateSheet(duration: TimeInterval, curve: LMKAnimation.Curve, animations: @escaping () -> Void, completion: (() -> Void)? = nil) {
        settleInFlightAnimation()
        let effectiveDuration = LMKAnimation.shouldAnimate ? duration : 0
        guard effectiveDuration > 0, view.window != nil else {
            animations()
            completion?()
            return
        }
        let animator = UIViewPropertyAnimator(duration: effectiveDuration, curve: curve.animationCurve, animations: animations)
        let once = LMKOnceCompletion(after: effectiveDuration) { [weak self] in
            if self?.animator === animator {
                self?.animator = nil
            }
            completion?()
        }
        animator.addCompletion { _ in once.fire() }
        self.animator = animator
        animator.startAnimation()
    }

    /// Finishes the slide in flight at its current position (its completion runs now).
    func settleInFlightAnimation() {
        guard let animator else { return }
        self.animator = nil
        if animator.state == .active {
            animator.stopAnimation(false)
        }
        if animator.state == .stopped {
            animator.finishAnimation(at: .current)
        }
    }

    // MARK: - Dismissal

    /// Slides the sheet out and removes it from its parent (`reason` = `.programmatic`).
    public func dismiss() {
        dismiss(reason: .programmatic)
    }

    /// Slides the sheet out and removes it from its parent, reporting `reason`.
    public func dismiss(reason: DismissReason) {
        guard !isDismissing else { return }
        isDismissing = true
        if isFirstResponder {
            resignFirstResponder()
        }
        willDismiss(reason: reason)
        let velocity = pendingDismissVelocity
        pendingDismissVelocity = 0
        animateOut(velocity: velocity) { [weak self] in
            guard let self else { return }
            willMove(toParent: nil)
            view.removeFromSuperview()
            removeFromParent()
            onDismiss?(reason)
            didDismiss(reason: reason)
        }
    }

    // MARK: - Key commands

    override open var canBecomeFirstResponder: Bool { true }

    override open var keyCommands: [UIKeyCommand]? {
        [
            UIKeyCommand(input: UIKeyCommand.inputEscape, modifierFlags: [], action: #selector(dismissFromKeyCommand)),
            UIKeyCommand(input: "w", modifierFlags: .command, action: #selector(dismissFromKeyCommand)),
        ]
    }

    @objc private func dismissFromKeyCommand() {
        dismiss(reason: .keyCommand)
    }

    /// Takes first responder on iPad and Mac (where hardware key commands matter) so Esc / ⌘W
    /// reach the sheet, unless a field inside is editing.
    private func claimFirstResponderIfIdle() {
        guard traitCollection.userInterfaceIdiom != .phone, view.window != nil, !isDismissing, !Self.containsFirstResponder(view) else { return }
        becomeFirstResponder()
    }

    private static func containsFirstResponder(_ view: UIView) -> Bool {
        if view.isFirstResponder { return true }
        return view.subviews.contains { containsFirstResponder($0) }
    }

    // MARK: - Keyboard avoidance

    private func setupKeyboardAvoidanceIfNeeded() {
        guard avoidsKeyboard, keyboardObserver == nil else { return }
        let observer = LMKKeyboardObserver()
        observer.onKeyboardChange = { [weak self] info in
            self?.applyKeyboardLift(for: info)
        }
        observer.startObserving()
        keyboardObserver = observer
    }

    private func tearDownKeyboardAvoidance() {
        keyboardObserver?.stopObserving()
        keyboardObserver = nil
    }

    private func applyKeyboardLift(for info: LMKKeyboardObserver.KeyboardInfo) {
        let overlap = keyboardOverlap(for: info)
        guard overlap != keyboardLift, !isDismissing else { return }
        keyboardLift = overlap
        containerBottomConstraint?.update(offset: restingOffset)
        let duration = LMKAnimation.shouldAnimate ? info.animationDuration : 0
        UIView.animate(withDuration: duration, delay: 0, options: info.animationOptions) {
            self.view.layoutIfNeeded()
        }
    }

    /// The keyboard's overlap with this view, not its raw height: floating keyboards and
    /// hosts that stop short of the screen bottom lift only what they are covered by.
    private func keyboardOverlap(for info: LMKKeyboardObserver.KeyboardInfo) -> CGFloat {
        guard info.isVisible, view.window != nil else { return 0 }
        let frameInView = view.convert(info.frameEnd, from: nil)
        let intersection = view.bounds.intersection(frameInView)
        return intersection.isNull ? 0 : intersection.height
    }

    // MARK: - Actions

    @objc private func dimmingViewTapped() {
        dismiss(reason: .dimmingTap)
    }

    // MARK: - Drag

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view).y
        let velocity = gesture.velocity(in: view).y
        let containerHeight = containerView.frame.height
        let innerScrollView = panDelegate.innerScrollView

        switch gesture.state {
        case .began:
            // A drag takes the keyboard down with it; resigning here lets the hide restore
            // land before drag offsets do, so both writers share one coordinate space.
            view.endEditing(true)
            isDraggingSheet = innerScrollView == nil
            dragStartTranslation = 0

        case .changed:
            if let innerScrollView, !isDraggingSheet {
                // The sheet only follows a downward drag that starts with the list at its top;
                // everything else is the scroll view's.
                let atTop = innerScrollView.contentOffset.y <= -innerScrollView.adjustedContentInset.top + 0.5
                guard atTop, translation - dragStartTranslation > 0 else {
                    dragStartTranslation = translation
                    return
                }
                isDraggingSheet = true
            }
            if let innerScrollView {
                innerScrollView.contentOffset.y = -innerScrollView.adjustedContentInset.top
            }
            let offset = max(translation - dragStartTranslation, 0)
            containerBottomConstraint?.update(offset: restingOffset + offset)
            dimmingView.alpha = 1 - offset / max(containerHeight, 1)

        case .ended, .cancelled:
            guard isDraggingSheet else { return }
            isDraggingSheet = false
            let offset = max(translation - dragStartTranslation, 0)
            let velocityThreshold = resolvedStyle.dismissVelocityThreshold ?? Self.defaultDismissVelocityThreshold
            let distanceRatio = resolvedStyle.dismissDistanceRatio ?? Self.defaultDismissDistanceRatio
            if gesture.state == .ended, velocity > velocityThreshold || offset > containerHeight * distanceRatio {
                pendingDismissVelocity = velocity
                dismiss(reason: .drag)
            } else {
                containerBottomConstraint?.update(offset: restingOffset)
                animateSheet(duration: LMKAnimation.Duration.fast, curve: .easeOut) {
                    self.view.layoutIfNeeded()
                    self.dimmingView.alpha = 1
                }
            }

        default:
            break
        }
    }
}

/// The container pan's delegate: lets an inner scroll view's pan run alongside so the
/// sheet can take over a downward drag once the list is at its top.
private final class LMKBottomSheetPanDelegate: NSObject, UIGestureRecognizerDelegate {
    private weak var owner: LMKBottomSheetViewController?
    private(set) weak var innerScrollView: UIScrollView?

    init(owner: LMKBottomSheetViewController) {
        self.owner = owner
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool {
        guard let scrollView = other.view as? UIScrollView, other === scrollView.panGestureRecognizer,
              let container = owner?.containerView, scrollView.isDescendant(of: container)
        else {
            return false
        }
        innerScrollView = scrollView
        return true
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        innerScrollView = nil
        return true
    }
}

public nonisolated extension LMKTheme {
    /// App-wide default style for `LMKBottomSheetViewController` and its subclasses.
    var bottomSheet: LMKBottomSheetViewController.Style {
        get { self[LMKBottomSheetViewController.Style.self] }
        set { self[LMKBottomSheetViewController.Style.self] = newValue }
    }
}
