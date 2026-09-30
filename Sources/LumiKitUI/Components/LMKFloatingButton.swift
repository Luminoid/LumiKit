//
//  LMKFloatingButton.swift
//  LumiKit
//
//  Draggable floating action button that snaps to the nearest horizontal
//  edge, stays inside the safe area, and can remember its corner.
//

import SnapKit
import UIKit

/// Draggable floating action button for quick actions or debug access.
///
/// ```swift
/// let button = LMKFloatingButton.show(icon: UIImage(systemName: "ladybug"), in: view) { openDebugMenu() }
/// button.badge = .count(3)
/// button.dismiss()
/// ```
///
/// The host retains the button through the view hierarchy; `show(in:)` installs
/// it in a view or a window scene's key window. With a `positionKey` the snapped
/// corner persists across launches.
public final class LMKFloatingButton: UIControl, LMKThemeApplying {
    // MARK: - Style

    public nonisolated struct Style: Sendable, Equatable, LMKThemeExtension {
        /// Side of the button; `nil` = 56.
        public var size: CGFloat?
        /// Background (`primary`; `.glass` for Liquid Glass), corners (circle), shadow (`level2`), border.
        public var surface: LMKSurfaceStyle
        /// `nil` = `onAccent`.
        public var iconTint: UIColor?
        /// `nil` = `iconMedium`.
        public var iconSize: CGFloat?
        /// Distance kept from the edges; `nil` = `large`.
        public var edgeMargin: CGFloat?
        /// Badge style; `nil` = the theme badge.
        public var badge: LMKBadgeView.Style?
        /// Scale while dragging; `nil` = 0.95.
        public var dragScale: CGFloat?
        public var highlighted: LMKControlStateStyle?
        public var disabled: LMKControlStateStyle?

        public init(
            size: CGFloat? = nil,
            surface: LMKSurfaceStyle = LMKSurfaceStyle(),
            iconTint: UIColor? = nil,
            iconSize: CGFloat? = nil,
            edgeMargin: CGFloat? = nil,
            badge: LMKBadgeView.Style? = nil,
            dragScale: CGFloat? = nil,
            highlighted: LMKControlStateStyle? = nil,
            disabled: LMKControlStateStyle? = nil
        ) {
            self.size = size
            self.surface = surface
            self.iconTint = iconTint
            self.iconSize = iconSize
            self.edgeMargin = edgeMargin
            self.badge = badge
            self.dragScale = dragScale
            self.highlighted = highlighted
            self.disabled = disabled
        }

        public static let defaultValue = Self()

        /// `other`'s non-nil fields over this style's.
        public func merging(_ other: Self) -> Self {
            Self(
                size: other.size ?? size,
                surface: surface.merging(other.surface),
                iconTint: other.iconTint ?? iconTint,
                iconSize: other.iconSize ?? iconSize,
                edgeMargin: other.edgeMargin ?? edgeMargin,
                badge: other.badge.map { badge?.merging($0) ?? $0 } ?? badge,
                dragScale: other.dragScale ?? dragScale,
                highlighted: LMKControlStateStyle.merge(highlighted, other.highlighted),
                disabled: LMKControlStateStyle.merge(disabled, other.disabled)
            )
        }
    }

    // MARK: - Strings

    public nonisolated struct Strings: Sendable, Equatable {
        public var accessibilityLabel: String
        public var moveToTopLeading: String
        public var moveToTopTrailing: String
        public var moveToBottomLeading: String
        public var moveToBottomTrailing: String

        public init(
            accessibilityLabel: String = LMKLocalized("floatingButton.accessibilityLabel"),
            moveToTopLeading: String = LMKLocalized("floatingButton.move.topLeading"),
            moveToTopTrailing: String = LMKLocalized("floatingButton.move.topTrailing"),
            moveToBottomLeading: String = LMKLocalized("floatingButton.move.bottomLeading"),
            moveToBottomTrailing: String = LMKLocalized("floatingButton.move.bottomTrailing")
        ) {
            self.accessibilityLabel = accessibilityLabel
            self.moveToTopLeading = moveToTopLeading
            self.moveToTopTrailing = moveToTopTrailing
            self.moveToBottomLeading = moveToBottomLeading
            self.moveToBottomTrailing = moveToBottomTrailing
        }
    }

    /// Process-wide defaults; set at app launch to override.
    public nonisolated(unsafe) static var strings = Strings()

    /// Per-instance strings (default `Self.strings`).
    public var strings: Strings = LMKFloatingButton.strings {
        didSet { updateAccessibility() }
    }

    // MARK: - Corner

