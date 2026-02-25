//
//  LMKButton.swift
//  LumiKit
//
//  Base button with closure-based tap handling and optional press animation.
//

import UIKit

/// Base button with closure-based tap handling.
open class LMKButton: UIButton {
    /// Visual style for the button.
    public enum Style {
        /// Solid background with white text.
        case filled(UIColor)
        /// Clear background with colored border and text.
        case outlined(UIColor)
    }

    /// Simple tap handler (no reference to button). Use for fire-and-forget actions.
    ///
    /// Both `tapHandler` and `didTapHandler` fire on every tap — use **one** or the other,
    /// not both. If you need a reference to the button, use `didTapHandler` instead.
    public var tapHandler: (() -> Void)?

    /// Typed tap handler that receives the button instance. Use when you need a reference to the tapped button.
    ///
    /// Both `tapHandler` and `didTapHandler` fire on every tap — use **one** or the other,
    /// not both. For fire-and-forget actions, prefer `tapHandler`.
    public var didTapHandler: ((LMKButton) -> Void)?

    /// When `true`, plays press animation + haptic on touch down.
    public var pressAnimationEnabled: Bool = false

    public var imageContentMode: UIView.ContentMode = .scaleAspectFit {
        didSet { imageView?.contentMode = imageContentMode }
    }

    override public init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }

    /// Create a styled button with a title.
    public convenience init(title: String, style: Style) {
        self.init(frame: .zero)
        applyStyle(style, title: title)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open func initialize() {
        imageView?.contentMode = imageContentMode
        addTarget(self, action: #selector(didTap), for: .touchUpInside)
        addTarget(self, action: #selector(handleTouchDown), for: .touchDown)
        addTarget(self, action: #selector(handleTouchUp), for: [.touchUpInside, .touchUpOutside, .touchCancel])
    }

    @objc private func handleTouchDown() {
        guard pressAnimationEnabled else { return }
        LMKHapticFeedbackHelper.medium()
        guard LMKAnimationHelper.shouldAnimate else { return }
        LMKAnimationHelper.animateButtonPressDown(self)
    }

    @objc private func handleTouchUp() {
        guard pressAnimationEnabled, LMKAnimationHelper.shouldAnimate else { return }
        LMKAnimationHelper.animateButtonPressUp(self)
    }

    @objc open func didTap() {
        tapHandler?()
        didTapHandler?(self)
    }

    // MARK: - Styling

    /// Apply a visual style to the button.
    public func applyStyle(_ style: Style, title: String) {
        switch style {
        case .filled(let color):
            var config = UIButton.Configuration.filled()
            config.title = title
            config.baseBackgroundColor = color
            config.baseForegroundColor = LMKColor.white
            config.cornerStyle = .fixed
            config.background.cornerRadius = LMKCornerRadius.small
            config.contentInsets = NSDirectionalEdgeInsets(
                top: LMKSpacing.buttonPaddingVertical,
                leading: LMKSpacing.buttonPaddingHorizontal,
                bottom: LMKSpacing.buttonPaddingVertical,
                trailing: LMKSpacing.buttonPaddingHorizontal,
            )
            config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
                var outgoing = incoming
                outgoing.font = LMKTypography.bodyMedium
                return outgoing
            }
            configuration = config

        case .outlined(let color):
            var config = UIButton.Configuration.plain()
            config.title = title
            config.baseForegroundColor = color
            config.cornerStyle = .fixed
            config.background.cornerRadius = LMKCornerRadius.small
            config.background.strokeColor = color
            config.background.strokeWidth = 1
            config.contentInsets = NSDirectionalEdgeInsets(
                top: LMKSpacing.buttonPaddingVertical,
                leading: LMKSpacing.buttonPaddingHorizontal,
                bottom: LMKSpacing.buttonPaddingVertical,
                trailing: LMKSpacing.buttonPaddingHorizontal,
            )
            config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
                var outgoing = incoming
                outgoing.font = LMKTypography.bodyMedium
                return outgoing
            }
            configuration = config
        }
        pressAnimationEnabled = true
    }
}
