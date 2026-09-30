//
//  LMKChipView.swift
//  LumiKit
//
//  Tag / filter chip: a small capsule control with optional icon and dismiss
//  button, filled, tinted, or outlined, with selected, pressed, and disabled states.
//

import SnapKit
import UIKit

/// Small tag/chip for categories, filters, or labels.
///
/// Three interaction modes:
/// - **Display-only**: no handlers set; a static label.
/// - **Tappable**: set `onTap`.
/// - **Dismissible**: set `onDismiss` to show an xmark button.
///
/// `isSelected` renders the selected appearance (`Style.selectedVariant`, filled
/// by default); `isEnabled` dims the chip and ignores taps. A chip that toggles reads best
/// tinted or outlined while off: the full tint is then the selected look.
///
/// ```swift
/// let chip = LMKChipView(text: "Design", style: .filled)
/// let filter = LMKChipView(text: "Category", style: .outlined)
/// filter.onDismiss = { print("removed") }
/// let toggle = LMKChipView(text: "Active", style: .tinted)
/// toggle.onTap = { toggle.isSelected.toggle() }
/// ```
public final class LMKChipView: UIControl, LMKThemeApplying {
    // MARK: - Variant

    /// The chip's fill.
    public nonisolated enum Variant: Sendable, Hashable, CaseIterable {
        /// The full tint as background, with contrasting text.
        case filled
        /// A soft wash of the tint as background, with text in the tint.
        case tinted
        /// Tinted border and text on a clear background.
        case outlined
    }

    // MARK: - Style

    public nonisolated struct Style: Sendable, Equatable, LMKThemeExtension {
        /// Fill of the unselected chip; `nil` = filled.
        public var variant: Variant?
        /// Fill of the selected chip; `nil` = filled.
        public var selectedVariant: Variant?
        /// Background (filled), wash and text (tinted), or border and text (outlined); `nil` = `primary`.
        public var tintColor: UIColor?
        /// Text and glyph color; `nil` = `onAccent` on a filled chip, the tint otherwise.
        public var foregroundColor: UIColor?
        /// Corners (default capsule), border (outlined: tint, 1.5pt), insets (xs / medium).
        public var surface: LMKSurfaceStyle
        /// `nil` = `captionMedium`.
        public var textStyle: LMKTextStyle?
        /// `nil` = `iconExtraSmall`.
        public var iconSize: CGFloat?
        /// Gap between icon, title, and dismiss button; `nil` = `xs`.
        public var iconSpacing: CGFloat?
        /// `nil` = "xmark".
        public var dismissSymbol: String?
        /// Side of the dismiss button; `nil` = `xl`.
        public var dismissButtonSize: CGFloat?
        /// Haptic on tap and dismiss; `nil` = yes.
        public var haptics: Bool?
        /// Pressed look; unset, a filled chip shades its fill and the others wash in the tint.
        public var highlighted: LMKControlStateStyle?
        /// Selected look, over `selectedVariant`; unset, a chip filled in both states shades its fill.
        public var selected: LMKControlStateStyle?
        public var disabled: LMKControlStateStyle?

        public init(
            variant: Variant? = nil,
            selectedVariant: Variant? = nil,
            tintColor: UIColor? = nil,
            foregroundColor: UIColor? = nil,
            surface: LMKSurfaceStyle = LMKSurfaceStyle(),
            textStyle: LMKTextStyle? = nil,
            iconSize: CGFloat? = nil,
            iconSpacing: CGFloat? = nil,
            dismissSymbol: String? = nil,
            dismissButtonSize: CGFloat? = nil,
            haptics: Bool? = nil,
            highlighted: LMKControlStateStyle? = nil,
            selected: LMKControlStateStyle? = nil,
            disabled: LMKControlStateStyle? = nil
        ) {
            self.variant = variant
            self.selectedVariant = selectedVariant
            self.tintColor = tintColor
            self.foregroundColor = foregroundColor
            self.surface = surface
            self.textStyle = textStyle
            self.iconSize = iconSize
            self.iconSpacing = iconSpacing
            self.dismissSymbol = dismissSymbol
            self.dismissButtonSize = dismissButtonSize
            self.haptics = haptics
            self.highlighted = highlighted
            self.selected = selected
            self.disabled = disabled
        }

        public static let defaultValue = Self()
        public static let filled = Self(variant: .filled)
        public static let tinted = Self(variant: .tinted)
        public static let outlined = Self(variant: .outlined)

        /// A copy tinted with `color`.
        public func tint(_ color: UIColor) -> Self {
            var copy = self
            copy.tintColor = color
            return copy
        }

        /// `other`'s non-nil fields over this style's.
        public func merging(_ other: Self) -> Self {
            Self(
                variant: other.variant ?? variant,
                selectedVariant: other.selectedVariant ?? selectedVariant,
                tintColor: other.tintColor ?? tintColor,
                foregroundColor: other.foregroundColor ?? foregroundColor,
                surface: surface.merging(other.surface),
                textStyle: other.textStyle ?? textStyle,
                iconSize: other.iconSize ?? iconSize,
                iconSpacing: other.iconSpacing ?? iconSpacing,
                dismissSymbol: other.dismissSymbol ?? dismissSymbol,
                dismissButtonSize: other.dismissButtonSize ?? dismissButtonSize,
                haptics: other.haptics ?? haptics,
                highlighted: LMKControlStateStyle.merge(highlighted, other.highlighted),
                selected: LMKControlStateStyle.merge(selected, other.selected),
                disabled: LMKControlStateStyle.merge(disabled, other.disabled)
            )
        }
    }

