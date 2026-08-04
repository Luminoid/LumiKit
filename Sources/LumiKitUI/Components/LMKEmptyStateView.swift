//
//  LMKEmptyStateView.swift
//  LumiKit
//
//  Reusable empty state view component with fullScreen, card, and inline styles.
//

import SnapKit
import UIKit

/// Empty state view style.
public enum LMKEmptyStateStyle {
    case fullScreen
    case card
    case inline

    public var iconSize: CGFloat {
        switch self {
        case .fullScreen: 80
        case .card: 40
        case .inline: 20
        }
    }

    public var font: UIFont {
        switch self {
        case .fullScreen: LMKTypography.h3
        case .card: LMKTypography.body
        case .inline: LMKTypography.caption
        }
    }

    public var isHorizontal: Bool { self == .inline }
}

/// Reusable empty state view for displaying messages when content is unavailable.
///
/// **Sizing contract**: the content (icon → message → optional action button)
/// forms one vertical constraint chain inside a centered container whose
/// height is content-driven, so it grows with multi-line messages and larger
/// Dynamic Type sizes and the pieces can never overlap. With no host-imposed
/// height the view sizes itself to that content (its edges hug the container
/// at below-required priority), so it can sit directly in a stack view. A
/// host-imposed height wins over the hugging and centers the content; make it
/// generous enough for the content, or it will overflow the view's bounds.
/// Don't anchor a separate call-to-action to the view's bottom edge — use
/// ``Action`` so the button participates in the chain.
public final class LMKEmptyStateView: UIView {
    /// Configuration for the optional call-to-action button rendered below the
    /// message.
    ///
    /// Shown for the `.fullScreen` and `.card` styles. The horizontal `.inline`
    /// style has no room for a call to action and ignores the action entirely.
    public struct Action {
        /// Button title.
        public var title: String
        /// Optional leading SF Symbol name.
        public var icon: String?
        /// Visual style for the button. Defaults to the filled primary style.
        public var style: LMKButton.Style
        /// Called when the button is tapped.
        public var handler: () -> Void

        public init(
            title: String,
            icon: String? = nil,
            style: LMKButton.Style = .filled(LMKColor.primary),
            handler: @escaping () -> Void
        ) {
            self.title = title
            self.icon = icon
            self.style = style
            self.handler = handler
        }
    }

    private static var iconToLabelSpacing: CGFloat { LMKSpacing.small }
    private static var labelToButtonSpacing: CGFloat { LMKSpacing.large }
    private static let iconAnimationScale: CGFloat = 0.95
    private static let iconAnimationDelay: TimeInterval = 0.05
    private static let labelAnimationDelay: TimeInterval = 0.1
    private static let buttonAnimationDelay: TimeInterval = 0.15

    public static let inlineCellHeight: CGFloat = 44
    public static let cardCellHeight: CGFloat = 120
    public static let fullScreenCellHeight: CGFloat = 150
    public static var inlineHorizontalInsets: CGFloat { LMKSpacing.large * 2 }

    private let messageLabel = UILabel()
    private let iconImageView = UIImageView()
    private var containerView = UIView()
    private var horizontalContainerView: UIView?
    private var currentStyle: LMKEmptyStateStyle = .fullScreen
    private var currentAction: Action?
    /// The rendered call-to-action button; nil when no action is set or the
    /// style is `.inline`.
    private(set) var actionButton: LMKButton?

