//
//  LMKButton.swift
//  LumiKit
//
//  The themed button: roles × variants × sizes resolved in one
//  `updateConfiguration()` pass (normal, highlighted, selected, disabled),
//  closure tap handling, loading state, toggle mode, and a 44pt hit target.
//

import SnapKit
import UIKit

/// Themed button.
///
/// ```swift
/// let save = LMKButton(title: "Save", style: .filled()) { save() }
/// let cancel = LMKButton(title: "Cancel", style: .ghost(.neutral), target: self, action: #selector(cancel))
/// let more = LMKButton(systemImage: "ellipsis", style: .iconOnly())
/// delete.style = .outlined(.destructive).size(.small)
/// ```
///
/// Every appearance decision is a `Style` field (role, variant, size, surface, text
/// style, image placement, per-state overrides), resolved against `theme.button`
/// and re-applied on theme and Dynamic Type changes. Content and runtime state
/// (`title`, `image`, `isLoading`, `isEnabled`, `isSelected`, `menu`) stay properties.
open class LMKButton: UIButton, LMKThemeApplying {
    // MARK: - Vocabulary

    /// Semantic role: picks the tint from the theme.
    public nonisolated enum Role: Sendable, Hashable, CaseIterable {
        case primary, secondary, tertiary, destructive, success, warning, info, neutral
    }

    /// How the tint is used.
    public nonisolated enum Variant: Sendable, Hashable, CaseIterable {
        /// Tinted background, `onAccent` foreground.
        case filled
        /// Translucent tinted background, tinted foreground.
        case tinted
        /// Tinted border and foreground on a clear background.
        case outlined
        /// Tinted text only.
        case ghost
        /// Liquid Glass on iOS 26 (`tinted` before).
        case glass
    }

    /// Content padding and text size.
    public nonisolated enum Size: Sendable, Hashable, CaseIterable {
        case small, medium, large
    }

    // MARK: - Style

