//
//  LMKNavigationController.swift
//  LumiKit
//
//  A navigation controller that keeps the interactive pop gesture alive with
//  the system bar hidden, and lets the top screen opt out of it.
//

import UIKit

/// Adopted by a pushed screen that wants the interactive pop gesture off while it is on
/// top: a page container whose first page is not showing, a canvas that owns edge drags.
public protocol LMKPopGestureConfiguring: AnyObject {
    /// `true` while the pop gesture must not begin.
    var prefersPopGestureDisabled: Bool { get }
}

/// A `UINavigationController` that keeps the interactive edge-swipe-to-go-back
/// gesture working when the system navigation bar is hidden.
///
/// Apps that replace the system bar with ``LMKNavigationBar`` hide it on every pushed
/// screen, and UIKit's default gesture delegate then disables the swipe. This controller
/// takes over as the gesture's delegate and enables it whenever the stack has at least
/// two view controllers, no push or pop is in flight, and the top one does not opt out
/// through ``LMKPopGestureConfiguring``. It never enables the gesture on the root (which
/// can leave UIKit ignoring later pushes). On iOS 26 the same rule governs the content-area
/// pop gesture, which has no delegate to ask: it is switched off while the rule says no and
/// back on afterwards (``updateContentPopGesture()``). The top screen also answers for the
/// status bar, so a forced-dark screen keeps its light status bar under a hidden system bar.
/// Under the Mac idiom it restores the back button that the window toolbar loses when a
/// full-screen presentation over the stack is dismissed, and collapses the sidebar of a split
/// view presented over it as that is dismissed, which would otherwise leave the stack's back
/// button and title a sidebar's width in from the window controls.
///
/// ```swift
/// let navigation = LMKNavigationController(rootViewController: homeViewController)
/// navigation.setNavigationBarHidden(true, animated: false)
/// ```
open class LMKNavigationController: UINavigationController {
    private lazy var popGestureDelegate = LMKPopGestureDelegate(owner: self)
    /// Whether this controller switched the content pop gesture off (a host's own `isEnabled = false` is left alone).
    private var disabledContentPopGesture = false

    /// Whether the pop gesture may begin now: a screen below the top, no transition in flight,
    /// and the top not opting out.
    public var canBeginPopGesture: Bool {
        // A swipe during a push or pop is the classic corrupted-stack case UIKit's own delegate blocks.
        guard viewControllers.count > 1, transitionCoordinator == nil else { return false }
        if let configuring = topViewController as? LMKPopGestureConfiguring, configuring.prefersPopGestureDisabled {
            return false
        }
        return true
    }

    override open func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = popGestureDelegate
        updateContentPopGesture()
    }

    override open func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateContentPopGesture()
    }

    /// Under the Mac idiom a split view presented over the stack is collapsed as it is dismissed,
    /// while it is still on screen (see ``collapseSidebarsOfDismissedPresentation()``).
    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if traitCollection.userInterfaceIdiom == .mac {
            collapseSidebarsOfDismissedPresentation()
        }
    }

    /// Under the Mac idiom the bar's items live in the window toolbar, and a full-screen
    /// presentation that is dismissed hands the toolbar back without the back button (the title
    /// returns, the button does not). This view controller reappears exactly then, so the top
    /// item's back button is re-asserted.
    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if traitCollection.userInterfaceIdiom == .mac {
            reassertBackButton()
        }
    }

    /// Toggles the top item's `hidesBackButton` so the bar rebuilds its back button; an item that
    /// hides its back button is left alone.
    func reassertBackButton() {
        guard !isNavigationBarHidden, viewControllers.count > 1, let item = topViewController?.navigationItem, !item.hidesBackButton else { return }
        item.hidesBackButton = true
        item.hidesBackButton = false
    }

    /// Under the Mac idiom a split view controller presented over the stack moves the window
    /// toolbar's sidebar edge to the end of its primary column, and its dismissal leaves the edge
    /// there: the stack's back button and title then start a sidebar's width in from the window
    /// controls, and nothing on the navigation side moves them back. Collapsing the primary column
    /// while the presentation is still on screen hands the edge back. Runs as the stack reappears.
    func collapseSidebarsOfDismissedPresentation() {
        var presented = presentedViewController
        while let controller = presented {
            if controller.isBeingDismissed {
                Self.collapseSidebars(in: controller)
            }
            presented = controller.presentedViewController
        }
    }

    /// Collapses the primary column of every column-style split view controller in `controller`'s
    /// hierarchy, without animation.
    static func collapseSidebars(in controller: UIViewController) {
        if let split = controller as? UISplitViewController, split.style != .unspecified {
            UIView.performWithoutAnimation {
                split.preferredDisplayMode = .secondaryOnly
                split.hide(.primary)
            }
        }
        for child in controller.children {
            collapseSidebars(in: child)
        }
    }

    /// Applies ``canBeginPopGesture`` to the iOS 26 content-area pop gesture, which has no
    /// delegate to ask on each touch. Runs after every stack change and layout pass; a top screen
    /// whose `prefersPopGestureDisabled` changes between layouts calls it. A gesture a host
    /// disabled itself stays disabled.
    public func updateContentPopGesture() {
        guard #available(iOS 26, *), let recognizer = interactiveContentPopGestureRecognizer else { return }
        if canBeginPopGesture {
            guard disabledContentPopGesture else { return }
            disabledContentPopGesture = false
            recognizer.isEnabled = true
        } else if recognizer.isEnabled {
            disabledContentPopGesture = true
            recognizer.isEnabled = false
        }
    }

    override open func pushViewController(_ viewController: UIViewController, animated: Bool) {
        super.pushViewController(viewController, animated: animated)
        updateContentPopGestureAfterTransition()
    }

    @discardableResult
    override open func popViewController(animated: Bool) -> UIViewController? {
        let popped = super.popViewController(animated: animated)
        updateContentPopGestureAfterTransition()
        return popped
    }

    @discardableResult
    override open func popToViewController(_ viewController: UIViewController, animated: Bool) -> [UIViewController]? {
        let popped = super.popToViewController(viewController, animated: animated)
        updateContentPopGestureAfterTransition()
        return popped
    }

    @discardableResult
    override open func popToRootViewController(animated: Bool) -> [UIViewController]? {
        let popped = super.popToRootViewController(animated: animated)
        updateContentPopGestureAfterTransition()
        return popped
    }

    override open func setViewControllers(_ viewControllers: [UIViewController], animated: Bool) {
        super.setViewControllers(viewControllers, animated: animated)
        updateContentPopGestureAfterTransition()
    }

    /// The rule says no while a transition runs; re-evaluate when it ends.
    private func updateContentPopGestureAfterTransition() {
        updateContentPopGesture()
        transitionCoordinator?.animate(alongsideTransition: nil) { [weak self] _ in
            self?.updateContentPopGesture()
        }
    }

    override open var childForStatusBarStyle: UIViewController? { topViewController }

    override open var childForStatusBarHidden: UIViewController? { topViewController }
}

/// The pop gesture's delegate, kept off the controller's public surface.
private final class LMKPopGestureDelegate: NSObject, UIGestureRecognizerDelegate {
    private weak var owner: LMKNavigationController?

    init(owner: LMKNavigationController) {
        self.owner = owner
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        owner?.canBeginPopGesture ?? false
    }
}
