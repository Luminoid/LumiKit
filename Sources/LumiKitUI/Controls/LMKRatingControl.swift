//
//  LMKRatingControl.swift
//  LumiKit
//
//  Star rating control: a row of symbols, tap or drag to rate, tap the
//  current star again to clear, adjustable for VoiceOver.
//

import SnapKit
import UIKit

/// Star rating.
///
/// ```swift
/// let rating = LMKRatingControl(maximum: 5)
/// rating.value = place.rating
/// rating.onValueChange = { place.rating = $0 }
/// ```
///
/// `value` is silent; `onValueChange` fires only for user changes (tap, drag, or a VoiceOver
/// adjustment). The whole row is a 44pt hit band however small the glyphs are.
public final class LMKRatingControl: UIControl, LMKThemeApplying {
    // MARK: - Style

    public nonisolated struct Style: Sendable, Equatable, LMKThemeExtension {
        /// `nil` = "star.fill".
        public var filledSymbol: String?
        /// `nil` = "star".
        public var emptySymbol: String?
        /// `nil` = `primary`.
        public var filledColor: UIColor?
        /// `nil` = `textTertiary`.
        public var emptyColor: UIColor?
        /// `nil` = `iconSmall`.
        public var glyphSize: CGFloat?
        /// Symbol weight; `nil` = `.regular`.
        public var symbolWeight: UIImage.SymbolWeight?
        /// Between glyphs; `nil` = `xs`.
        public var spacing: CGFloat?
        /// Tapping the current value's glyph clears the rating; `nil` = yes.
        public var allowsClearByRetap: Bool?
        /// Haptic on change; `nil` = yes.
        public var haptics: Bool?
        public var highlighted: LMKControlStateStyle?
        public var disabled: LMKControlStateStyle?

        public init(
            filledSymbol: String? = nil,
            emptySymbol: String? = nil,
            filledColor: UIColor? = nil,
            emptyColor: UIColor? = nil,
            glyphSize: CGFloat? = nil,
            symbolWeight: UIImage.SymbolWeight? = nil,
            spacing: CGFloat? = nil,
            allowsClearByRetap: Bool? = nil,
            haptics: Bool? = nil,
            highlighted: LMKControlStateStyle? = nil,
            disabled: LMKControlStateStyle? = nil
        ) {
            self.filledSymbol = filledSymbol
            self.emptySymbol = emptySymbol
            self.filledColor = filledColor
            self.emptyColor = emptyColor
            self.glyphSize = glyphSize
            self.symbolWeight = symbolWeight
            self.spacing = spacing
            self.allowsClearByRetap = allowsClearByRetap
            self.haptics = haptics
            self.highlighted = highlighted
            self.disabled = disabled
        }

        public static let defaultValue = Self()

        /// `other`'s non-nil fields over this style's.
        public func merging(_ other: Self) -> Self {
            Self(
                filledSymbol: other.filledSymbol ?? filledSymbol,
                emptySymbol: other.emptySymbol ?? emptySymbol,
                filledColor: other.filledColor ?? filledColor,
                emptyColor: other.emptyColor ?? emptyColor,
                glyphSize: other.glyphSize ?? glyphSize,
                symbolWeight: other.symbolWeight ?? symbolWeight,
                spacing: other.spacing ?? spacing,
                allowsClearByRetap: other.allowsClearByRetap ?? allowsClearByRetap,
                haptics: other.haptics ?? haptics,
                highlighted: LMKControlStateStyle.merge(highlighted, other.highlighted),
                disabled: LMKControlStateStyle.merge(disabled, other.disabled)
            )
        }
    }

    // MARK: - Strings

    public nonisolated struct Strings: Sendable, Equatable {
        public var accessibilityLabel: String
        /// `%lld of %lld`: the value, then the maximum.
        public var accessibilityValueFormat: String

        public init(
            accessibilityLabel: String = LMKLocalized("ratingControl.accessibilityLabel"),
            accessibilityValueFormat: String = LMKLocalized("ratingControl.accessibilityValue")
        ) {
            self.accessibilityLabel = accessibilityLabel
            self.accessibilityValueFormat = accessibilityValueFormat
        }
    }

    /// Process-wide defaults; set at app launch to override.
    public nonisolated(unsafe) static var strings = Strings()

    /// Per-instance strings (default `Self.strings`).
    public var strings: Strings = LMKRatingControl.strings {
        didSet { updateAccessibility() }
    }