    /// Where the button rests.
    public nonisolated enum Corner: String, Sendable, Hashable, CaseIterable {
        case topLeading, topTrailing, bottomLeading, bottomTrailing
    }

    // MARK: - Properties

    /// Called when the button is tapped.
    public var onTap: (() -> Void)?

    /// The button icon.
    public var icon: UIImage? {
        didSet { iconView.image = icon }
    }

    /// Badge content (`nil` hides the badge).
    public var badge: LMKBadgeView.Content? {
        didSet { updateBadge() }
    }

    /// Per-instance style; `nil` fields resolve from `theme.floatingButton`, then the built-in look.
    public var style: Style {
        didSet {
            guard style != oldValue else { return }
            applyTheme(traitCollection.lmkTheme)
        }
    }

    /// `UserDefaults` key under which the resting corner and vertical position persist.
    public var positionKey: String? {
        didSet { restorePositionIfNeeded() }
    }

    /// Called at the end of every `applyTheme`, for tweaks the style does not cover.
    public var didApplyStyle: ((LMKFloatingButton) -> Void)?

    public let iconView = UIImageView()
    public private(set) var badgeView: LMKBadgeView?

    private var resolved = Style()
    private var sizeConstraint: Constraint?
    private var iconSizeConstraint: Constraint?
    private var panStartCenter: CGPoint = .zero
    private var isDragging = false
    private var restingCorner: Corner = .bottomTrailing
    /// Vertical position as a fraction of the available height, so it survives resizes.
    private var restingFraction: CGFloat = 1

    private var buttonSize: CGFloat { resolved.size ?? Self.defaultSize }
    private var edgeMargin: CGFloat { resolved.edgeMargin ?? traitCollection.lmkTheme.spacing.large }
    private static let defaultSize: CGFloat = 56
    private static let defaultDragScale: CGFloat = 0.95
    private static let badgeOffset: CGFloat = -4

    // MARK: - Initialization

    public init(icon: UIImage?, style: Style = Style()) {
        self.icon = icon
        self.style = style
        super.init(frame: .zero)
        setupUI()
        lmk_startApplyingTheme()
    }

    /// A button with an explicit side.
    public convenience init(icon: UIImage?, size: CGFloat) {
        self.init(icon: icon, style: Style(size: size))
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI() {
        snp.makeConstraints { make in
            sizeConstraint = make.width.height.equalTo(Self.defaultSize).constraint
        }
        iconView.image = icon
        iconView.contentMode = .scaleAspectFit
        iconView.isUserInteractionEnabled = false
        addSubview(iconView)
        iconView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            iconSizeConstraint = make.width.height.equalTo(0).constraint
        }

        addTarget(self, action: #selector(handleTap), for: .touchUpInside)
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        addGestureRecognizer(pan)

        isAccessibilityElement = true
        accessibilityTraits = .button
        updateAccessibility()
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        lmk_layoutSurfaceIfNeeded()
    }

    override public func didMoveToSuperview() {
        super.didMoveToSuperview()
        guard superview != nil else { return }
        restorePositionIfNeeded()
        place(animated: false)
    }

    override public func safeAreaInsetsDidChange() {
        super.safeAreaInsetsDidChange()
        place(animated: false)
    }

    override public var isHighlighted: Bool {
        didSet {
            guard isHighlighted != oldValue else { return }
            applyTheme(traitCollection.lmkTheme)
        }
    }

    override public var isEnabled: Bool {
        didSet {
            guard isEnabled != oldValue else { return }
            applyTheme(traitCollection.lmkTheme)
            updateAccessibility()
        }
    }

    override public func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        guard isEnabled, !isHidden else { return false }
        return lmk_hitTestBounds(minimumSide: traitCollection.lmkTheme.layout.minimumTouchTarget).contains(point)
    }

    // MARK: - Theme

    public func applyTheme(_ theme: LMKTheme) {
        resolved = theme.floatingButton.merging(style)
        var defaults = LMKSurfaceStyle(
            background: .solid(LMKColor.primary),
            corners: .circle,
            shadow: .level(.level2)
        )
        var surface = resolved.surface
        var stateAlpha: CGFloat = 1
        var scale: CGFloat = isDragging ? (resolved.dragScale ?? Self.defaultDragScale) : 1
        if isHighlighted, let highlighted = resolved.highlighted {
            if let background = highlighted.background { surface.background = background }
            if let border = highlighted.border { surface.border = border }
            if let shadow = highlighted.shadow { surface.shadow = shadow }
            if let alpha = highlighted.alpha { stateAlpha = min(stateAlpha, alpha) }
            if let value = highlighted.scale { scale = value }
        } else if isHighlighted {
            defaults.background = .solid(LMKColor.primaryVariant)
        }
        if !isEnabled {
            let disabled = resolved.disabled ?? LMKControlStateStyle(alpha: theme.alpha.disabled)
            if let background = disabled.background { surface.background = background }
            stateAlpha = min(stateAlpha, disabled.alpha ?? theme.alpha.disabled)
        }
        lmk_apply(surface: surface, defaults: defaults, clipsContent: false)
        alpha = stateAlpha
        transform = scale == 1 ? .identity : CGAffineTransform(scaleX: scale, y: scale)
        sizeConstraint?.update(offset: buttonSize)
        iconView.tintColor = resolved.iconTint ?? LMKColor.onAccent
        iconSizeConstraint?.update(offset: resolved.iconSize ?? theme.layout.iconMedium)
        badgeView?.style = resolved.badge ?? LMKBadgeView.Style()
        didApplyStyle?(self)
    }

