//
//  LMKCardPanelController.swift
//  LumiKit
//
//  Centered floating card panel that hosts content in an embedded
//  navigation controller. Presented in its own overlay window,
//  fully independent of the underlying view controller hierarchy.
//
//  Works standalone or together with LMKCardPageController — embed
//  a card page as the root view controller for a combined
//  panel + page experience.
//

import SnapKit
import UIKit

/// Centered floating card panel with shadow and slide-in/out animation.
///
/// Hosts an embedded `UINavigationController` with a hidden system nav bar
/// inside a rounded card. Presented in a separate overlay `UIWindow` so that
/// navigation and interaction are fully independent of the underlying
/// view controller hierarchy.
///
/// Works together with `LMKCardPageController` or any `UIViewController`:
/// ```swift
/// // With LMKCardPageController
/// let page = MyCardPage(title: "Settings")
/// let panel = LMKCardPanelController(rootViewController: page)
/// LMKCardPanelController.show(panel, in: window)
///
/// // With any UIViewController
/// let vc = MyViewController()
/// let panel = LMKCardPanelController(rootViewController: vc)
/// LMKCardPanelController.show(panel, in: window)
/// ```
open class LMKCardPanelController: UIViewController {
    // MARK: - Configuration

    /// Maximum card width. Default: `LMKCardPanelLayout.cardMaxWidth` (420pt).
    open var cardMaxWidth: CGFloat { LMKCardPanelLayout.cardMaxWidth }

    /// Horizontal inset from screen edges. Default: `LMKCardPanelLayout.cardHorizontalInset` (24pt).
    open var cardHorizontalInset: CGFloat { LMKCardPanelLayout.cardHorizontalInset }

    /// Card height as a ratio of the container height. Default: `LMKCardPanelLayout.cardMaxHeightRatio` (0.6).
    open var cardMaxHeightRatio: CGFloat { LMKCardPanelLayout.cardMaxHeightRatio }

    /// Whether tapping outside the card dismisses the panel. Default: `true`.
    open var dismissesOnBackgroundTap: Bool { true }

    // MARK: - Public Properties

    /// The card container view with corner radius and shadow.
    public private(set) lazy var cardView: UIView = {
        let view = UIView()
        view.backgroundColor = LMKColor.backgroundPrimary
        view.layer.cornerRadius = LMKCornerRadius.large
        view.lmk_applyShadow(LMKShadow.card())
        return view
    }()

    /// The embedded navigation controller hosting the root view controller.
    public private(set) var embeddedNavigationController: UINavigationController

    /// The overlay window hosting this panel. Retained until dismissal.
    private var overlayWindow: UIWindow?

    // MARK: - Initialization

