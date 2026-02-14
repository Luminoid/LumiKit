//
//  LMKBannerView.swift
//  LumiKit
//
//  Persistent informational banner with icon, message, and optional action button.
//

import SnapKit
import UIKit

/// Banner type (reuses toast type for color/icon consistency).
public typealias LMKBannerType = LMKToastType

/// Persistent banner for status messages, warnings, or actionable notifications.
///
/// Unlike `LMKToastView`, banners remain visible until explicitly dismissed or
/// removed by the host view controller.
///
/// ```swift
/// let banner = LMKBannerView(type: .warning, message: "No internet connection")
/// banner.actionTitle = "Settings"
/// banner.actionHandler = { openSettings() }
/// banner.show(on: self)
/// ```
public final class LMKBannerView: UIView {
    // MARK: - Configurable Strings

    public nonisolated struct Strings: Sendable {
        public var dismissAccessibilityLabel: String

        public init(dismissAccessibilityLabel: String = "Dismiss") {
            self.dismissAccessibilityLabel = dismissAccessibilityLabel
        }
    }

    public nonisolated(unsafe) static var strings = Strings()

    // MARK: - Properties

    private let messageLabel = UILabel()
    private let iconView = UIImageView()
    private let actionButton = UIButton(type: .system)
    private let dismissButton = UIButton(type: .system)

    private let type: LMKBannerType
    private let message: String

    /// Optional action button title. When set, shows an action button.
    public var actionTitle: String? {
        didSet {
            actionButton.setTitle(actionTitle, for: .normal)
            actionButton.isHidden = actionTitle == nil
            updateAccessibilityElements()
        }
    }

    /// Handler called when the action button is tapped.
    public var actionHandler: (() -> Void)?

    /// Whether the banner shows a dismiss (X) button. Defaults to `true`.
    public var showsDismissButton: Bool = true {
        didSet {
            dismissButton.isHidden = !showsDismissButton
            updateAccessibilityElements()
        }
    }

    // MARK: - Initialization

    public init(type: LMKBannerType, message: String) {
        self.type = type
        self.message = message
        super.init(frame: .zero)
        setupUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI() {
        backgroundColor = type.color.withAlphaComponent(LMKAlpha.overlayLight)
        layer.cornerRadius = LMKCornerRadius.small

        // Icon
        iconView.image = UIImage(systemName: type.iconName)
        iconView.tintColor = type.color
        iconView.contentMode = .scaleAspectFit
        addSubview(iconView)

        // Message
        messageLabel.text = message
        messageLabel.font = LMKTypography.captionMedium
        messageLabel.textColor = LMKColor.textPrimary
        messageLabel.numberOfLines = 0
        addSubview(messageLabel)

        // Action button
        actionButton.titleLabel?.font = LMKTypography.captionMedium
        actionButton.setTitleColor(type.color, for: .normal)
        actionButton.isHidden = true
        actionButton.addTarget(self, action: #selector(actionTapped), for: .touchUpInside)
        addSubview(actionButton)

        // Dismiss button
        dismissButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        dismissButton.tintColor = LMKColor.textTertiary
        dismissButton.addTarget(self, action: #selector(dismissTapped), for: .touchUpInside)
        dismissButton.accessibilityLabel = Self.strings.dismissAccessibilityLabel
        addSubview(dismissButton)

        // Layout
        iconView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(LMKSpacing.medium)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(LMKLayout.iconSmall)
        }

        dismissButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-LMKSpacing.small)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(LMKLayout.minimumTouchTarget)
        }

        actionButton.snp.makeConstraints { make in
            make.trailing.equalTo(dismissButton.snp.leading).offset(-LMKSpacing.xs)
            make.centerY.equalToSuperview()
        }

        messageLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconView.snp.trailing).offset(LMKSpacing.small)
            make.trailing.lessThanOrEqualTo(actionButton.snp.leading).offset(-LMKSpacing.small)
            make.top.bottom.equalToSuperview().inset(LMKSpacing.medium)
        }

        isAccessibilityElement = false
        updateAccessibilityElements()
    }

    private func updateAccessibilityElements() {
        var elements: [Any] = [messageLabel]
        if !actionButton.isHidden { elements.append(actionButton) }
        if !dismissButton.isHidden { elements.append(dismissButton) }
        accessibilityElements = elements
    }

    // MARK: - Actions

    @objc private func actionTapped() {
        actionHandler?()
    }

    @objc private func dismissTapped() {
        dismiss()
    }

    // MARK: - Show / Dismiss

    /// Show the banner at the top of a view controller. Removes any existing banners first.
    public func show(on viewController: UIViewController) {
        guard let view = viewController.view else { return }

        // Remove existing banners
        for subview in view.subviews where subview is LMKBannerView {
            subview.removeFromSuperview()
        }

        view.addSubview(self)
        snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(LMKSpacing.cardPadding)
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(LMKSpacing.small)
        }

        if LMKAnimationHelper.shouldAnimate {
            alpha = 0
            transform = CGAffineTransform(translationX: 0, y: -LMKSpacing.xl)
            UIView.animate(withDuration: LMKAnimationHelper.Duration.actionSheet) {
                self.alpha = 1
                self.transform = .identity
            }
        }
    }

    /// Dismiss the banner with animation.
    public func dismiss() {
        let duration = LMKAnimationHelper.shouldAnimate ? LMKAnimationHelper.Duration.actionSheet : 0
        UIView.animate(
            withDuration: duration,
            animations: { self.alpha = 0 },
            completion: { _ in self.removeFromSuperview() }
        )
    }
}
