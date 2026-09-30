//
//  LMKSlider.swift
//  LumiKit
//
//  Tokenized slider with optional caption and live value readout, step
//  snapping (with track ticks on iOS 26), and a neutral value.
//

import SnapKit
import UIKit

/// A continuous or step-snapped slider with an optional caption row.
///
/// Sends `.valueChanged` and fires `onValueChange` only on user-driven
/// changes; `value` and `setValue(_:animated:)` are silent.
///
/// ```swift
/// let slider = LMKSlider()
/// slider.caption = "Severity"
/// slider.maximumValue = 100
/// slider.step = 10
/// slider.valueFormatter = { "\(Int($0))%" }
/// slider.onValueChange = { print("severity =", $0) }
/// ```
public final class LMKSlider: UIControl, LMKThemeApplying {
    // MARK: - Style

    public nonisolated struct Style: Sendable, Equatable, LMKThemeExtension {
        /// `nil` = `primary`.
        public var minimumTrackColor: UIColor?
        /// `nil` = `fill`.
        public var maximumTrackColor: UIColor?
        /// `nil` = `primary`.
        public var thumbColor: UIColor?
        /// Custom thumb image; `nil` = the system thumb tinted with `thumbColor`.
        public var thumbImage: UIImage?
        /// `nil` = `captionMedium`.
        public var captionTextStyle: LMKTextStyle?
        /// `nil` = `textPrimary`.
        public var captionColor: UIColor?
        /// `nil` = `captionMedium`.
        public var readoutTextStyle: LMKTextStyle?
        /// `nil` = `textSecondary`.
        public var readoutColor: UIColor?
        /// Gap between the caption row and the track; `nil` = `xs`.
        public var spacing: CGFloat?
        /// Show track ticks for `step` on iOS 26; `nil` = yes.
        public var showsTicks: Bool?
        /// Haptic on release; `nil` = yes.
        public var haptics: Bool?

        public init(
            minimumTrackColor: UIColor? = nil,
            maximumTrackColor: UIColor? = nil,
            thumbColor: UIColor? = nil,
            thumbImage: UIImage? = nil,
            captionTextStyle: LMKTextStyle? = nil,
            captionColor: UIColor? = nil,
            readoutTextStyle: LMKTextStyle? = nil,
            readoutColor: UIColor? = nil,
            spacing: CGFloat? = nil,
            showsTicks: Bool? = nil,
            haptics: Bool? = nil
        ) {
            self.minimumTrackColor = minimumTrackColor
            self.maximumTrackColor = maximumTrackColor
            self.thumbColor = thumbColor
            self.thumbImage = thumbImage
            self.captionTextStyle = captionTextStyle
            self.captionColor = captionColor
            self.readoutTextStyle = readoutTextStyle
            self.readoutColor = readoutColor
            self.spacing = spacing
            self.showsTicks = showsTicks
            self.haptics = haptics
        }

        public static let defaultValue = Self()

        /// `other`'s non-nil fields over this style's.
        public func merging(_ other: Self) -> Self {
            Self(
                minimumTrackColor: other.minimumTrackColor ?? minimumTrackColor,
                maximumTrackColor: other.maximumTrackColor ?? maximumTrackColor,
                thumbColor: other.thumbColor ?? thumbColor,
                thumbImage: other.thumbImage ?? thumbImage,
                captionTextStyle: other.captionTextStyle ?? captionTextStyle,
                captionColor: other.captionColor ?? captionColor,
                readoutTextStyle: other.readoutTextStyle ?? readoutTextStyle,
                readoutColor: other.readoutColor ?? readoutColor,
                spacing: other.spacing ?? spacing,
                showsTicks: other.showsTicks ?? showsTicks,
                haptics: other.haptics ?? haptics
            )
        }
    }

    // MARK: - Public API

    /// Caption above the track on the leading edge; `nil` hides it.
    public var caption: String? {
        didSet {
            captionLabel.lmk_setText(caption)
            updateRowVisibility()
        }
    }

    /// Formats the live readout on the trailing edge; `nil` hides it. Called on every change.
    public var valueFormatter: ((Float) -> String)? {
        didSet {
            updateReadout()
            updateRowVisibility()
        }
    }

    /// Current value; setting it is silent. With `step > 0` it reads back as an exact multiple.
    public var value: Float {
        get { step > 0 ? snappedValue : slider.value }
        set {
            let snapped = snap(newValue)
            snappedValue = snapped
            slider.value = snapped
            updateReadout()
            updateAccessibilityValue()
        }
    }

    public var minimumValue: Float {
        get { slider.minimumValue }
        set {
            slider.minimumValue = newValue
            updateTrackConfiguration()
            updateReadout()
            updateAccessibilityValue()
        }
    }