    public nonisolated struct Style: Sendable, Equatable, LMKThemeExtension {
        /// `nil` = `.primary`.
        public var role: Role?
        /// `nil` = `.filled`.
        public var variant: Variant?
        /// `nil` = `.medium`.
        public var size: Size?
        /// Corners (default capsule), border (outlined: tint, 1pt), shadow, content insets (per size).
        public var surface: LMKSurfaceStyle
        /// Overrides the role's tint.
        public var tintColor: UIColor?
        /// Overrides the derived foreground (`onAccent` on filled, the tint otherwise).
        public var foregroundColor: UIColor?
        /// `nil` = `bodyMedium` (`captionMedium` for `.small`, `h4` for `.large`).
        public var textStyle: LMKTextStyle?
        /// Side of the image relative to the title; `nil` = leading.
        public var imagePlacement: NSDirectionalRectEdge?
        /// Gap between image and title; `nil` = `iconToText`.
        public var imagePadding: CGFloat?
        /// Point size of an SF Symbol image; `nil` = `symbolAction`.
        public var symbolPointSize: CGFloat?
        /// Weight of an SF Symbol image; `nil` = `.medium`.
        public var symbolWeight: UIImage.SymbolWeight?
        /// Cross-fades a symbol swap (`setSymbol`, a toggle's `selectedImage`) on iOS 26
        /// (`UISymbolContentTransition`); `nil` = yes. Reduce Motion always disables it; before
        /// iOS 26 the image is replaced without a transition.
        public var animatesSymbolChanges: Bool?
        /// Height floor; `nil` = none (the hit target is still 44pt).
        public var minimumHeight: CGFloat?
        /// Shows the pop-up chevron when a `menu` is set; `nil` = no.
        public var showsMenuIndicator: Bool?
        /// `nil` = the foreground color.
        public var loadingIndicatorColor: UIColor?
        /// Scale-down on press; `nil` = yes.
        public var pressAnimation: Bool?
        /// Haptic on touch down; `nil` = yes.
        public var haptics: Bool?
        public var highlighted: LMKControlStateStyle?
        public var selected: LMKControlStateStyle?
        public var disabled: LMKControlStateStyle?
        public var focused: LMKControlStateStyle?

        public init(
            role: Role? = nil,
            variant: Variant? = nil,
            size: Size? = nil,
            surface: LMKSurfaceStyle = LMKSurfaceStyle(),
            tintColor: UIColor? = nil,
            foregroundColor: UIColor? = nil,
            textStyle: LMKTextStyle? = nil,
            imagePlacement: NSDirectionalRectEdge? = nil,
            imagePadding: CGFloat? = nil,
            symbolPointSize: CGFloat? = nil,
            symbolWeight: UIImage.SymbolWeight? = nil,
            animatesSymbolChanges: Bool? = nil,
            minimumHeight: CGFloat? = nil,
            showsMenuIndicator: Bool? = nil,
            loadingIndicatorColor: UIColor? = nil,
            pressAnimation: Bool? = nil,
            haptics: Bool? = nil,
            highlighted: LMKControlStateStyle? = nil,
            selected: LMKControlStateStyle? = nil,
            disabled: LMKControlStateStyle? = nil,
            focused: LMKControlStateStyle? = nil
        ) {
            self.role = role
            self.variant = variant
            self.size = size
            self.surface = surface
            self.tintColor = tintColor
            self.foregroundColor = foregroundColor
            self.textStyle = textStyle
            self.imagePlacement = imagePlacement
            self.imagePadding = imagePadding
            self.symbolPointSize = symbolPointSize
            self.symbolWeight = symbolWeight
            self.animatesSymbolChanges = animatesSymbolChanges
            self.minimumHeight = minimumHeight
            self.showsMenuIndicator = showsMenuIndicator
            self.loadingIndicatorColor = loadingIndicatorColor
            self.pressAnimation = pressAnimation
            self.haptics = haptics
            self.highlighted = highlighted
            self.selected = selected
            self.disabled = disabled
            self.focused = focused
        }

        public static let defaultValue = Self()

        public static func filled(_ role: Role = .primary) -> Self {
            Self(role: role, variant: .filled)
        }

        public static func tinted(_ role: Role = .primary) -> Self {
            Self(role: role, variant: .tinted)
        }

        public static func outlined(_ role: Role = .primary) -> Self {
            Self(role: role, variant: .outlined)
        }

        public static func ghost(_ role: Role = .primary) -> Self {
            Self(role: role, variant: .ghost)
        }

        public static func glass(_ role: Role = .primary) -> Self {
            Self(role: role, variant: .glass)
        }

        /// A circular glyph button: ghost variant, circle corners, uniform insets.
        public static func iconOnly(_ role: Role = .primary) -> Self {
            Self(role: role, variant: .ghost, surface: LMKSurfaceStyle(corners: .circle))
        }

        /// A copy with a custom tint.
        public func tint(_ color: UIColor) -> Self {
            var copy = self
            copy.tintColor = color
            return copy
        }

        /// A copy at another size.
        public func size(_ size: Size) -> Self {
            var copy = self
            copy.size = size
            return copy
        }

        /// `other`'s non-nil fields over this style's.
        public func merging(_ other: Self) -> Self {
            Self(
                role: other.role ?? role,
                variant: other.variant ?? variant,
                size: other.size ?? size,
                surface: surface.merging(other.surface),
                tintColor: other.tintColor ?? tintColor,
                foregroundColor: other.foregroundColor ?? foregroundColor,
                textStyle: other.textStyle ?? textStyle,
                imagePlacement: other.imagePlacement ?? imagePlacement,
                imagePadding: other.imagePadding ?? imagePadding,
                symbolPointSize: other.symbolPointSize ?? symbolPointSize,
                symbolWeight: other.symbolWeight ?? symbolWeight,
                animatesSymbolChanges: other.animatesSymbolChanges ?? animatesSymbolChanges,
                minimumHeight: other.minimumHeight ?? minimumHeight,
                showsMenuIndicator: other.showsMenuIndicator ?? showsMenuIndicator,
                loadingIndicatorColor: other.loadingIndicatorColor ?? loadingIndicatorColor,
                pressAnimation: other.pressAnimation ?? pressAnimation,
                haptics: other.haptics ?? haptics,
                highlighted: LMKControlStateStyle.merge(highlighted, other.highlighted),
                selected: LMKControlStateStyle.merge(selected, other.selected),
                disabled: LMKControlStateStyle.merge(disabled, other.disabled),
                focused: LMKControlStateStyle.merge(focused, other.focused)
            )
        }
    }

