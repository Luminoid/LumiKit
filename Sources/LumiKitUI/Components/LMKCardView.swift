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
        public static let flat = Self(surface: LMKSurfaceStyle(shadow: LMKShadowSource.none))
        /// Hairline outline, no shadow.
        public static let outlined = Self(surface: LMKSurfaceStyle(border: .solid(), shadow: LMKShadowSource.none))

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

    /// Content container. Inset from the card edge by the resolved content insets and
    /// clipped to a plain rect (the card's own layer owns the rounding).
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

    private var contentInsetsConstraint: Constraint?
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
        contentView.layer.masksToBounds = true
        addSubview(contentView)
        contentView.snp.makeConstraints { make in
            contentInsetsConstraint = make.edges.equalToSuperview().constraint
        }
        isAccessibilityElement = false
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        lmk_layoutSurfaceIfNeeded()
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
        contentView.backgroundColor = backgroundColor == .clear ? nil : backgroundColor
        let insets = applied.contentInsets ?? .lmk_all(theme.spacing.large)
        contentInsetsConstraint?.update(inset: UIEdgeInsets(top: insets.top, left: insets.leading, bottom: insets.bottom, right: insets.trailing))

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

    override public func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        guard onTap != nil else { return }
        setPressed(true)
    }

    override public func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        guard onTap != nil else { return }
        let inside = touches.first.map { bounds.contains($0.location(in: self)) } ?? false
        setPressed(false)
        if inside {
            onTap?()
        }
    }

    override public func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
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
}

public nonisolated extension LMKTheme {
    /// App-wide default style for `LMKCardView`.
    var card: LMKCardView.Style {
        get { self[LMKCardView.Style.self] }
        set { self[LMKCardView.Style.self] = newValue }
    }
}
