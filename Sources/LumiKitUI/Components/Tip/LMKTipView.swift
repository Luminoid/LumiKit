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
/// Tap anywhere outside the bubble to dismiss. The tip is a VoiceOver modal: the bubble's
/// text and button come first, then the dismiss area, and the escape gesture dismisses.
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
        ///
        /// The tip reads the source's frame each time it lays out (a rotation, a resize, a Dynamic
        /// Type change) and never constrains the source, so the source keeps its size and position.
        /// After moving the source in code, call `setNeedsLayout()` on the tip.
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
        /// A pointed tip never dims.
        public var dimmingColor: UIColor?
        /// `nil` = 300.
        public var maxWidth: CGFloat?
        /// Distance from the host's safe area; `nil` = `large`.
        public var minMargin: CGFloat?
        /// Gap between arrow tip and source; `nil` = `xs`.
        public var sourceSpacing: CGFloat?
        /// Style of the dismiss button; `nil` = ghost primary, small.
        public var button: LMKButton.Style?
        /// A light haptic when the tip shows; `nil` = yes.
        public var haptics: Bool?

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
            button: LMKButton.Style? = nil,
            haptics: Bool? = nil
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
            self.haptics = haptics
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
                button: other.button.map { button?.merging($0) ?? $0 } ?? button,
                haptics: other.haptics ?? haptics
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

    /// Called once after the tip is dismissed.
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

    /// The direction a pointed tip resolved to; `nil` for a centered tip.
    private(set) var pointedDirection: ArrowDirection?

    private let outerStack = UIStackView()
    private let iconRow = UIStackView()
    private let textStack = UIStackView()
    private var iconSizeConstraint: Constraint?
    private var iconBackgroundConstraint: Constraint?
    private var contentInsetsConstraint: Constraint?
    private var placement: Placement = .center
    /// The pointed tip's source, read live at every layout so the bubble and the arrow follow a resize.
    private weak var sourceView: UIView?
    private var sourceOffset: CGPoint = .zero
    /// The source's frame (plus `sourceOffset`) in this view's coordinates; the bubble anchors to
    /// it. A constraint to the source itself would let Auto Layout stretch or move the source to
    /// center the bubble wherever the source's own size is held below `.high`.
    private let sourceGuide = UILayoutGuide()
    private var sourceGuideFrame: CGRect?
    private var sourceGuideLeftConstraint: Constraint?
    private var sourceGuideTopConstraint: Constraint?
    private var sourceGuideWidthConstraint: Constraint?
    private var sourceGuideHeightConstraint: Constraint?
    private var animator: UIViewPropertyAnimator?
    private var isDismissing = false

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
        // Frames are not mirrored in a right-to-left layout, so the guide is placed by left and top.
        addLayoutGuide(sourceGuide)
        sourceGuide.snp.makeConstraints { make in
            sourceGuideLeftConstraint = make.left.equalTo(snp.left).constraint
            sourceGuideTopConstraint = make.top.equalTo(snp.top).constraint
            sourceGuideWidthConstraint = make.width.equalTo(0).constraint
            sourceGuideHeightConstraint = make.height.equalTo(0).constraint
        }

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
            contentInsetsConstraint = make.directionalEdges.equalToSuperview().constraint
        }

        // Sublayers of the bubble, so they inherit the bubble's alpha animation.
        outlineLayer.isHidden = true
        bubbleView.layer.insertSublayer(outlineLayer, at: 0)
        arrowLayer.isHidden = true
        bubbleView.layer.addSublayer(arrowLayer)
        // Layer colors are resolved values: re-resolve them when the appearance changes.
        registerForTraitChanges([UITraitUserInterfaceStyle.self, UITraitAccessibilityContrast.self, UITraitUserInterfaceLevel.self]) { (self: Self, _: UITraitCollection) in
            self.applyTheme(self.traitCollection.lmkTheme)
        }

        // A VoiceOver modal: the bubble's content, then the dismiss area; escape dismisses.
        isAccessibilityElement = false
        accessibilityViewIsModal = true
        accessibilityElements = [bubbleView, dimmingView]
        bubbleView.isAccessibilityElement = false
        titleLabel.accessibilityTraits.insert(.header)
        updateBubbleAccessibilityElements()
        applyStrings()
    }

    private func applyStrings() {
        dimmingView.accessibilityLabel = strings.dismissButtonTitle
        dimmingView.accessibilityHint = strings.dismissAccessibilityHint
        dismissButton.title = strings.dismissButtonTitle
    }

    /// The bubble reads as its visible text and button, in order.
    private func updateBubbleAccessibilityElements() {
        var elements: [UIView] = []
        if title != nil { elements.append(titleLabel) }
        elements.append(messageLabel)
        if !dismissButton.isHidden { elements.append(dismissButton) }
        bubbleView.accessibilityElements = elements
    }

    override public func layoutSubviews() {
        // Before super: the bubble is placed from the source's frame of this pass.
        updateSourceGuide()
        super.layoutSubviews()
        bubbleView.lmk_layoutSurfaceIfNeeded()
        drawArrowIfPointed()
    }

    override public func accessibilityPerformEscape() -> Bool {
        dismiss()
        return true
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
            bubbleSurface.border = LMKBorderStyle.hidden
            bubbleSurface.shadow = LMKShadowSource.hidden
        }
        let applied = bubbleView.lmk_apply(surface: bubbleSurface, clipsContent: false)
        let insets = applied.contentInsets ?? .lmk_symmetric(vertical: theme.spacing.medium, horizontal: theme.spacing.large)
        contentInsetsConstraint?.update(inset: insets)

        // The placement decides the dimming: a pointed tip leaves the screen readable.
        dimmingView.backgroundColor = isPointed ? .clear : (resolved.dimmingColor ?? LMKColor.scrim.withAlphaComponent(theme.alpha.dimming))
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
        let shadow: LMKShadowStyle? = switch resolvedSurface.shadow ?? .hidden {
        case .hidden: nil
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

    /// Shows the tip over `hostView`, replacing any tip there. A dismissed tip can be shown again.
    public func show(placement: Placement, in hostView: UIView) {
        for subview in hostView.subviews where subview is Self && subview !== self {
            (subview as? Self)?.dismiss()
        }
        settleAnimator()
        isDismissing = false
        alpha = 1
        self.placement = placement
        let theme = traitCollection.lmkTheme

        switch placement {
        case .center:
            dismissButton.isHidden = false
            dismissButton.contentHorizontalAlignment = .center
            if icon == nil {
                titleLabel.textAlignment = .center
                messageLabel.textAlignment = .center
            }
            sourceView = nil
            sourceOffset = .zero
            pointedDirection = nil
        case let .pointed(source, _, offset):
            dismissButton.isHidden = true
            sourceView = source
            sourceOffset = offset
        }
        updateBubbleAccessibilityElements()
        // The placement decides who draws the bubble and whether the host dims.
        applyTheme(theme)

        hostView.addSubview(self)
        snp.remakeConstraints { $0.edges.equalToSuperview() }
        let maxWidth = resolved.maxWidth ?? Self.defaultMaxWidth
        let margin = resolved.minMargin ?? theme.spacing.large

        switch placement {
        case .center:
            bubbleView.snp.remakeConstraints { make in
                make.center.equalToSuperview().priority(.high)
                make.width.lessThanOrEqualTo(maxWidth)
                clamp(make, inside: safeAreaLayoutGuide, margin: margin)
            }
        case let .pointed(source, arrowDirection, offset):
            let direction = resolveDirection(arrowDirection, sourceView: source, sourceOffset: offset, hostView: hostView, maxWidth: maxWidth, margin: margin)
            pointedDirection = direction
            let gap = (resolved.arrowHeight ?? Self.defaultArrowHeight) + (resolved.sourceSpacing ?? theme.spacing.xs)
            // Anchored to the source's frame, read at every layout, so a rotation or a resize moves
            // the bubble with it while the source's own layout stays untouched.
            updateSourceGuide()
            bubbleView.snp.remakeConstraints { make in
                make.width.lessThanOrEqualTo(maxWidth)
                make.centerX.equalTo(sourceGuide.snp.centerX).priority(.high)
                switch direction {
                case .up: make.top.equalTo(sourceGuide.snp.bottom).offset(gap).priority(.high)
                case .down: make.bottom.equalTo(sourceGuide.snp.top).offset(-gap).priority(.high)
                case .automatic: break
                }
                clamp(make, inside: safeAreaLayoutGuide, margin: margin)
            }
        }

        // Resolve the bubble's frame before drawing the arrow and animating in.
        hostView.layoutIfNeeded()
        drawArrowIfPointed()
        animateIn()
        if resolved.haptics ?? true {
            LMKHaptics.light()
        }
        UIAccessibility.post(notification: .screenChanged, argument: title == nil ? messageLabel : titleLabel)
    }

    /// Keeps the bubble inside `guide` by `margin` on every edge.
    private func clamp(_ make: ConstraintMaker, inside guide: UILayoutGuide, margin: CGFloat) {
        make.leading.greaterThanOrEqualTo(guide).offset(margin)
        make.trailing.lessThanOrEqualTo(guide).offset(-margin)
        make.top.greaterThanOrEqualTo(guide).offset(margin)
        make.bottom.lessThanOrEqualTo(guide).offset(-margin)
    }

    /// Dismisses the tip. A second call, or a call after the tip is gone, does nothing;
    /// `onDismiss` fires once.
    public func dismiss() {
        guard !isDismissing else { return }
        isDismissing = true
        settleAnimator()
        run(duration: LMKAnimation.Duration.normal, spring: false) { [weak self] in
            self?.alpha = 0
        } completion: { [weak self] in
            guard let self else { return }
            removeFromSuperview()
            onDismiss?()
        }
    }

    /// Moves `sourceGuide` onto the source's live frame (plus `sourceOffset`); a no-op for a
    /// centered tip or a source this view cannot measure (not in a window, not under the host).
    private func updateSourceGuide() {
        guard isPointed, let sourceView, let superview,
              (sourceView.window != nil && window != nil) || sourceView.isDescendant(of: superview) else { return }
        let frame = convert(sourceView.bounds, from: sourceView).offsetBy(dx: sourceOffset.x, dy: sourceOffset.y)
        guard frame != sourceGuideFrame else { return }
        sourceGuideFrame = frame
        sourceGuideLeftConstraint?.update(offset: frame.minX)
        sourceGuideTopConstraint?.update(offset: frame.minY)
        sourceGuideWidthConstraint?.update(offset: frame.width)
        sourceGuideHeightConstraint?.update(offset: frame.height)
    }

    /// Redraws the arrow toward the source; a no-op for a centered tip.
    private func drawArrowIfPointed() {
        guard let pointedDirection, let sourceGuideFrame else { return }
        drawArrow(direction: pointedDirection, sourceFrame: sourceGuideFrame)
    }

    /// Picks `.down` (bubble above the source) when the bubble fits above, `.up` when it fits
    /// below, else the side with more room, measuring the bubble at `maxWidth`.
    private func resolveDirection(_ direction: ArrowDirection, sourceView: UIView, sourceOffset: CGPoint, hostView: UIView, maxWidth: CGFloat, margin: CGFloat) -> ArrowDirection {
        guard direction == .automatic else { return direction }
        let sourceFrame = sourceView.convert(sourceView.bounds, to: hostView).offsetBy(dx: sourceOffset.x, dy: sourceOffset.y)
        let bubbleHeight = bubbleView.systemLayoutSizeFitting(
            CGSize(width: maxWidth, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        ).height
        let needed = bubbleHeight + (resolved.arrowHeight ?? Self.defaultArrowHeight) + (resolved.sourceSpacing ?? traitCollection.lmkTheme.spacing.xs)
        let spaceAbove = sourceFrame.minY - hostView.safeAreaInsets.top - margin
        let spaceBelow = hostView.bounds.height - hostView.safeAreaInsets.bottom - margin - sourceFrame.maxY
        if spaceAbove >= needed { return .down }
        if spaceBelow >= needed { return .up }
        return spaceAbove >= spaceBelow ? .down : .up
    }

    private func animateIn() {
        let shouldAnimate = LMKAnimation.shouldAnimate
        dimmingView.alpha = 0
        bubbleView.alpha = 0
        if shouldAnimate {
            let scale: CGFloat = if case .center = placement { Self.centerEntranceScale } else { Self.pointedEntranceScale }
            bubbleView.transform = CGAffineTransform(scaleX: scale, y: scale)
        }
        run(duration: LMKAnimation.Duration.moderate, spring: true) { [weak self] in
            self?.dimmingView.alpha = 1
            self?.bubbleView.alpha = 1
            self?.bubbleView.transform = .identity
        }
    }

    /// Runs `animations` in a property animator. Immediate without a window or under Reduce Motion.
    private func run(duration: TimeInterval, spring: Bool, animations: @escaping () -> Void, completion: (() -> Void)? = nil) {
        let effectiveDuration = LMKAnimation.shouldAnimate ? duration : 0
        guard effectiveDuration > 0, window != nil else {
            animations()
            completion?()
            return
        }
        let animator = spring
            ? UIViewPropertyAnimator(duration: effectiveDuration, dampingRatio: LMKAnimation.spring.damping, animations: animations)
            : UIViewPropertyAnimator(duration: effectiveDuration, curve: LMKAnimation.Curve.easeIn.animationCurve, animations: animations)
        let once = LMKOnceCompletion(after: effectiveDuration) { [weak self] in
            if self?.animator === animator {
                self?.animator = nil
            }
            completion?()
        }
        animator.addCompletion { _ in once.fire() }
        self.animator = animator
        animator.startAnimation()
    }

    /// Settles an entrance or exit still in flight so the next animation starts from a
    /// resolved state (a dismissal during the entrance completes).
    private func settleAnimator() {
        guard let animator else { return }
        self.animator = nil
        if animator.state == .active {
            animator.stopAnimation(false)
        }
        if animator.state == .stopped {
            animator.finishAnimation(at: .current)
        }
    }

    // MARK: - Actions

    @objc private func dimmingTapped() {
        dismiss()
    }
}

public nonisolated extension LMKTheme {
    /// App-wide default style for `LMKTipView`.
    var tip: LMKTipView.Style {
        get { self[LMKTipView.Style.self] }
        set { self[LMKTipView.Style.self] = newValue }
    }
}
