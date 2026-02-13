//
//  LMKEmptyStateView.swift
//  LumiKit
//
//  Reusable empty state view component with fullScreen, card, and inline styles.
//

import SnapKit
import UIKit

/// Empty state view style.
public enum LMKEmptyStateStyle {
    case fullScreen
    case card
    case inline

    @MainActor
    public var iconSize: CGFloat {
        switch self {
        case .fullScreen: return 80
        case .card: return 40
        case .inline: return 20
        }
    }

    @MainActor
    public var fontSize: UIFont {
        switch self {
        case .fullScreen: return LMKTypography.h3
        case .card: return LMKTypography.body
        case .inline: return LMKTypography.caption
        }
    }

    public var isHorizontal: Bool { self == .inline }
}

/// Reusable empty state view for displaying messages when content is unavailable.
@MainActor
public final class LMKEmptyStateView: UIView {
    private static var iconToLabelSpacing: CGFloat { LMKSpacing.small }

    public static let inlineCellHeight: CGFloat = 44
    public static let cardCellHeight: CGFloat = 120
    public static let fullScreenCellHeight: CGFloat = 150
    public static var inlineHorizontalInsets: CGFloat { LMKSpacing.large * 2 }

    private let messageLabel = UILabel()
    private let iconImageView = UIImageView()
    private var containerView = UIView()
    private var horizontalContainerView: UIView?
    private var currentStyle: LMKEmptyStateStyle = .fullScreen

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .clear

        containerView.backgroundColor = .clear
        addSubview(containerView)
        containerView.snp.makeConstraints { make in
            make.centerX.centerY.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(LMKSpacing.xxl)
        }

        iconImageView.contentMode = .scaleAspectFit
        iconImageView.tintColor = LMKColor.textTertiary
        iconImageView.isHidden = true
        containerView.addSubview(iconImageView)

        messageLabel.textColor = LMKColor.textPrimary
        messageLabel.numberOfLines = 0
        messageLabel.lineBreakMode = .byWordWrapping
        containerView.addSubview(messageLabel)
    }

    private func setupConstraints(for style: LMKEmptyStateStyle) {
        if let horizontalContainer = horizontalContainerView {
            iconImageView.removeFromSuperview()
            messageLabel.removeFromSuperview()
            horizontalContainer.removeFromSuperview()
            horizontalContainerView = nil
            containerView.addSubview(iconImageView)
            containerView.addSubview(messageLabel)
        }

        iconImageView.snp.remakeConstraints { _ in }
        messageLabel.snp.remakeConstraints { _ in }

        if style.isHorizontal {
            messageLabel.textAlignment = .natural
            if !iconImageView.isHidden {
                let horizontalContainer = UIView()
                horizontalContainer.backgroundColor = .clear
                containerView.addSubview(horizontalContainer)
                horizontalContainerView = horizontalContainer

                iconImageView.removeFromSuperview()
                messageLabel.removeFromSuperview()
                horizontalContainer.addSubview(iconImageView)
                horizontalContainer.addSubview(messageLabel)

                iconImageView.snp.makeConstraints { make in
                    make.width.height.equalTo(style.iconSize)
                    make.leading.equalToSuperview()
                    make.centerY.equalToSuperview()
                }
                messageLabel.snp.makeConstraints { make in
                    make.leading.equalTo(iconImageView.snp.trailing).offset(Self.iconToLabelSpacing)
                    make.trailing.equalToSuperview()
                    make.centerY.equalToSuperview()
                    make.top.bottom.equalToSuperview()
                }
                horizontalContainer.snp.makeConstraints { make in
                    make.centerX.centerY.equalToSuperview()
                    make.top.bottom.equalToSuperview()
                }
            } else {
                messageLabel.snp.makeConstraints { make in
                    make.centerX.centerY.equalToSuperview()
                    make.leading.trailing.equalToSuperview()
                    make.top.bottom.equalToSuperview()
                }
            }
        } else {
            messageLabel.textAlignment = .center
            if !iconImageView.isHidden {
                iconImageView.snp.makeConstraints { make in
                    make.width.height.equalTo(style.iconSize)
                    make.centerX.equalToSuperview()
                    make.top.equalToSuperview()
                }
                messageLabel.snp.makeConstraints { make in
                    make.top.equalTo(iconImageView.snp.bottom).offset(LMKSpacing.small)
                    make.leading.trailing.equalToSuperview()
                    make.bottom.equalToSuperview()
                }
            } else {
                messageLabel.snp.makeConstraints { make in
                    make.centerX.centerY.equalToSuperview()
                    make.leading.trailing.equalToSuperview()
                    make.top.bottom.equalToSuperview()
                }
            }
        }
    }

    /// Configure the empty state view.
    public func configure(message: String, icon: String? = nil, style: LMKEmptyStateStyle = .fullScreen) {
        messageLabel.text = message
        messageLabel.font = style.fontSize
        currentStyle = style

        if let iconName = icon, let iconImage = UIImage(systemName: iconName) {
            iconImageView.image = iconImage
            iconImageView.isHidden = false
        } else {
            iconImageView.isHidden = true
        }

        setupConstraints(for: style)

        if LMKAnimationHelper.shouldAnimate {
            if !iconImageView.isHidden {
                iconImageView.alpha = 0
                iconImageView.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
                UIView.animate(withDuration: LMKAnimationHelper.Duration.actionSheet, delay: 0.05, options: .curveEaseOut) {
                    self.iconImageView.alpha = 1
                    self.iconImageView.transform = .identity
                }
            }
            messageLabel.alpha = 0
            UIView.animate(withDuration: LMKAnimationHelper.Duration.actionSheet, delay: 0.1, options: .curveEaseOut) {
                self.messageLabel.alpha = 1
            }
        } else {
            iconImageView.alpha = 1
            iconImageView.transform = .identity
            messageLabel.alpha = 1
        }
    }

    /// Wraps this view for use as `tableView.backgroundView`.
    public func wrappedForTableBackground(backgroundColor: UIColor? = nil) -> UIView {
        let container = UIView()
        container.backgroundColor = backgroundColor ?? LMKColor.backgroundPrimary
        container.addSubview(self)
        snp.makeConstraints { make in make.edges.equalToSuperview() }
        return container
    }
}

/// Helper extension for creating empty state table view cells.
extension UITableViewCell {
    @MainActor
    public static func lmk_emptyStateCell(message: String, icon: String? = nil, style: LMKEmptyStateStyle = .card, reuseIdentifier: String = "LMKEmptyStateCell") -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: reuseIdentifier)
        cell.selectionStyle = .none
        cell.backgroundColor = .clear

        let emptyStateView = LMKEmptyStateView()
        emptyStateView.configure(message: message, icon: icon, style: style)
        cell.contentView.addSubview(emptyStateView)

        let height: CGFloat = style == .inline ? LMKEmptyStateView.inlineCellHeight : (style == .card ? LMKEmptyStateView.cardCellHeight : LMKEmptyStateView.fullScreenCellHeight)
        emptyStateView.snp.makeConstraints { make in
            make.centerX.centerY.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(LMKEmptyStateView.inlineHorizontalInsets)
            make.height.greaterThanOrEqualTo(height)
        }
        return cell
    }
}
