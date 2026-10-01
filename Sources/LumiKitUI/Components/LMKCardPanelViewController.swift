//
//  LMKCardPanelViewController.swift
//  LumiKit
//
//  Centered floating card panel hosting an embedded navigation controller,
//  presented in its own overlay window or as a modal, styled from
//  `theme.cardPanel`.
//

import LumiKitCore
import SnapKit
import UIKit

/// Centered floating card with a shadow and a slide-in / slide-out animation.
///
/// Hosts an embedded `UINavigationController` (system bar hidden) inside a rounded
/// card. `presentation` picks between a separate overlay window (independent of the
/// underlying hierarchy, the default) and a full-screen modal that composes with
/// other modals. Works with `LMKCardPageViewController` or any view controller; a
/// page reaches its panel through `lmk_cardPanel`.
///
/// ```swift
/// let panel = LMKCardPanelViewController(rootViewController: SettingsPage())
/// panel.dismissesOnBackgroundTap = false
/// panel.present(from: self)
/// ```
///
/// The panel is a VoiceOver modal: the escape gesture, Escape, and ⌘W dismiss it, and
/// `onDismiss` fires once however it goes away (its own `dismiss()`, a background tap,
/// or a UIKit dismissal of the modal).
open class LMKCardPanelViewController: UIViewController, LMKThemeApplying {
    // MARK: - Vocabulary

    /// How the panel is shown.
    public nonisolated enum Presentation: Sendable, Hashable, CaseIterable {
        /// A separate window above the scene's content; touches outside the card can pass through.
        case overlayWindow
        /// A full-screen modal over the host, so it stacks with other modals.
        case modal
    }

    // MARK: - Style

    public nonisolated struct Style: Sendable, Equatable, LMKThemeExtension {
        /// Card background (`backgroundPrimary`), corners (large), border, shadow (`level3`).
        public var surface: LMKSurfaceStyle
        /// `nil` = 420.
        public var maxWidth: CGFloat?
        /// Inset from the safe area on narrow hosts; `nil` = 24.
        public var horizontalInset: CGFloat?
        /// Card height as a fraction of the safe area; `nil` = 0.6.
        public var heightRatio: CGFloat?
        /// Dimming behind the card while `dismissesOnBackgroundTap`; `nil` = `scrim`.
        public var dimmingColor: UIColor?
        /// `nil` = `alpha.dimming`.
        public var dimmingAlpha: CGFloat?
        /// Vertical travel of the slide animation; `nil` = 20.
        public var slideOffset: CGFloat?
        /// Overlay window level; `nil` = `.normal + 1`.
        public var windowLevel: CGFloat?

        public init(
            surface: LMKSurfaceStyle = LMKSurfaceStyle(),
            maxWidth: CGFloat? = nil,
            horizontalInset: CGFloat? = nil,
            heightRatio: CGFloat? = nil,
            dimmingColor: UIColor? = nil,
            dimmingAlpha: CGFloat? = nil,
            slideOffset: CGFloat? = nil,
            windowLevel: CGFloat? = nil
        ) {
            self.surface = surface
            self.maxWidth = maxWidth
            self.horizontalInset = horizontalInset
            self.heightRatio = heightRatio
            self.dimmingColor = dimmingColor
            self.dimmingAlpha = dimmingAlpha
            self.slideOffset = slideOffset
            self.windowLevel = windowLevel
        }

        public static let defaultValue = Self()

        /// `other`'s non-nil fields over this style's.
        public func merging(_ other: Self) -> Self {
            Self(
                surface: surface.merging(other.surface),
                maxWidth: other.maxWidth ?? maxWidth,
                horizontalInset: other.horizontalInset ?? horizontalInset,
                heightRatio: other.heightRatio ?? heightRatio,
                dimmingColor: other.dimmingColor ?? dimmingColor,
                dimmingAlpha: other.dimmingAlpha ?? dimmingAlpha,
                slideOffset: other.slideOffset ?? slideOffset,
                windowLevel: other.windowLevel ?? windowLevel
            )
        }
    }

    // MARK: - Properties

    /// The card surface.
    public let cardView: UIView = LMKSurfaceView()
    /// The embedded navigation controller hosting the root view controller.
    public let embeddedNavigationController: UINavigationController

    /// How `present(from:)` shows the panel. Set before presenting.
    public var presentation: Presentation = .overlayWindow

    /// Whether tapping outside the card dismisses the panel (and dims the background). Default `true`.
    public var dismissesOnBackgroundTap = true {
        didSet {
            overlayWindow?.passthroughEnabled = !dismissesOnBackgroundTap
            if isViewLoaded, isPresented {
                view.backgroundColor = dismissesOnBackgroundTap ? dimmingColor : .clear
            }
        }
    }

