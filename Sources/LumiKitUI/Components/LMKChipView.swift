//
//  LMKChipView.swift
//  LumiKit
//
//  Small tag/chip component for categories, filters, and labels.
//

import SnapKit
import UIKit

/// Style for chip appearance.
public enum LMKChipStyle {
    /// Filled background with contrasting text.
    case filled
    /// Border outline with colored text.
    case outlined
}

/// Small tag/chip for categories, filters, or labels.
///
/// Supports three interaction modes:
/// - **Display-only**: No handlers set — acts as a static label.
/// - **Tappable**: Set `tapHandler` for single-tap actions.
/// - **Dismissible**: Set `dismissHandler` to show an xmark button.
///
/// Toggle selection is supported via `isChipSelected`, which swaps between
/// filled and outlined appearance regardless of the initial style.
///
/// ```swift
/// // Simple tag
/// let chip = LMKChipView(text: "Indoor", style: .filled)
///
/// // Dismissible filter chip
/// let filter = LMKChipView(text: "Watering", style: .outlined)
/// filter.dismissHandler = { print("removed") }
///
/// // Toggle chip
/// let toggle = LMKChipView(text: "Active", style: .filled)
/// toggle.tapHandler = { toggle.isChipSelected.toggle() }
/// ```
public final class LMKChipView: UIView {
    // MARK: - Properties

    private let titleLabel = UILabel()
    private let iconImageView = UIImageView()
    private let dismissButton = UIButton(type: .system)
    private let contentStack: UIStackView

    /// Tap handler for the chip. When nil (and no `dismissHandler`), the chip acts as a display-only label.
    public var tapHandler: (() -> Void)? {
        didSet { updateAccessibilityTraits() }
    }

    /// Dismiss handler. When set, shows an xmark button on the trailing edge.
    /// Called when the user taps the xmark.
    public var dismissHandler: (() -> Void)? {
        didSet {
            dismissButton.isHidden = dismissHandler == nil
            updateAccessibilityTraits()
        }
    }

    /// Toggle selection state. Swaps between filled and outlined appearance.
    public var isChipSelected: Bool = false {
        didSet { updateAppearance() }
    }

    /// Chip tint color (background for filled, border for outlined).
    public var chipColor: UIColor = LMKColor.primary {
        didSet { updateAppearance() }
    }

    private let style: LMKChipStyle

    // MARK: - Initialization

    public init(text: String, icon: UIImage? = nil, style: LMKChipStyle = .filled) {
        self.style = style
        self.contentStack = UIStackView(arrangedSubviews: [])
        super.init(frame: .zero)
        setupUI()
        configure(text: text, icon: icon)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    override public func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.height / 2
    }

    private func setupUI() {
        layer.masksToBounds = true

        iconImageView.contentMode = .scaleAspectFit
        iconImageView.isHidden = true
        iconImageView.snp.makeConstraints { make in
            make.width.height.equalTo(LMKLayout.iconExtraSmall)
        }

        titleLabel.font = LMKTypography.captionMedium
        titleLabel.textAlignment = .center

        let dismissConfig = UIImage.SymbolConfiguration(pointSize: 10, weight: .bold)
        dismissButton.setImage(UIImage(systemName: "xmark", withConfiguration: dismissConfig), for: .normal)
        dismissButton.isHidden = true
        dismissButton.addTarget(self, action: #selector(didDismiss), for: .touchUpInside)
        dismissButton.snp.makeConstraints { make in
            make.width.height.equalTo(LMKSpacing.xl)
        }

        contentStack.axis = .horizontal
        contentStack.spacing = LMKSpacing.xs
        contentStack.alignment = .center
        contentStack.addArrangedSubview(iconImageView)
        contentStack.addArrangedSubview(titleLabel)
        contentStack.addArrangedSubview(dismissButton)

        addSubview(contentStack)
        contentStack.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(LMKSpacing.medium)
            make.top.bottom.equalToSuperview().inset(LMKSpacing.xs)
        }

        let tap = UITapGestureRecognizer(target: self, action: #selector(didTap))
        addGestureRecognizer(tap)

        isAccessibilityElement = true
        accessibilityTraits = .staticText

        _ = registerForTraitChanges([UITraitUserInterfaceStyle.self], action: #selector(refreshDynamicColors))

        updateAppearance()
    }

    @objc private func refreshDynamicColors() {
        updateAppearance()
    }

    // MARK: - Configuration

    /// Update chip text and optional icon.
    public func configure(text: String, icon: UIImage? = nil) {
        titleLabel.text = text
        accessibilityLabel = text
        if let icon {
            iconImageView.image = icon
            iconImageView.isHidden = false
        } else {
            iconImageView.isHidden = true
        }
    }

    // MARK: - Actions

    @objc private func didTap() {
        guard let tapHandler else { return }
        LMKHapticFeedbackHelper.light()
        tapHandler()
    }

    @objc private func didDismiss() {
        LMKHapticFeedbackHelper.light()
        dismissHandler?()
    }

    // MARK: - Helpers

    private func updateAccessibilityTraits() {
        if tapHandler != nil || dismissHandler != nil {
            accessibilityTraits = .button
        } else {
            accessibilityTraits = .staticText
        }
    }

    // MARK: - Appearance

    private func updateAppearance() {
        let effectiveStyle = resolvedStyle
        switch effectiveStyle {
        case .filled:
            backgroundColor = chipColor
            titleLabel.textColor = LMKColor.white
            iconImageView.tintColor = LMKColor.white
            dismissButton.tintColor = LMKColor.white
            layer.borderWidth = 0
        case .outlined:
            backgroundColor = .clear
            titleLabel.textColor = chipColor
            iconImageView.tintColor = chipColor
            dismissButton.tintColor = chipColor
            layer.borderWidth = LMKThemeManager.shared.badge.borderWidth
            layer.borderColor = chipColor.cgColor
        }
    }

    /// When `isChipSelected` is set, swap the visual style.
    private var resolvedStyle: LMKChipStyle {
        guard isChipSelected else { return style }
        return switch style {
        case .filled: LMKChipStyle.outlined
        case .outlined: LMKChipStyle.filled
        }
    }
}
