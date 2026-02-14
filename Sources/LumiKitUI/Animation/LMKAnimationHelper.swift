//
//  LMKAnimationHelper.swift
//  LumiKit
//
//  Animation helper following UI/UX design specifications.
//  Respects Reduce Motion accessibility setting throughout.
//  Proxies to `LMKThemeManager.shared.animation` for customization.
//

import UIKit

/// Animation helper with standard durations, curves, and accessibility support.
///
/// Customize by applying an animation theme:
/// ```swift
/// LMKThemeManager.shared.apply(animation: .init(modalPresentation: 0.25))
/// ```
public enum LMKAnimationHelper {
    // MARK: - Animation Durations

    public enum Duration {
        private static var config: LMKAnimationTheme {
            LMKThemeManager.shared.animation
        }

        public static var screenTransition: TimeInterval { config.screenTransition }
        public static var modalPresentation: TimeInterval { config.modalPresentation }
        public static var actionSheet: TimeInterval { config.actionSheet }
        public static var alert: TimeInterval { config.alert }
        /// Short UI transitions (menus, overlays).
        public static var uiShort: TimeInterval { config.uiShort }
        public static var buttonPress: TimeInterval { config.buttonPress }
        public static var successFeedback: TimeInterval { config.successFeedback }
        public static var errorShake: TimeInterval { config.errorShake }
        public static var photoLoad: TimeInterval { config.photoLoad }
        public static var listUpdate: TimeInterval { config.listUpdate }
        public static var listInsertDelete: TimeInterval { config.listInsertDelete }
        public static var cardExpand: TimeInterval { config.cardExpand }
    }

    /// Whether animations should run (`false` when Reduce Motion is enabled).
    public static var shouldAnimate: Bool { !UIAccessibility.isReduceMotionEnabled }

    // MARK: - Spring

    public enum Spring {
        private static var config: LMKAnimationTheme {
            LMKThemeManager.shared.animation
        }

        /// Damping for smooth spring animations (per design spec 0.6–0.8).
        public static var damping: CGFloat { config.springDamping }
    }

    // MARK: - Animation Curves

    public enum Curve {
        public static let easeInOut = UIView.AnimationOptions.curveEaseInOut
        public static let easeOut = UIView.AnimationOptions.curveEaseOut
        public static let easeIn = UIView.AnimationOptions.curveEaseIn
        public static let spring = UIView.AnimationOptions.curveEaseInOut
    }

    // MARK: - Button Press Animation

    private static let buttonPressScale: CGFloat = 0.96
    private static let buttonPressSpringDamping: CGFloat = 0.6

    public static func animateButtonPress(_ button: UIButton, completion: (() -> Void)? = nil) {
        guard shouldAnimate else {
            completion?()
            return
        }
        UIView.animate(
            withDuration: Duration.buttonPress,
            delay: 0,
            usingSpringWithDamping: buttonPressSpringDamping,
            initialSpringVelocity: 0,
            options: [.allowUserInteraction, .beginFromCurrentState],
            animations: {
                button.transform = CGAffineTransform(scaleX: buttonPressScale, y: buttonPressScale)
            },
            completion: { _ in
                UIView.animate(
                    withDuration: Duration.buttonPress,
                    delay: 0,
                    usingSpringWithDamping: buttonPressSpringDamping,
                    initialSpringVelocity: 0,
                    options: [.allowUserInteraction, .beginFromCurrentState],
                    animations: {
                        button.transform = .identity
                    },
                    completion: { _ in completion?() },
                )
            },
        )
    }

    // MARK: - Success Feedback Animation

