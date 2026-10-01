//
//  LMKCardView.swift
//  LumiKit
//
//  Card container: a themed surface (background, corners, border, shadow,
//  insets) around a `contentView`, optionally tappable.
//

import SnapKit
import UIKit

/// Card container whose surface comes from the theme.
///
/// Add child views to `contentView`:
/// ```swift
/// let card = LMKCardView(style: .elevated)
/// card.contentView.addSubview(myLabel)
/// myLabel.snp.makeConstraints { $0.edges.equalToSuperview() }
/// ```
///
/// Presets: `.cell` (list-row lift), `.elevated` (the default), `.flat` (no shadow),
/// `.outlined` (hairline border, no shadow). Every surface field is overridable per
/// instance (`card.style.surface.corners = .fixed(24)`) or app-wide (`theme.card`).
public final class LMKCardView: UIView, LMKThemeApplying {
    // MARK: - Style

    public nonisolated struct Style: Sendable, Equatable, LMKThemeExtension {
        /// Background (default `backgroundSecondary`), corners (`medium`), border (none),
        /// shadow (`level3`), and content insets (`large`).
        public var surface: LMKSurfaceStyle
        /// Pressed appearance while `onTap` is set; `nil` scales the card by the theme's press scale.
        public var highlighted: LMKControlStateStyle?
        /// Whether a tappable card animates its press. `nil` = yes.
        public var pressAnimation: Bool?

        public init(surface: LMKSurfaceStyle = LMKSurfaceStyle(), highlighted: LMKControlStateStyle? = nil, pressAnimation: Bool? = nil) {
            self.surface = surface
            self.highlighted = highlighted
            self.pressAnimation = pressAnimation
        }

        public static let defaultValue = Self()
        /// List-row card: the `level2` shadow.
        public static let cell = Self(surface: LMKSurfaceStyle(shadow: .level(.level2)))
        /// Floating card: the `level3` shadow (the default look).
        public static let elevated = Self(surface: LMKSurfaceStyle(shadow: .level(.level3)))
        /// No shadow; the card clips its content to the corners.
        public static let flat = Self(surface: LMKSurfaceStyle(shadow: LMKShadowSource.hidden))
        /// Hairline outline, no shadow.
        public static let outlined = Self(surface: LMKSurfaceStyle(border: .solid(), shadow: LMKShadowSource.hidden))

        /// `other`'s non-nil fields over this style's.
        public func merging(_ other: Self) -> Self {
            Self(
                surface: surface.merging(other.surface),
                highlighted: LMKControlStateStyle.merge(highlighted, other.highlighted),
                pressAnimation: other.pressAnimation ?? pressAnimation
            )
        }
    }

    // MARK: - Properties

    /// Content container. Inset from the card edge by the resolved content insets and clear,
    /// so the card's own layer draws the fill. It clips to the curve concentric with the card's
    /// corners, so edge-to-edge content never squares off a corner or the shadow.
    public let contentView = UIView()

    /// Per-instance style; `nil` fields resolve from `theme.card`, then the built-in look.
    public var style: Style {
        didSet {
            guard style != oldValue else { return }
            applyTheme(traitCollection.lmkTheme)
        }
    }

    /// Makes the card tappable: press feedback, the `.button` trait, and this handler.
    public var onTap: (() -> Void)? {
        didSet { updateInteraction() }
    }

    /// Called at the end of every `applyTheme`, for tweaks the style does not cover.
    public var didApplyStyle: ((LMKCardView) -> Void)?

    /// VoiceOver label of a tappable card: the host's, or the labels of the content's
    /// accessible descendants joined, so the button is never unnamed.
    override public var accessibilityLabel: String? {
        get { super.accessibilityLabel ?? (onTap == nil ? nil : Self.derivedLabel(in: contentView)) }
        set { super.accessibilityLabel = newValue }
    }

    private var contentInsetsConstraint: Constraint?
    private var appliedContentInsets = NSDirectionalEdgeInsets.lmk_all(0)
    private var isPressed = false {
        didSet { guard isPressed != oldValue else { return }; applyTheme(traitCollection.lmkTheme) }
    }

    // MARK: - Initialization

    public init(style: Style = Style()) {
        self.style = style
        super.init(frame: .zero)
        setupUI()
        lmk_startApplyingTheme()
    }

