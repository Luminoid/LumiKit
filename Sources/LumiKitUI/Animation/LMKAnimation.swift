//
//  LMKAnimation.swift
//  LumiKit
//
//  Animation helpers following the design specification. Every helper honors
//  Reduce Motion, and every duration, spring, and curve comes from
//  `LMKAnimationTheme`.
//

import UIKit

/// Motion tokens and the shared animation helpers.
public enum LMKAnimation {
    // MARK: - Tokens

    /// Duration steps (seconds), read from the active theme.
    public nonisolated enum Duration {
        private static var config: LMKAnimationTheme {
            LMKTheme.current.animation
        }

        /// Press feedback.
        public static var instant: TimeInterval { config.instant }
        /// Short UI changes, photo fades.
        public static var fast: TimeInterval { config.fast }
        /// Alerts, action sheets.
        public static var normal: TimeInterval { config.normal }
        /// Modal presentation, list updates, card expansion.
        public static var moderate: TimeInterval { config.moderate }
        /// Screen transitions, error shake.
        public static var slow: TimeInterval { config.slow }
        /// Success feedback.
        public static var emphasis: TimeInterval { config.emphasis }
        /// One shimmer sweep of a skeleton.
        public static var shimmer: TimeInterval { config.shimmer }
    }

    /// A damped spring.
    public nonisolated struct Spring: Sendable, Equatable {
        /// `0...1`; 1 is critically damped (no bounce).
        public var damping: CGFloat
        public var initialVelocity: CGFloat

        public init(damping: CGFloat = 0.8, initialVelocity: CGFloat = 0) {
            self.damping = min(max(damping, 0), 1)
            self.initialVelocity = initialVelocity
        }
    }

    /// Timing curves, usable as `UIView.AnimationOptions` or Core Animation timing functions.
    public nonisolated enum Curve: Sendable, Hashable, CaseIterable {
        case easeIn
        case easeOut
        case easeInOut
        case linear

        public var options: UIView.AnimationOptions {
            switch self {
            case .easeIn: .curveEaseIn
            case .easeOut: .curveEaseOut
            case .easeInOut: .curveEaseInOut
            case .linear: .curveLinear
            }
        }

        /// The curve for `UIViewPropertyAnimator`.
        public var animationCurve: UIView.AnimationCurve {
            switch self {
            case .easeIn: .easeIn
            case .easeOut: .easeOut
            case .easeInOut: .easeInOut
            case .linear: .linear
            }
        }

        public var timingFunction: CAMediaTimingFunction {
            switch self {
            case .easeIn: CAMediaTimingFunction(name: .easeIn)
            case .easeOut: CAMediaTimingFunction(name: .easeOut)
            case .easeInOut: CAMediaTimingFunction(name: .easeInEaseOut)
            case .linear: CAMediaTimingFunction(name: .linear)
            }
        }
    }

    /// Spring for sheet and indicator motion.
    public nonisolated static var spring: Spring { LMKTheme.current.animation.spring }
    /// Spring for control press feedback.
    public nonisolated static var pressSpring: Spring { LMKTheme.current.animation.pressSpring }
    /// Scale applied to a pressed control.
    public nonisolated static var pressScale: CGFloat { LMKTheme.current.animation.pressScale }
    /// Curve used when a call site does not pick one.
    public nonisolated static var defaultCurve: Curve { LMKTheme.current.animation.defaultCurve }

    /// `false` while Reduce Motion is on. Hosts gate their own animations on this.
    public static var shouldAnimate: Bool {
        !UIAccessibility.isReduceMotionEnabled
    }

    // MARK: - Button Press Animation

    /// Scales the control down; pair with `animateButtonPressUp`.
    public static func animateButtonPressDown(_ control: UIControl) {
        guard shouldAnimate else { return }
        let scale = pressScale
        UIView.animate(
            withDuration: Duration.instant,
            delay: 0,
            usingSpringWithDamping: pressSpring.damping,
            initialSpringVelocity: pressSpring.initialVelocity,
            options: [.allowUserInteraction, .beginFromCurrentState],
            animations: {
                control.transform = CGAffineTransform(scaleX: scale, y: scale)
            }
        )
    }

    /// Restores the control's transform.
    public static func animateButtonPressUp(_ control: UIControl, completion: (() -> Void)? = nil) {
        guard shouldAnimate else {
            completion?()
            return
        }
        UIView.animate(
            withDuration: Duration.instant,
            delay: 0,
            usingSpringWithDamping: pressSpring.damping,
            initialSpringVelocity: pressSpring.initialVelocity,
            options: [.allowUserInteraction, .beginFromCurrentState],
            animations: {
                control.transform = .identity
            },
            completion: { _ in completion?() }
        )
    }

    /// Convenience that chains press-down then release. Used by controls that own a press animation.
    public static func animateButtonPress(_ control: UIControl, completion: (() -> Void)? = nil) {
        guard shouldAnimate else {
            completion?()
            return
        }
        animateButtonPressDown(control)
        UIView.animate(
            withDuration: Duration.instant,
            delay: Duration.instant,
            usingSpringWithDamping: pressSpring.damping,
            initialSpringVelocity: pressSpring.initialVelocity,
            options: [.allowUserInteraction, .beginFromCurrentState],
            animations: {
                control.transform = .identity
            },
            completion: { _ in completion?() }
        )
    }

    // MARK: - Success Feedback Animation

    private static let successCheckmarkSize: CGFloat = 60
    private static let successScaleUpFraction: Double = 0.6
    private static let successSettleFraction: Double = 0.4
    private static let successOvershootScale: CGFloat = 1.2
    private static let successSpringDamping: CGFloat = 0.6
    private static let successCheckmarkTag = 8888