    // MARK: - Public API

    /// The number of glyphs (at least 1). Changing it rebuilds the row and clamps `value`.
    public var maximum: Int {
        didSet {
            maximum = max(1, maximum)
            guard maximum != oldValue else { return }
            rebuildGlyphs()
            value = min(value, maximum)
            // The new glyphs need their symbol configuration and the row its new width.
            applyTheme(traitCollection.lmkTheme)
        }
    }

    /// The rating, `0` = unrated, clamped to `0...maximum`. Setting it is silent.
    public var value = 0 {
        didSet {
            value = min(max(0, value), maximum)
            guard value != oldValue else { return }
            render()
        }
    }

    /// `false` shows the rating without accepting taps (static VoiceOver text).
    public var isInteractive = true {
        didSet {
            isUserInteractionEnabled = isInteractive
            updateAccessibility()
        }
    }

    /// Called after a user change (tap, drag, or VoiceOver adjustment) with the new value.
    public var onValueChange: ((Int) -> Void)?

    /// Per-instance style; `nil` fields resolve from `theme.ratingControl`, then the built-in look.
    public var style: Style {
        didSet {
            guard style != oldValue else { return }
            applyTheme(traitCollection.lmkTheme)
        }
    }

    /// Called at the end of every `applyTheme`, for tweaks the style does not cover.
    public var didApplyStyle: ((LMKRatingControl) -> Void)?

    /// One image view per glyph, leading to trailing.
    public private(set) var glyphViews: [UIImageView] = []

    public let stackView = UIStackView()

    private var resolved = Style()
    private var trackingStartValue = 0
    private var trackingStartIndex = 0
    private var trackingMoved = false

    // MARK: - Initialization

    public init(maximum: Int = 5, style: Style = Style()) {
        self.maximum = max(1, maximum)
        self.style = style
        super.init(frame: .zero)
        setupUI()
        lmk_startApplyingTheme()
    }

    override public convenience init(frame: CGRect) {
        self.init(maximum: 5)
        self.frame = frame
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI() {
        stackView.axis = .horizontal
        stackView.alignment = .center
        // Equal boxes: a symbol measures wider than its point size, so a `.fill` row laid out
        // at the intrinsic width crushed one or two glyphs to nothing to make up the shortfall.
        stackView.distribution = .fillEqually
        stackView.isUserInteractionEnabled = false
        addSubview(stackView)
        // Pinned, not framed in `layoutSubviews`: a stack sized by its frame solves its spacing
        // against its own zero-width frame before the first layout and logs a conflict.
        stackView.snp.makeConstraints { $0.edges.equalToSuperview() }
        rebuildGlyphs()
        setContentHuggingPriority(.required, for: .horizontal)
        setContentHuggingPriority(.required, for: .vertical)
        addInteraction(UIPointerInteraction(delegate: self))
        isAccessibilityElement = true
        updateAccessibility()
    }

    private func rebuildGlyphs() {
        glyphViews.forEach { $0.removeFromSuperview() }
        glyphViews = (0 ..< maximum).map { _ in
            let view = UIImageView()
            view.contentMode = .scaleAspectFit
            return view
        }
        glyphViews.forEach(stackView.addArrangedSubview)
    }

    override public var intrinsicContentSize: CGSize {
        let glyph = glyphSize
        let spacing = resolved.spacing ?? traitCollection.lmkTheme.spacing.xs
        return CGSize(width: glyph * CGFloat(maximum) + spacing * CGFloat(maximum - 1), height: glyph)
    }

    private var glyphSize: CGFloat { resolved.glyphSize ?? traitCollection.lmkTheme.layout.iconSmall }

    /// A disabled row absorbs a touch inside its bounds, like every UIKit control; an enabled one answers the minimum touch target.
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
        resolved = theme.ratingControl.merging(style)
        var stateAlpha: CGFloat = 1
        if isHighlighted { stateAlpha = min(stateAlpha, resolved.highlighted?.alpha ?? 1) }
        if !isEnabled { stateAlpha = min(stateAlpha, resolved.disabled?.alpha ?? theme.alpha.disabled) }
        alpha = stateAlpha
        stackView.spacing = resolved.spacing ?? theme.spacing.xs
        let configuration = UIImage.SymbolConfiguration(pointSize: glyphSize, weight: resolved.symbolWeight ?? .regular)
        for view in glyphViews {
            view.preferredSymbolConfiguration = configuration
        }
        render()
        invalidateIntrinsicContentSize()
        didApplyStyle?(self)
    }