    public static func animateSuccessFeedback(on view: UIView, completion: (() -> Void)? = nil) {
        let shouldReduceMotion = UIAccessibility.isReduceMotionEnabled

        let checkmarkView = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
        checkmarkView.tintColor = LMKColor.success
        checkmarkView.frame = CGRect(x: 0, y: 0, width: 60, height: 60)
        checkmarkView.center = CGPoint(x: view.bounds.midX, y: view.bounds.midY)
        checkmarkView.alpha = 0
        checkmarkView.transform = CGAffineTransform(scaleX: 0, y: 0)
        view.addSubview(checkmarkView)

        UIView.animate(
            withDuration: shouldReduceMotion ? 0 : Duration.successFeedback * 0.6,
            delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0,
            options: [.allowUserInteraction],
            animations: {
                checkmarkView.alpha = 1
                checkmarkView.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
            },
            completion: { _ in
                UIView.animate(
                    withDuration: shouldReduceMotion ? 0 : Duration.successFeedback * 0.4,
                    delay: 0, options: [.allowUserInteraction],
                    animations: { checkmarkView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0) },
                    completion: { _ in
                        UIView.animate(
                            withDuration: shouldReduceMotion ? 0 : Duration.alert,
                            delay: Duration.modalPresentation,
                            options: [.allowUserInteraction],
                            animations: { checkmarkView.alpha = 0 },
                            completion: { _ in
                                checkmarkView.removeFromSuperview()
                                completion?()
                            },
                        )
                    },
                )
            },
        )
    }

    // MARK: - Error Shake Animation

    public static func animateErrorShake(on view: UIView, completion: (() -> Void)? = nil) {
        let shouldReduceMotion = UIAccessibility.isReduceMotionEnabled

        if shouldReduceMotion {
            let originalBorderColor = view.layer.borderColor
            view.layer.borderWidth = 2
            view.layer.borderColor = LMKColor.error.cgColor
            UIView.animate(
                withDuration: Duration.modalPresentation,
                animations: { view.alpha = LMKAlpha.overlayStrong },
                completion: { _ in
                    UIView.animate(
                        withDuration: Duration.modalPresentation,
                        animations: {
                            view.alpha = 1.0
                            view.layer.borderColor = originalBorderColor
                            view.layer.borderWidth = 0
                        },
                        completion: { _ in completion?() },
                    )
                },
            )
            return
        }

        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        animation.values = [-10, 10, -10, 10, -5, 5, -2.5, 2.5, 0]
        animation.duration = Duration.errorShake

        CATransaction.begin()
        CATransaction.setCompletionBlock { completion?() }
        view.layer.add(animation, forKey: "shake")
        CATransaction.commit()
    }

    // MARK: - Photo Load Animation

    public static func animatePhotoLoad(on imageView: UIImageView, completion: (() -> Void)? = nil) {
        let shouldReduceMotion = UIAccessibility.isReduceMotionEnabled

        imageView.alpha = 0
        if !shouldReduceMotion {
            imageView.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }
        UIView.animate(
            withDuration: shouldReduceMotion ? 0 : Duration.photoLoad,
            delay: 0, options: [.allowUserInteraction, Curve.easeIn],
            animations: {
                imageView.alpha = 1
                imageView.transform = .identity
            },
            completion: { _ in completion?() },
        )
    }

    // MARK: - Fade In/Out

    public static func fadeIn(_ view: UIView, duration: TimeInterval = Duration.alert, completion: (() -> Void)? = nil) {
        let shouldReduceMotion = UIAccessibility.isReduceMotionEnabled
        view.alpha = 0
        UIView.animate(
            withDuration: shouldReduceMotion ? 0 : duration,
            delay: 0, options: [.allowUserInteraction, Curve.easeIn],
            animations: { view.alpha = 1 },
            completion: { _ in completion?() },
        )
    }

    public static func fadeOut(_ view: UIView, duration: TimeInterval = Duration.alert, completion: (() -> Void)? = nil) {
        let shouldReduceMotion = UIAccessibility.isReduceMotionEnabled
        UIView.animate(
            withDuration: shouldReduceMotion ? 0 : duration,
            delay: 0, options: [.allowUserInteraction, Curve.easeOut],
            animations: { view.alpha = 0 },
            completion: { _ in completion?() },
        )
    }

    // MARK: - List Update

    /// Row animation for table view insert/delete operations.
    public static var tableViewRowAnimation: UITableView.RowAnimation {
        shouldAnimate ? .automatic : .none
    }

    /// Wraps table/collection batch updates with appropriate animation.
    public static func animateListUpdate(animations: @escaping () -> Void, completion: (() -> Void)? = nil) {
        let duration = shouldAnimate ? Duration.listInsertDelete : 0
        UIView.animate(
            withDuration: duration, delay: 0, options: [.curveEaseOut],
            animations: animations,
            completion: { _ in completion?() },
        )
    }
}
