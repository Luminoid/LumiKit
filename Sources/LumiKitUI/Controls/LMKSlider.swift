//
//  LMKSlider.swift
//  LumiKit
//
//  Tokenized slider with optional caption + live value readout.
//

import SnapKit
import UIKit

/// A continuous or step-snapped slider with optional caption row.
///
/// Wraps `UISlider` to apply design-token colors and adds an optional
/// caption (left) + formatted value readout (right) row above the track.
/// Sends `.valueChanged` and fires `valueChangedHandler` only on
/// user-driven changes; programmatic `value`/`setValue(_:animated:)`
/// updates are silent (mirrors `LMKSwitch` / `LMKSegmentedControl`).
///
/// ```swift
/// let slider = LMKSlider()
/// slider.caption = "Severity"
/// slider.minimumValue = 0
/// slider.maximumValue = 100
/// slider.step = 10                                    // snap to 0, 10, 20, ..., 100
/// slider.valueFormatter = { "\(Int($0))%" }
/// slider.valueChangedHandler = { print("severity =", $0) }
/// ```
public final class LMKSlider: UIControl {
    // MARK: - Public API

    /// Optional caption displayed above the track on the leading edge.
    /// `nil` hides the caption (and the readout row collapses if `valueFormatter` is also nil).
    public var caption: String? {
        didSet {
            captionLabel.text = caption
            updateRowVisibility()
        }
    }

    /// Optional formatter for the live value readout shown above the track on the trailing edge.
    /// `nil` hides the readout (and the row collapses if `caption` is also nil).
    /// Called on every value change, including programmatic.
    public var valueFormatter: ((Float) -> String)? {
        didSet {
            updateReadout()
            updateRowVisibility()
        }
    }

    /// Current value. Setting this updates the UI without firing the handler.
    /// When `step > 0`, reads back as an exact multiple of `step` from `minimumValue`
    /// (the underlying `UISlider`'s float round-trip is bypassed via the snapped cache).
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

    /// Minimum value. Default `0`.
    public var minimumValue: Float {
        get { slider.minimumValue }
        set {
            slider.minimumValue = newValue
            updateReadout()
            updateAccessibilityValue()
        }
    }

    /// Maximum value. Default `1`.
    public var maximumValue: Float {
        get { slider.maximumValue }
        set {
            slider.maximumValue = newValue
            updateReadout()
            updateAccessibilityValue()
        }
    }

    /// When `> 0`, values snap to `minimumValue + n * step` on drag and on `setValue`.
    /// `0` (default) leaves the slider continuous.
    public var step: Float = 0 {
        didSet {
            guard step != oldValue else { return }
            value = slider.value   // re-snap the live position under the new step
        }
    }

    /// Closure called when the user drags the slider. Not called on programmatic `value` changes.
    public var valueChangedHandler: ((Float) -> Void)?

    /// Animate to a new value.
    public func setValue(_ newValue: Float, animated: Bool) {
        let snapped = snap(newValue)
        snappedValue = snapped
        slider.setValue(snapped, animated: animated && LMKAnimationHelper.shouldAnimate)
        updateReadout()
        updateAccessibilityValue()
    }

    // MARK: - Subviews

    private let captionRow = UIStackView()
    private let captionLabel = UILabel()
    private let readoutLabel = UILabel()
    private let slider = UISlider()
    private var snappedValue: Float = 0

    // MARK: - Initialization

    public init() {
        super.init(frame: .zero)
        setupUI()
    }

    override public init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI() {
        captionLabel.font = LMKTypography.captionMedium
        captionLabel.textColor = LMKColor.textPrimary
        captionLabel.adjustsFontForContentSizeCategory = true
        captionLabel.numberOfLines = 1
        captionLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        captionLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        readoutLabel.font = LMKTypography.captionMedium
        readoutLabel.textColor = LMKColor.textSecondary
        readoutLabel.adjustsFontForContentSizeCategory = true
        readoutLabel.numberOfLines = 1
        readoutLabel.textAlignment = .right
        readoutLabel.setContentHuggingPriority(.required, for: .horizontal)
        readoutLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        captionRow.axis = .horizontal
        captionRow.alignment = .firstBaseline
        captionRow.distribution = .fill
        captionRow.spacing = LMKSpacing.small
        captionRow.lmk_addArrangedSubviews([captionLabel, readoutLabel])
        captionRow.isHidden = true

        slider.minimumTrackTintColor = LMKColor.primary
        slider.maximumTrackTintColor = LMKColor.grayMuted
        slider.thumbTintColor = LMKColor.primary
        slider.addTarget(self, action: #selector(handleSliderChanged), for: .valueChanged)
        slider.addTarget(self, action: #selector(handleSliderTouchUp), for: [.touchUpInside, .touchUpOutside, .touchCancel])

        addSubview(captionRow)
        addSubview(slider)

        captionRow.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }
        slider.snp.makeConstraints { make in
            make.top.equalTo(captionRow.snp.bottom).offset(LMKSpacing.xs).priority(.high)
            make.leading.trailing.bottom.equalToSuperview()
        }

        isAccessibilityElement = true
        accessibilityTraits = .adjustable
        updateAccessibilityValue()

        _ = registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: Self, _: UITraitCollection) in
            self.refreshColors()
        }
    }

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

    // MARK: - Readout

    private func updateReadout() {
        guard let formatter = valueFormatter else {
            readoutLabel.text = nil
            return
        }
        readoutLabel.text = formatter(value)
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
        valueChangedHandler?(value)
        sendActions(for: .valueChanged)
    }

    @objc private func handleSliderTouchUp() {
        LMKHapticFeedbackHelper.selection()
    }

    // MARK: - Appearance

    private func refreshColors() {
        captionLabel.textColor = LMKColor.textPrimary
        readoutLabel.textColor = LMKColor.textSecondary
        slider.minimumTrackTintColor = LMKColor.primary
        slider.maximumTrackTintColor = LMKColor.grayMuted
        slider.thumbTintColor = LMKColor.primary
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
        valueChangedHandler?(value)
        sendActions(for: .valueChanged)
    }

    override public func accessibilityDecrement() {
        let decrement = step > 0 ? step : (slider.maximumValue - slider.minimumValue) / 10
        setValue(value - decrement, animated: false)
        valueChangedHandler?(value)
        sendActions(for: .valueChanged)
    }
}
