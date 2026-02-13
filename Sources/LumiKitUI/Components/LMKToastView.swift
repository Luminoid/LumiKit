//
//  LMKToastView.swift
//  LumiKit
//
//  Toast notification component with type-based styling and haptic feedback.
//

import SnapKit
import UIKit

/// Toast notification type.
public enum LMKToastType {
    case error
    case success
    case warning
    case info

    public var iconName: String {
        switch self {
        case .error: "exclamationmark.circle.fill"
        case .success: "checkmark.circle.fill"
        case .warning: "exclamationmark.triangle.fill"
        case .info: "info.circle.fill"
        }
    }

    public var color: UIColor {
        switch self {
        case .error: LMKColor.error
        case .success: LMKColor.success
        case .warning: LMKColor.warning
        case .info: LMKColor.info
        }
    }
}

/// Toast notification view with icon, message, and accent bar.
public final class LMKToastView: UIView {
    public static let defaultDuration: TimeInterval = 3.0

    private static let showInitialYOffset: CGFloat = -200
    private static let dismissYOffset: CGFloat = 200
    private static let springDamping: CGFloat = 0.78

    private let messageLabel = UILabel()
    private let iconView = UIImageView()
    private let containerView = UIView()
    private var dismissTimer: Timer?

    private let type: LMKToastType
    private let message: String
    private let duration: TimeInterval

    public init(type: LMKToastType, message: String, duration: TimeInterval = LMKToastView.defaultDuration) {
        self.type = type
        self.message = message
        self.duration = duration
        super.init(frame: .zero)
        setupUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .clear
        isUserInteractionEnabled = false

        containerView.backgroundColor = LMKColor.backgroundSecondary
        containerView.layer.cornerRadius = LMKCornerRadius.medium
        containerView.layer.masksToBounds = false

        let shadow = LMKShadow.card()
        containerView.layer.shadowColor = shadow.color
        containerView.layer.shadowOffset = shadow.offset
        containerView.layer.shadowRadius = shadow.radius
        containerView.layer.shadowOpacity = shadow.opacity

        addSubview(containerView)
        containerView.snp.makeConstraints { make in make.edges.equalToSuperview() }

        iconView.image = UIImage(systemName: type.iconName)
        iconView.tintColor = type.color
        iconView.contentMode = .scaleAspectFit
        containerView.addSubview(iconView)
        iconView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(LMKSpacing.medium)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(LMKLayout.iconSmall)
        }

        messageLabel.text = message
        messageLabel.font = LMKTypography.body
        messageLabel.textColor = LMKColor.textPrimary
        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .natural
        containerView.addSubview(messageLabel)
        messageLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconView.snp.trailing).offset(LMKSpacing.small)
            make.trailing.equalToSuperview().offset(-LMKSpacing.medium)
            make.top.bottom.equalToSuperview().inset(LMKSpacing.medium)
        }

        let accentView = UIView()
        accentView.backgroundColor = type.color
        containerView.addSubview(accentView)
        accentView.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
            make.width.equalTo(4)
        }
    }

    /// Show on a view controller.
    public func show(on viewController: UIViewController, onShowComplete: (() -> Void)? = nil) {
        guard let view = viewController.view else { return }
        show(in: view, safeAreaGuide: view.safeAreaLayoutGuide, onShowComplete: onShowComplete)
    }

    /// Show on the key window (avoids affecting host VC layout).
    public func showOnWindow(onShowComplete: (() -> Void)? = nil) {
        guard let window = Self.keyWindow,
              let rootView = window.rootViewController?.view else { return }
        show(in: rootView, safeAreaGuide: rootView.safeAreaLayoutGuide, onShowComplete: onShowComplete)
    }

    private func show(in hostView: UIView, safeAreaGuide: UILayoutGuide, onShowComplete: (() -> Void)?) {
        for subview in hostView.subviews where subview is LMKToastView {
            subview.removeFromSuperview()
        }

        hostView.addSubview(self)
        snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(LMKSpacing.cardPadding)
            make.top.equalTo(safeAreaGuide.snp.top).offset(LMKSpacing.medium)
        }

        transform = CGAffineTransform(translationX: 0, y: Self.showInitialYOffset)
        alpha = 0

        let shouldReduceMotion = !LMKAnimationHelper.shouldAnimate
        let duration = shouldReduceMotion ? 0 : LMKAnimationHelper.Duration.modalPresentation
        UIView.animate(
            withDuration: duration, delay: 0,
            usingSpringWithDamping: Self.springDamping, initialSpringVelocity: 0,
            options: [.allowUserInteraction, .curveEaseOut],
            animations: {
                self.transform = .identity
                self.alpha = 1
            },
            completion: { _ in onShowComplete?() },
        )

        dismissTimer = Timer.scheduledTimer(withTimeInterval: self.duration, repeats: false) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.dismiss()
            }
        }

        switch type {
        case .error: LMKHapticFeedbackHelper.error()
        case .success: LMKHapticFeedbackHelper.success()
        case .warning: LMKHapticFeedbackHelper.warning()
        case .info: LMKHapticFeedbackHelper.light()
        }
    }

    private static var keyWindow: UIWindow? {
        UIApplication.shared.connectedScenes
            .filter { $0.activationState == .foregroundActive }
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow }
    }

    public func dismiss() {
        dismissTimer?.invalidate()
        dismissTimer = nil

        let shouldReduceMotion = !LMKAnimationHelper.shouldAnimate
        UIView.animate(
            withDuration: shouldReduceMotion ? 0 : LMKAnimationHelper.Duration.actionSheet,
            delay: 0, options: [.allowUserInteraction, .curveEaseIn],
            animations: {
                self.transform = CGAffineTransform(translationX: 0, y: Self.dismissYOffset)
                self.alpha = 0
            },
            completion: { _ in self.removeFromSuperview() },
        )
    }

    deinit {
        // Timer must be invalidated on deallocation to prevent retain cycles.
        // We use MainActor.assumeIsolated since UIView deinit runs on main thread.
        MainActor.assumeIsolated {
            dismissTimer?.invalidate()
        }
    }
}