    /// Called once after the panel has gone away, whichever way it was dismissed.
    public var onDismiss: (() -> Void)?

    /// Per-instance style; `nil` fields resolve from `theme.cardPanel`, then the built-in look.
    public var style: Style {
        didSet {
            guard style != oldValue, isViewLoaded else { return }
            applyTheme(traitCollection.lmkTheme)
        }
    }

    /// Called at the end of every `applyTheme`, for tweaks the style does not cover.
    public var didApplyStyle: ((LMKCardPanelViewController) -> Void)?

    /// The style last resolved against the theme.
    public private(set) var resolvedStyle = Style()

    /// Whether the panel is on screen (or animating in).
    public private(set) var isPresented = false

    private var overlayWindow: LMKCardPanelOverlayWindow?
    private weak var previousKeyWindow: UIWindow?
    private var isDismissing = false
    private var animator: UIViewPropertyAnimator?
    private var maxWidthConstraint: Constraint?
    private var horizontalInsetConstraint: Constraint?
    private var heightConstraint: Constraint?
    private var appliedHeightRatio: CGFloat?

    static let defaultMaxWidth: CGFloat = 420
    static let defaultHorizontalInset: CGFloat = 24
    static let defaultHeightRatio: CGFloat = 0.6
    static let defaultSlideOffset: CGFloat = 20

    private var dimmingColor: UIColor {
        (resolvedStyle.dimmingColor ?? LMKColor.scrim).withAlphaComponent(resolvedStyle.dimmingAlpha ?? traitCollection.lmkTheme.alpha.dimming)
    }

    private var slideOffset: CGFloat {
        resolvedStyle.slideOffset ?? Self.defaultSlideOffset
    }

    // MARK: - Initialization

    /// A panel hosting `rootViewController` inside an embedded navigation controller.
    public init(rootViewController: UIViewController, style: Style = Style()) {
        self.style = style
        embeddedNavigationController = UINavigationController(rootViewController: rootViewController)
        embeddedNavigationController.setNavigationBarHidden(true, animated: false)
        super.init(nibName: nil, bundle: nil)
        modalPresentationCapturesStatusBarAppearance = true
        // A child from the start, so a page can reach its panel (`lmk_cardPanel`) before the view loads.
        addChild(embeddedNavigationController)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override open func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        view.accessibilityViewIsModal = true
        setupCard()
        let tap = UITapGestureRecognizer(target: self, action: #selector(backgroundTapped(_:)))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
        lmk_startApplyingTheme()
    }

    /// A modal the host dismissed through UIKit still ends in the panel's own state.
    override open func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        guard isPresented, !isDismissing, overlayWindow == nil, isBeingDismissed else { return }
        finishDismissal(completion: nil)
    }

    /// The embedded stack decides the status bar (the forced-dark pattern).
    override open var childForStatusBarStyle: UIViewController? {
        embeddedNavigationController
    }

    // MARK: - Setup

    private func setupCard() {
        view.addSubview(cardView)
        // Center and inset against the safe area, not the raw window: landscape phones and
        // iPhone Duo carry asymmetric side insets for the camera region.
        let safeArea = view.safeAreaLayoutGuide
        cardView.snp.makeConstraints { make in
            make.center.equalTo(safeArea)
            maxWidthConstraint = make.width.lessThanOrEqualTo(Self.defaultMaxWidth).constraint
            horizontalInsetConstraint = make.leading.trailing.equalTo(safeArea).inset(Self.defaultHorizontalInset).priority(.high).constraint
        }

        cardView.addSubview(embeddedNavigationController.view)
        embeddedNavigationController.view.snp.makeConstraints { $0.edges.equalToSuperview() }
        embeddedNavigationController.didMove(toParent: self)
        // The recognizers exist once the navigation view is loaded; the card's own slide would
        // fight an edge pop or, on iOS 26, a content-wide pop.
        embeddedNavigationController.interactivePopGestureRecognizer?.isEnabled = false
        if #available(iOS 26, *) {
            embeddedNavigationController.interactiveContentPopGestureRecognizer?.isEnabled = false
        }

