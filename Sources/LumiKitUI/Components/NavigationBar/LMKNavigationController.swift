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
/// two view controllers and the top one does not opt out through
/// ``LMKPopGestureConfiguring``. It never enables the gesture on the root (which can
/// leave UIKit ignoring later pushes).
///
/// ```swift
/// let navigation = LMKNavigationController(rootViewController: homeViewController)
/// navigation.setNavigationBarHidden(true, animated: false)
/// ```
open class LMKNavigationController: UINavigationController {
    private lazy var popGestureDelegate = LMKPopGestureDelegate(owner: self)

    /// Whether the pop gesture may begin now: a screen below the top, and the top not opting out.
    public var canBeginPopGesture: Bool {
        guard viewControllers.count > 1 else { return false }
        if let configuring = topViewController as? LMKPopGestureConfiguring, configuring.prefersPopGestureDisabled {
            return false
        }
        return true
    }

    override open func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = popGestureDelegate
    }
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