    // MARK: - Strings

    public nonisolated struct Strings: Sendable, Equatable {
        /// VoiceOver value of a toggle button that is on.
        public var onAccessibilityValue: String
        /// VoiceOver value of a toggle button that is off.
        public var offAccessibilityValue: String

        public init(
            onAccessibilityValue: String = LMKLocalized("button.on.accessibilityValue"),
            offAccessibilityValue: String = LMKLocalized("button.off.accessibilityValue")
        ) {
            self.onAccessibilityValue = onAccessibilityValue
            self.offAccessibilityValue = offAccessibilityValue
        }
    }

    /// Process-wide defaults; set at app launch to override.
    public nonisolated(unsafe) static var strings = Strings()

    /// Per-instance strings (default `Self.strings`).
    public var strings: Strings = LMKButton.strings {
        didSet { updateContent() }
    }

    // MARK: - Content and state

    /// Per-instance style; `nil` fields resolve from `theme.button`, then the built-in look.
    public var style: Style {
        didSet {
            guard style != oldValue else { return }
            applyTheme(traitCollection.lmkTheme)
        }
    }

    /// The title (the `selectedTitle` shows instead while a toggle is on).
    public var title: String? {
        didSet { updateContent() }
    }

    /// The image (the `selectedImage` shows instead while a toggle is on).
    public var image: UIImage? {
        didSet { updateContent() }
    }

    /// Fires on every tap. Capture the button in the closure when the handler needs it.
    public var onTap: (() -> Void)?

    /// When `true`, a tap flips `isSelected`, swaps in `selectedTitle` / `selectedImage`,
    /// exposes on/off as the accessibility value, and calls `onValueChange`.
    public var isToggle = false {
        didSet { updateContent() }
    }

    public var selectedTitle: String? {
        didSet { updateContent() }
    }

    public var selectedImage: UIImage? {
        didSet { updateContent() }
    }

    /// Called after a toggle flips, with the new `isSelected`.
    public var onValueChange: ((Bool) -> Void)?

    /// Shows an activity indicator in place of the title and disables interaction.
    public var isLoading = false {
        didSet {
            guard isLoading != oldValue else { return }
            configuration?.showsActivityIndicator = isLoading
            if isLoading {
                savedTitle = configuration?.title
                // A space keeps the title's line-height contribution so the button does not shrink.
                configuration?.title = " "
            } else {
                configuration?.title = savedTitle
            }
            isUserInteractionEnabled = !isLoading
        }
    }

    /// Side of the minimum hit target; `nil` = `LMKLayout.minimumTouchTarget`.
    public var minimumHitTarget: CGFloat?

    public var imageContentMode: UIView.ContentMode = .scaleAspectFit {
        didSet { imageView?.contentMode = imageContentMode }
    }

    /// Called at the end of every `applyTheme`, for tweaks the style does not cover.
    public var didApplyStyle: ((LMKButton) -> Void)?

    private var savedTitle: String?
    private var resolvedStyle = Style()
    private var minimumHeightConstraint: Constraint?

    override open var isSelected: Bool {
        didSet {
            guard isSelected != oldValue else { return }
            updateContent()
        }
    }

    // MARK: - Initialization

    /// A styled button (`Style()` = `theme.button`, then filled primary). `onTap` fires on every tap.
    public init(title: String? = nil, image: UIImage? = nil, style: Style = Style(), onTap: (() -> Void)? = nil) {
        self.style = style
        self.title = title
        self.image = image
        self.onTap = onTap
        super.init(frame: .zero)
        initialize()
    }

