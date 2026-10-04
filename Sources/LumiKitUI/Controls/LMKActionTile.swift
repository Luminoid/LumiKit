//
//  LMKActionTile.swift
//  LumiKit
//
//  Tappable icon + label tile for action grids (a detail page's shortcuts),
//  with an optional inline count and an accent color that tints the tile.
//

import LumiKitCore
import SnapKit
import UIKit

/// Icon-over-label tile for action grids.
///
/// ```swift
/// let tile = LMKActionTile()
/// tile.configure(title: "Expenses", systemName: "creditcard", count: 3)   // "Expenses · 3"
/// tile.accentColor = trip.accentColor
/// tile.onTap = { [weak self] in self?.showExpenses() }
/// ```
///
/// The count reads as descriptive text on the label, never as a corner badge (which misreads as
/// a to-do notification). An `accentColor` tints the background lightly and the glyph fully; a
/// light accent is darkened for the glyph so it stays legible (`UIColor.lmk_glyphTint`).
public final class LMKActionTile: UIControl, LMKThemeApplying {
    // MARK: - Style

    public nonisolated struct Style: Sendable, Equatable, LMKThemeExtension {
        /// Background (default `backgroundSecondary`), corners (`medium`), border, shadow, content insets.
        public var surface: LMKSurfaceStyle
        /// Glyph tint without an accent; `nil` = `primary`.
        public var iconTint: UIColor?
        /// `nil` = `iconLarge`.
        public var iconSize: CGFloat?
        /// `nil` = `.caption`.
        public var titleTextStyle: LMKTextStyle?
        /// `nil` = `textSecondary`.
        public var titleColor: UIColor?
        /// `nil` = 2.
        public var titleLines: Int?
        /// Between glyph and title; `nil` = `xs`.
        public var spacing: CGFloat?
        /// Between title and count; `nil` = " · ".
        public var countSeparator: String?
        /// Alpha of the accent behind the tile; `nil` = `alpha.xxs`.
        public var accentBackgroundAlpha: CGFloat?
        /// Brightness factor applied to a light accent for the glyph; `nil` = 0.7. Unused while
        /// `glyphMinimumContrast` is set.
        public var lightAccentGlyphBrightness: CGFloat?
        /// The WCAG contrast the glyph keeps against the fill behind it; `nil` = the glyph takes
        /// the accent as is (a light accent darkened by `lightAccentGlyphBrightness`).
        ///
        /// When set, the glyph takes the softest tone of its color that still meets this ratio
        /// (`UIColor.lmk_softestTone(over:washAlpha:minimumContrast:resolvedWith:)`), resolved per
        /// appearance: the accent mixed toward the page while it has contrast to spare, darkened
        /// just enough when it has none. The fill measured is the accent's wash over
        /// `LMKColor.backgroundPrimary`, or a solid `surface.background`; a gradient, blur, or glass
        /// background leaves the glyph as it is. Dark Mode keeps the usual tone while it meets the
        /// ratio, and Increase Contrast raises the ratio to at least 4.5. A state's
        /// `foregroundColor` still wins.
        public var glyphMinimumContrast: CGFloat?
        /// The smallest scale the title shrinks to before it truncates, so a word too long for
        /// the tile shrinks rather than breaking mid-word; `nil` = no shrinking.
        public var titleMinimumScaleFactor: CGFloat?
        /// A height floor for the tile that still grows with its content (a title wrapping at
        /// large text sizes); `nil` = the content's height. Held just below required, so a table
        /// or collection view's own sizing wins.
        public var minimumHeight: CGFloat?
        /// Scale on press; `nil` = yes.
        public var pressAnimation: Bool?
        /// Haptic on tap; `nil` = yes.
        public var haptics: Bool?
        public var highlighted: LMKControlStateStyle?
        public var disabled: LMKControlStateStyle?

        public init(
            surface: LMKSurfaceStyle = LMKSurfaceStyle(),
            iconTint: UIColor? = nil,
            iconSize: CGFloat? = nil,
            titleTextStyle: LMKTextStyle? = nil,
            titleColor: UIColor? = nil,
            titleLines: Int? = nil,
            spacing: CGFloat? = nil,
            countSeparator: String? = nil,
            accentBackgroundAlpha: CGFloat? = nil,
            lightAccentGlyphBrightness: CGFloat? = nil,
            glyphMinimumContrast: CGFloat? = nil,
            titleMinimumScaleFactor: CGFloat? = nil,
            minimumHeight: CGFloat? = nil,
            pressAnimation: Bool? = nil,
            haptics: Bool? = nil,
            highlighted: LMKControlStateStyle? = nil,
            disabled: LMKControlStateStyle? = nil
        ) {
            self.surface = surface
            self.iconTint = iconTint
            self.iconSize = iconSize
            self.titleTextStyle = titleTextStyle
            self.titleColor = titleColor
            self.titleLines = titleLines
            self.spacing = spacing
            self.countSeparator = countSeparator
            self.accentBackgroundAlpha = accentBackgroundAlpha
            self.lightAccentGlyphBrightness = lightAccentGlyphBrightness
            self.glyphMinimumContrast = glyphMinimumContrast
            self.titleMinimumScaleFactor = titleMinimumScaleFactor
            self.minimumHeight = minimumHeight
            self.pressAnimation = pressAnimation
            self.haptics = haptics
            self.highlighted = highlighted
            self.disabled = disabled
        }

        public static let defaultValue = Self()

        /// `other`'s non-nil fields over this style's.
        public func merging(_ other: Self) -> Self {
            Self(
                surface: surface.merging(other.surface),
                iconTint: other.iconTint ?? iconTint,
                iconSize: other.iconSize ?? iconSize,
                titleTextStyle: other.titleTextStyle ?? titleTextStyle,
                titleColor: other.titleColor ?? titleColor,
                titleLines: other.titleLines ?? titleLines,
                spacing: other.spacing ?? spacing,
                countSeparator: other.countSeparator ?? countSeparator,
                accentBackgroundAlpha: other.accentBackgroundAlpha ?? accentBackgroundAlpha,
                lightAccentGlyphBrightness: other.lightAccentGlyphBrightness ?? lightAccentGlyphBrightness,
                glyphMinimumContrast: other.glyphMinimumContrast ?? glyphMinimumContrast,
                titleMinimumScaleFactor: other.titleMinimumScaleFactor ?? titleMinimumScaleFactor,
                minimumHeight: other.minimumHeight ?? minimumHeight,
                pressAnimation: other.pressAnimation ?? pressAnimation,
                haptics: other.haptics ?? haptics,
                highlighted: LMKControlStateStyle.merge(highlighted, other.highlighted),
                disabled: LMKControlStateStyle.merge(disabled, other.disabled)
            )
        }
    }