// MARK: - Toast Helper

/// Static convenience methods for showing toasts.
public enum LMKToast {
    public static func show(type: LMKToastType, message: String, duration: TimeInterval = LMKToastView.defaultDuration, on viewController: UIViewController, onShowComplete: (() -> Void)? = nil) {
        let toast = LMKToastView(type: type, message: message, duration: duration)
        toast.show(on: viewController, onShowComplete: onShowComplete)
    }

    public static func showOnWindow(type: LMKToastType, message: String, duration: TimeInterval = LMKToastView.defaultDuration, onShowComplete: (() -> Void)? = nil) {
        let toast = LMKToastView(type: type, message: message, duration: duration)
        toast.showOnWindow(onShowComplete: onShowComplete)
    }

    public static func showError(message: String, duration: TimeInterval = LMKToastView.defaultDuration, on viewController: UIViewController, onShowComplete: (() -> Void)? = nil) {
        show(type: .error, message: message, duration: duration, on: viewController, onShowComplete: onShowComplete)
    }

    public static func showErrorOnWindow(message: String, duration: TimeInterval = LMKToastView.defaultDuration, onShowComplete: (() -> Void)? = nil) {
        showOnWindow(type: .error, message: message, duration: duration, onShowComplete: onShowComplete)
    }

    public static func showSuccess(message: String, duration: TimeInterval = LMKToastView.defaultDuration, on viewController: UIViewController, onShowComplete: (() -> Void)? = nil) {
        show(type: .success, message: message, duration: duration, on: viewController, onShowComplete: onShowComplete)
    }

    public static func showSuccessOnWindow(message: String, duration: TimeInterval = LMKToastView.defaultDuration, onShowComplete: (() -> Void)? = nil) {
        showOnWindow(type: .success, message: message, duration: duration, onShowComplete: onShowComplete)
    }

    public static func showWarning(message: String, duration: TimeInterval = LMKToastView.defaultDuration, on viewController: UIViewController, onShowComplete: (() -> Void)? = nil) {
        show(type: .warning, message: message, duration: duration, on: viewController, onShowComplete: onShowComplete)
    }

    public static func showWarningOnWindow(message: String, duration: TimeInterval = LMKToastView.defaultDuration, onShowComplete: (() -> Void)? = nil) {
        showOnWindow(type: .warning, message: message, duration: duration, onShowComplete: onShowComplete)
    }

    public static func showInfo(message: String, duration: TimeInterval = LMKToastView.defaultDuration, on viewController: UIViewController, onShowComplete: (() -> Void)? = nil) {
        show(type: .info, message: message, duration: duration, on: viewController, onShowComplete: onShowComplete)
    }

    public static func showInfoOnWindow(message: String, duration: TimeInterval = LMKToastView.defaultDuration, onShowComplete: (() -> Void)? = nil) {
        showOnWindow(type: .info, message: message, duration: duration, onShowComplete: onShowComplete)
    }
}
