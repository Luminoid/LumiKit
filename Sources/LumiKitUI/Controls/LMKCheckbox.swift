//
//  LMKCheckbox.swift
//  LumiKit
//
//  Checkbox control: a symbol that toggles between checked and unchecked,
//  with a 44pt hit target and a symbol content transition on every supported OS.
//

import UIKit

/// Checkbox.
///
/// ```swift
/// let checkbox = LMKCheckbox()
/// checkbox.onValueChange = { isChecked in item.isDone = isChecked }
/// checkbox.setChecked(true, animated: true)
/// ```
public final class LMKCheckbox: UIControl, LMKThemeApplying {
    // MARK: - Style

    public nonisolated struct Style: Sendable, Equatable, LMKThemeExtension {
        /// `nil` = "checkmark.circle.fill".
        public var onSymbol: String?
        /// `nil` = "circle".
        public var offSymbol: String?
        /// `nil` = `success`.
        public var onColor: UIColor?
        /// `nil` = `primary`.
        public var offColor: UIColor?
        /// `nil` = `iconMedium`.
        public var glyphSize: CGFloat?
        /// Symbol weight; `nil` = `.regular`.
        public var symbolWeight: UIImage.SymbolWeight?
        /// Haptic on toggle; `nil` = yes.
        public var haptics: Bool?
        public var highlighted: LMKControlStateStyle?
        public var disabled: LMKControlStateStyle?

        public init(
            onSymbol: String? = nil,
            offSymbol: String? = nil,
            onColor: UIColor? = nil,
            offColor: UIColor? = nil,
            glyphSize: CGFloat? = nil,
            symbolWeight: UIImage.SymbolWeight? = nil,
            haptics: Bool? = nil,
            highlighted: LMKControlStateStyle? = nil,
            disabled: LMKControlStateStyle? = nil
        ) {
            self.onSymbol = onSymbol
            self.offSymbol = offSymbol
            self.onColor = onColor
            self.offColor = offColor
            self.glyphSize = glyphSize
            self.symbolWeight = symbolWeight
            self.haptics = haptics
            self.highlighted = highlighted
            self.disabled = disabled
        }

        public static let defaultValue = Self()

        /// `other`'s non-nil fields over this style's.
        public func merging(_ other: Self) -> Self {
            Self(
                onSymbol: other.onSymbol ?? onSymbol,
                offSymbol: other.offSymbol ?? offSymbol,
                onColor: other.onColor ?? onColor,
                offColor: other.offColor ?? offColor,
                glyphSize: other.glyphSize ?? glyphSize,
                symbolWeight: other.symbolWeight ?? symbolWeight,
                haptics: other.haptics ?? haptics,
                highlighted: LMKControlStateStyle.merge(highlighted, other.highlighted),
                disabled: LMKControlStateStyle.merge(disabled, other.disabled)
            )
        }
    }

    // MARK: - Strings

    public nonisolated struct Strings: Sendable, Equatable {
        public var onAccessibilityValue: String
        public var offAccessibilityValue: String

        public init(
            onAccessibilityValue: String = LMKLocalized("checkbox.on.accessibilityValue"),
            offAccessibilityValue: String = LMKLocalized("checkbox.off.accessibilityValue")
        ) {
            self.onAccessibilityValue = onAccessibilityValue
            self.offAccessibilityValue = offAccessibilityValue
        }
    }

    /// Process-wide defaults; set at app launch to override.
    public nonisolated(unsafe) static var strings = Strings()

    /// Per-instance strings (default `Self.strings`).
    public var strings: Strings = LMKCheckbox.strings {
        didSet { updateAccessibility() }
    }

    // MARK: - Public API

    /// Whether the box is checked. Setting it is silent (no handler, no `.valueChanged`) and
    /// not animated; `setChecked(_:animated:)` cross-fades the symbol.
    public var isChecked: Bool {
        get { storedIsChecked }
        set { setChecked(newValue, animated: false) }
    }

    /// Called when the user toggles the box.
    public var onValueChange: ((Bool) -> Void)?

    /// Per-instance style; `nil` fields resolve from `theme.checkbox`, then the built-in look.
    public var style: Style {
        didSet {
            guard style != oldValue else { return }
            applyTheme(traitCollection.lmkTheme)
        }
    }

    /// Called at the end of every `applyTheme`, for tweaks the style does not cover.
    public var didApplyStyle: ((LMKCheckbox) -> Void)?

    public let glyphView = UIImageView()