    // MARK: - Strings

    public nonisolated struct Strings: Sendable, Equatable {
        /// Name of the VoiceOver custom action that removes a dismissible chip.
        public var dismissAccessibilityLabel: String

        public init(dismissAccessibilityLabel: String = LMKLocalized("chip.dismiss.accessibilityLabel")) {
            self.dismissAccessibilityLabel = dismissAccessibilityLabel
        }
    }

    /// Process-wide defaults; set at app launch to override.
    public nonisolated(unsafe) static var strings = Strings()

    /// Per-instance strings (default `Self.strings`).
    public var strings: Strings = LMKChipView.strings {
        didSet {
            dismissButton.accessibilityLabel = strings.dismissAccessibilityLabel
            updateAccessibility()
        }
    }

    // MARK: - Subviews

    public let titleLabel = UILabel()
    public let iconView = UIImageView()
    public let dismissButton: UIButton = LMKChipDismissButton(type: .system)
    public let contentStack = UIStackView()

    // MARK: - Content

    /// Chip text (also the accessibility label).
    public var text: String? {
        didSet {
            titleLabel.text = text
            updateAccessibility()
        }
    }

    /// Optional leading icon.
    public var icon: UIImage? {
        didSet {
            iconView.image = icon
            iconView.isHidden = icon == nil
        }
    }

    /// Per-instance style; `nil` fields resolve from `theme.chip`, then the built-in look.
    public var style: Style {
        didSet {
            guard style != oldValue else { return }
            applyTheme(traitCollection.lmkTheme)
        }
    }

    /// Tap handler. With neither this nor `onDismiss`, the chip is a display-only label.
    public var onTap: (() -> Void)? {
        didSet { updateAccessibility() }
    }

    /// Dismiss handler; when set, an xmark button appears on the trailing edge.
    public var onDismiss: (() -> Void)? {
        didSet {
            dismissButton.isHidden = onDismiss == nil
            updateAccessibility()
        }
    }

    /// Called at the end of every `applyTheme`, for tweaks the style does not cover.
    public var didApplyStyle: ((LMKChipView) -> Void)?

