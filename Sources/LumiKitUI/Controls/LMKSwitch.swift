//
//  LMKSwitch.swift
//  LumiKit
//
//  Custom toggle switch with spring animations and design system theming.
//

import UIKit

/// Custom toggle switch that replaces `UISwitch`.
///
/// Features a rounded track with a sliding circular thumb, spring animation
/// on toggle, haptic feedback, and full design system theming.
///
/// ```swift
/// let toggle = LMKSwitch()
/// toggle.valueChangedHandler = { isOn in print("Toggle: \(isOn)") }
/// ```
public final class LMKSwitch: UIControl {
    // MARK: - Constants

    private static let trackWidth: CGFloat = 52
    private static let trackHeight: CGFloat = 30
    private static let thumbInset: CGFloat = 2
    private static var thumbDiameter: CGFloat { trackHeight - thumbInset * 2 }

    // MARK: - Public API

    /// Whether the toggle is on.
    public var isOn: Bool = false {
        didSet {
            guard isOn != oldValue else { return }
            updateAppearance(animated: false)
            updateAccessibilityValue()
        }
    }

    /// Closure called when the toggle value changes.
    public var valueChangedHandler: ((Bool) -> Void)?

    /// Animate to a new on/off state.
    public func setOn(_ on: Bool, animated: Bool) {
        guard on != isOn else { return }
        isOn = on
        updateAppearance(animated: animated)
    }

    // MARK: - Subviews

    private let trackView = UIView()
    private let thumbView = UIView()

    // MARK: - Initialization

    public init() {
        super.init(frame: CGRect(origin: .zero, size: CGSize(width: Self.trackWidth, height: Self.trackHeight)))
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

    // MARK: - Intrinsic Size

    override public var intrinsicContentSize: CGSize {
        CGSize(width: Self.trackWidth, height: Self.trackHeight)
    }

    // MARK: - Setup

    private func setupUI() {
        // Track
        trackView.layer.cornerRadius = Self.trackHeight / 2
        trackView.isUserInteractionEnabled = false
        addSubview(trackView)

        // Thumb
        thumbView.backgroundColor = .white
        thumbView.layer.cornerRadius = Self.thumbDiameter / 2
        thumbView.lmk_applyShadow(LMKShadow.small())
        thumbView.isUserInteractionEnabled = false
        addSubview(thumbView)

        // Layout
        trackView.frame = CGRect(x: 0, y: 0, width: Self.trackWidth, height: Self.trackHeight)
        updateAppearance(animated: false)

        // Tap gesture
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tap)

        // Accessibility
        isAccessibilityElement = true
        accessibilityTraits = [.button]
        updateAccessibilityValue()

        // Dynamic colors
        _ = registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: Self, _: UITraitCollection) in
            self.refreshColors()
        }
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        trackView.frame = bounds
        trackView.layer.cornerRadius = bounds.height / 2
        thumbView.layer.cornerRadius = (bounds.height - Self.thumbInset * 2) / 2
        updateThumbPosition(animated: false)
    }

    override public func sizeThatFits(_ size: CGSize) -> CGSize {
        intrinsicContentSize
    }

    // MARK: - Actions

    @objc private func handleTap() {
        isOn.toggle()
        updateAppearance(animated: true)
        LMKHapticFeedbackHelper.selection()
        valueChangedHandler?(isOn)
        sendActions(for: .valueChanged)
    }

    // MARK: - Appearance

    private func updateAppearance(animated: Bool) {
        let trackColor = isOn ? LMKColor.primary : LMKColor.grayMuted

        if animated, LMKAnimationHelper.shouldAnimate {
            UIView.animate(
                withDuration: LMKAnimationHelper.Duration.uiShort,
                delay: 0,
                usingSpringWithDamping: LMKAnimationHelper.Spring.damping,
                initialSpringVelocity: 0,
                options: .curveEaseInOut
            ) { [self] in
                trackView.backgroundColor = trackColor
                updateThumbPosition(animated: false)
            }
        } else {
            trackView.backgroundColor = trackColor
            updateThumbPosition(animated: false)
        }
    }

    private func updateThumbPosition(animated: Bool) {
        let thumbSize = bounds.height - Self.thumbInset * 2
        let offX = Self.thumbInset
        let onX = bounds.width - thumbSize - Self.thumbInset
        let x = isOn ? onX : offX
        thumbView.frame = CGRect(
            x: x,
            y: Self.thumbInset,
            width: thumbSize,
            height: thumbSize
        )
    }

    private func refreshColors() {
        trackView.backgroundColor = isOn ? LMKColor.primary : LMKColor.grayMuted
    }

    private func updateAccessibilityValue() {
        accessibilityValue = isOn ? "1" : "0"
    }
}
