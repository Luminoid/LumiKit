//
//  LMKSwitch.swift
//  LumiKit
//
//  Toggle switch: a rounded track with a sliding thumb, spring animation,
//  haptic, and a 44pt hit target.
//

import UIKit

/// Toggle switch replacing `UISwitch`.
///
/// ```swift
/// let toggle = LMKSwitch()
/// toggle.onValueChange = { isOn in print("Toggle: \(isOn)") }
/// ```
public final class LMKSwitch: UIControl, LMKThemeApplying {
    // MARK: - Style

    public nonisolated struct Style: Sendable, Equatable, LMKThemeExtension {
        /// `nil` = `primary`.
        public var onTint: UIColor?
        /// `nil` = `fill`.
        public var offTint: UIColor?
        /// `nil` = `onAccent`.
        public var thumbTint: UIColor?
        /// `nil` = 52 × 30.
        public var trackSize: CGSize?
        /// `nil` = 2.
        public var thumbInset: CGFloat?
        /// `nil` = `level1`.
        public var thumbShadow: LMKShadowSource?
        /// Haptic on toggle; `nil` = yes.
        public var haptics: Bool?
        public var highlighted: LMKControlStateStyle?
        public var disabled: LMKControlStateStyle?

        public init(
            onTint: UIColor? = nil,
            offTint: UIColor? = nil,
            thumbTint: UIColor? = nil,
            trackSize: CGSize? = nil,
            thumbInset: CGFloat? = nil,
            thumbShadow: LMKShadowSource? = nil,
            haptics: Bool? = nil,
            highlighted: LMKControlStateStyle? = nil,
            disabled: LMKControlStateStyle? = nil
        ) {
            self.onTint = onTint
            self.offTint = offTint
            self.thumbTint = thumbTint
            self.trackSize = trackSize
            self.thumbInset = thumbInset
            self.thumbShadow = thumbShadow
            self.haptics = haptics
            self.highlighted = highlighted
            self.disabled = disabled
        }

        public static let defaultValue = Self()

        /// `other`'s non-nil fields over this style's.
        public func merging(_ other: Self) -> Self {
            Self(
                onTint: other.onTint ?? onTint,
                offTint: other.offTint ?? offTint,
                thumbTint: other.thumbTint ?? thumbTint,
                trackSize: other.trackSize ?? trackSize,
                thumbInset: other.thumbInset ?? thumbInset,
                thumbShadow: other.thumbShadow ?? thumbShadow,
                haptics: other.haptics ?? haptics,
                highlighted: LMKControlStateStyle.merge(highlighted, other.highlighted),
                disabled: LMKControlStateStyle.merge(disabled, other.disabled)
            )
        }
    }

    // MARK: - Strings

    public nonisolated struct Strings: Sendable, Equatable {
        /// VoiceOver value while the switch is on.
        public var onAccessibilityValue: String
        /// VoiceOver value while the switch is off.
        public var offAccessibilityValue: String

        public init(
            onAccessibilityValue: String = LMKLocalized("switch.on.accessibilityValue"),
            offAccessibilityValue: String = LMKLocalized("switch.off.accessibilityValue")
        ) {
            self.onAccessibilityValue = onAccessibilityValue
            self.offAccessibilityValue = offAccessibilityValue
        }
    }

    /// Process-wide defaults; set at app launch to override.
    public nonisolated(unsafe) static var strings = Strings()

    /// Per-instance strings (default `Self.strings`).
    public var strings: Strings = LMKSwitch.strings {
        didSet { updateAccessibilityValue() }
    }

    // MARK: - Public API

    /// Whether the toggle is on. Setting it is silent (no handler, no `.valueChanged`) and
    /// not animated; `setOn(_:animated:)` slides the thumb.
    public var isOn: Bool {
        get { storedIsOn }
        set { setOn(newValue, animated: false) }
    }

    /// Called when the user toggles the switch.
    public var onValueChange: ((Bool) -> Void)?

    /// Per-instance style; `nil` fields resolve from `theme.switch`, then the built-in look.
    public var style: Style {
        didSet {
            guard style != oldValue else { return }
            applyTheme(traitCollection.lmkTheme)
        }
    }

    /// Called at the end of every `applyTheme`, for tweaks the style does not cover.
    public var didApplyStyle: ((LMKSwitch) -> Void)?

    public let trackView = UIView()
    public let thumbView = UIView()

    /// Sets the state (silent), sliding the thumb and cross-fading the track when `animated`.
    public func setOn(_ on: Bool, animated: Bool) {
        guard on != storedIsOn else { return }
        storedIsOn = on
        updateAppearance(animated: animated)
        updateAccessibilityValue()
    }

    private var storedIsOn = false
    private var resolved = Style()
    private var trackSize: CGSize { resolved.trackSize ?? Self.defaultTrackSize }
    private var thumbInset: CGFloat { resolved.thumbInset ?? Self.defaultThumbInset }
    private static let defaultTrackSize = CGSize(width: 52, height: 30)
    private static let defaultThumbInset: CGFloat = 2

    // MARK: - Initialization