    override public var isSelected: Bool {
        didSet {
            guard isSelected != oldValue else { return }
            applyTheme(traitCollection.lmkTheme)
            updateAccessibility()
        }
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
            dismissButton.isEnabled = isEnabled
            applyTheme(traitCollection.lmkTheme)
            updateAccessibility()
        }
    }

    private var iconSizeConstraint: Constraint?
    private var dismissSizeConstraint: Constraint?
    private var contentInsetsConstraint: Constraint?
    private var isInteractive: Bool { onTap != nil || onDismiss != nil }

    // MARK: - Initialization

    public init(text: String, icon: UIImage? = nil, style: Style = Style()) {
        self.style = style
        super.init(frame: .zero)
        setupUI()
        self.text = text
        titleLabel.text = text
        self.icon = icon
        iconView.image = icon
        iconView.isHidden = icon == nil
        updateAccessibility()
        lmk_startApplyingTheme()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI() {
        iconView.contentMode = .scaleAspectFit
        iconView.isHidden = true
        iconView.snp.makeConstraints { make in
            iconSizeConstraint = make.width.height.equalTo(0).constraint
        }

        titleLabel.textAlignment = .center

        dismissButton.isHidden = true
        dismissButton.addTarget(self, action: #selector(didDismiss), for: .touchUpInside)
        dismissButton.snp.makeConstraints { make in
            dismissSizeConstraint = make.width.height.equalTo(0).constraint
        }

        contentStack.axis = .horizontal
        contentStack.alignment = .center
        contentStack.isUserInteractionEnabled = true
        contentStack.addArrangedSubview(iconView)
        contentStack.addArrangedSubview(titleLabel)
        contentStack.addArrangedSubview(dismissButton)
        addSubview(contentStack)
        contentStack.snp.makeConstraints { make in
            contentInsetsConstraint = make.edges.equalToSuperview().constraint
        }
        titleLabel.isUserInteractionEnabled = false
        iconView.isUserInteractionEnabled = false

        addTarget(self, action: #selector(didTap), for: .touchUpInside)
        isAccessibilityElement = true
        accessibilityTraits = .staticText
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        lmk_layoutSurfaceIfNeeded()
    }

    override public func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        guard isInteractive, isEnabled, !isHidden else { return bounds.contains(point) }
        return lmk_hitTestBounds(minimumSide: traitCollection.lmkTheme.layout.minimumTouchTarget, insets: lmk_hitTestInsets).contains(point)
    }

    /// The chip claims every touch except the ones on its dismiss button: a touch that lands on
    /// the content stack and reaches the chip through the responder chain never starts control
    /// tracking, so `touchUpInside` would not fire.
    override public func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard isUserInteractionEnabled, !isHidden, alpha > 0.01, self.point(inside: point, with: event) else { return nil }
        if !dismissButton.isHidden, let hit = dismissButton.hitTest(convert(point, to: dismissButton), with: event) {
            return hit
        }
        return self
    }

    // MARK: - Configuration

    /// Sets the text and optional icon.
    public func configure(text: String, icon: UIImage? = nil) {
        self.text = text
        self.icon = icon
    }

    // MARK: - Theme

    public func applyTheme(_ theme: LMKTheme) {
        let resolved = theme.chip.merging(style)
        let baseVariant = resolved.variant ?? .filled
        let variant = isSelected ? (resolved.selectedVariant ?? .filled) : baseVariant
        let tint = resolved.tintColor ?? LMKColor.primary
        var foreground = resolved.foregroundColor ?? (variant == .filled ? LMKColor.onFill(tint, preferred: LMKColor.onAccent) : tint)

        var background = Self.background(for: variant, tint: tint, theme: theme)
        var border: LMKBorderStyle? = variant == .outlined ? .solid(tint, width: Self.outlinedBorderWidth) : nil
        var shadow: LMKShadowSource?
        var stateAlpha: CGFloat = 1
        var scale: CGFloat = 1

        // Selected: a distinct fill. A chip that is filled in both states shades its tint.
        if isSelected {
            if baseVariant == .filled, variant == .filled, resolved.selected?.background == nil {
                background = .solid(tint.lmk_stateShade(by: Self.selectedTintDelta))
            }
            apply(resolved.selected, to: &background, &foreground, &border, &shadow, &stateAlpha, &scale)
        }
        if isHighlighted {
            let highlighted = resolved.highlighted ?? LMKControlStateStyle()
            if highlighted.alpha == nil, highlighted.background == nil {
                background = Self.highlightedBackground(over: background, variant: variant, tint: tint, theme: theme)
            }
            apply(highlighted, to: &background, &foreground, &border, &shadow, &stateAlpha, &scale)
        }
        if !isEnabled {
            var disabled = resolved.disabled ?? LMKControlStateStyle()
            if disabled.alpha == nil { disabled.alpha = theme.alpha.disabled }
            apply(disabled, to: &background, &foreground, &border, &shadow, &stateAlpha, &scale)
        }

        let defaults = LMKSurfaceStyle(
            background: background,
            corners: .capsule,
            border: border,
            shadow: shadow ?? LMKShadowSource.none,
            contentInsets: .lmk_symmetric(vertical: theme.spacing.xs, horizontal: theme.spacing.medium)
        )
        var surface = resolved.surface
        if isSelected || isHighlighted || !isEnabled {
            // State overrides win over the instance surface for the fields they set.
            if resolved.selected?.background != nil || resolved.highlighted?.background != nil || resolved.disabled?.background != nil { surface.background = background }
            if resolved.selected?.border != nil || resolved.highlighted?.border != nil || resolved.disabled?.border != nil { surface.border = border }
        }
        if isHighlighted, resolved.highlighted?.background == nil, resolved.highlighted?.alpha == nil, let own = surface.background {
            // The derived pressed shade applies to an instance background too.
            surface.background = Self.highlightedBackground(over: own.resolved(against: background), variant: variant, tint: tint, theme: theme)
        }
        let applied = lmk_apply(surface: surface, defaults: defaults)
        alpha = stateAlpha
        transform = scale == 1 ? .identity : CGAffineTransform(scaleX: scale, y: scale)

        titleLabel.lmk_apply(resolved.textStyle ?? .captionMedium, color: foreground)
        iconView.tintColor = foreground
        dismissButton.tintColor = foreground
        // The Mac idiom derives no label from the symbol; VoiceOver needs the localized one everywhere.
        dismissButton.accessibilityLabel = strings.dismissAccessibilityLabel
        let symbolSize = theme.layout.symbolMicro
        dismissButton.setImage(UIImage(systemName: resolved.dismissSymbol ?? "xmark", withConfiguration: UIImage.SymbolConfiguration(pointSize: symbolSize, weight: .bold)), for: .normal)

        iconSizeConstraint?.update(offset: resolved.iconSize ?? theme.layout.iconExtraSmall)
        dismissSizeConstraint?.update(offset: resolved.dismissButtonSize ?? theme.spacing.xl)
        contentStack.spacing = resolved.iconSpacing ?? theme.spacing.xs
        let insets = applied.contentInsets ?? .lmk_symmetric(vertical: theme.spacing.xs, horizontal: theme.spacing.medium)
        contentInsetsConstraint?.update(inset: UIEdgeInsets(top: insets.top, left: insets.leading, bottom: insets.bottom, right: insets.trailing))
        (dismissButton as? LMKChipDismissButton)?.minimumTarget = theme.layout.minimumTouchTarget
        invalidateIntrinsicContentSize()
        didApplyStyle?(self)
    }

    private static let outlinedBorderWidth: CGFloat = 1.5
    /// Brightness factors for `lmk_stateShade(by:)` (a multiplier): 25% and 15% darker.
    private static let selectedTintDelta: CGFloat = 0.75
    private static let highlightedTintDelta: CGFloat = 0.85

    /// The resting background of a variant.
    static func background(for variant: Variant, tint: UIColor, theme: LMKTheme) -> LMKBackgroundStyle {
        switch variant {
        case .filled: .solid(tint)
        case .tinted: .solid(tint.withAlphaComponent(theme.alpha.xs))
        case .outlined: .clear
        }
    }

    /// The pressed background: a solid fill shades itself; a wash or a clear chip takes a
    /// stronger wash of the tint.
    static func highlightedBackground(over background: LMKBackgroundStyle, variant: Variant, tint: UIColor, theme: LMKTheme) -> LMKBackgroundStyle {
        switch variant {
        case .filled:
            if case let .solid(color) = background, let color {
                return .solid(color.lmk_stateShade(by: highlightedTintDelta))
            }
            return .solid(tint.lmk_stateShade(by: highlightedTintDelta))
        case .tinted:
            return .solid(tint.withAlphaComponent(theme.alpha.medium))
        case .outlined:
            return .solid(tint.withAlphaComponent(theme.alpha.xs))
        }
    }

    // swiftlint:disable:next function_parameter_count
    private func apply(
        _ state: LMKControlStateStyle?,
        to background: inout LMKBackgroundStyle,
        _ foreground: inout UIColor,
        _ border: inout LMKBorderStyle?,
        _ shadow: inout LMKShadowSource?,
        _ alpha: inout CGFloat,
        _ scale: inout CGFloat
    ) {
        guard let state else { return }
        if let value = state.background { background = value }
        if let value = state.foregroundColor { foreground = value }
        if let value = state.border { border = value }
        if let value = state.shadow { shadow = value }
        if let value = state.alpha { alpha = min(alpha, value) }
        if let value = state.scale { scale = value }
    }

    // MARK: - Actions

    /// Runs the tap handler (with its haptic) as a user tap would.
    @objc func didTap() {
        guard let onTap, isEnabled else { return }
        if theme.chip.merging(style).haptics ?? true { LMKHaptics.light() }
        onTap()
    }

    /// Runs the dismiss handler as a tap on the xmark would.
    @objc func didDismiss() {
        guard isEnabled else { return }
        if theme.chip.merging(style).haptics ?? true { LMKHaptics.light() }
        onDismiss?()
    }

    private var theme: LMKTheme { traitCollection.lmkTheme }

    // MARK: - Accessibility

    private func updateAccessibility() {
        accessibilityLabel = text
        var traits: UIAccessibilityTraits = isInteractive ? .button : .staticText
        if isSelected { traits.insert(.selected) }
        if !isEnabled { traits.insert(.notEnabled) }
        accessibilityTraits = traits
        if onDismiss != nil {
            accessibilityCustomActions = [
                UIAccessibilityCustomAction(name: strings.dismissAccessibilityLabel, target: self, selector: #selector(didDismiss)),
            ]
        } else {
            accessibilityCustomActions = nil
        }
    }
}

/// The xmark button: a glyph-sized view with a full-size hit target.
private final class LMKChipDismissButton: UIButton {
    var minimumTarget: CGFloat = 44

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        guard isEnabled, !isHidden else { return false }
        return lmk_hitTestBounds(minimumSide: minimumTarget).contains(point)
    }
}

public nonisolated extension LMKTheme {
    /// App-wide default style for `LMKChipView`.
    var chip: LMKChipView.Style {
        get { self[LMKChipView.Style.self] }
        set { self[LMKChipView.Style.self] = newValue }
    }
}