    public var maximumValue: Float {
        get { slider.maximumValue }
        set {
            slider.maximumValue = newValue
            updateTrackConfiguration()
            updateReadout()
            updateAccessibilityValue()
        }
    }

    /// When `> 0`, values snap to `minimumValue + n * step`; `0` (default) leaves the slider continuous.
    /// On iOS 26 the track shows a tick per step (see `Style.showsTicks`).
    public var step: Float = 0 {
        didSet {
            guard step != oldValue else { return }
            value = slider.value
            updateTrackConfiguration()
        }
    }

    /// A value the track fills from instead of the minimum (an exposure slider's 0); iOS 26 only.
    public var neutralValue: Float? {
        didSet { updateTrackConfiguration() }
    }

    /// Called when the user drags the slider.
    public var onValueChange: ((Float) -> Void)?

    /// Per-instance style; `nil` fields resolve from `theme.slider`, then the built-in look.
    public var style: Style {
        didSet {
            guard style != oldValue else { return }
            applyTheme(traitCollection.lmkTheme)
        }
    }

    /// Called at the end of every `applyTheme`, for tweaks the style does not cover.
    public var didApplyStyle: ((LMKSlider) -> Void)?

    /// Animates to a new value (silent).
    public func setValue(_ newValue: Float, animated: Bool) {
        let snapped = snap(newValue)
        snappedValue = snapped
        slider.setValue(snapped, animated: animated && LMKAnimation.shouldAnimate)
        updateReadout()
        updateAccessibilityValue()
    }

    // MARK: - Subviews

    public let captionLabel = UILabel()
    public let readoutLabel = UILabel()
    /// The wrapped slider.
    /// The track responds to touches at least `minimumTouchTarget` tall, like the control itself.
    public let slider: UISlider = LMKHitExpandingSlider()
    private let captionRow = UIStackView()
    private var snappedValue: Float = 0
    private var resolved = Style()
    private var spacingConstraint: Constraint?

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
        captionLabel.numberOfLines = 1
        captionLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        captionLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        readoutLabel.numberOfLines = 1
        readoutLabel.textAlignment = .right
        readoutLabel.setContentHuggingPriority(.required, for: .horizontal)
        readoutLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        captionRow.axis = .horizontal
        captionRow.alignment = .firstBaseline
        captionRow.distribution = .fill
        captionRow.lmk_addArrangedSubviews([captionLabel, readoutLabel])
        captionRow.isHidden = true

        slider.addTarget(self, action: #selector(handleSliderChanged), for: .valueChanged)
        slider.addTarget(self, action: #selector(handleSliderTouchUp), for: [.touchUpInside, .touchUpOutside, .touchCancel])

        addSubview(captionRow)
        addSubview(slider)
        captionRow.snp.makeConstraints { $0.top.leading.trailing.equalToSuperview() }
        slider.snp.makeConstraints { make in
            spacingConstraint = make.top.equalTo(captionRow.snp.bottom).offset(0).priority(.high).constraint
            make.leading.trailing.bottom.equalToSuperview()
        }

        isAccessibilityElement = true
        accessibilityTraits = .adjustable
        updateAccessibilityValue()
    }

    override public var intrinsicContentSize: CGSize {
        let rowHeight = captionRow.isHidden ? 0 : captionRow.intrinsicContentSize.height + (resolved.spacing ?? traitCollection.lmkTheme.spacing.xs)
        return CGSize(width: UIView.noIntrinsicMetric, height: rowHeight + slider.intrinsicContentSize.height)
    }

    override public var isEnabled: Bool {
        didSet {
            guard isEnabled != oldValue else { return }
            slider.isEnabled = isEnabled
            applyTheme(traitCollection.lmkTheme)
            accessibilityTraits = isEnabled ? .adjustable : [.adjustable, .notEnabled]
        }
    }

    /// A caption-less slider is 34pt tall; the control still answers a 44pt touch.
    override public func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        guard isEnabled, !isHidden else { return bounds.contains(point) }
        return lmk_hitTestBounds(minimumSide: traitCollection.lmkTheme.layout.minimumTouchTarget).contains(point)
    }

    // MARK: - Theme

