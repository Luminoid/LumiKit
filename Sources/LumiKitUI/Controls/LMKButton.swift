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
        /// No background, no border — just colored text. For text links and lightweight actions.
        case ghost(UIColor)
        /// Circular icon-only button. No title, icon centered.
        case iconOnly(UIColor)
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

    /// Whether the button is in a loading state. Shows an activity indicator and disables interaction.
    public var isLoading: Bool = false {
        didSet {
            guard isLoading != oldValue else { return }
            configuration?.showsActivityIndicator = isLoading
            if isLoading {
                savedTitle = configuration?.title
                // Use a space instead of nil to preserve the title's line height contribution.
                configuration?.title = " "
            } else {
                configuration?.title = savedTitle
            }
            isUserInteractionEnabled = !isLoading
        }
    }

    private var savedTitle: String?

    /// Apply a visual style to the button.
    public func applyStyle(_ style: Style, title: String) {
        var config: UIButton.Configuration
        switch style {
        case let .filled(color):
            config = .filled()
            config.baseBackgroundColor = color
            config.baseForegroundColor = LMKColor.white
            config.cornerStyle = .capsule
            config.contentInsets = NSDirectionalEdgeInsets(
                top: LMKSpacing.buttonPaddingVertical,
                leading: LMKSpacing.buttonPaddingHorizontal,
                bottom: LMKSpacing.buttonPaddingVertical,
                trailing: LMKSpacing.buttonPaddingHorizontal
            )
        case let .outlined(color):
            config = .plain()
            config.baseForegroundColor = color
            config.background.strokeColor = color
            config.background.strokeWidth = 1
            config.cornerStyle = .capsule
            config.contentInsets = NSDirectionalEdgeInsets(
                top: LMKSpacing.buttonPaddingVertical,
                leading: LMKSpacing.buttonPaddingHorizontal,
                bottom: LMKSpacing.buttonPaddingVertical,
                trailing: LMKSpacing.buttonPaddingHorizontal
            )
        case let .ghost(color):
            config = .plain()
            config.baseForegroundColor = color
            config.contentInsets = NSDirectionalEdgeInsets(
                top: LMKSpacing.xs,
                leading: LMKSpacing.small,
                bottom: LMKSpacing.xs,
                trailing: LMKSpacing.small
            )
        case let .iconOnly(color):
            config = .plain()
            config.baseForegroundColor = color
            config.contentInsets = NSDirectionalEdgeInsets(
                top: LMKSpacing.small,
                leading: LMKSpacing.small,
                bottom: LMKSpacing.small,
                trailing: LMKSpacing.small
            )
        }

        config.title = title
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = LMKTypography.bodyMedium
            return outgoing
        }

        configuration = config
        pressAnimationEnabled = true
    }

    /// Apply a style with an icon instead of title.
    public func applyIconStyle(_ style: Style, iconName: String, pointSize: CGFloat = 16, weight: UIImage.SymbolWeight = .medium) {
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: pointSize, weight: weight)
        let image = UIImage(systemName: iconName, withConfiguration: symbolConfig)

        applyStyle(style, title: "")
        configuration?.title = nil
        configuration?.image = image
    }

    /// Constrain the title to a single line that shrinks to fit the available width.
    /// - Parameter minimumScaleFactor: Smallest fraction the font will shrink to (default 0.7).
    @discardableResult
    public func lmk_singleLineShrinkToFit(minimumScaleFactor: CGFloat = 0.7) -> Self {
        configuration?.titleLineBreakMode = .byTruncatingTail
        titleLabel?.numberOfLines = 1
        titleLabel?.adjustsFontSizeToFitWidth = true
        titleLabel?.minimumScaleFactor = minimumScaleFactor
        return self
    }
}
