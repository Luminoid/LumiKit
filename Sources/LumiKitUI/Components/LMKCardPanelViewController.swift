//
//  LMKCardPanelViewController.swift
//  LumiKit
//
//  Centered floating card panel hosting an embedded navigation controller,
//  presented in its own overlay window or as a modal, styled from
//  `theme.cardPanel`.
//

import SnapKit
import UIKit

/// Centered floating card with a shadow and a slide-in / slide-out animation.
///
/// Hosts an embedded `UINavigationController` (system bar hidden) inside a rounded
/// card. `presentation` picks between a separate overlay window (independent of the
/// underlying hierarchy, the default) and a full-screen modal that composes with
/// other modals. Works with `LMKCardPageViewController` or any view controller.
///
/// ```swift
/// let panel = LMKCardPanelViewController(rootViewController: SettingsPage())
/// panel.dismissesOnBackgroundTap = false
/// panel.present(from: self)
/// ```
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
        public var maxHeightRatio: CGFloat?
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
            maxHeightRatio: CGFloat? = nil,
            dimmingColor: UIColor? = nil,
            dimmingAlpha: CGFloat? = nil,
            slideOffset: CGFloat? = nil,
            windowLevel: CGFloat? = nil
        ) {
            self.surface = surface
            self.maxWidth = maxWidth
            self.horizontalInset = horizontalInset
            self.maxHeightRatio = maxHeightRatio
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
                maxHeightRatio: other.maxHeightRatio ?? maxHeightRatio,
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

    /// Called after the panel has gone away.
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
    static let defaultMaxHeightRatio: CGFloat = 0.6
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
        embeddedNavigationController.interactivePopGestureRecognizer?.isEnabled = false
        super.init(nibName: nil, bundle: nil)
        modalPresentationCapturesStatusBarAppearance = true
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override open func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        setupCard()
        let tap = UITapGestureRecognizer(target: self, action: #selector(backgroundTapped(_:)))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
        lmk_startApplyingTheme()
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

        addChild(embeddedNavigationController)
        cardView.addSubview(embeddedNavigationController.view)
        embeddedNavigationController.view.snp.makeConstraints { $0.edges.equalToSuperview() }
        embeddedNavigationController.didMove(toParent: self)

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
        let ratio = resolved.maxHeightRatio ?? Self.defaultMaxHeightRatio
        if appliedHeightRatio != ratio {
            appliedHeightRatio = ratio
            heightConstraint?.deactivate()
            cardView.snp.makeConstraints { make in
                heightConstraint = make.height.equalTo(view.safeAreaLayoutGuide.snp.height).multipliedBy(ratio).constraint
            }
        }
        if isPresented {
            view.backgroundColor = dismissesOnBackgroundTap ? dimmingColor : .clear
        }
        overlayWindow?.windowLevel = UIWindow.Level(rawValue: resolved.windowLevel ?? (UIWindow.Level.normal.rawValue + 1))
        didApplyStyle?(self)
    }

    // MARK: - Presentation

    /// Shows the panel: in an overlay window above the host's scene, or as a modal over `host`.
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
            view.layoutIfNeeded()
            animateIn()
        }
    }

    private func presentInOverlayWindow(from host: UIViewController) {
        let hostWindow = host.view.window ?? LMKScene.keyWindow
        guard let windowScene = hostWindow?.windowScene else {
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
    public func animateIn() {
        run(duration: LMKAnimation.Duration.moderate, spring: true) { [weak self] in
            guard let self else { return }
            cardView.alpha = 1
            cardView.transform = .identity
            view.backgroundColor = dismissesOnBackgroundTap ? dimmingColor : .clear
        }
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
    /// window) or dismisses the modal.
    public func dismiss(completion: (() -> Void)? = nil) {
        guard isPresented, !isDismissing else { return }
        isDismissing = true
        animateOut { [weak self] in
            guard let self else { return }
            let finish = { [weak self] in
                guard let self else { return }
                isPresented = false
                isDismissing = false
                onDismiss?()
                completion?()
            }
            if let overlayWindow {
                overlayWindow.isHidden = true
                overlayWindow.rootViewController = nil
                self.overlayWindow = nil
                previousKeyWindow?.makeKey()
                previousKeyWindow = nil
                finish()
            } else {
                if presentingViewController != nil {
                    dismiss(animated: false)
                }
                finish()
            }
        }
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
        guard passthroughEnabled, let panel = rootViewController as? LMKCardPanelViewController else {
            return super.hitTest(point, with: event)
        }
        let panelPoint = convert(point, to: panel.view)
        guard panel.cardView.frame.contains(panelPoint) else { return nil }
        return super.hitTest(point, with: event)
    }
}

public nonisolated extension LMKTheme {
    /// App-wide default style for `LMKCardPanelViewController`.
    var cardPanel: LMKCardPanelViewController.Style {
        get { self[LMKCardPanelViewController.Style.self] }
        set { self[LMKCardPanelViewController.Style.self] = newValue }
    }
}
