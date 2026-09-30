//
//  LMKTipView.swift
//  LumiKit
//
//  Onboarding tip: a centered card over a dimmed host, or a bubble with an
//  arrow pointing at a source view.
//

import SnapKit
import UIKit

/// Tip view for onboarding hints and feature discovery.
///
/// ```swift
/// LMKTip.show(title: "Welcome", message: "Tap + to add an item", in: self)
/// LMKTip.show(message: "Tap here to add a photo", placement: .pointed(sourceView: addButton), in: self)
/// ```
///
/// Tap anywhere outside the bubble to dismiss.
public final class LMKTipView: UIView, LMKThemeApplying {
    // MARK: - Placement

    /// Arrow direction for pointed tips.
    public nonisolated enum ArrowDirection: Sendable, Hashable, CaseIterable {
        /// Bubble below the source view; arrow points up toward it.
        case up
        /// Bubble above the source view; arrow points down toward it.
        case down
        /// Picks the direction with room.
        case automatic
    }

    /// Where the tip appears.
    public enum Placement {
        /// Centered card with a dimming overlay and a dismiss button.
        case center
        /// A bubble with an arrow pointing at `sourceView`; `sourceOffset` shifts the anchor.
        case pointed(sourceView: UIView, arrowDirection: ArrowDirection = .automatic, sourceOffset: CGPoint = .zero)
    }

    // MARK: - Style

    public nonisolated struct Style: Sendable, Equatable, LMKThemeExtension {
        /// Bubble background (`backgroundSecondary`), corners (`medium`), border (none), shadow
        /// (`level3`), insets (`medium` / `large`). On a pointed tip a solid background, the border,
        /// and the shadow follow one outline around the bubble and its arrow.
        public var surface: LMKSurfaceStyle
        /// `nil` = `bodyMedium`.
        public var titleTextStyle: LMKTextStyle?
        /// `nil` = `body`.
        public var messageTextStyle: LMKTextStyle?
        /// `nil` = `textPrimary`.
        public var titleColor: UIColor?
        /// `nil` = `textSecondary`.
        public var messageColor: UIColor?
        /// `nil` = `primary`.
        public var iconTint: UIColor?
        /// `nil` = 36.
        public var iconBackgroundSize: CGFloat?
        /// `nil` = 16.
        public var arrowWidth: CGFloat?
        /// `nil` = 8.
        public var arrowHeight: CGFloat?
        /// `nil` = 2.
        public var arrowTipRadius: CGFloat?
        /// Fill of the arrow under a gradient, blur, or glass bubble, which the arrow cannot
        /// continue; `nil` = `backgroundSecondary`. A solid bubble colors its own arrow.
        public var arrowColor: UIColor?
        /// Dimming behind a centered tip; `nil` = `scrim` at `dimming`. `.clear` disables it.
        public var dimmingColor: UIColor?
        /// `nil` = 300.
        public var maxWidth: CGFloat?
        /// Distance from the host's edges; `nil` = `large`.
        public var minMargin: CGFloat?
        /// Gap between arrow tip and source; `nil` = `xs`.
        public var sourceSpacing: CGFloat?
        /// Style of the dismiss button; `nil` = ghost primary, small.
        public var button: LMKButton.Style?

        public init(
            surface: LMKSurfaceStyle = LMKSurfaceStyle(),
            titleTextStyle: LMKTextStyle? = nil,
            messageTextStyle: LMKTextStyle? = nil,
            titleColor: UIColor? = nil,
            messageColor: UIColor? = nil,
            iconTint: UIColor? = nil,
            iconBackgroundSize: CGFloat? = nil,
            arrowWidth: CGFloat? = nil,
            arrowHeight: CGFloat? = nil,
            arrowTipRadius: CGFloat? = nil,
            arrowColor: UIColor? = nil,
            dimmingColor: UIColor? = nil,
            maxWidth: CGFloat? = nil,
            minMargin: CGFloat? = nil,
            sourceSpacing: CGFloat? = nil,
            button: LMKButton.Style? = nil
        ) {
            self.surface = surface
            self.titleTextStyle = titleTextStyle
            self.messageTextStyle = messageTextStyle
            self.titleColor = titleColor
            self.messageColor = messageColor
            self.iconTint = iconTint
            self.iconBackgroundSize = iconBackgroundSize
            self.arrowWidth = arrowWidth
            self.arrowHeight = arrowHeight
            self.arrowTipRadius = arrowTipRadius
            self.arrowColor = arrowColor
            self.dimmingColor = dimmingColor
            self.maxWidth = maxWidth
            self.minMargin = minMargin
            self.sourceSpacing = sourceSpacing
            self.button = button
        }

        public static let defaultValue = Self()

        /// `other`'s non-nil fields over this style's.
        public func merging(_ other: Self) -> Self {
            Self(
                surface: surface.merging(other.surface),
                titleTextStyle: other.titleTextStyle ?? titleTextStyle,
                messageTextStyle: other.messageTextStyle ?? messageTextStyle,
                titleColor: other.titleColor ?? titleColor,
                messageColor: other.messageColor ?? messageColor,
                iconTint: other.iconTint ?? iconTint,
                iconBackgroundSize: other.iconBackgroundSize ?? iconBackgroundSize,
                arrowWidth: other.arrowWidth ?? arrowWidth,
                arrowHeight: other.arrowHeight ?? arrowHeight,
                arrowTipRadius: other.arrowTipRadius ?? arrowTipRadius,
                arrowColor: other.arrowColor ?? arrowColor,
                dimmingColor: other.dimmingColor ?? dimmingColor,
                maxWidth: other.maxWidth ?? maxWidth,
                minMargin: other.minMargin ?? minMargin,
                sourceSpacing: other.sourceSpacing ?? sourceSpacing,
                button: other.button.map { button?.merging($0) ?? $0 } ?? button
            )
        }
    }