    override public convenience init(frame: CGRect) {
        self.init(style: Style())
        self.frame = frame
    }

    /// A styled button wired to a target/action (`.touchUpInside`).
    public convenience init(title: String, style: Style, target: Any?, action: Selector) {
        self.init(title: title, style: style)
        addTarget(target, action: action, for: .touchUpInside)
    }

    /// A glyph button showing an SF Symbol.
    public convenience init(systemImage: String, style: Style = .iconOnly(), onTap: (() -> Void)? = nil) {
        self.init(style: style, onTap: onTap)
        setSymbol(systemImage)
    }

    /// A glyph button wired to a target/action.
    public convenience init(systemImage: String, style: Style, target: Any?, action: Selector) {
        self.init(systemImage: systemImage, style: style)
        addTarget(target, action: action, for: .touchUpInside)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// One-time setup; subclasses call `super`.
    open func initialize() {
        configuration = .plain()
        imageView?.contentMode = imageContentMode
        // Hover feedback for iPad pointer / Mac Catalyst.
        isPointerInteractionEnabled = true
        addTarget(self, action: #selector(didTap), for: .touchUpInside)
        addTarget(self, action: #selector(handleTouchDown), for: .touchDown)
        addTarget(self, action: #selector(handleTouchUp), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        updateContent()
        lmk_startApplyingTheme()
    }

    /// UIKit's state hook: re-resolves every appearance field (the handler pattern from the
    /// iOS 26 filled-configuration lesson, as an override so it runs synchronously too).
    override open func updateConfiguration() {
        super.updateConfiguration()
        applyResolvedConfiguration()
    }

    // MARK: - Content

    /// Sets an SF Symbol as the image. Point size and weight default to the style's values.
    public func setSymbol(_ name: String, pointSize: CGFloat? = nil, weight: UIImage.SymbolWeight? = nil) {
        var configuration = UIImage.SymbolConfiguration(pointSize: pointSize ?? resolvedStyle.symbolPointSize ?? traitCollection.lmkTheme.layout.symbolAction)
        configuration = configuration.applying(UIImage.SymbolConfiguration(weight: weight ?? resolvedStyle.symbolWeight ?? .medium))
        image = UIImage(systemName: name, withConfiguration: configuration)
    }

    private func updateContent() {
        let showsSelected = isToggle && isSelected
        var config = configuration ?? .plain()
        config.title = isLoading ? " " : (showsSelected ? (selectedTitle ?? title) : title)
        config.image = showsSelected ? (selectedImage ?? image) : image
        configuration = config
        if isToggle {
            accessibilityValue = isSelected ? strings.onAccessibilityValue : strings.offAccessibilityValue
        } else {
            accessibilityValue = nil
        }
    }

    // MARK: - Theme

    open func applyTheme(_ theme: LMKTheme) {
        resolvedStyle = theme.button.merging(style)
        if let minimumHeight = resolvedStyle.minimumHeight {
            if let constraint = minimumHeightConstraint {
                constraint.update(offset: minimumHeight)
            } else {
                snp.makeConstraints { make in
                    minimumHeightConstraint = make.height.greaterThanOrEqualTo(minimumHeight).constraint
                }
            }
        } else {
            minimumHeightConstraint?.deactivate()
            minimumHeightConstraint = nil
        }
        applyResolvedConfiguration()
        setNeedsUpdateConfiguration()
        didApplyStyle?(self)
    }

    /// The appearance derived for one control state.
    private struct Appearance {
        var background: LMKBackgroundStyle
        var foreground: UIColor
        var border: LMKBorderStyle?
        var shadow: LMKShadowSource
        var alpha: CGFloat
    }

    /// Resolves every appearance field for the button's current state into `configuration`.
    private func applyResolvedConfiguration() {
        let button = self
        let theme = traitCollection.lmkTheme
        let resolved = resolvedStyle
        let role = resolved.role ?? .primary
        let variant = resolved.variant ?? .filled
        let size = resolved.size ?? .medium
        let tint = resolved.tintColor ?? Self.tint(for: role)

        var config: UIButton.Configuration = if variant == .glass, #available(iOS 26, *) {
            .glass()
        } else {
            .plain()
        }
        // Content is owned by `updateContent`; carry it over.
        config.title = button.configuration?.title
        config.image = button.configuration?.image
        config.showsActivityIndicator = button.configuration?.showsActivityIndicator ?? false
        config.imagePlacement = resolved.imagePlacement ?? .leading
        config.imagePadding = resolved.imagePadding ?? theme.spacing.iconToText
        config.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(
            pointSize: resolved.symbolPointSize ?? theme.layout.symbolAction,
            weight: resolved.symbolWeight ?? .medium
        )
        if #available(iOS 26, *) {
            // A symbol swap cross-fades through the symbol's own layers; nothing to do before 26.
            let animates = (resolved.animatesSymbolChanges ?? true) && LMKAnimation.shouldAnimate
            config.symbolContentTransition = animates ? UISymbolContentTransition(.replace) : nil
        }

        let appearance = appearance(for: button.state, role: role, variant: variant, tint: tint, theme: theme)
        var foreground = appearance.foreground
        let border = appearance.border
        let shadow = appearance.shadow
        let stateAlpha = appearance.alpha

        switch appearance.background {
        case .clear: config.background.backgroundColor = .clear
        case let .solid(color): config.background.backgroundColor = color ?? .clear
        case .gradient, .blur, .glass: config.background.backgroundColor = .clear
        }
        config.background.backgroundColorTransformer = nil
        if variant == .glass, #available(iOS 26, *) {
            // Glass draws its own material; only the foreground is ours.
        } else if stateAlpha < 1 {
            let alpha = stateAlpha
            config.background.backgroundColorTransformer = UIConfigurationColorTransformer { $0.withAlphaComponent($0.cgColor.alpha * alpha) }
            foreground = foreground.withAlphaComponent(alpha)
        }
        config.baseForegroundColor = foreground
        config.baseBackgroundColor = nil

        if let border, (border.width ?? 1) > 0 {
            config.background.strokeColor = (border.color ?? LMKColor.outline).withAlphaComponent(stateAlpha)
            config.background.strokeWidth = LMKLayout.pixelAligned(border.width ?? Self.outlinedBorderWidth, for: self)
        } else {
            config.background.strokeColor = nil
            config.background.strokeWidth = 0
        }

        let corners = resolved.surface.corners ?? .capsule
        switch corners.radius {
        case .capsule, .circle:
            config.cornerStyle = .capsule
        case .none:
            config.cornerStyle = .fixed
            config.background.cornerRadius = 0
        case let .fixed(radius):
            config.cornerStyle = .fixed
            config.background.cornerRadius = radius
        case let .concentric(minimum):
            config.cornerStyle = .fixed
            config.background.cornerRadius = minimum
        }

        switch shadow {
        case .none:
            config.background.shadowProperties.opacity = 0
        case let .level(level):
            Self.apply(theme.shadow.shadow(for: level).style, to: &config.background.shadowProperties, traits: traitCollection)
        case let .custom(style):
            Self.apply(style, to: &config.background.shadowProperties, traits: traitCollection)
        }

        config.contentInsets = resolved.surface.contentInsets ?? Self.insets(for: size, variant: variant, corners: corners, theme: theme)

        let textStyle = resolved.textStyle ?? Self.textStyle(for: size)
        let font = theme.typography.font(for: textStyle, compatibleWith: traitCollection)
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = font
            return outgoing
        }
        config.indicator = (resolved.showsMenuIndicator ?? false) && button.menu != nil ? .popup : .none
        let indicatorColor = resolved.loadingIndicatorColor ?? foreground
        config.activityIndicatorColorTransformer = UIConfigurationColorTransformer { _ in indicatorColor }

        button.configuration = config
    }

