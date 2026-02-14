//
//  LMKSkeletonCell.swift
//  LumiKit
//
//  Skeleton loading cell for better perceived performance.
//

import SnapKit
import UIKit

/// Skeleton loading cell with shimmer animation.
public final class LMKSkeletonCell: UITableViewCell {
    private static let cellHeight: CGFloat = 80
    private static var containerInsets: UIEdgeInsets {
        UIEdgeInsets(top: LMKSpacing.xs, left: LMKSpacing.large, bottom: LMKSpacing.xs, right: LMKSpacing.large)
    }
    private static let shimmerAnimationDuration: TimeInterval = 1.8
    private static let staggerDelayPerIndex: TimeInterval = 0.1
    private static let gradientLocations: [NSNumber] = [0.0, 0.5, 1.0]
    private static let gradientStartPoint = CGPoint(x: 0.0, y: 0.5)
    private static let gradientEndPoint = CGPoint(x: 1.0, y: 0.5)

    private let containerView = UIView()
    private let shimmerView = UIView()
    private let gradientLayer = CAGradientLayer()

    override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: LMKSkeletonCell, _: UITraitCollection) in
            self.refreshDynamicColors()
        }
    }

    private func refreshDynamicColors() {
        containerView.backgroundColor = LMKColor.backgroundPrimary
        let shadow = LMKShadow.small()
        containerView.layer.shadowColor = shadow.color
        shimmerView.backgroundColor = LMKColor.backgroundTertiary
        gradientLayer.colors = [
            LMKColor.backgroundTertiary.cgColor,
            LMKColor.backgroundSecondary.cgColor,
            LMKColor.backgroundTertiary.cgColor,
        ]
    }

    override public func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        lmk_applyCustomHighlight(highlighted: highlighted, animated: animated)
    }

    override public func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        lmk_applyCustomHighlight(highlighted: selected, animated: animated)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .clear

        containerView.backgroundColor = LMKColor.backgroundPrimary
        containerView.layer.cornerRadius = LMKCornerRadius.medium
        containerView.layer.masksToBounds = false

        let shadow = LMKShadow.small()
        containerView.layer.shadowColor = shadow.color
        containerView.layer.shadowOffset = shadow.offset
        containerView.layer.shadowRadius = shadow.radius
        containerView.layer.shadowOpacity = shadow.opacity

        contentView.addSubview(containerView)
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(Self.containerInsets)
            make.height.equalTo(Self.cellHeight)
        }

        shimmerView.backgroundColor = LMKColor.backgroundTertiary
        containerView.addSubview(shimmerView)
        shimmerView.snp.makeConstraints { make in make.edges.equalToSuperview() }

        gradientLayer.colors = [
            LMKColor.backgroundTertiary.cgColor,
            LMKColor.backgroundSecondary.cgColor,
            LMKColor.backgroundTertiary.cgColor,
        ]
        gradientLayer.locations = Self.gradientLocations
        gradientLayer.startPoint = Self.gradientStartPoint
        gradientLayer.endPoint = Self.gradientEndPoint
    }

    override public func prepareForReuse() {
        super.prepareForReuse()
        stopShimmer()
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = shimmerView.bounds
    }

    /// Start shimmer animation.
    /// - Parameter staggerIndex: Optional row index for staggered start (delay = index * 0.1s).
    public func startShimmer(staggerIndex: Int = 0) {
        shimmerView.layer.insertSublayer(gradientLayer, at: 0)
        guard LMKAnimationHelper.shouldAnimate else { return }

        let animation = CABasicAnimation(keyPath: "transform.translation.x")
        animation.fromValue = -shimmerView.bounds.width
        animation.toValue = shimmerView.bounds.width
        animation.duration = Self.shimmerAnimationDuration
        animation.repeatCount = .infinity
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        animation.beginTime = CACurrentMediaTime() + Double(staggerIndex) * Self.staggerDelayPerIndex
        gradientLayer.add(animation, forKey: "shimmer")
    }

    public func stopShimmer() {
        gradientLayer.removeAnimation(forKey: "shimmer")
        gradientLayer.removeFromSuperlayer()
    }
}