    /// Create a card panel hosting the given root view controller.
    /// - Parameter rootViewController: The view controller to display inside the card.
    public init(rootViewController: UIViewController) {
        embeddedNavigationController = UINavigationController(rootViewController: rootViewController)
        embeddedNavigationController.setNavigationBarHidden(true, animated: false)
        embeddedNavigationController.interactivePopGestureRecognizer?.isEnabled = false
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - Lifecycle

    override open func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        setupCard()
        setupBackgroundTap()
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: LMKCardPanelController, _: UITraitCollection) in
            self.refreshPanelColors()
        }
    }

    // MARK: - Setup

    private func setupCard() {
        view.addSubview(cardView)
        cardView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.lessThanOrEqualTo(cardMaxWidth)
            make.leading.trailing.equalToSuperview().inset(cardHorizontalInset).priority(.high)
            make.height.equalTo(view.snp.height).multipliedBy(cardMaxHeightRatio)
        }

        addChild(embeddedNavigationController)
        cardView.addSubview(embeddedNavigationController.view)
        embeddedNavigationController.view.layer.cornerRadius = LMKCornerRadius.large
        embeddedNavigationController.view.clipsToBounds = true
        embeddedNavigationController.view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        embeddedNavigationController.didMove(toParent: self)

        // Start hidden for animate-in
        cardView.alpha = 0
        cardView.transform = CGAffineTransform(translationX: 0, y: -LMKCardPanelLayout.slideOffset)
    }

    private func setupBackgroundTap() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(backgroundTapped(_:)))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    // MARK: - Actions

    @objc private func backgroundTapped(_ gesture: UITapGestureRecognizer) {
        guard dismissesOnBackgroundTap else { return }
        let location = gesture.location(in: view)
        guard !cardView.frame.contains(location) else { return }
        dismissPanel()
    }

    // MARK: - Animation

    /// Animate the card into view with a spring effect.
    public func animateIn() {
        let duration = LMKAnimationHelper.shouldAnimate ? LMKAnimationHelper.Duration.modalPresentation : 0
        UIView.animate(
            withDuration: duration,
            delay: 0,
            usingSpringWithDamping: LMKAnimationHelper.Spring.damping,
            initialSpringVelocity: 0,
            options: .curveEaseOut
        ) {
            self.cardView.alpha = 1
            self.cardView.transform = .identity
            if self.dismissesOnBackgroundTap {
                self.view.backgroundColor = UIColor.black.withAlphaComponent(LMKAlpha.dimmingOverlay)
            }
        }
    }

    private func animateOut(completion: @escaping () -> Void) {
        let duration = LMKAnimationHelper.shouldAnimate ? LMKAnimationHelper.Duration.actionSheet : 0
        UIView.animate(withDuration: duration, delay: 0, options: .curveEaseIn) {
            self.cardView.alpha = 0
            self.cardView.transform = CGAffineTransform(translationX: 0, y: -LMKCardPanelLayout.slideOffset)
            self.view.backgroundColor = .clear
        } completion: { _ in
            completion()
        }
    }

    // MARK: - Dismissal

    /// Dismiss the panel with an animate-out and tear down the overlay window.
    /// - Parameter completion: Called after the panel is fully removed.
    public func dismissPanel(completion: (() -> Void)? = nil) {
        animateOut { [weak self] in
            guard let self else { return }
            self.overlayWindow?.isHidden = true
            self.overlayWindow?.rootViewController = nil
            self.overlayWindow = nil
            completion?()
        }
    }

    // MARK: - Static Convenience

    /// Show the panel in a separate overlay window above all other content.
    ///
    /// The panel is fully independent of the underlying view controller hierarchy —
    /// navigation and interaction on the underlying window are unaffected.
    /// - Parameters:
    ///   - panel: The card panel controller to show.
    ///   - window: The window whose scene is used to create the overlay.
    public static func show(_ panel: LMKCardPanelController, in window: UIWindow) {
        guard let windowScene = window.windowScene else { return }
        let overlay = CardPanelOverlayWindow(windowScene: windowScene)
        overlay.windowLevel = .normal + 1
        overlay.backgroundColor = .clear
        overlay.passthroughEnabled = !panel.dismissesOnBackgroundTap
        overlay.rootViewController = panel
        panel.overlayWindow = overlay
        overlay.makeKeyAndVisible()

        // Dispatch to next run loop so initial layout resolves before animating
        DispatchQueue.main.async {
            panel.animateIn()
        }
    }

    // MARK: - Helpers

    private func refreshPanelColors() {
        cardView.backgroundColor = LMKColor.backgroundPrimary
    }
}

// MARK: - CardPanelOverlayWindow

/// Overlay window that optionally passes touches outside the card through
/// to the underlying window.
private final class CardPanelOverlayWindow: UIWindow {
    var passthroughEnabled = false

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard passthroughEnabled,
              let panel = rootViewController as? LMKCardPanelController else {
            return super.hitTest(point, with: event)
        }
        let panelPoint = convert(point, to: panel.view)
        guard panel.cardView.frame.contains(panelPoint) else { return nil }
        return super.hitTest(point, with: event)
    }
}