    private func appearance(for state: UIControl.State, role: Role, variant: Variant, tint: UIColor, theme: LMKTheme) -> Appearance {
        let resolved = resolvedStyle
        let filledBackground = role == .neutral && resolved.tintColor == nil ? LMKColor.fill : tint
        let filledForeground = role == .neutral ? LMKColor.textPrimary : LMKColor.onFill(filledBackground, preferred: LMKColor.onAccent)
        var appearance = Appearance(
            background: .clear,
            foreground: resolved.foregroundColor ?? (variant == .filled ? filledForeground : tint),
            border: variant == .outlined ? .solid(tint, width: Self.outlinedBorderWidth) : nil,
            shadow: resolved.surface.shadow ?? .none,
            alpha: 1
        )
        switch variant {
        case .filled: appearance.background = .solid(filledBackground)
        case .tinted: appearance.background = .solid(tint.withAlphaComponent(theme.alpha.xs))
        case .outlined, .ghost, .glass: appearance.background = .clear
        }

        // State overrides: derived defaults, then the style's per-state fields. A filled
        // button shifts the fill it shows (a neutral one is filled in gray, not in its tint).
        let stateBase = variant == .filled ? filledBackground : tint
        if state.contains(.selected) {
            appearance.background = Self.selectedBackground(variant: variant, base: stateBase, theme: theme) ?? appearance.background
            Self.apply(resolved.selected, to: &appearance)
        }
        if state.contains(.highlighted) {
            appearance.background = Self.highlightedBackground(variant: variant, base: stateBase, theme: theme) ?? appearance.background
            Self.apply(resolved.highlighted, to: &appearance)
        }
        if state.contains(.focused) {
            Self.apply(resolved.focused, to: &appearance)
        }
        if state.contains(.disabled) {
            var disabled = resolved.disabled ?? LMKControlStateStyle()
            if disabled.alpha == nil, disabled.background == nil, disabled.foregroundColor == nil {
                disabled.alpha = theme.alpha.disabled
            }
            Self.apply(disabled, to: &appearance)
        }
        // Instance surface fields win over the derived base for background and border.
        if let surfaceBackground = resolved.surface.background {
            appearance.background = surfaceBackground.resolved(against: appearance.background)
        }
        if let surfaceBorder = resolved.surface.border {
            appearance.border = surfaceBorder
        }
        return appearance
    }

