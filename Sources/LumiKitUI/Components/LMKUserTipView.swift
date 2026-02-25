//
//  LMKUserTipView.swift
//  LumiKit
//
//  User tip component for onboarding and feature discovery.
//  Supports centered and pointed (arrow) presentation styles.
//

import SnapKit
import UIKit

/// Arrow direction for pointed user tips.
public enum LMKUserTipArrowDirection {
    /// Bubble appears below the source view; arrow points up toward it.
    case up
    /// Bubble appears above the source view; arrow points down toward it.
    case down
    /// Automatically picks the best direction based on available space.
    case automatic
}

/// Presentation style for user tips.
public enum LMKUserTipStyle {
    /// Centered card with dimming overlay.
    case center
    /// Arrow pointing at a source view.
    case pointed(sourceView: UIView, arrowDirection: LMKUserTipArrowDirection)
}

/// Layout constants for user tips.
public enum LMKUserTipLayout {
    public static let arrowWidth: CGFloat = 16
    public static let arrowHeight: CGFloat = 8
    public static let arrowTipRadius: CGFloat = 2
    public static let maxWidth: CGFloat = 300
    public static let minMargin: CGFloat = 16
    public static let sourceSpacing: CGFloat = 4
    public static let iconBackgroundSize: CGFloat = 36
}

/// User tip view for onboarding hints and feature discovery.
///
/// Two presentation styles:
/// - **Center**: A card displayed in the screen center with a dimming overlay and "Got it" button.
/// - **Pointed**: A compact tip with an arrow pointing at a source view.
///
/// Tap anywhere outside the tip to dismiss.
///
/// ```swift
/// // Centered tip
/// LMKUserTip.show(title: "Welcome", message: "Tap the + button to add a plant", on: self)
///
/// // Pointed at a button
/// LMKUserTip.show(message: "Tap here to add a photo",
///                 style: .pointed(sourceView: addButton, arrowDirection: .automatic),
///                 on: self)
/// ```
public final class LMKUserTipView: UIView {
    // MARK: - Configurable Strings

    public nonisolated struct Strings: Sendable {
        public var dismissAccessibilityHint: String
        public var dismissButtonTitle: String

        public init(
            dismissAccessibilityHint: String = "Tap anywhere to dismiss",
            dismissButtonTitle: String = "Got it"
        ) {
            self.dismissAccessibilityHint = dismissAccessibilityHint
            self.dismissButtonTitle = dismissButtonTitle
        }
    }

    public nonisolated(unsafe) static var strings = Strings()

    // MARK: - Properties

    /// Called when the tip is dismissed.
    public var onDismiss: (() -> Void)?

    private let titleText: String?
    private let messageText: String
    private let iconImage: UIImage?

    private let dimmingView = UIView()
    private let bubbleView = UIView()
    private let arrowLayer = CAShapeLayer()
    private var resolvedDirection: LMKUserTipArrowDirection?
    private var pendingArrowParams: (direction: LMKUserTipArrowDirection, sourceFrame: CGRect)?