    // MARK: - Show / Dismiss

    /// Installs the button in `hostView` at its resting corner, animating in.
    public func show(in hostView: UIView) {
        for subview in hostView.subviews where subview is Self && subview !== self {
            (subview as? Self)?.dismiss()
        }
        hostView.addSubview(self)
        hostView.layoutIfNeeded()
        place(animated: false)
        guard LMKAnimation.shouldAnimate else { return }
        alpha = 0
        transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        UIView.animate(
            withDuration: LMKAnimation.Duration.moderate,
            delay: 0,
            usingSpringWithDamping: LMKAnimation.spring.damping,
            initialSpringVelocity: 0,
            options: LMKAnimation.Curve.easeOut.options,
            animations: {
                self.alpha = 1
                self.transform = .identity
            }
        )
    }

    /// Installs the button on the scene's key window (`nil` = the active key window), above every screen.
    public func show(in scene: UIWindowScene?) {
        guard let window = scene?.keyWindow ?? LMKScene.keyWindow else { return }
        show(in: window)
    }

    /// Removes the button with an animation.
    public func dismiss() {
        let duration = LMKAnimation.shouldAnimate ? LMKAnimation.Duration.normal : 0
        UIView.animate(
            withDuration: duration,
            animations: {
                self.alpha = 0
                self.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
            },
            completion: { _ in
                self.removeFromSuperview()
                self.alpha = 1
                self.transform = .identity
            }
        )
    }

    /// Shows a floating button in `hostView` (`nil` = the key window) and returns it.
    @discardableResult
    public static func show(icon: UIImage?, in hostView: UIView? = nil, onTap: @escaping () -> Void) -> LMKFloatingButton {
        let button = LMKFloatingButton(icon: icon)
        button.onTap = onTap
        if let hostView {
            button.show(in: hostView)
        } else {
            button.show(in: nil as UIWindowScene?)
        }
        return button
    }

    // MARK: - Badge

    private func updateBadge() {
        guard let badge else {
            badgeView?.removeFromSuperview()
            badgeView = nil
            return
        }
        let view = badgeView ?? {
            let view = LMKBadgeView(style: resolved.badge ?? LMKBadgeView.Style())
            // A touch on the badge belongs to the button; an interactive subview would swallow it.
            view.isUserInteractionEnabled = false
            addSubview(view)
            view.snp.makeConstraints { make in
                make.top.equalToSuperview().offset(Self.badgeOffset)
                make.trailing.equalToSuperview().offset(-Self.badgeOffset)
            }
            badgeView = view
            return view
        }()
        view.configure(badge)
    }

    // MARK: - Position

    /// Moves the button to `corner` (the vertical fraction stays), optionally animated.
    public func move(to corner: Corner, animated: Bool = true) {
        restingCorner = corner
        restingFraction = corner == .topLeading || corner == .topTrailing ? 0 : 1
        persistPosition()
        place(animated: animated)
    }

    private func place(animated: Bool) {
        guard let superview else { return }
        let safeArea = superview.safeAreaInsets
        let bounds = superview.bounds
        let half = buttonSize / 2
        let leadingX = safeArea.left + edgeMargin + half
        let trailingX = bounds.width - safeArea.right - edgeMargin - half
        let isLeading = restingCorner == .topLeading || restingCorner == .bottomLeading
        let isRightToLeft = effectiveUserInterfaceLayoutDirection == .rightToLeft
        let x = isLeading != isRightToLeft ? leadingX : trailingX
        let minY = safeArea.top + edgeMargin + half
        let maxY = bounds.height - safeArea.bottom - edgeMargin - half
        let y = minY + (maxY - minY) * restingFraction
        let target = CGPoint(x: x, y: clampY(y, in: bounds, safeArea: safeArea))
        if animated, LMKAnimation.shouldAnimate {
            UIView.animate(
                withDuration: LMKAnimation.Duration.fast,
                delay: 0,
                usingSpringWithDamping: LMKAnimation.spring.damping,
                initialSpringVelocity: 0,
                options: LMKAnimation.Curve.easeOut.options,
                animations: { self.center = target }
            )
        } else {
            center = target
        }
    }