    // MARK: - Resolution helpers

    private static let outlinedBorderWidth: CGFloat = 1
    /// Brightness factors for `lmk_stateShade(by:)` (a multiplier): 10% and 15% darker.
    private static let highlightedTintDelta: CGFloat = 0.9
    private static let selectedTintDelta: CGFloat = 0.85

    private static func tint(for role: Role) -> UIColor {
        switch role {
        case .primary: LMKColor.primary
        case .secondary: LMKColor.secondary
        case .tertiary: LMKColor.tertiary
        case .destructive: LMKColor.error
        case .success: LMKColor.success
        case .warning: LMKColor.warning
        case .info: LMKColor.info
        case .neutral: LMKColor.textPrimary
        }
    }

    private static func shifted(_ color: UIColor, by delta: CGFloat) -> UIColor {
        color.lmk_stateShade(by: delta)
    }

    /// `base` is the fill of a filled button, the tint of every other variant.
    private static func highlightedBackground(variant: Variant, base: UIColor, theme: LMKTheme) -> LMKBackgroundStyle? {
        switch variant {
        case .filled: .solid(shifted(base, by: highlightedTintDelta))
        case .tinted: .solid(base.withAlphaComponent(theme.alpha.small))
        case .outlined, .ghost: .solid(base.withAlphaComponent(theme.alpha.xxs))
        case .glass: nil
        }
    }

    /// `base` is the fill of a filled button, the tint of every other variant.
    private static func selectedBackground(variant: Variant, base: UIColor, theme: LMKTheme) -> LMKBackgroundStyle? {
        switch variant {
        case .filled: .solid(shifted(base, by: selectedTintDelta))
        case .tinted: .solid(base.withAlphaComponent(theme.alpha.medium))
        case .outlined, .ghost: .solid(base.withAlphaComponent(theme.alpha.xs))
        case .glass: nil
        }
    }