    public func applyTheme(_ theme: LMKTheme) {
        resolved = theme.slider.merging(style)
        captionLabel.lmk_apply(resolved.captionTextStyle ?? .captionMedium, color: resolved.captionColor ?? LMKColor.textPrimary)
        readoutLabel.lmk_apply(resolved.readoutTextStyle ?? .captionMedium, color: resolved.readoutColor ?? LMKColor.textSecondary)
        captionRow.spacing = theme.spacing.small
        spacingConstraint?.update(offset: resolved.spacing ?? theme.spacing.xs)
        if traitCollection.userInterfaceIdiom == .mac {
            // The Mac idiom renders an AppKit slider: track and thumb tints throw
            // (`setMinimumTrackTintColor: is not supported ... in the Mac idiom`); only `tintColor` applies.
            slider.tintColor = resolved.minimumTrackColor ?? LMKColor.primary
        } else {
            slider.minimumTrackTintColor = resolved.minimumTrackColor ?? LMKColor.primary
            slider.maximumTrackTintColor = resolved.maximumTrackColor ?? LMKColor.fill
            if resolved.thumbImage != nil || slider.currentThumbImage != nil {
                slider.setThumbImage(resolved.thumbImage, for: .normal)
            }
            slider.thumbTintColor = resolved.thumbColor ?? LMKColor.primary
        }
        alpha = isEnabled ? 1 : theme.alpha.disabled
        updateTrackConfiguration()
        invalidateIntrinsicContentSize()
        didApplyStyle?(self)
    }

    /// iOS 26: ticks per step and the neutral value; earlier systems keep a plain track.
    private func updateTrackConfiguration() {
        guard #available(iOS 26, *), traitCollection.userInterfaceIdiom != .mac else { return }
        let range = slider.maximumValue - slider.minimumValue
        let showsTicks = (resolved.showsTicks ?? true) && step > 0 && range > 0
        let neutral = range > 0 ? (neutralValue.map { ($0 - slider.minimumValue) / range } ?? 0) : 0
        let configuration: UISlider.TrackConfiguration? = if showsTicks {
            UISlider.TrackConfiguration(allowsTickValuesOnly: true, neutralValue: neutral, numberOfTicks: max(2, min(Int((range / step).rounded()) + 1, Self.maximumTicks)))
        } else if neutralValue != nil, range > 0 {
            UISlider.TrackConfiguration(allowsTickValuesOnly: false, neutralValue: neutral, numberOfTicks: 0)
        } else {
            nil
        }
        // Assigning nil over nil resets the slider's value; only clear a configuration that exists.
        guard configuration != nil || slider.trackConfiguration != nil else { return }
        let current = slider.value
        slider.trackConfiguration = configuration
        slider.value = current
    }

    private static let maximumTicks = 50

    // MARK: - Row visibility

    private func updateRowVisibility() {
        let hasCaption = !(caption?.isEmpty ?? true)
        let hasReadout = valueFormatter != nil
        captionLabel.isHidden = !hasCaption
        readoutLabel.isHidden = !hasReadout
        captionRow.isHidden = !(hasCaption || hasReadout)
        if hasReadout { updateReadout() }
        invalidateIntrinsicContentSize()
    }

    private func updateReadout() {
        guard let formatter = valueFormatter else {
            readoutLabel.lmk_setText(nil)
            return
        }
        readoutLabel.lmk_setText(formatter(value))
    }

    // MARK: - Snap

    private func snap(_ raw: Float) -> Float {
        let clamped = min(max(raw, slider.minimumValue), slider.maximumValue)
        guard step > 0 else { return clamped }
        let offset = clamped - slider.minimumValue
        let snappedOffset = (offset / step).rounded() * step
        return min(slider.minimumValue + snappedOffset, slider.maximumValue)
    }

    // MARK: - Actions

    @objc private func handleSliderChanged() {
        let raw = slider.value
        let snapped = snap(raw)
        snappedValue = snapped
        if snapped != raw {
            slider.value = snapped
        }
        updateReadout()
        updateAccessibilityValue()
        onValueChange?(value)
        sendActions(for: .valueChanged)
    }

    @objc private func handleSliderTouchUp() {
        if resolved.haptics ?? true { LMKHaptics.selection() }
    }

    // MARK: - Accessibility

    override public var accessibilityLabel: String? {
        get { super.accessibilityLabel ?? caption }
        set { super.accessibilityLabel = newValue }
    }

    private func updateAccessibilityValue() {
        if let formatter = valueFormatter {
            accessibilityValue = formatter(value)
        } else {
            accessibilityValue = String(format: "%g", Double(value))
        }
    }

    override public func accessibilityIncrement() {
        let increment = step > 0 ? step : (slider.maximumValue - slider.minimumValue) / 10
        setValue(value + increment, animated: false)
        onValueChange?(value)
        sendActions(for: .valueChanged)
    }

    override public func accessibilityDecrement() {
        let decrement = step > 0 ? step : (slider.maximumValue - slider.minimumValue) / 10
        setValue(value - decrement, animated: false)
        onValueChange?(value)
        sendActions(for: .valueChanged)
    }
}

public nonisolated extension LMKTheme {
    /// App-wide default style for `LMKSlider`.
    var slider: LMKSlider.Style {
        get { self[LMKSlider.Style.self] }
        set { self[LMKSlider.Style.self] = newValue }
    }
}