    // MARK: - Public API

    public var title: String? {
        didSet { updateContent() }
    }

    public var icon: UIImage? {
        didSet { updateContent() }
    }

    /// Shown after the title ("Expenses · 3"); `nil` or `0` hides it.
    public var count: Int? {
        didSet { updateContent() }
    }

    /// Tints the background lightly and the glyph fully; `nil` = the default colors.
    /// Ignored while `lockedAccentColor` is set.
    public var accentColor: UIColor? {
        didSet { applyTheme(traitCollection.lmkTheme) }
    }

    /// An accent the tile keeps whatever `accentColor` says (a destructive tile that must stay red).
    public var lockedAccentColor: UIColor? {
        didSet { applyTheme(traitCollection.lmkTheme) }
    }

    /// Called on tap.
    public var onTap: (() -> Void)?

    /// Per-instance style; `nil` fields resolve from `theme.actionTile`, then the built-in look.
    public var style: Style {
        didSet {
            guard style != oldValue else { return }
            applyTheme(traitCollection.lmkTheme)
        }
    }

    /// Called at the end of every `applyTheme`, for tweaks the style does not cover.
    public var didApplyStyle: ((LMKActionTile) -> Void)?

    public let iconView = UIImageView()
    public let titleLabel = UILabel()
    public let contentStack = UIStackView()

