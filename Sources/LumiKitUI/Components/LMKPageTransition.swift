//
//  LMKPageTransition.swift
//  LumiKit
//
//  Slide transition between two page views inside a container, shared by the
//  action sheet and the card page controller. Direction follows the layout
//  direction, so a forward push slides in from the trailing edge in RTL too.
//

import SnapKit
import UIKit

enum LMKPageTransition {
    enum Direction {
        case forward
        case backward
        case none
    }

    /// Replaces `oldView` with `newView` in `container`: the new view slides in from the
    /// trailing (`forward`) or leading (`backward`) edge while the old one slides out and
    /// fades. Without animation, a window, a laid-out container, or with Reduce Motion, the
    /// swap is immediate. `layoutRoot` is laid out inside the animation so a height change
    /// animates with the slide. `completion` runs once the old view is gone.
    static func run(
        in container: UIView,
        from oldView: UIView?,
        to newView: UIView,
        direction: Direction,
        duration: TimeInterval,
        animated: Bool,
        layoutRoot: UIView? = nil,
        completion: (() -> Void)? = nil
    ) {
        guard animated, direction != .none, LMKAnimation.shouldAnimate, let oldView, !container.bounds.isEmpty, container.window != nil else {
            oldView?.removeFromSuperview()
            container.addSubview(newView)
            newView.snp.makeConstraints { $0.edges.equalToSuperview() }
            completion?()
            return
        }

        // Freeze the outgoing view at its current frame so both views can be transformed.
        let oldFrame = oldView.frame
        oldView.snp.removeConstraints()
        oldView.translatesAutoresizingMaskIntoConstraints = true
        oldView.frame = oldFrame

        container.addSubview(newView)
        newView.snp.makeConstraints { $0.edges.equalToSuperview() }
        container.layoutIfNeeded()

        let width = max(container.bounds.width, 1)
        let isRightToLeft = container.effectiveUserInterfaceLayoutDirection == .rightToLeft
        var slideIn = direction == .forward ? width : -width
        if isRightToLeft { slideIn = -slideIn }
        newView.transform = CGAffineTransform(translationX: slideIn, y: 0)

        let animator = UIViewPropertyAnimator(duration: duration, curve: .easeInOut) {
            oldView.transform = CGAffineTransform(translationX: -slideIn, y: 0)
            oldView.alpha = 0
            newView.transform = .identity
            layoutRoot?.layoutIfNeeded()
        }
        let once = LMKOnceCompletion(after: duration) {
            oldView.removeFromSuperview()
            completion?()
        }
        animator.addCompletion { _ in once.fire() }
        animator.startAnimation()
    }
}