    /// Pops a checkmark in the center of `view`, then fades it out.
    public static func animateSuccessFeedback(on view: UIView, completion: (() -> Void)? = nil) {
        let reduceMotion = !shouldAnimate
        // Remove any existing success checkmark before adding a new one
        view.subviews.filter { $0.tag == successCheckmarkTag }.forEach { $0.removeFromSuperview() }

        let checkmarkView = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
        checkmarkView.tag = successCheckmarkTag
        checkmarkView.tintColor = LMKColor.success
        checkmarkView.frame = CGRect(x: 0, y: 0, width: successCheckmarkSize, height: successCheckmarkSize)
        checkmarkView.center = CGPoint(x: view.bounds.midX, y: view.bounds.midY)
        checkmarkView.alpha = 0
        checkmarkView.transform = CGAffineTransform(scaleX: 0, y: 0)
        view.addSubview(checkmarkView)

        UIView.animate(
            withDuration: reduceMotion ? 0 : Duration.emphasis * successScaleUpFraction,
            delay: 0, usingSpringWithDamping: successSpringDamping, initialSpringVelocity: 0,
            options: [.allowUserInteraction],
            animations: {
                checkmarkView.alpha = 1
                checkmarkView.transform = CGAffineTransform(scaleX: successOvershootScale, y: successOvershootScale)
            },
            completion: { _ in
                UIView.animate(
                    withDuration: reduceMotion ? 0 : Duration.emphasis * successSettleFraction,
                    delay: 0, options: [.allowUserInteraction],
                    animations: { checkmarkView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0) },
                    completion: { _ in
                        UIView.animate(
                            withDuration: reduceMotion ? 0 : Duration.normal,
                            delay: Duration.moderate,
                            options: [.allowUserInteraction],
                            animations: { checkmarkView.alpha = 0 },
                            completion: { _ in
                                checkmarkView.removeFromSuperview()
                                completion?()
                            }
                        )
                    }
                )
            }
        )
    }

    // MARK: - Error Shake Animation

    private static let errorShakeBorderWidth: CGFloat = 2

    /// Shakes `view` horizontally; under Reduce Motion it flashes an error border instead.
    public static func animateErrorShake(on view: UIView, completion: (() -> Void)? = nil) {
        let shouldReduceMotion = !shouldAnimate

        if shouldReduceMotion {
            let originalBorderColor = view.layer.borderColor
            view.layer.borderWidth = errorShakeBorderWidth
            view.layer.borderColor = LMKColor.error.cgColor
            UIView.animate(
                withDuration: Duration.moderate,
                animations: { view.alpha = LMKAlpha.xl },
                completion: { _ in
                    UIView.animate(
                        withDuration: Duration.moderate,
                        animations: {
                            view.alpha = 1.0
                            view.layer.borderColor = originalBorderColor
                            view.layer.borderWidth = 0
                        },
                        completion: { _ in completion?() }
                    )
                }
            )
            return
        }

        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.timingFunction = Curve.easeInOut.timingFunction
        animation.values = [-10, 10, -10, 10, -5, 5, -2.5, 2.5, 0]
        animation.duration = Duration.slow

        CATransaction.begin()
        CATransaction.setCompletionBlock { completion?() }
        view.layer.add(animation, forKey: "shake")
        CATransaction.commit()
    }

    // MARK: - Photo Load Animation

    private static let photoLoadInitialScale: CGFloat = 0.95

    /// Fades and scales a freshly loaded image into place.
    public static func animatePhotoLoad(on imageView: UIImageView, completion: (() -> Void)? = nil) {
        let reduceMotion = !shouldAnimate
        imageView.alpha = 0
        if !reduceMotion {
            imageView.transform = CGAffineTransform(scaleX: photoLoadInitialScale, y: photoLoadInitialScale)
        }
        UIView.animate(
            withDuration: reduceMotion ? 0 : Duration.fast,
            delay: 0, options: [.allowUserInteraction, Curve.easeIn.options],
            animations: {
                imageView.alpha = 1
                imageView.transform = .identity
            },
            completion: { _ in completion?() }
        )
    }

    // MARK: - Fade In/Out

    /// Fades `view` in from alpha 0.
    public static func fadeIn(_ view: UIView, duration: TimeInterval = Duration.normal, completion: (() -> Void)? = nil) {
        let reduceMotion = !shouldAnimate
        view.alpha = 0
        UIView.animate(
            withDuration: reduceMotion ? 0 : duration,
            delay: 0, options: [.allowUserInteraction, Curve.easeIn.options],
            animations: { view.alpha = 1 },
            completion: { _ in completion?() }
        )
    }

    /// Fades `view` out to alpha 0.
    public static func fadeOut(_ view: UIView, duration: TimeInterval = Duration.normal, completion: (() -> Void)? = nil) {
        let reduceMotion = !shouldAnimate
        UIView.animate(
            withDuration: reduceMotion ? 0 : duration,
            delay: 0, options: [.allowUserInteraction, Curve.easeOut.options],
            animations: { view.alpha = 0 },
            completion: { _ in completion?() }
        )
    }

    // MARK: - List Update

    /// `.automatic`, or `.none` under Reduce Motion.
    public static var tableViewRowAnimation: UITableView.RowAnimation {
        shouldAnimate ? .automatic : .none
    }

    /// Runs a list update with the moderate duration (instant under Reduce Motion).
    public static func animateListUpdate(animations: @escaping () -> Void, completion: (() -> Void)? = nil) {
        let duration = shouldAnimate ? Duration.moderate : 0
        UIView.animate(
            withDuration: duration, delay: 0, options: [Curve.easeOut.options],
            animations: animations,
            completion: { _ in completion?() }
        )
    }
}