    override public convenience init(frame: CGRect) {
        self.init(style: Style())
        self.frame = frame
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI() {
        contentView.backgroundColor = .clear
        addSubview(contentView)
        contentView.snp.makeConstraints { make in
            contentInsetsConstraint = make.directionalEdges.equalToSuperview().constraint
        }
        isAccessibilityElement = false
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        lmk_layoutSurfaceIfNeeded()
        updateContentCorners()
    }

    // MARK: - Theme

    public func applyTheme(_ theme: LMKTheme) {
        let resolved = theme.card.merging(style)
        let defaults = LMKSurfaceStyle(
            background: .solid(LMKColor.backgroundSecondary),
            corners: .fixed(theme.cornerRadius.medium),
            shadow: .level(.level3),
            contentInsets: .lmk_all(theme.spacing.large)
        )
        var surface = resolved.surface
        if isPressed, let highlighted = resolved.highlighted {
            if let background = highlighted.background { surface.background = background }
            if let border = highlighted.border { surface.border = border }
            if let shadow = highlighted.shadow { surface.shadow = shadow }
        }
        let applied = lmk_apply(surface: surface, defaults: defaults)
        let insets = applied.contentInsets ?? .lmk_all(theme.spacing.large)
        appliedContentInsets = insets
        contentInsetsConstraint?.update(inset: insets)
        updateContentCorners()

        if isPressed {
            let scale = resolved.highlighted?.scale ?? (resolved.pressAnimation ?? true ? theme.animation.pressScale : 1)
            transform = CGAffineTransform(scaleX: scale, y: scale)
            alpha = resolved.highlighted?.alpha ?? 1
        } else {
            transform = .identity
            alpha = 1
        }
        didApplyStyle?(self)
    }

    /// Clips the content to the curve concentric with the card's corners (the card radius less
    /// the smallest inset), so a card that carries a shadow, and so does not mask, keeps its
    /// rounded corners under edge-to-edge content.
    private func updateContentCorners() {
        let corners = lmk_resolvedSurface?.corners ?? .square
        let insets = appliedContentInsets
        let smallestInset = min(insets.top, insets.leading, insets.bottom, insets.trailing)
        let contentRadius = max(0, corners.resolvedRadius(for: bounds) - smallestInset)
        contentView.lmk_applyCornerStyle(.fixed(contentRadius, corners: corners.maskedCorners, curve: corners.curve), masking: true)
    }

    // MARK: - Interaction

    private func updateInteraction() {
        if onTap != nil {
            isAccessibilityElement = true
            accessibilityTraits = .button
        } else {
            isAccessibilityElement = false
            accessibilityTraits = .none
            isPressed = false
        }
    }

    /// A tappable card handles its own touches (no forwarding to a tappable ancestor or a
    /// selectable cell); a plain card passes them up as any view does.
    override public func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard onTap != nil else {
            super.touchesBegan(touches, with: event)
            return
        }
        setPressed(true)
    }

    override public func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard onTap != nil else {
            super.touchesMoved(touches, with: event)
            return
        }
    }

    override public func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard onTap != nil else {
            super.touchesEnded(touches, with: event)
            return
        }
        let inside = touches.first.map { bounds.contains($0.location(in: self)) } ?? false
        setPressed(false)
        if inside {
            onTap?()
        }
    }

    override public func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard onTap != nil else {
            super.touchesCancelled(touches, with: event)
            return
        }
        setPressed(false)
    }

    override public func accessibilityActivate() -> Bool {
        guard let onTap else { return false }
        onTap()
        return true
    }

    private func setPressed(_ pressed: Bool) {
        let animates = LMKAnimation.shouldAnimate
        UIView.animate(withDuration: animates ? LMKAnimation.Duration.instant : 0, delay: 0, options: [.allowUserInteraction, .beginFromCurrentState]) {
            self.isPressed = pressed
        }
    }

    /// The labels of `view`'s accessible descendants (an element's label, a label's text),
    /// in order, joined with a comma.
    private static func derivedLabel(in view: UIView) -> String? {
        var labels: [String] = []
        func collect(_ view: UIView) {
            if view.isHidden || view.accessibilityElementsHidden { return }
            if view.isAccessibilityElement || view is UILabel {
                let label = view.accessibilityLabel ?? (view as? UILabel)?.text
                if let label, !label.isEmpty { labels.append(label) }
                return
            }
            view.subviews.forEach(collect)
        }
        view.subviews.forEach(collect)
        return labels.isEmpty ? nil : labels.joined(separator: ", ")
    }
}

public nonisolated extension LMKTheme {
    /// App-wide default style for `LMKCardView`.
    var card: LMKCardView.Style {
        get { self[LMKCardView.Style.self] }
        set { self[LMKCardView.Style.self] = newValue }
    }
}
