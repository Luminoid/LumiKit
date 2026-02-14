//
//  UIStackView+LMK.swift
//  LumiKit
//
//  Convenience initializers and helpers for UIStackView.
//

import UIKit

public extension UIStackView {
    /// Convenience initializer with all common configuration.
    ///
    /// ```swift
    /// let stack = UIStackView(lmk_axis: .vertical, spacing: LMKSpacing.small, alignment: .fill)
    /// ```
    convenience init(
        lmk_axis: NSLayoutConstraint.Axis,
        spacing: CGFloat = LMKSpacing.small,
        alignment: UIStackView.Alignment = .fill,
        distribution: UIStackView.Distribution = .fill,
        arrangedSubviews: [UIView] = []
    ) {
        self.init(arrangedSubviews: arrangedSubviews)
        self.axis = lmk_axis
        self.spacing = spacing
        self.alignment = alignment
        self.distribution = distribution
    }

    /// Add multiple arranged subviews at once.
    ///
    /// ```swift
    /// stack.lmk_addArrangedSubviews([titleLabel, subtitleLabel, actionButton])
    /// ```
    func lmk_addArrangedSubviews(_ views: [UIView]) {
        views.forEach { addArrangedSubview($0) }
    }

    /// Remove all arranged subviews.
    func lmk_removeAllArrangedSubviews() {
        arrangedSubviews.forEach {
            removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
    }
}