        cardView.alpha = 0
        cardView.transform = CGAffineTransform(translationX: 0, y: -Self.defaultSlideOffset)
    }

    // MARK: - Theme

    open func applyTheme(_ theme: LMKTheme) {
        resolvedStyle = theme.cardPanel.merging(style)
        let resolved = resolvedStyle
        let applied = cardView.lmk_apply(
            surface: resolved.surface,
            defaults: LMKSurfaceStyle(background: .solid(LMKColor.backgroundPrimary), corners: .fixed(theme.cornerRadius.large), shadow: .level(.level3))
        )
        // The card carries the shadow, so the embedded stack clips itself to the same corners.
        embeddedNavigationController.view.lmk_applyCornerStyle(applied.corners ?? .fixed(theme.cornerRadius.large), masking: true)
        maxWidthConstraint?.update(offset: resolved.maxWidth ?? Self.defaultMaxWidth)
        horizontalInsetConstraint?.update(inset: resolved.horizontalInset ?? Self.defaultHorizontalInset)
        let ratio = resolved.heightRatio ?? Self.defaultHeightRatio
        if appliedHeightRatio != ratio {
            appliedHeightRatio = ratio
            heightConstraint?.deactivate()
            cardView.snp.makeConstraints { make in
                heightConstraint = make.height.equalTo(view.safeAreaLayoutGuide.snp.height).multipliedBy(ratio).constraint
            }
        }
        if isPresented {
            view.backgroundColor = dismissesOnBackgroundTap ? dimmingColor : .clear
        } else {
            // At rest, above its resting place: the first slide-in travels the style's offset.
            cardView.transform = CGAffineTransform(translationX: 0, y: -slideOffset)
        }
        overlayWindow?.windowLevel = UIWindow.Level(rawValue: resolved.windowLevel ?? (UIWindow.Level.normal.rawValue + 1))
        applyContentTheme(theme)
        didApplyStyle?(self)
    }

    /// Called at the end of every `applyTheme`, before `didApplyStyle`, for subclasses to
    /// style their own content from `theme` and `resolvedStyle`.
    open func applyContentTheme(_ theme: LMKTheme) {}

    // MARK: - Presentation

    /// Shows the panel: in an overlay window above the host's scene, or as a modal over `host`.
    ///
    /// Nothing happens while the panel is already presented, without a window scene to
    /// overlay, or when `host` cannot present (it is presenting something else already).
    public func present(from host: UIViewController) {
        guard !isPresented else { return }
        isPresented = true
        switch presentation {
        case .overlayWindow:
            presentInOverlayWindow(from: host)
        case .modal:
            modalPresentationStyle = .overFullScreen
            modalTransitionStyle = .crossDissolve
            host.present(self, animated: false)
            guard presentingViewController != nil else {
                LMKLogger.warning("LMKCardPanelViewController: the host refused the presentation", category: .ui)
                isPresented = false
                return
            }
            view.layoutIfNeeded()
            animateIn()
        }
    }

    private func presentInOverlayWindow(from host: UIViewController) {
        let hostWindow = host.view.window ?? LMKScene.keyWindow
        guard let windowScene = hostWindow?.windowScene else {
            LMKLogger.warning("LMKCardPanelViewController: no window scene to overlay", category: .ui)
            isPresented = false
            return
        }
        previousKeyWindow = hostWindow
        let overlay = LMKCardPanelOverlayWindow(windowScene: windowScene)
        overlay.windowLevel = UIWindow.Level(rawValue: resolvedStyle.windowLevel ?? (UIWindow.Level.normal.rawValue + 1))
        overlay.backgroundColor = .clear
        overlay.passthroughEnabled = !dismissesOnBackgroundTap
        overlay.rootViewController = self
        overlayWindow = overlay
        overlay.makeKeyAndVisible()
        // Let the first layout pass land before animating.
        view.layoutIfNeeded()
        animateIn()
    }

    // MARK: - Animation

    /// Slides the card in with a spring and dims the background (when background taps dismiss).
    func animateIn() {
        run(duration: LMKAnimation.Duration.moderate, spring: true) { [weak self] in
            guard let self else { return }
            cardView.alpha = 1
            cardView.transform = .identity
            view.backgroundColor = dismissesOnBackgroundTap ? dimmingColor : .clear
        }
        UIAccessibility.post(notification: .screenChanged, argument: cardView)
        claimFirstResponderIfIdle()
    }

    private func animateOut(completion: @escaping () -> Void) {
        run(duration: LMKAnimation.Duration.normal, spring: false, animations: { [weak self] in
            guard let self else { return }
            cardView.alpha = 0
            cardView.transform = CGAffineTransform(translationX: 0, y: -slideOffset)
            view.backgroundColor = .clear
        }, completion: completion)
    }

    /// Runs `animations` in a property animator, settling any slide still in flight first so a
    /// dismissal during the slide-in completes. Immediate without a window or under Reduce Motion.
    private func run(duration: TimeInterval, spring: Bool, animations: @escaping () -> Void, completion: (() -> Void)? = nil) {
        if let animator {
            self.animator = nil
            if animator.state == .active {
                animator.stopAnimation(false)
            }
            if animator.state == .stopped {
                animator.finishAnimation(at: .current)
            }
        }
        let effectiveDuration = LMKAnimation.shouldAnimate ? duration : 0
        guard effectiveDuration > 0, view.window != nil else {
            animations()
            completion?()
            return
        }
        let animator = spring
            ? UIViewPropertyAnimator(duration: effectiveDuration, dampingRatio: LMKAnimation.spring.damping, animations: animations)
            : UIViewPropertyAnimator(duration: effectiveDuration, curve: .easeIn, animations: animations)
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

    // MARK: - Dismissal

    /// Slides the card out, then tears down the overlay window (restoring the previous key
    /// window) or dismisses the modal. A second call while dismissing is ignored.
    public func dismiss(completion: (() -> Void)? = nil) {
        guard isPresented, !isDismissing else { return }
        isDismissing = true
        if isFirstResponder {
            resignFirstResponder()
        }
        animateOut { [weak self] in
            guard let self else { return }
            if let overlayWindow {
                overlayWindow.isHidden = true
                overlayWindow.rootViewController = nil
                self.overlayWindow = nil
                previousKeyWindow?.makeKey()
                previousKeyWindow = nil
            } else if presentingViewController != nil {
                dismissModalThroughUIKit()
            }
            finishDismissal(completion: completion)
        }
    }

    /// The UIKit dismissal of the modal (`super`, which a closure cannot name).
    private func dismissModalThroughUIKit() {
        super.dismiss(animated: false, completion: nil)
    }

    /// The UIKit dismissal routes to the panel's own: a page calling `dismiss(animated:)` on
    /// its panel gets the slide-out and `onDismiss`. Something the panel presented itself is
    /// dismissed as usual.
    override open func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        guard presentedViewController == nil, isPresented else {
            super.dismiss(animated: flag, completion: completion)
            return
        }
        dismiss(completion: completion)
    }

    private func finishDismissal(completion: (() -> Void)?) {
        isPresented = false
        isDismissing = false
        onDismiss?()
        completion?()
    }

    // MARK: - Accessibility and key commands

    override open func accessibilityPerformEscape() -> Bool {
        guard isPresented, !isDismissing else { return false }
        dismiss()
        return true
    }

    override open var canBecomeFirstResponder: Bool { true }

    override open var keyCommands: [UIKeyCommand]? {
        [
            UIKeyCommand(input: UIKeyCommand.inputEscape, modifierFlags: [], action: #selector(dismissFromKeyCommand)),
            UIKeyCommand(input: "w", modifierFlags: .command, action: #selector(dismissFromKeyCommand)),
        ]
    }

    @objc private func dismissFromKeyCommand() {
        dismiss()
    }

    /// Takes first responder on iPad and Mac (where hardware key commands matter) so Esc / ⌘W
    /// reach the panel, unless a field inside is editing.
    private func claimFirstResponderIfIdle() {
        guard traitCollection.userInterfaceIdiom != .phone, view.window != nil, !isDismissing, !Self.containsFirstResponder(view) else { return }
        becomeFirstResponder()
    }

    private static func containsFirstResponder(_ view: UIView) -> Bool {
        if view.isFirstResponder { return true }
        return view.subviews.contains { containsFirstResponder($0) }
    }

    // MARK: - Actions

    @objc private func backgroundTapped(_ gesture: UITapGestureRecognizer) {
        guard dismissesOnBackgroundTap else { return }
        let location = gesture.location(in: view)
        guard !cardView.frame.contains(location) else { return }
        dismiss()
    }
}

/// Overlay window that can pass touches outside the card through to the window below.
final class LMKCardPanelOverlayWindow: UIWindow {
    var passthroughEnabled = false

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        // Something the panel presented (an alert, a sheet) covers the window: every touch is its.
        guard passthroughEnabled, let panel = rootViewController as? LMKCardPanelViewController, panel.presentedViewController == nil else {
            return super.hitTest(point, with: event)
        }
        let panelPoint = convert(point, to: panel.view)
        guard panel.cardView.frame.contains(panelPoint) else { return nil }
        return super.hitTest(point, with: event)
    }
}

public extension UIViewController {
    /// The `LMKCardPanelViewController` this controller is shown in (through its embedded
    /// navigation controller), or `nil` outside a panel.
    var lmk_cardPanel: LMKCardPanelViewController? {
        var candidate: UIViewController? = self
        while let current = candidate {
            if let panel = current as? LMKCardPanelViewController { return panel }
            candidate = current.parent
        }
        return nil
    }
}

public nonisolated extension LMKTheme {
    /// App-wide default style for `LMKCardPanelViewController`.
    var cardPanel: LMKCardPanelViewController.Style {
        get { self[LMKCardPanelViewController.Style.self] }
        set { self[LMKCardPanelViewController.Style.self] = newValue }
    }
}