    private func persistPosition() {
        guard let positionKey else { return }
        UserDefaults.standard.set([Self.cornerKey: restingCorner.rawValue, Self.fractionKey: restingFraction], forKey: positionKey)
    }

    private func restorePositionIfNeeded() {
        guard let positionKey, let stored = UserDefaults.standard.dictionary(forKey: positionKey) else { return }
        if let corner = (stored[Self.cornerKey] as? String).flatMap(Corner.init(rawValue:)) {
            restingCorner = corner
        }
        if let fraction = stored[Self.fractionKey] as? CGFloat {
            restingFraction = min(max(fraction, 0), 1)
        }
    }

    private static let cornerKey = "corner"
    private static let fractionKey = "fraction"

    // MARK: - Gestures

    @objc private func handleTap() {
        guard isEnabled else { return }
        onTap?()
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let superview, isEnabled else { return }
        switch gesture.state {
        case .began:
            panStartCenter = center
            isDragging = true
            applyTheme(traitCollection.lmkTheme)
        case .changed:
            let translation = gesture.translation(in: superview)
            let safeArea = superview.safeAreaInsets
            center = CGPoint(
                x: clampX(panStartCenter.x + translation.x, in: superview.bounds, safeArea: safeArea),
                y: clampY(panStartCenter.y + translation.y, in: superview.bounds, safeArea: safeArea)
            )
        case .ended, .cancelled:
            isDragging = false
            snapToNearestEdge()
            applyTheme(traitCollection.lmkTheme)
        default:
            break
        }
    }

    private func snapToNearestEdge() {
        guard let superview else { return }
        let safeArea = superview.safeAreaInsets
        let bounds = superview.bounds
        let half = buttonSize / 2
        let minY = safeArea.top + edgeMargin + half
        let maxY = bounds.height - safeArea.bottom - edgeMargin - half
        restingFraction = maxY > minY ? min(max((center.y - minY) / (maxY - minY), 0), 1) : 0.5
        let isLeadingSide = (center.x < bounds.midX) != (effectiveUserInterfaceLayoutDirection == .rightToLeft)
        let isTop = restingFraction < 0.5
        restingCorner = switch (isTop, isLeadingSide) {
        case (true, true): .topLeading
        case (true, false): .topTrailing
        case (false, true): .bottomLeading
        case (false, false): .bottomTrailing
        }
        persistPosition()
        place(animated: true)
    }

    /// Keeps the center inside the horizontal safe area (landscape cutouts, iPhone Duo camera region).
    private func clampX(_ x: CGFloat, in bounds: CGRect, safeArea: UIEdgeInsets) -> CGFloat {
        let half = buttonSize / 2
        return min(max(x, safeArea.left + half), bounds.width - safeArea.right - half)
    }

    private func clampY(_ y: CGFloat, in bounds: CGRect, safeArea: UIEdgeInsets) -> CGFloat {
        let half = buttonSize / 2
        let minY = safeArea.top + edgeMargin + half
        let maxY = bounds.height - safeArea.bottom - edgeMargin - half
        return min(max(y, minY), max(minY, maxY))
    }

    // MARK: - Accessibility

    private func updateAccessibility() {
        accessibilityLabel = strings.accessibilityLabel
        var traits: UIAccessibilityTraits = .button
        if !isEnabled { traits.insert(.notEnabled) }
        accessibilityTraits = traits
        accessibilityCustomActions = [
            UIAccessibilityCustomAction(name: strings.moveToTopLeading) { [weak self] _ in self?.move(to: .topLeading); return true },
            UIAccessibilityCustomAction(name: strings.moveToTopTrailing) { [weak self] _ in self?.move(to: .topTrailing); return true },
            UIAccessibilityCustomAction(name: strings.moveToBottomLeading) { [weak self] _ in self?.move(to: .bottomLeading); return true },
            UIAccessibilityCustomAction(name: strings.moveToBottomTrailing) { [weak self] _ in self?.move(to: .bottomTrailing); return true },
        ]
    }
}

public nonisolated extension LMKTheme {
    /// App-wide default style for `LMKFloatingButton`.
    var floatingButton: LMKFloatingButton.Style {
        get { self[LMKFloatingButton.Style.self] }
        set { self[LMKFloatingButton.Style.self] = newValue }
    }
}