    // MARK: - Strings

    public nonisolated struct Strings: Sendable, Equatable {
        public var dismissAccessibilityHint: String
        public var dismissButtonTitle: String

        public init(
            dismissAccessibilityHint: String = LMKLocalized("tip.dismiss.accessibilityHint"),
            dismissButtonTitle: String = LMKLocalized("tip.dismissButton")
        ) {
            self.dismissAccessibilityHint = dismissAccessibilityHint
            self.dismissButtonTitle = dismissButtonTitle
        }
    }

    /// Process-wide defaults; set at app launch to override.
    public nonisolated(unsafe) static var strings = Strings()

    /// Per-instance strings (default `Self.strings`).
    public var strings: Strings = LMKTipView.strings {
        didSet { applyStrings() }
    }

    // MARK: - Properties

    /// Called after the tip is dismissed.
    public var onDismiss: (() -> Void)?

    /// Per-instance style; `nil` fields resolve from `theme.tip`, then the built-in look.
    public var style: Style {
        didSet {
            guard style != oldValue else { return }
            applyTheme(traitCollection.lmkTheme)
        }
    }

    /// Called at the end of every `applyTheme`, for tweaks the style does not cover.
    public var didApplyStyle: ((LMKTipView) -> Void)?

    public let dimmingView = UIView()
    public let bubbleView = UIView()
    public let iconBackgroundView = UIView()
    public let iconView = UIImageView()
    public let titleLabel = UILabel()
    public let messageLabel = UILabel()
    public let dismissButton = LMKButton(style: .ghost().size(.small))

    public let title: String?
    public let message: String
    public let icon: UIImage?

    /// The arrow of a pointed tip whose bubble is a gradient, blur, or glass.
    let arrowLayer = CAShapeLayer()
    /// The outline of a pointed tip with a solid bubble: bubble and arrow as one shape, so the
    /// fill, the border, and the shadow run around both without a seam.
    let outlineLayer = CAShapeLayer()
    var resolved = Style()
    /// The bubble surface as resolved against the theme, before a pointed tip hands the
    /// fill, border, and shadow to `outlineLayer`.
    var resolvedSurface = LMKSurfaceStyle()
    var isPointed: Bool {
        if case .pointed = placement { return true }
        return false
    }

    /// Whether `outlineLayer` draws the bubble (a pointed tip with a solid or clear background).
    var drawsOutline: Bool {
        guard isPointed else { return false }
        switch resolvedSurface.background ?? .clear {
        case .clear, .solid: return true
        case .gradient, .blur, .glass: return false
        }
    }

    private let outerStack = UIStackView()
    private let iconRow = UIStackView()
    private let textStack = UIStackView()
    private var iconSizeConstraint: Constraint?
    private var iconBackgroundConstraint: Constraint?
    private var contentInsetsConstraint: Constraint?
    private var placement: Placement = .center
    private var pendingArrow: (direction: ArrowDirection, sourceFrame: CGRect)?

    // MARK: - Initialization

