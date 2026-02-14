//
//  LMKBadgeView.swift
//  LumiKit
//
//  Small count or status badge component.
//

import SnapKit
import UIKit

/// Small badge for notification counts, "New" labels, or status indicators.
///
/// ```swift
/// let badge = LMKBadgeView()
/// badge.configure(count: 5)
/// // Or: badge.configure(text: "New")
/// // Or: badge.configure() // dot-only badge
/// ```
public final class LMKBadgeView: UIView {
    // MARK: - Properties

    private static var config: LMKBadgeTheme {
        LMKThemeManager.shared.badge
    }

    private let countLabel = UILabel()

    /// Badge background color. Defaults to `LMKColor.error`.
    public var badgeColor: UIColor = LMKColor.error {
        didSet { backgroundColor = badgeColor }
    }

    /// Badge text color. Defaults to `LMKColor.white`.
    public var textColor: UIColor = LMKColor.white {
        didSet { countLabel.textColor = textColor }
    }

    /// Badge border color. Defaults to `LMKColor.backgroundPrimary`.
    public var borderColor: UIColor = LMKColor.backgroundPrimary {
        didSet { layer.borderColor = borderColor.cgColor }
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
        backgroundColor = badgeColor
        layer.borderColor = borderColor.cgColor
        layer.borderWidth = Self.config.borderWidth
        clipsToBounds = true

        countLabel.font = LMKTypography.extraSmallSemibold
        countLabel.textColor = textColor
        countLabel.textAlignment = .center
        addSubview(countLabel)
        countLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        isAccessibilityElement = true
        accessibilityTraits = .staticText

        _ = registerForTraitChanges([UITraitUserInterfaceStyle.self], action: #selector(refreshDynamicColors))
    }

    @objc private func refreshDynamicColors() {
        layer.borderColor = borderColor.cgColor
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.height / 2
    }

    // MARK: - Configuration

    /// Configure as a count badge. Hides if count is 0.
    public func configure(count: Int) {
        isHidden = count <= 0
        countLabel.text = count > 99 ? "99+" : "\(count)"
        accessibilityLabel = "\(count)"
        invalidateIntrinsicContentSize()
    }

    /// Configure with custom text (e.g., "New").
    public func configure(text: String) {
        isHidden = text.isEmpty
        countLabel.text = text
        accessibilityLabel = text
        invalidateIntrinsicContentSize()
    }

    /// Configure as a dot badge (no text).
    public func configure() {
        isHidden = false
        countLabel.text = nil
        accessibilityLabel = "New"
        invalidateIntrinsicContentSize()
    }

    override public var intrinsicContentSize: CGSize {
        let config = Self.config
        if let text = countLabel.text, !text.isEmpty {
            let textSize = countLabel.intrinsicContentSize
            let width = max(config.minWidth, textSize.width + config.horizontalPadding * 2)
            return CGSize(width: width, height: config.height)
        }
        // Dot badge: small circle
        let dotSize = config.height * 0.55
        return CGSize(width: dotSize, height: dotSize)
    }
}
