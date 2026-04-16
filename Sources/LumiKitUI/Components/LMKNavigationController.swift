import UIKit

/// A `UINavigationController` that keeps the interactive edge-swipe-to-go-back
/// gesture working when the system navigation bar is hidden.
///
/// Apps that replace the system nav bar with ``LMKNavigationBar`` typically call
/// `setNavigationBarHidden(true)` on every pushed screen. UIKit's default
/// interactive-pop gesture delegate disables the gesture whenever the system
/// nav bar is hidden, so users lose the swipe-to-go-back affordance.
///
/// `LMKNavigationController` takes over as the gesture's delegate and enables
/// the gesture whenever the stack has at least two view controllers. It
/// intentionally does **not** enable the gesture on the root view controller
/// (where the gesture is meaningless and can leave the stack in a state where
/// further pushes are ignored).
///
/// Drop-in replacement — use anywhere you would use `UINavigationController`:
///
/// ```swift
/// let nav = LMKNavigationController(rootViewController: homeVC)
/// nav.setNavigationBarHidden(true, animated: false)
/// ```
open class LMKNavigationController: UINavigationController, UIGestureRecognizerDelegate {
    override open func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = self
    }

    /// Allow the interactive pop gesture only when there is a view controller
    /// below the top to pop to. Returning `true` on the root controller can
    /// put UIKit into a state where subsequent pushes are silently ignored.
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        viewControllers.count > 1
    }
}
