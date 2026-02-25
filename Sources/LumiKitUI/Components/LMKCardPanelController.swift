//
//  LMKCardPanelController.swift
//  LumiKit
//
//  Centered floating card panel that hosts content in an embedded
//  navigation controller. Touches outside the card pass through
//  to views underneath.
//
//  Works standalone or together with LMKCardPageController — embed
//  a card page as the root view controller for a combined
//  panel + page experience.
//

import SnapKit
import UIKit

/// Centered floating card panel with passthrough touches, shadow, and
/// slide-in/out animation.
///
/// Hosts an embedded `UINavigationController` with a hidden system nav bar
/// inside a rounded card. Designed for overlays that appear above all other
/// content without blocking interaction outside the card.
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
/// panel.present(from: parentVC)
/// ```
open class LMKCardPanelController: UIViewController {
    // MARK: - Configuration

    /// Maximum card width. Default: `LMKCardPanelLayout.cardMaxWidth` (420pt).
    open var cardMaxWidth: CGFloat { LMKCardPanelLayout.cardMaxWidth }

    /// Horizontal inset from screen edges. Default: `LMKCardPanelLayout.cardHorizontalInset` (24pt).
    open var cardHorizontalInset: CGFloat { LMKCardPanelLayout.cardHorizontalInset }

    /// Card height as a ratio of the container height. Default: `LMKCardPanelLayout.cardMaxHeightRatio` (0.6).
    open var cardMaxHeightRatio: CGFloat { LMKCardPanelLayout.cardMaxHeightRatio }

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

    override open func loadView() {
        view = PassthroughView()
    }

    override open func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        setupCard()
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
        }
    }

    private func animateOut(completion: @escaping () -> Void) {
        let duration = LMKAnimationHelper.shouldAnimate ? LMKAnimationHelper.Duration.actionSheet : 0
        UIView.animate(withDuration: duration, delay: 0, options: .curveEaseIn) {
            self.cardView.alpha = 0
            self.cardView.transform = CGAffineTransform(translationX: 0, y: -LMKCardPanelLayout.slideOffset)
        } completion: { _ in
            completion()
        }
    }

    // MARK: - Dismissal

    /// Dismiss the panel with an animate-out and remove from the view hierarchy.
    /// - Parameter completion: Called after the panel is fully removed.
    public func dismissPanel(completion: (() -> Void)? = nil) {
        animateOut { [weak self] in
            guard let self else { return }
            self.willMove(toParent: nil)
            self.view.removeFromSuperview()
            self.removeFromParent()
            completion?()
        }
    }

    // MARK: - Static Convenience

    /// Add the panel to the window so it appears above all presented view controllers.
    ///
    /// Uses child VC containment with the window's root view controller for proper lifecycle.
    /// The panel animates in on the next run loop after layout resolves.
    /// - Parameters:
    ///   - panel: The card panel controller to show.
    ///   - window: The window to add the panel to.
    public static func show(_ panel: LMKCardPanelController, in window: UIWindow) {
        guard let rootVC = window.rootViewController else { return }
        rootVC.addChild(panel)
        panel.view.frame = window.bounds
        panel.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        window.addSubview(panel.view)
        panel.didMove(toParent: rootVC)

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

// MARK: - PassthroughView

/// Passes touches through to views behind it, except for its subviews.
private final class PassthroughView: UIView {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let result = super.hitTest(point, with: event)
        return result === self ? nil : result
    }
}
