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
/// ```swift
/// let chip = LMKChipView(text: "Indoor", style: .filled)
/// chip.chipColor = LMKColor.primary
/// chip.tapHandler = { print("tapped") }
/// ```
public final class LMKChipView: UIView {
    // MARK: - Properties

    private let titleLabel = UILabel()
    private let iconImageView = UIImageView()
    private let contentStack: UIStackView

    /// Tap handler for the chip. When nil, the chip acts as a display-only label.
    public var tapHandler: (() -> Void)? {
        didSet {
            accessibilityTraits = tapHandler != nil ? .button : .staticText
        }
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

    private func setupUI() {
        layer.cornerRadius = LMKCornerRadius.large
        layer.masksToBounds = true

        iconImageView.contentMode = .scaleAspectFit
        iconImageView.isHidden = true
        iconImageView.snp.makeConstraints { make in
            make.width.height.equalTo(LMKLayout.iconExtraSmall)
        }

        titleLabel.font = LMKTypography.captionMedium
        titleLabel.textAlignment = .center

        contentStack.axis = .horizontal
        contentStack.spacing = LMKSpacing.xs
        contentStack.alignment = .center
        contentStack.addArrangedSubview(iconImageView)
        contentStack.addArrangedSubview(titleLabel)

        addSubview(contentStack)
        contentStack.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(LMKSpacing.medium)
            make.top.bottom.equalToSuperview().inset(LMKSpacing.xs)
        }

        let tap = UITapGestureRecognizer(target: self, action: #selector(didTap))
        addGestureRecognizer(tap)

        isAccessibilityElement = true
        accessibilityTraits = .staticText

        if style == .outlined {
            _ = registerForTraitChanges([UITraitUserInterfaceStyle.self], action: #selector(refreshDynamicColors))
        }

        updateAppearance()
    }

    @objc private func refreshDynamicColors() {
        layer.borderColor = chipColor.cgColor
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

    // MARK: - Appearance

    private func updateAppearance() {
        switch style {
        case .filled:
            backgroundColor = chipColor
            titleLabel.textColor = chipColor.lmk_contrastingTextColor
            iconImageView.tintColor = chipColor.lmk_contrastingTextColor
            layer.borderWidth = 0
        case .outlined:
            backgroundColor = .clear
            titleLabel.textColor = chipColor
            iconImageView.tintColor = chipColor
            layer.borderWidth = LMKThemeManager.shared.badge.borderWidth
            layer.borderColor = chipColor.cgColor
        }
    }
}
