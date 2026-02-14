//
//  LMKCardView.swift
//  LumiKit
//
//  Styled card container with shadow, corner radius, and content insets.
//

import SnapKit
import UIKit

/// Card container with design-token-driven shadow, corner radius, and padding.
///
/// Add child views to `contentView`:
/// ```swift
/// let card = LMKCardView()
/// card.contentView.addSubview(myLabel)
/// myLabel.snp.makeConstraints { make in make.edges.equalToSuperview() }
/// ```
public final class LMKCardView: UIView {
    // MARK: - Properties

    /// Content container where child views should be added.
    /// Has `masksToBounds = true` for corner radius clipping.
    public let contentView = UIView()

    /// Card background color.
    public var cardBackgroundColor: UIColor = LMKColor.backgroundSecondary {
        didSet {
            backgroundColor = cardBackgroundColor
            contentView.backgroundColor = cardBackgroundColor
        }
    }

    /// Card corner radius.
    public var cardCornerRadius: CGFloat = LMKCornerRadius.medium {
        didSet {
            contentView.layer.cornerRadius = cardCornerRadius
            layer.cornerRadius = cardCornerRadius
        }
    }

    /// Content edge insets within the card.
    public var contentInsets: UIEdgeInsets = UIEdgeInsets(
        top: LMKSpacing.large,
        left: LMKSpacing.large,
        bottom: LMKSpacing.large,
        right: LMKSpacing.large
    ) {
        didSet { updateContentConstraints() }
    }

    // MARK: - Initialization

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
        backgroundColor = cardBackgroundColor
        layer.cornerRadius = cardCornerRadius
        layer.masksToBounds = false
        lmk_applyShadow(LMKShadow.card())

        contentView.backgroundColor = cardBackgroundColor
        contentView.layer.cornerRadius = cardCornerRadius
        contentView.layer.masksToBounds = true
        addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(contentInsets)
        }

        isAccessibilityElement = false

        _ = registerForTraitChanges([UITraitUserInterfaceStyle.self], action: #selector(refreshDynamicColors))
    }

    @objc private func refreshDynamicColors() {
        lmk_applyShadow(LMKShadow.card())
    }

    private func updateContentConstraints() {
        contentView.snp.remakeConstraints { make in
            make.edges.equalToSuperview().inset(contentInsets)
        }
    }
}