    private static func apply(_ state: LMKControlStateStyle?, to appearance: inout Appearance) {
        guard let state else { return }
        if let value = state.background { appearance.background = value }
        if let value = state.foregroundColor { appearance.foreground = value }
        if let value = state.border { appearance.border = value }
        if let value = state.shadow { appearance.shadow = value }
        if let value = state.alpha { appearance.alpha = min(appearance.alpha, value) }
    }

    private static func apply(_ style: LMKShadowStyle, to properties: inout UIShadowProperties, traits: UITraitCollection) {
        properties.color = style.color.resolvedColor(with: traits)
        properties.opacity = CGFloat(style.opacity)
        properties.radius = style.radius
        properties.offset = style.offset
    }

    private static func insets(for size: Size, variant: Variant, corners: LMKCornerStyle, theme: LMKTheme) -> NSDirectionalEdgeInsets {
        if case .circle = corners.radius {
            return .lmk_all(theme.spacing.small)
        }
        switch (variant, size) {
        case (.ghost, .small): return .lmk_symmetric(vertical: theme.spacing.xxs, horizontal: theme.spacing.xs)
        case (.ghost, .medium): return .lmk_symmetric(vertical: theme.spacing.xs, horizontal: theme.spacing.small)
        case (.ghost, .large): return .lmk_symmetric(vertical: theme.spacing.small, horizontal: theme.spacing.medium)
        case (_, .small): return .lmk_symmetric(vertical: theme.spacing.xs, horizontal: theme.spacing.medium)
        case (_, .medium): return .lmk_symmetric(vertical: theme.spacing.buttonPaddingVertical, horizontal: theme.spacing.buttonPaddingHorizontal)
        case (_, .large): return .lmk_symmetric(vertical: theme.spacing.large, horizontal: theme.spacing.xl)
        }
    }

    private static func textStyle(for size: Size) -> LMKTextStyle {
        switch size {
        case .small: .captionMedium
        case .medium: .bodyMedium
        case .large: .h4
        }
    }

    // MARK: - Interaction

    override open func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        guard isEnabled, !isHidden else { return false }
        let minimum = minimumHitTarget ?? traitCollection.lmkTheme.layout.minimumTouchTarget
        return lmk_hitTestBounds(minimumSide: minimum, insets: lmk_hitTestInsets).contains(point)
    }

    @objc private func handleTouchDown() {
        if resolvedStyle.haptics ?? true {
            LMKHaptics.medium()
        }
        guard resolvedStyle.pressAnimation ?? true, LMKAnimation.shouldAnimate else { return }
        LMKAnimation.animateButtonPressDown(self)
    }

    @objc private func handleTouchUp() {
        guard resolvedStyle.pressAnimation ?? true, LMKAnimation.shouldAnimate else { return }
        LMKAnimation.animateButtonPressUp(self)
    }

    /// Runs the tap: flips a toggle, then calls `onTap`.
    @objc open func didTap() {
        if isToggle {
            isSelected.toggle()
            onValueChange?(isSelected)
        }
        onTap?()
    }

    /// Constrains the title to a single line that shrinks to fit the available width.
    /// - Parameter minimumScaleFactor: Smallest fraction the font will shrink to (default 0.7).
    @discardableResult
    public func shrinkingTitleToFit(minimumScaleFactor: CGFloat = 0.7) -> Self {
        configuration?.titleLineBreakMode = .byTruncatingTail
        titleLabel?.numberOfLines = 1
        titleLabel?.adjustsFontSizeToFitWidth = true
        titleLabel?.minimumScaleFactor = minimumScaleFactor
        return self
    }
}

public nonisolated extension LMKTheme {
    /// App-wide default style for `LMKButton`.
    var button: LMKButton.Style {
        get { self[LMKButton.Style.self] }
        set { self[LMKButton.Style.self] = newValue }
    }
}