    private func render() {
        let filledName = resolved.filledSymbol ?? "star.fill"
        let emptyName = resolved.emptySymbol ?? "star"
        var filledColor = resolved.filledColor ?? LMKColor.primary
        var emptyColor = resolved.emptyColor ?? LMKColor.textTertiary
        if isHighlighted, let color = resolved.highlighted?.foregroundColor { filledColor = color; emptyColor = color }
        if !isEnabled, let color = resolved.disabled?.foregroundColor { filledColor = color; emptyColor = color }
        for (index, view) in glyphViews.enumerated() {
            let filled = index < value
            view.image = UIImage(systemName: filled ? filledName : emptyName)
            view.tintColor = filled ? filledColor : emptyColor
        }
        updateAccessibility()
    }

    // MARK: - Tracking

    override public func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        guard isInteractive else { return false }
        trackingStartValue = value
        trackingStartIndex = glyphIndex(atX: touch.location(in: self).x)
        trackingMoved = false
        return true
    }

    override public func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        // A retap clears only while the finger stays on the glyph it landed on: sub-point
        // jitter within one glyph is not a drag.
        let index = glyphIndex(atX: touch.location(in: self).x)
        if index != trackingStartIndex { trackingMoved = true }
        value = index
        return true
    }

    override public func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        super.endTracking(touch, with: event)
        guard let touch else {
            value = trackingStartValue
            return
        }
        let tapped = glyphIndex(atX: touch.location(in: self).x)
        let clears = !trackingMoved && tapped == trackingStartValue && (resolved.allowsClearByRetap ?? true)
        commit(clears ? 0 : tapped)
    }

    override public func cancelTracking(with event: UIEvent?) {
        super.cancelTracking(with: event)
        value = trackingStartValue
    }

    /// The 1-based glyph under `x`, in this control's coordinates (RTL-aware through the stack's layout).
    private func glyphIndex(atX x: CGFloat) -> Int {
        let ordered = glyphViews.enumerated().map { (index: $0.offset + 1, frame: $0.element.convert($0.element.bounds, to: self)) }
            .sorted { $0.frame.minX < $1.frame.minX }
        let half = stackView.spacing / 2
        let isRTL = effectiveUserInterfaceLayoutDirection == .rightToLeft
        for (position, entry) in ordered.enumerated() where x <= entry.frame.maxX + half {
            return isRTL ? maximum - position : entry.index
        }
        // Past the right edge: the rightmost glyph, which is the first one in RTL.
        return isRTL ? 1 : maximum
    }

    private func commit(_ newValue: Int) {
        value = newValue
        guard value != trackingStartValue else { return }
        if resolved.haptics ?? true { LMKHaptics.light() }
        onValueChange?(value)
        sendActions(for: .valueChanged)
    }

    // MARK: - Accessibility

    /// A host-assigned label wins; otherwise `strings.accessibilityLabel`.
    override public var accessibilityLabel: String? {
        get { super.accessibilityLabel ?? strings.accessibilityLabel }
        set { super.accessibilityLabel = newValue }
    }

    private func updateAccessibility() {
        accessibilityValue = String(format: strings.accessibilityValueFormat, Int64(value), Int64(maximum))
        var traits: UIAccessibilityTraits = isInteractive ? .adjustable : .staticText
        if !isEnabled { traits.insert(.notEnabled) }
        accessibilityTraits = traits
    }

    override public func accessibilityIncrement() {
        guard isInteractive, isEnabled, value < maximum else { return }
        trackingStartValue = value
        commit(value + 1)
    }

    override public func accessibilityDecrement() {
        guard isInteractive, isEnabled, value > 0 else { return }
        trackingStartValue = value
        commit(value - 1)
    }
}

// MARK: - UIPointerInteractionDelegate

extension LMKRatingControl: UIPointerInteractionDelegate {
    public func pointerInteraction(_: UIPointerInteraction, styleFor _: UIPointerRegion) -> UIPointerStyle? {
        LMKPointerStyle.hover(for: self)
    }
}

public nonisolated extension LMKTheme {
    /// App-wide default style for `LMKRatingControl`.
    var ratingControl: LMKRatingControl.Style {
        get { self[LMKRatingControl.Style.self] }
        set { self[LMKRatingControl.Style.self] = newValue }
    }
}