    private var resolved = Style()
    private var iconSizeConstraint: Constraint?
    private var contentLeadingConstraint: Constraint?
    private var contentTopConstraint: Constraint?
    /// Carries the `minimumHeight` floor: a constraint on the tile itself would turn off its
    /// autoresizing translation and break frame-based hosts.
    private let minimumHeightGuide = UILayoutGuide()
    private var minimumHeightConstraint: Constraint?
    /// Whether `titleMinimumScaleFactor` configured the title, so clearing it restores the label
    /// without overwriting what a host set on it directly.
    private var appliesTitleScaling = false
    /// The scale a state style set, so the press animation keeps the transform otherwise.
    private var appliedStateScale: CGFloat?

    /// Brightness factor for `lmk_stateShade(by:)` of the pressed fill (15% darker).
    private static let highlightedFillDelta: CGFloat = 0.85
    /// The glyph contrast floor under Increase Contrast (WCAG's ratio for body text).
    private nonisolated static let highContrastGlyphContrast: CGFloat = 4.5

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
        iconView.contentMode = .scaleAspectFit
        iconView.snp.makeConstraints { make in
            iconSizeConstraint = make.width.height.equalTo(0).constraint
        }
        titleLabel.textAlignment = .center
        contentStack.axis = .vertical
        contentStack.alignment = .center
        contentStack.isUserInteractionEnabled = false
        contentStack.addArrangedSubview(iconView)
        contentStack.addArrangedSubview(titleLabel)
        addSubview(contentStack)
        contentStack.snp.makeConstraints { make in
            make.center.equalToSuperview()
            contentLeadingConstraint = make.leading.greaterThanOrEqualToSuperview().offset(0).constraint
            contentTopConstraint = make.top.greaterThanOrEqualToSuperview().offset(0).constraint
        }
        addTarget(self, action: #selector(handleTap), for: .touchUpInside)
        addTarget(self, action: #selector(handleTouchDown), for: .touchDown)
        addTarget(self, action: #selector(handleTouchUp), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        addInteraction(UIPointerInteraction(delegate: self))
        isAccessibilityElement = true
        accessibilityTraits = .button
        // At accessibility text sizes a long press shows the title and glyph in the large content
        // viewer, so a title shrunk or truncated to fit stays readable.
        showsLargeContentViewer = true
        scalesLargeContentImage = true
        addInteraction(UILargeContentViewerInteraction(delegate: self))
        addLayoutGuide(minimumHeightGuide)
        minimumHeightGuide.snp.makeConstraints { make in
            make.top.bottom.leading.trailing.equalToSuperview()
        }
        minimumHeightGuide.snp.prepareConstraints { make in
            minimumHeightConstraint = make.height.greaterThanOrEqualTo(0).priority(999).constraint
        }
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        lmk_layoutSurfaceIfNeeded()
    }

    override public var isEnabled: Bool {
        didSet {
            guard isEnabled != oldValue else { return }
            applyTheme(traitCollection.lmkTheme)
            updateContent()
        }
    }

    override public var isHighlighted: Bool {
        didSet {
            guard isHighlighted != oldValue else { return }
            applyTheme(traitCollection.lmkTheme)
        }
    }

    /// Hidden: no touch. Disabled: the bounds absorb the touch (UIKit's behavior for a disabled
    /// control). Enabled: the minimum touch target.
    override public func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        guard !isHidden else { return false }
        guard isEnabled else { return bounds.contains(point) }
        return lmk_hitTestBounds(minimumSide: traitCollection.lmkTheme.layout.minimumTouchTarget, insets: lmk_hitTestInsets).contains(point)
    }

    /// Sets the title, glyph, and count in one call.
    public func configure(title: String, icon: UIImage?, count: Int? = nil) {
        self.title = title
        self.icon = icon
        self.count = count
    }

    /// `configure(title:icon:count:)` with an SF Symbol.
    public func configure(title: String, systemName: String, count: Int? = nil) {
        configure(title: title, icon: UIImage(systemName: systemName), count: count)
    }

    // MARK: - Theme

    public func applyTheme(_ theme: LMKTheme) {
        resolved = theme.actionTile.merging(style)
        let accent = lockedAccentColor ?? accentColor
        var surface = resolved.surface
        var defaults = LMKSurfaceStyle(background: .solid(LMKColor.backgroundSecondary), corners: .fixed(theme.cornerRadius.medium))
        var glyphTint = resolved.iconTint ?? LMKColor.primary
        let washAlpha = resolved.accentBackgroundAlpha ?? theme.alpha.xxs
        if let accent {
            defaults.background = .solid(accent.withAlphaComponent(washAlpha))
            glyphTint = accent.lmk_glyphTint(onLightAccentDarkenBy: resolved.lightAccentGlyphBrightness ?? 0.7)
        }
        if let minimumContrast = resolved.glyphMinimumContrast,
           let fill = Self.glyphFill(background: surface.background, accent: accent, washAlpha: washAlpha) {
            glyphTint = Self.contrastingGlyphTint(
                base: accent ?? glyphTint,
                usual: glyphTint,
                fill: fill,
                minimumContrast: minimumContrast
            )
        }
        var stateAlpha: CGFloat = 1
        var stateScale: CGFloat?
        if isHighlighted {
            let highlighted = resolved.highlighted ?? LMKControlStateStyle()
            if highlighted.background == nil, highlighted.alpha == nil {
                // Pressed: a shade of the fill shown, so the press reads without motion too.
                if case let .solid(color) = surface.background ?? defaults.background {
                    surface.background = .solid((color ?? LMKColor.backgroundSecondary).lmk_stateShade(by: Self.highlightedFillDelta))
                }
            }
            apply(highlighted, to: &surface, &glyphTint, &stateAlpha, &stateScale)
        }
        if !isEnabled {
            var disabled = resolved.disabled ?? LMKControlStateStyle()
            if disabled.alpha == nil { disabled.alpha = theme.alpha.disabled }
            apply(disabled, to: &surface, &glyphTint, &stateAlpha, &stateScale)
        }
        let applied = lmk_apply(surface: surface, defaults: defaults)
        alpha = stateAlpha
        // A state scale owns the transform; without one the press animation does.
        if let stateScale {
            transform = CGAffineTransform(scaleX: stateScale, y: stateScale)
        } else if appliedStateScale != nil {
            transform = .identity
        }
        appliedStateScale = stateScale
        let insets = applied.contentInsets ?? .lmk_all(theme.spacing.xs)
        contentLeadingConstraint?.update(offset: insets.leading)
        contentTopConstraint?.update(offset: insets.top)
        contentStack.spacing = resolved.spacing ?? theme.spacing.xs
        iconSizeConstraint?.update(offset: resolved.iconSize ?? theme.layout.iconLarge)
        iconView.tintColor = glyphTint
        titleLabel.lmk_apply(resolved.titleTextStyle ?? .caption, color: resolved.titleColor ?? LMKColor.textSecondary)
        titleLabel.numberOfLines = resolved.titleLines ?? 2
        applyTitleScaling(resolved.titleMinimumScaleFactor)
        if let minimumHeight = resolved.minimumHeight {
            minimumHeightConstraint?.update(offset: minimumHeight)
            minimumHeightConstraint?.activate()
        } else {
            minimumHeightConstraint?.deactivate()
        }
        updateContent()
        didApplyStyle?(self)
    }

    private func applyTitleScaling(_ minimumScaleFactor: CGFloat?) {
        if let minimumScaleFactor {
            titleLabel.adjustsFontSizeToFitWidth = true
            titleLabel.minimumScaleFactor = min(max(minimumScaleFactor, 0), 1)
            titleLabel.lineBreakMode = .byTruncatingTail
            appliesTitleScaling = true
        } else if appliesTitleScaling {
            titleLabel.adjustsFontSizeToFitWidth = false
            titleLabel.minimumScaleFactor = 0
            appliesTitleScaling = false
        }
    }

    /// What the glyph is measured against: the color under the fill and the opacity of `base`'s
    /// wash over it. `nil` for a fill that is not one solid color.
    private static func glyphFill(background: LMKBackgroundStyle?, accent: UIColor?, washAlpha: CGFloat) -> (color: UIColor, washAlpha: CGFloat)? {
        switch background {
        case nil, .solid(nil):
            // The default fill: the accent's wash over the page, or the secondary background.
            accent == nil ? (LMKColor.backgroundSecondary, 0) : (LMKColor.backgroundPrimary, washAlpha)
        case let .solid(color?):
            // A translucent fill shows the page through it.
            (color.lmk_composited(over: LMKColor.backgroundPrimary, alpha: 1), 0)
        case .clear:
            (LMKColor.backgroundPrimary, 0)
        case .gradient, .blur, .glass:
            nil
        }
    }

    /// `base`'s softest tone that keeps `minimumContrast` (4.5 or more under Increase Contrast)
    /// against `fill`; in Dark Mode `usual` while it already does.
    private nonisolated static func contrastingGlyphTint(base: UIColor, usual: UIColor, fill: (color: UIColor, washAlpha: CGFloat), minimumContrast: CGFloat) -> UIColor {
        UIColor { traits in
            let target = traits.accessibilityContrast == .high ? max(Self.highContrastGlyphContrast, minimumContrast) : minimumContrast
            if traits.userInterfaceStyle == .dark {
                let wash = base.lmk_composited(over: fill.color, alpha: fill.washAlpha)
                let tone = usual.resolvedColor(with: traits)
                if tone.lmk_contrastRatio(to: wash, resolvedWith: traits) >= target { return tone }
            }
            return base.lmk_softestTone(over: fill.color, washAlpha: fill.washAlpha, minimumContrast: target, resolvedWith: traits)
        }
    }

    private func apply(_ state: LMKControlStateStyle, to surface: inout LMKSurfaceStyle, _ foreground: inout UIColor, _ alpha: inout CGFloat, _ scale: inout CGFloat?) {
        if let value = state.background { surface.background = value }
        if let value = state.border { surface.border = value }
        if let value = state.shadow { surface.shadow = value }
        if let value = state.foregroundColor { foreground = value }
        if let value = state.alpha { alpha = min(alpha, value) }
        if let value = state.scale { scale = value }
    }

    private func updateContent() {
        iconView.image = icon
        let separator = resolved.countSeparator ?? " · "
        if let count, count > 0, let title {
            let formattedCount = LMKFormat.number(count)
            titleLabel.lmk_setText("\(title)\(separator)\(formattedCount)")
            accessibilityLabel = "\(title), \(formattedCount)"
        } else {
            titleLabel.lmk_setText(title)
            accessibilityLabel = title
        }
        largeContentTitle = title
        largeContentImage = icon
        var traits: UIAccessibilityTraits = .button
        if !isEnabled { traits.insert(.notEnabled) }
        accessibilityTraits = traits
    }

    // MARK: - Actions

    @objc private func handleTap() {
        guard isEnabled else { return }
        if resolved.haptics ?? true { LMKHaptics.light() }
        onTap?()
        sendActions(for: .primaryActionTriggered)
    }

    @objc private func handleTouchDown() {
        guard resolved.pressAnimation ?? true, appliedStateScale == nil else { return }
        LMKAnimation.animateButtonPressDown(self)
    }

    @objc private func handleTouchUp() {
        guard resolved.pressAnimation ?? true, appliedStateScale == nil else { return }
        LMKAnimation.animateButtonPressUp(self)
    }
}

// MARK: - UIPointerInteractionDelegate

extension LMKActionTile: UIPointerInteractionDelegate {
    public func pointerInteraction(_: UIPointerInteraction, styleFor _: UIPointerRegion) -> UIPointerStyle? {
        LMKPointerStyle.lift(for: self)
    }
}

// MARK: - UILargeContentViewerInteractionDelegate

extension LMKActionTile: UILargeContentViewerInteractionDelegate {
    /// Lifting the finger on the tile while its large content shows is a tap.
    public func largeContentViewerInteraction(_: UILargeContentViewerInteraction, didEndOn item: (any UILargeContentViewerItem)?, at point: CGPoint) {
        guard item === self, bounds.contains(point) else { return }
        handleTap()
    }
}

public nonisolated extension LMKTheme {
    /// App-wide default style for `LMKActionTile`.
    var actionTile: LMKActionTile.Style {
        get { self[LMKActionTile.Style.self] }
        set { self[LMKActionTile.Style.self] = newValue }
    }
}