    public init(style: Style = Style()) {
        self.style = style
        super.init(frame: CGRect(origin: .zero, size: Self.defaultTrackSize))
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

    // MARK: - Intrinsic Size

    override public var intrinsicContentSize: CGSize { trackSize }

    override public func sizeThatFits(_ size: CGSize) -> CGSize {
        intrinsicContentSize
    }

    // MARK: - Setup

    private func setupUI() {
        trackView.isUserInteractionEnabled = false
        addSubview(trackView)
        thumbView.isUserInteractionEnabled = false
        addSubview(thumbView)

        // The track renders at whatever frame the layout resolves, so a stack view must never
        // stretch or squeeze this control: required priorities pin it to its intrinsic size.
        setContentHuggingPriority(.required, for: .horizontal)
        setContentHuggingPriority(.required, for: .vertical)
        setContentCompressionResistancePriority(.required, for: .horizontal)
        setContentCompressionResistancePriority(.required, for: .vertical)

        addTarget(self, action: #selector(handleTap), for: .touchUpInside)
        addInteraction(UIPointerInteraction(delegate: self))

        isAccessibilityElement = true
        updateAccessibilityTraits()
        updateAccessibilityValue()
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        trackView.frame = bounds
        trackView.lmk_layoutCornersIfNeeded()
        updateThumbPosition()
        thumbView.lmk_layoutCornersIfNeeded()
    }

    /// A disabled switch absorbs a touch inside its bounds, like `UISwitch`; an enabled one answers the minimum touch target.
    override public func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        guard !isHidden else { return false }
        guard isEnabled else { return bounds.contains(point) }
        return lmk_hitTestBounds(minimumSide: traitCollection.lmkTheme.layout.minimumTouchTarget, insets: lmk_hitTestInsets).contains(point)
    }

    override public var isEnabled: Bool {
        didSet {
            guard isEnabled != oldValue else { return }
            applyTheme(traitCollection.lmkTheme)
            updateAccessibilityTraits()
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
        resolved = theme.switch.merging(style)
        trackView.lmk_applyCornerStyle(.capsule)
        thumbView.backgroundColor = resolved.thumbTint ?? LMKColor.onAccent
        thumbView.lmk_applyCornerStyle(.circle, masking: false)
        switch resolved.thumbShadow ?? .level(.level1) {
        case .hidden: thumbView.lmk_removeShadow()
        case let .level(level): thumbView.lmk_applyShadow(level)
        case let .custom(shadow): thumbView.lmk_applyShadow(shadow)
        }
        var stateAlpha: CGFloat = 1
        if isHighlighted, let alpha = resolved.highlighted?.alpha { stateAlpha = min(stateAlpha, alpha) }
        if !isEnabled { stateAlpha = min(stateAlpha, resolved.disabled?.alpha ?? theme.alpha.disabled) }
        alpha = stateAlpha
        invalidateIntrinsicContentSize()
        updateAppearance(animated: false)
        setNeedsLayout()
        didApplyStyle?(self)
    }

    // MARK: - Actions

    @objc private func handleTap() {
        guard isEnabled else { return }
        setOn(!isOn, animated: true)
        if resolved.haptics ?? true { LMKHaptics.selection() }
        onValueChange?(isOn)
        sendActions(for: .valueChanged)
    }

    // MARK: - Appearance

    private var trackColor: UIColor {
        var color = isOn ? (resolved.onTint ?? LMKColor.primary) : (resolved.offTint ?? LMKColor.fill)
        if isHighlighted, case let .solid(highlighted?)? = resolved.highlighted?.background { color = highlighted }
        if !isEnabled, case let .solid(disabled?)? = resolved.disabled?.background { color = disabled }
        return color
    }

    private func updateAppearance(animated: Bool) {
        let color = trackColor
        if animated, LMKAnimation.shouldAnimate {
            let animation = traitCollection.lmkTheme.animation
            UIView.animate(
                withDuration: animation.fast,
                delay: 0,
                usingSpringWithDamping: animation.spring.damping,
                initialSpringVelocity: 0,
                options: LMKAnimation.Curve.easeInOut.options
            ) { [self] in
                trackView.backgroundColor = color
                updateThumbPosition()
            }
        } else {
            trackView.backgroundColor = color
            updateThumbPosition()
        }
    }

    private func updateThumbPosition() {
        let thumbSize = bounds.height - thumbInset * 2
        let offX = thumbInset
        let onX = bounds.width - thumbSize - thumbInset
        let isRightToLeft = effectiveUserInterfaceLayoutDirection == .rightToLeft
        let x = isOn != isRightToLeft ? onX : offX
        thumbView.frame = CGRect(x: x, y: thumbInset, width: thumbSize, height: thumbSize)
        thumbView.layer.cornerRadius = thumbSize / 2
    }

    private func updateAccessibilityValue() {
        accessibilityValue = isOn ? strings.onAccessibilityValue : strings.offAccessibilityValue
    }

    private func updateAccessibilityTraits() {
        var traits: UIAccessibilityTraits = [.button, .toggleButton]
        if !isEnabled { traits.insert(.notEnabled) }
        accessibilityTraits = traits
    }
}

// MARK: - UIPointerInteractionDelegate

extension LMKSwitch: UIPointerInteractionDelegate {
    public func pointerInteraction(_: UIPointerInteraction, styleFor _: UIPointerRegion) -> UIPointerStyle? {
        LMKPointerStyle.hover(for: self)
    }
}

public nonisolated extension LMKTheme {
    /// App-wide default style for `LMKSwitch`.
    var `switch`: LMKSwitch.Style {
        get { self[LMKSwitch.Style.self] }
        set { self[LMKSwitch.Style.self] = newValue }
    }
}