    /// Sets the checked state (silent), animating the symbol swap when possible.
    public func setChecked(_ checked: Bool, animated: Bool) {
        guard checked != storedIsChecked else { return }
        storedIsChecked = checked
        updateGlyph(animated: animated)
        updateAccessibility()
    }

    private var storedIsChecked = false
    private var resolved = Style()
    private var glyphSize: CGFloat { resolved.glyphSize ?? traitCollection.lmkTheme.layout.iconMedium }

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
        glyphView.contentMode = .scaleAspectFit
        glyphView.isUserInteractionEnabled = false
        addSubview(glyphView)
        addTarget(self, action: #selector(handleTap), for: .touchUpInside)
        addInteraction(UIPointerInteraction(delegate: self))
        setContentHuggingPriority(.required, for: .horizontal)
        setContentHuggingPriority(.required, for: .vertical)
        isAccessibilityElement = true
        updateAccessibility()
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        glyphView.frame = bounds
    }

    override public var intrinsicContentSize: CGSize {
        CGSize(width: glyphSize, height: glyphSize)
    }

    /// A disabled box absorbs a touch inside its bounds, like every UIKit control; an enabled one answers the minimum touch target.
    override public func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        guard !isHidden else { return false }
        guard isEnabled else { return bounds.contains(point) }
        return lmk_hitTestBounds(minimumSide: traitCollection.lmkTheme.layout.minimumTouchTarget, insets: lmk_hitTestInsets).contains(point)
    }

    override public var isEnabled: Bool {
        didSet {
            guard isEnabled != oldValue else { return }
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

    // MARK: - Theme

    public func applyTheme(_ theme: LMKTheme) {
        resolved = theme.checkbox.merging(style)
        var stateAlpha: CGFloat = 1
        if isHighlighted { stateAlpha = min(stateAlpha, resolved.highlighted?.alpha ?? theme.alpha.xl) }
        if !isEnabled { stateAlpha = min(stateAlpha, resolved.disabled?.alpha ?? theme.alpha.disabled) }
        alpha = stateAlpha
        glyphView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: glyphSize, weight: resolved.symbolWeight ?? .regular)
        updateGlyph(animated: false)
        invalidateIntrinsicContentSize()
        didApplyStyle?(self)
    }

    private func updateGlyph(animated: Bool) {
        let name = isChecked ? (resolved.onSymbol ?? "checkmark.circle.fill") : (resolved.offSymbol ?? "circle")
        var color = isChecked ? (resolved.onColor ?? LMKColor.success) : (resolved.offColor ?? LMKColor.primary)
        if isHighlighted, let highlighted = resolved.highlighted?.foregroundColor { color = highlighted }
        if !isEnabled, let disabled = resolved.disabled?.foregroundColor { color = disabled }
        glyphView.tintColor = color
        let image = UIImage(systemName: name)
        // Set the image directly, never via a cross-dissolve: a reused cell would animate from
        // whatever glyph it last held, flashing a checkmark on unrelated rows.
        if animated, LMKAnimation.shouldAnimate, let image {
            glyphView.setSymbolImage(image, contentTransition: .replace)
        } else {
            glyphView.image = image
        }
    }

    // MARK: - Actions

    @objc private func handleTap() {
        guard isEnabled else { return }
        setChecked(!isChecked, animated: true)
        if resolved.haptics ?? true { LMKHaptics.light() }
        onValueChange?(isChecked)
        sendActions(for: .valueChanged)
    }

    // MARK: - Accessibility

    private func updateAccessibility() {
        accessibilityValue = isChecked ? strings.onAccessibilityValue : strings.offAccessibilityValue
        var traits: UIAccessibilityTraits = [.button, .toggleButton]
        if isChecked { traits.insert(.selected) }
        if !isEnabled { traits.insert(.notEnabled) }
        accessibilityTraits = traits
    }
}

// MARK: - UIPointerInteractionDelegate

extension LMKCheckbox: UIPointerInteractionDelegate {
    public func pointerInteraction(_: UIPointerInteraction, styleFor _: UIPointerRegion) -> UIPointerStyle? {
        LMKPointerStyle.hover(for: self)
    }
}

public nonisolated extension LMKTheme {
    /// App-wide default style for `LMKCheckbox`.
    var checkbox: LMKCheckbox.Style {
        get { self[LMKCheckbox.Style.self] }
        set { self[LMKCheckbox.Style.self] = newValue }
    }
}