    override public init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: Self, _: UITraitCollection) in
            self.refreshDynamicColors()
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func refreshDynamicColors() {
        iconImageView.tintColor = LMKColor.textTertiary
        messageLabel.textColor = LMKColor.textPrimary
    }

    private func setupUI() {
        backgroundColor = .clear
        isAccessibilityElement = true
        accessibilityTraits = .staticText

        containerView.backgroundColor = .clear
        addSubview(containerView)
        containerView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.greaterThanOrEqualToSuperview()
            make.trailing.lessThanOrEqualToSuperview()
            // Vertical sizing contract. The guards keep the content inside the
            // view whenever the host height allows it (999, not required, so a
            // host that pins a too-short height gets the old silent overflow
            // instead of unsatisfiable-constraint breakage); the edge hugging
            // gives the view its content height when the host imposes none —
            // without it the view collapses to zero height in a stack view and
            // the centered content spills over its neighbors. The hugging must
            // stay below UILabel's default vertical content hugging (250): any
            // higher and a host-imposed taller height stretches the message
            // label to fill the view instead of breaking the hugging, losing
            // the centered layout.
            make.top.greaterThanOrEqualToSuperview().priority(999)
            make.bottom.lessThanOrEqualToSuperview().priority(999)
            make.top.equalToSuperview().priority(249)
            make.bottom.equalToSuperview().priority(249)
        }

        iconImageView.contentMode = .scaleAspectFit
        iconImageView.tintColor = LMKColor.textTertiary
        iconImageView.isHidden = true
        containerView.addSubview(iconImageView)

        messageLabel.textColor = LMKColor.textPrimary
        messageLabel.numberOfLines = 0
        messageLabel.lineBreakMode = .byWordWrapping
        // Without this, a mid-session Dynamic Type change would not reflow the
        // message until the next configure() call.
        messageLabel.adjustsFontForContentSizeCategory = true
        containerView.addSubview(messageLabel)
    }

    private func setupConstraints(for style: LMKEmptyStateStyle) {
        if let horizontalContainer = horizontalContainerView {
            iconImageView.removeFromSuperview()
            messageLabel.removeFromSuperview()
            horizontalContainer.removeFromSuperview()
            horizontalContainerView = nil
            containerView.addSubview(iconImageView)
            containerView.addSubview(messageLabel)
        }

        iconImageView.snp.remakeConstraints { _ in }
        messageLabel.snp.remakeConstraints { _ in }

        if style.isHorizontal {
            messageLabel.textAlignment = .natural
            if !iconImageView.isHidden {
                let horizontalContainer = UIView()
                horizontalContainer.backgroundColor = .clear
                containerView.addSubview(horizontalContainer)
                horizontalContainerView = horizontalContainer

                iconImageView.removeFromSuperview()
                messageLabel.removeFromSuperview()
                horizontalContainer.addSubview(iconImageView)
                horizontalContainer.addSubview(messageLabel)

                iconImageView.snp.makeConstraints { make in
                    make.width.height.equalTo(style.iconSize)
                    make.leading.equalToSuperview()
                    make.centerY.equalToSuperview()
                }
                messageLabel.snp.makeConstraints { make in
                    make.leading.equalTo(iconImageView.snp.trailing).offset(Self.iconToLabelSpacing)
                    make.trailing.equalToSuperview()
                    make.centerY.equalToSuperview()
                    make.top.bottom.equalToSuperview()
                }
                horizontalContainer.snp.makeConstraints { make in
                    make.centerX.centerY.equalToSuperview()
                    make.top.bottom.equalToSuperview()
                }
            } else {
                messageLabel.snp.makeConstraints { make in
                    make.centerX.centerY.equalToSuperview()
                    make.leading.trailing.equalToSuperview()
                    make.top.bottom.equalToSuperview()
                }
            }
        } else {
            messageLabel.textAlignment = .center
            if !iconImageView.isHidden {
                iconImageView.snp.makeConstraints { make in
                    make.width.height.equalTo(style.iconSize)
                    make.centerX.equalToSuperview()
                    make.top.equalToSuperview()
                }
                messageLabel.snp.makeConstraints { make in
                    make.top.equalTo(iconImageView.snp.bottom).offset(LMKSpacing.small)
                    make.leading.trailing.equalToSuperview()
                }
            } else {
                messageLabel.snp.makeConstraints { make in
                    make.centerX.equalToSuperview()
                    make.top.leading.trailing.equalToSuperview()
                }
            }

            if let actionButton {
                actionButton.snp.makeConstraints { make in
                    make.top.equalTo(messageLabel.snp.bottom).offset(Self.labelToButtonSpacing)
                    make.centerX.equalToSuperview()
                    make.leading.greaterThanOrEqualToSuperview()
                    make.trailing.lessThanOrEqualToSuperview()
                    make.bottom.equalToSuperview()
                }
            } else {
                messageLabel.snp.makeConstraints { make in
                    make.bottom.equalToSuperview()
                }
            }
        }
    }

    /// Configure the empty state view.
    ///
    /// - Parameters:
    ///   - message: The message text.
    ///   - icon: Optional SF Symbol shown above the message (beside it for `.inline`).
    ///   - style: Presentation style. Default `.fullScreen`.
    ///   - action: Optional call-to-action button rendered below the message,
    ///     centered and hugging its content. Shown for `.fullScreen` and
    ///     `.card`; the `.inline` style ignores it.
    public func configure(message: String, icon: String? = nil, style: LMKEmptyStateStyle = .fullScreen, action: Action? = nil) {
        messageLabel.text = message
        messageLabel.font = style.font
        currentStyle = style
        currentAction = action

        if let iconName = icon, let iconImage = UIImage(systemName: iconName) {
            iconImageView.image = iconImage
            iconImageView.isHidden = false
        } else {
            iconImageView.isHidden = true
        }

        rebuildActionButton()
        setupConstraints(for: style)
        updateAccessibility()

        if LMKAnimationHelper.shouldAnimate {
            if !iconImageView.isHidden {
                iconImageView.alpha = 0
                iconImageView.transform = CGAffineTransform(scaleX: Self.iconAnimationScale, y: Self.iconAnimationScale)
                UIView.animate(withDuration: LMKAnimationHelper.Duration.actionSheet, delay: Self.iconAnimationDelay, options: .curveEaseOut) {
                    self.iconImageView.alpha = 1
                    self.iconImageView.transform = .identity
                }
            }
            messageLabel.alpha = 0
            UIView.animate(withDuration: LMKAnimationHelper.Duration.actionSheet, delay: Self.labelAnimationDelay, options: .curveEaseOut) {
                self.messageLabel.alpha = 1
            }
            fadeInActionButton()
        } else {
            iconImageView.alpha = 1
            iconImageView.transform = .identity
            messageLabel.alpha = 1
            actionButton?.alpha = 1
        }
    }

    /// Add, replace, or remove the call-to-action button after `configure`.
    ///
    /// Passing `nil` removes the button and restores the view as a single
    /// static-text accessibility element. The `.inline` style ignores the
    /// action (see ``configure(message:icon:style:action:)``).
    public func setAction(_ action: Action?) {
        currentAction = action
        rebuildActionButton()
        setupConstraints(for: currentStyle)
        updateAccessibility()

        if LMKAnimationHelper.shouldAnimate {
            fadeInActionButton()
        } else {
            actionButton?.alpha = 1
        }
    }

    // MARK: - Action Button

    /// Tears down and (when an action is set and the style has room for it)
    /// rebuilds the call-to-action button. Rebuilding rather than mutating
    /// keeps constraint state trivial: a fresh button carries no stale
    /// constraints into `setupConstraints`.
    private func rebuildActionButton() {
        actionButton?.removeFromSuperview()
        actionButton = nil

        // The horizontal inline style has no room for a call to action.
        guard let action = currentAction, !currentStyle.isHorizontal else { return }

        let button = LMKButton()
        button.applyStyle(action.style, title: action.title)
        if let iconName = action.icon {
            button.configuration?.image = UIImage(systemName: iconName)
            button.configuration?.imagePlacement = .leading
            button.configuration?.imagePadding = LMKSpacing.small
        }
        button.tapHandler = action.handler
        // Hug the content: the button should never stretch to the message width.
        button.setContentHuggingPriority(.required, for: .horizontal)
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
        containerView.addSubview(button)
        actionButton = button
    }

    /// Fades the action button in after the label (same duration, later delay),
    /// mirroring the icon → label entrance stagger.
    private func fadeInActionButton() {
        guard let actionButton else { return }
        actionButton.alpha = 0
        UIView.animate(withDuration: LMKAnimationHelper.Duration.actionSheet, delay: Self.buttonAnimationDelay, options: .curveEaseOut) {
            actionButton.alpha = 1
        }
    }

    // MARK: - Accessibility

    /// With no action the view is one static-text element (message as label).
    /// With an action present that single element would swallow the button, so
    /// the view becomes a plain container exposing the message label and the
    /// button as separate accessibility elements.
    private func updateAccessibility() {
        if actionButton != nil {
            isAccessibilityElement = false
            accessibilityTraits = []
            accessibilityLabel = nil
            messageLabel.isAccessibilityElement = true
        } else {
            isAccessibilityElement = true
            accessibilityTraits = .staticText
            accessibilityLabel = messageLabel.text
            messageLabel.isAccessibilityElement = false
        }
    }

    /// Wraps this view for use as `tableView.backgroundView`.
    public func wrappedForTableBackground(backgroundColor: UIColor? = nil) -> UIView {
        let container = UIView()
        container.backgroundColor = backgroundColor ?? LMKColor.backgroundPrimary
        container.addSubview(self)
        snp.makeConstraints { make in make.edges.equalToSuperview() }
        return container
    }
}

/// Helper extension for creating empty state table view cells.
public extension UITableViewCell {
    static func lmk_emptyStateCell(message: String, icon: String? = nil, style: LMKEmptyStateStyle = .card, reuseIdentifier: String = "LMKEmptyStateCell") -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: reuseIdentifier)
        cell.selectionStyle = .none
        cell.backgroundColor = .clear

        let emptyStateView = LMKEmptyStateView()
        emptyStateView.configure(message: message, icon: icon, style: style)
        cell.contentView.addSubview(emptyStateView)

        let height: CGFloat = style == .inline ? LMKEmptyStateView.inlineCellHeight : (style == .card ? LMKEmptyStateView.cardCellHeight : LMKEmptyStateView.fullScreenCellHeight)
        emptyStateView.snp.makeConstraints { make in
            make.centerX.centerY.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(LMKEmptyStateView.inlineHorizontalInsets)
            make.height.greaterThanOrEqualTo(height)
        }
        return cell
    }
}