    private lazy var iconBackgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = LMKColor.primary.withAlphaComponent(LMKAlpha.overlayLight)
        view.layer.cornerRadius = LMKUserTipLayout.iconBackgroundSize / 2
        return view
    }()

    private lazy var iconView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.tintColor = LMKColor.primary
        return view
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = LMKTypography.bodyMedium
        label.textColor = LMKColor.textPrimary
        label.numberOfLines = 0
        return label
    }()

    private lazy var messageLabel: UILabel = {
        let label = UILabel()
        label.font = LMKTypography.body
        label.textColor = LMKColor.textSecondary
        label.numberOfLines = 0
        return label
    }()

    private lazy var dismissButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(Self.strings.dismissButtonTitle, for: .normal)
        button.setTitleColor(LMKColor.primary, for: .normal)
        button.titleLabel?.font = LMKTypography.captionMedium
        button.addTarget(self, action: #selector(dismissTapped), for: .touchUpInside)
        button.contentHorizontalAlignment = .trailing
        return button
    }()

    // MARK: - Initialization

    public init(title: String? = nil, message: String, icon: UIImage? = nil) {
        self.titleText = title
        self.messageText = message
        self.iconImage = icon
        super.init(frame: .zero)
        setupUI()
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: LMKUserTipView, _: UITraitCollection) in
            self.refreshDynamicColors()
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI() {
        // Dimming overlay
        dimmingView.backgroundColor = LMKColor.black.withAlphaComponent(LMKAlpha.dimmingOverlay)
        let tap = UITapGestureRecognizer(target: self, action: #selector(dimmingTapped))
        dimmingView.addGestureRecognizer(tap)
        dimmingView.isAccessibilityElement = true
        dimmingView.accessibilityLabel = Self.strings.dismissAccessibilityHint
        dimmingView.accessibilityTraits = .button
        addSubview(dimmingView)
        dimmingView.snp.makeConstraints { $0.edges.equalToSuperview() }

        // Bubble container
        bubbleView.backgroundColor = LMKColor.backgroundSecondary
        bubbleView.layer.cornerRadius = LMKCornerRadius.medium
        bubbleView.lmk_applyShadow(LMKShadow.card())
        addSubview(bubbleView)

        // Build content
        let outerStack = UIStackView(lmk_axis: .vertical, spacing: LMKSpacing.medium)

        // Top row: icon + text
        let topContent: UIView
        let textStack = UIStackView(lmk_axis: .vertical, spacing: LMKSpacing.xs)

        if let titleText {
            titleLabel.text = titleText
            textStack.addArrangedSubview(titleLabel)
        }
        messageLabel.text = messageText
        textStack.addArrangedSubview(messageLabel)

        if let iconImage {
            iconView.image = iconImage
            let iconRow = UIStackView(lmk_axis: .horizontal, spacing: LMKSpacing.medium)
            iconRow.alignment = .top

            // Icon in a tinted circle
            iconBackgroundView.addSubview(iconView)
            iconView.snp.makeConstraints { make in
                make.center.equalToSuperview()
                make.width.height.equalTo(LMKLayout.iconSmall)
            }
            iconBackgroundView.snp.makeConstraints { make in
                make.width.height.equalTo(LMKUserTipLayout.iconBackgroundSize)
            }

            iconRow.addArrangedSubview(iconBackgroundView)
            iconRow.addArrangedSubview(textStack)
            topContent = iconRow
        } else {
            topContent = textStack
        }

        outerStack.addArrangedSubview(topContent)

        // Dismiss button — shown only for center style (configured in show())
        dismissButton.isHidden = true
        outerStack.addArrangedSubview(dismissButton)

        bubbleView.addSubview(outerStack)
        outerStack.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(LMKSpacing.medium)
            make.leading.trailing.equalToSuperview().inset(LMKSpacing.large)
        }

        // Arrow layer on bubbleView so it inherits bubble's alpha animation
        arrowLayer.isHidden = true
        bubbleView.layer.addSublayer(arrowLayer)

        // Accessibility
        isAccessibilityElement = false
        bubbleView.isAccessibilityElement = true
        bubbleView.accessibilityLabel = [titleText, messageText].compactMap { $0 }.joined(separator: ". ")
        bubbleView.accessibilityHint = Self.strings.dismissAccessibilityHint
    }

    private func refreshDynamicColors() {
        dimmingView.backgroundColor = LMKColor.black.withAlphaComponent(LMKAlpha.dimmingOverlay)
        bubbleView.backgroundColor = LMKColor.backgroundSecondary
        bubbleView.lmk_applyShadow(LMKShadow.card())
        titleLabel.textColor = LMKColor.textPrimary
        messageLabel.textColor = LMKColor.textSecondary
        iconView.tintColor = LMKColor.primary
        iconBackgroundView.backgroundColor = LMKColor.primary.withAlphaComponent(LMKAlpha.overlayLight)
        dismissButton.setTitleColor(LMKColor.primary, for: .normal)
        arrowLayer.fillColor = LMKColor.backgroundSecondary.cgColor
    }

    // MARK: - Show

    /// Show the user tip on a view controller.
    public func show(style: LMKUserTipStyle, on viewController: UIViewController) {
        guard let hostView = viewController.view else { return }

        // Remove existing tips
        for subview in hostView.subviews where subview is LMKUserTipView {
            (subview as? LMKUserTipView)?.dismiss()
        }

        // Show dismiss button only for center style
        switch style {
        case .center:
            dismissButton.isHidden = false
        case .pointed:
            dismissButton.isHidden = true
        }

        hostView.addSubview(self)
        snp.makeConstraints { $0.edges.equalToSuperview() }

        switch style {
        case .center:
            layoutCenterStyle()
        case let .pointed(sourceView, arrowDirection):
            layoutPointedStyle(sourceView: sourceView, requestedDirection: arrowDirection, hostView: hostView)
        }

        // Force layout so bubble has its final frame before drawing arrow
        hostView.layoutIfNeeded()

        // Draw arrow now that bubble is laid out (must happen before animateIn)
        if let params = pendingArrowParams {
            drawArrow(direction: params.direction, sourceFrame: params.sourceFrame)
            pendingArrowParams = nil
        }

        animateIn(style: style)
        LMKHapticFeedbackHelper.light()

        UIAccessibility.post(notification: .announcement, argument: messageText)
    }

    /// Dismiss the user tip.
    public func dismiss() {
        let duration = LMKAnimationHelper.shouldAnimate ? LMKAnimationHelper.Duration.actionSheet : 0
        UIView.animate(
            withDuration: duration,
            animations: {
                self.alpha = 0
            },
            completion: { _ in
                self.onDismiss?()
                self.removeFromSuperview()
            }
        )
    }

    // MARK: - Layout

    private func layoutCenterStyle() {
        bubbleView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.lessThanOrEqualTo(LMKUserTipLayout.maxWidth)
            make.leading.greaterThanOrEqualToSuperview().offset(LMKUserTipLayout.minMargin)
            make.trailing.lessThanOrEqualToSuperview().offset(-LMKUserTipLayout.minMargin)
        }
    }

    private func layoutPointedStyle(sourceView: UIView, requestedDirection: LMKUserTipArrowDirection, hostView: UIView) {
        let sourceFrame = sourceView.convert(sourceView.bounds, to: hostView)
        let direction = resolveDirection(requestedDirection, sourceFrame: sourceFrame, hostView: hostView)
        resolvedDirection = direction

        bubbleView.snp.makeConstraints { make in
            make.width.lessThanOrEqualTo(LMKUserTipLayout.maxWidth)
            make.leading.greaterThanOrEqualToSuperview().offset(LMKUserTipLayout.minMargin)
            make.trailing.lessThanOrEqualToSuperview().offset(-LMKUserTipLayout.minMargin)
            make.centerX.equalTo(sourceFrame.midX).priority(.high)

            switch direction {
            case .up:
                make.top.equalToSuperview().offset(
                    sourceFrame.maxY + LMKUserTipLayout.arrowHeight + LMKUserTipLayout.sourceSpacing
                )
            case .down:
                make.bottom.equalToSuperview().offset(
                    -(hostView.bounds.height - sourceFrame.minY + LMKUserTipLayout.arrowHeight + LMKUserTipLayout.sourceSpacing)
                )
            case .automatic:
                break
            }
        }

        // Store params — arrow drawn after layoutIfNeeded() in show()
        pendingArrowParams = (direction: direction, sourceFrame: sourceFrame)
    }

    private func resolveDirection(_ direction: LMKUserTipArrowDirection, sourceFrame: CGRect, hostView: UIView) -> LMKUserTipArrowDirection {
        guard direction == .automatic else { return direction }

        let spaceAbove = sourceFrame.minY - hostView.safeAreaInsets.top
        let estimatedBubbleHeight: CGFloat = 80
        let needed = estimatedBubbleHeight + LMKUserTipLayout.arrowHeight + LMKUserTipLayout.sourceSpacing

        return spaceAbove >= needed ? .down : .up
    }

    // MARK: - Arrow

    private func drawArrow(direction: LMKUserTipArrowDirection, sourceFrame: CGRect) {
        // Convert sourceFrame from self's coordinate space to bubbleView's coordinate space
        let sourceInBubble = convert(sourceFrame, to: bubbleView)
        let bubbleBounds = bubbleView.bounds
        let arrowW = LMKUserTipLayout.arrowWidth
        let arrowH = LMKUserTipLayout.arrowHeight
        let r = LMKUserTipLayout.arrowTipRadius

        // Arrow X in bubbleView's coordinate space, centered on source
        let arrowCenterX = sourceInBubble.midX
        let bubbleMinX = bubbleBounds.minX + LMKCornerRadius.medium + arrowW / 2
        let bubbleMaxX = bubbleBounds.maxX - LMKCornerRadius.medium - arrowW / 2
        let clampedCenterX = min(max(arrowCenterX, bubbleMinX), bubbleMaxX)

        let path = UIBezierPath()

        switch direction {
        case .up:
            // Arrow sits above bubble's top edge (extends beyond bounds)
            let baseY = bubbleBounds.minY
            let tipY = baseY - arrowH
            path.move(to: CGPoint(x: clampedCenterX - arrowW / 2, y: baseY))
            path.addLine(to: CGPoint(x: clampedCenterX - r, y: tipY + r))
            path.addQuadCurve(
                to: CGPoint(x: clampedCenterX + r, y: tipY + r),
                controlPoint: CGPoint(x: clampedCenterX, y: tipY)
            )
            path.addLine(to: CGPoint(x: clampedCenterX + arrowW / 2, y: baseY))
            path.close()

        case .down:
            // Arrow sits below bubble's bottom edge (extends beyond bounds)
            let baseY = bubbleBounds.maxY
            let tipY = baseY + arrowH
            path.move(to: CGPoint(x: clampedCenterX - arrowW / 2, y: baseY))
            path.addLine(to: CGPoint(x: clampedCenterX - r, y: tipY - r))
            path.addQuadCurve(
                to: CGPoint(x: clampedCenterX + r, y: tipY - r),
                controlPoint: CGPoint(x: clampedCenterX, y: tipY)
            )
            path.addLine(to: CGPoint(x: clampedCenterX + arrowW / 2, y: baseY))
            path.close()

        case .automatic:
            break
        }

        arrowLayer.path = path.cgPath
        arrowLayer.fillColor = LMKColor.backgroundSecondary.cgColor
        arrowLayer.shadowColor = LMKShadow.card().color.cgColor
        arrowLayer.shadowOffset = LMKShadow.card().offset
        arrowLayer.shadowRadius = LMKShadow.card().radius
        arrowLayer.shadowOpacity = LMKShadow.card().opacity
        arrowLayer.isHidden = false
    }

    // MARK: - Animation

    private func animateIn(style: LMKUserTipStyle) {
        let shouldAnimate = LMKAnimationHelper.shouldAnimate
        let duration = shouldAnimate ? LMKAnimationHelper.Duration.modalPresentation : 0

        dimmingView.alpha = 0
        bubbleView.alpha = 0

        if shouldAnimate {
            switch style {
            case .center:
                bubbleView.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
            case .pointed:
                bubbleView.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
            }
        }

        // Arrow is a sublayer of bubbleView, so it inherits bubbleView's alpha
        UIView.animate(
            withDuration: duration,
            delay: 0,
            usingSpringWithDamping: LMKAnimationHelper.Spring.damping,
            initialSpringVelocity: 0,
            options: [.curveEaseOut],
            animations: {
                self.dimmingView.alpha = 1
                self.bubbleView.alpha = 1
                self.bubbleView.transform = .identity
            }
        )
    }

    // MARK: - Actions

    @objc private func dimmingTapped() {
        dismiss()
    }

    @objc private func dismissTapped() {
        dismiss()
    }
}

// MARK: - Static Convenience

/// Static convenience methods for showing user tips.
public enum LMKUserTip {
    /// Show a user tip on a view controller.
    public static func show(
        title: String? = nil,
        message: String,
        icon: UIImage? = nil,
        style: LMKUserTipStyle = .center,
        on viewController: UIViewController,
        onDismiss: (() -> Void)? = nil
    ) {
        let tip = LMKUserTipView(title: title, message: message, icon: icon)
        tip.onDismiss = onDismiss
        tip.show(style: style, on: viewController)
    }
}