    public init(title: String? = nil, message: String, icon: UIImage? = nil, style: Style = Style()) {
        self.title = title
        self.message = message
        self.icon = icon
        self.style = style
        super.init(frame: .zero)
        setupUI()
        lmk_startApplyingTheme()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(dimmingTapped))
        dimmingView.addGestureRecognizer(tap)
        dimmingView.isAccessibilityElement = true
        dimmingView.accessibilityTraits = .button
        addSubview(dimmingView)
        dimmingView.snp.makeConstraints { $0.edges.equalToSuperview() }

        addSubview(bubbleView)

        iconView.contentMode = .scaleAspectFit
        iconView.image = icon
        iconBackgroundView.addSubview(iconView)
        iconView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            iconSizeConstraint = make.width.height.equalTo(0).constraint
        }
        iconBackgroundView.snp.makeConstraints { make in
            iconBackgroundConstraint = make.width.height.equalTo(0).constraint
        }
        iconBackgroundView.isHidden = icon == nil

        titleLabel.text = title
        titleLabel.isHidden = title == nil
        titleLabel.numberOfLines = 0
        messageLabel.text = message
        messageLabel.numberOfLines = 0
        textStack.axis = .vertical
        textStack.addArrangedSubview(titleLabel)
        textStack.addArrangedSubview(messageLabel)

        iconRow.axis = .horizontal
        iconRow.alignment = .top
        iconRow.addArrangedSubview(iconBackgroundView)
        iconRow.addArrangedSubview(textStack)

        dismissButton.isHidden = true
        dismissButton.onTap = { [weak self] in self?.dismiss() }

        outerStack.axis = .vertical
        outerStack.addArrangedSubview(iconRow)
        outerStack.addArrangedSubview(dismissButton)
        bubbleView.addSubview(outerStack)
        outerStack.snp.makeConstraints { make in
            contentInsetsConstraint = make.edges.equalToSuperview().constraint
        }

        // Sublayers of the bubble, so they inherit the bubble's alpha animation.
        outlineLayer.isHidden = true
        bubbleView.layer.insertSublayer(outlineLayer, at: 0)
        arrowLayer.isHidden = true
        bubbleView.layer.addSublayer(arrowLayer)
        // Layer colors are resolved values: re-resolve them when the appearance changes.
        registerForTraitChanges([UITraitUserInterfaceStyle.self, UITraitAccessibilityContrast.self]) { (self: Self, _: UITraitCollection) in
            self.applyTheme(self.traitCollection.lmkTheme)
        }

        isAccessibilityElement = false
        bubbleView.isAccessibilityElement = true
        bubbleView.accessibilityLabel = [title, message].compactMap(\.self).joined(separator: ". ")
        applyStrings()
    }

    private func applyStrings() {
        dimmingView.accessibilityLabel = strings.dismissAccessibilityHint
        bubbleView.accessibilityHint = strings.dismissAccessibilityHint
        dismissButton.title = strings.dismissButtonTitle
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        bubbleView.lmk_layoutSurfaceIfNeeded()
        if let pendingArrow {
            drawArrow(direction: pendingArrow.direction, sourceFrame: pendingArrow.sourceFrame)
        }
    }

    // MARK: - Theme

    public func applyTheme(_ theme: LMKTheme) {
        resolved = theme.tip.merging(style)
        let defaults = LMKSurfaceStyle(
            background: .solid(LMKColor.backgroundSecondary),
            corners: .fixed(theme.cornerRadius.medium),
            shadow: .level(.level3),
            contentInsets: .lmk_symmetric(vertical: theme.spacing.medium, horizontal: theme.spacing.large)
        )
        resolvedSurface = defaults.merging(resolved.surface)
        var bubbleSurface = resolvedSurface
        if drawsOutline {
            // The outline layer paints these around the bubble and the arrow together.
            bubbleSurface.background = .clear
            bubbleSurface.border = LMKBorderStyle.none
            bubbleSurface.shadow = LMKShadowSource.none
        }
        let applied = bubbleView.lmk_apply(surface: bubbleSurface, clipsContent: false)
        let insets = applied.contentInsets ?? .lmk_symmetric(vertical: theme.spacing.medium, horizontal: theme.spacing.large)
        contentInsetsConstraint?.update(inset: UIEdgeInsets(top: insets.top, left: insets.leading, bottom: insets.bottom, right: insets.trailing))

        dimmingView.backgroundColor = resolved.dimmingColor ?? LMKColor.scrim.withAlphaComponent(theme.alpha.dimming)
        let tint = resolved.iconTint ?? LMKColor.primary
        iconView.tintColor = tint
        iconBackgroundView.backgroundColor = tint.withAlphaComponent(theme.alpha.xxs)
        iconBackgroundView.lmk_applyCornerStyle(.circle)
        iconBackgroundConstraint?.update(offset: resolved.iconBackgroundSize ?? Self.defaultIconBackgroundSize)
        iconSizeConstraint?.update(offset: theme.layout.iconSmall)
        titleLabel.lmk_apply(resolved.titleTextStyle ?? .bodyMedium, color: resolved.titleColor ?? LMKColor.textPrimary)
        messageLabel.lmk_apply(resolved.messageTextStyle ?? .body, color: resolved.messageColor ?? LMKColor.textSecondary)
        dismissButton.style = resolved.button ?? LMKButton.Style.ghost().size(.small)
        outerStack.spacing = theme.spacing.medium
        iconRow.spacing = theme.spacing.medium
        textStack.spacing = theme.spacing.xs
        arrowLayer.fillColor = (resolved.arrowColor ?? LMKColor.backgroundSecondary).resolvedColor(with: traitCollection).cgColor
        applyOutlineColors(theme: theme)
        setNeedsLayout()
        didApplyStyle?(self)
    }

    static let defaultIconBackgroundSize: CGFloat = 36
    static let defaultMaxWidth: CGFloat = 300
    static let defaultArrowWidth: CGFloat = 16
    static let defaultArrowHeight: CGFloat = 8
    static let defaultArrowTipRadius: CGFloat = 2
    private static let estimatedBubbleHeight: CGFloat = 120
    private static let centerEntranceScale: CGFloat = 0.85
    private static let pointedEntranceScale: CGFloat = 0.95

    /// Fill, stroke, and shadow of the outline layer, from the resolved bubble surface.
    private func applyOutlineColors(theme: LMKTheme) {
        guard drawsOutline else {
            outlineLayer.isHidden = true
            return
        }
        let fill: UIColor = if case let .solid(color) = resolvedSurface.background { color ?? LMKColor.backgroundSecondary } else { .clear }
        outlineLayer.fillColor = fill.resolvedColor(with: traitCollection).cgColor
        if let border = resolvedSurface.border, (border.width ?? 1) > 0 {
            outlineLayer.strokeColor = (border.color ?? LMKColor.outline).resolvedColor(with: traitCollection).cgColor
            outlineLayer.lineWidth = LMKLayout.pixelAligned(border.width ?? LMKLayout.hairline(for: self), for: self)
            outlineLayer.lineDashPattern = border.dash?.map { NSNumber(value: Double($0)) }
        } else {
            outlineLayer.strokeColor = nil
            outlineLayer.lineWidth = 0
            outlineLayer.lineDashPattern = nil
        }
        outlineLayer.lineJoin = .round
        let shadow: LMKShadowStyle? = switch resolvedSurface.shadow ?? .none {
        case .none: nil
        case let .level(level): theme.shadow.shadow(for: level).style
        case let .custom(style): style
        }
        if let shadow {
            outlineLayer.shadowColor = shadow.color.resolvedColor(with: traitCollection).cgColor
            outlineLayer.shadowOffset = shadow.offset
            outlineLayer.shadowRadius = shadow.radius
            outlineLayer.shadowOpacity = shadow.opacity
        } else {
            outlineLayer.shadowOpacity = 0
        }
    }

    // MARK: - Show

    /// Shows the tip over `viewController`'s view.
    public func show(placement: Placement, in viewController: UIViewController) {
        guard let hostView = viewController.view else { return }
        show(placement: placement, in: hostView)
    }

    /// Shows the tip over `hostView`, replacing any tip there.
    public func show(placement: Placement, in hostView: UIView) {
        for subview in hostView.subviews where subview is Self {
            (subview as? Self)?.dismiss()
        }
        self.placement = placement
        let theme = traitCollection.lmkTheme
        // The placement decides who draws the bubble.
        applyTheme(theme)

        switch placement {
        case .center:
            dismissButton.isHidden = false
            dismissButton.contentHorizontalAlignment = .center
            if icon == nil {
                titleLabel.textAlignment = .center
                messageLabel.textAlignment = .center
            }
        case .pointed:
            dismissButton.isHidden = true
            dimmingView.backgroundColor = .clear
        }

        hostView.addSubview(self)
        snp.makeConstraints { $0.edges.equalToSuperview() }
        let maxWidth = resolved.maxWidth ?? Self.defaultMaxWidth
        let margin = resolved.minMargin ?? theme.spacing.large

        switch placement {
        case .center:
            bubbleView.snp.makeConstraints { make in
                make.center.equalToSuperview()
                make.width.lessThanOrEqualTo(maxWidth)
                make.leading.greaterThanOrEqualToSuperview().offset(margin)
                make.trailing.lessThanOrEqualToSuperview().offset(-margin)
            }
        case let .pointed(sourceView, arrowDirection, sourceOffset):
            let sourceFrame = sourceView.convert(sourceView.bounds, to: hostView).offsetBy(dx: sourceOffset.x, dy: sourceOffset.y)
            let direction = resolveDirection(arrowDirection, sourceFrame: sourceFrame, hostView: hostView)
            let arrowHeight = resolved.arrowHeight ?? Self.defaultArrowHeight
            let sourceSpacing = resolved.sourceSpacing ?? theme.spacing.xs
            bubbleView.snp.makeConstraints { make in
                make.width.lessThanOrEqualTo(maxWidth)
                make.leading.greaterThanOrEqualToSuperview().offset(margin)
                make.trailing.lessThanOrEqualToSuperview().offset(-margin)
                make.centerX.equalTo(sourceFrame.midX).priority(.high)
                switch direction {
                case .up: make.top.equalToSuperview().offset(sourceFrame.maxY + arrowHeight + sourceSpacing)
                case .down: make.bottom.equalToSuperview().offset(-(hostView.bounds.height - sourceFrame.minY + arrowHeight + sourceSpacing))
                case .automatic: break
                }
            }
            pendingArrow = (direction, sourceFrame)
        }

        // Resolve the bubble's frame before drawing the arrow and animating in.
        hostView.layoutIfNeeded()
        if let pendingArrow {
            drawArrow(direction: pendingArrow.direction, sourceFrame: pendingArrow.sourceFrame)
        }
        animateIn()
        LMKHaptics.light()
        UIAccessibility.post(notification: .announcement, argument: message)
    }

    /// Dismisses the tip.
    public func dismiss() {
        let duration = LMKAnimation.shouldAnimate ? LMKAnimation.Duration.normal : 0
        UIView.animate(
            withDuration: duration,
            animations: { self.alpha = 0 },
            completion: { _ in
                self.removeFromSuperview()
                self.onDismiss?()
            }
        )
    }

    private func resolveDirection(_ direction: ArrowDirection, sourceFrame: CGRect, hostView: UIView) -> ArrowDirection {
        guard direction == .automatic else { return direction }
        let spaceAbove = sourceFrame.minY - hostView.safeAreaInsets.top
        let needed = Self.estimatedBubbleHeight + (resolved.arrowHeight ?? Self.defaultArrowHeight) + (resolved.sourceSpacing ?? traitCollection.lmkTheme.spacing.xs)
        return spaceAbove >= needed ? .down : .up
    }

    private func animateIn() {
        let shouldAnimate = LMKAnimation.shouldAnimate
        dimmingView.alpha = 0
        bubbleView.alpha = 0
        if shouldAnimate {
            let scale: CGFloat = if case .center = placement { Self.centerEntranceScale } else { Self.pointedEntranceScale }
            bubbleView.transform = CGAffineTransform(scaleX: scale, y: scale)
        }
        UIView.animate(
            withDuration: shouldAnimate ? LMKAnimation.Duration.moderate : 0,
            delay: 0,
            usingSpringWithDamping: LMKAnimation.spring.damping,
            initialSpringVelocity: 0,
            options: LMKAnimation.Curve.easeOut.options,
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
}

// MARK: - LMKTip

/// Tip presentation.
public enum LMKTip {
    /// Shows a tip over `viewController`'s view.
    @discardableResult
    public static func show(
        title: String? = nil,
        message: String,
        icon: UIImage? = nil,
        placement: LMKTipView.Placement = .center,
        style: LMKTipView.Style = LMKTipView.Style(),
        in viewController: UIViewController,
        onDismiss: (() -> Void)? = nil
    ) -> LMKTipView {
        let tip = LMKTipView(title: title, message: message, icon: icon, style: style)
        tip.onDismiss = onDismiss
        tip.show(placement: placement, in: viewController)
        return tip
    }
}

public nonisolated extension LMKTheme {
    /// App-wide default style for `LMKTipView`.
    var tip: LMKTipView.Style {
        get { self[LMKTipView.Style.self] }
        set { self[LMKTipView.Style.self] = newValue }
    }
}
