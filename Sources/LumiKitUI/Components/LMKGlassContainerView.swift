//
//  LMKGlassContainerView.swift
//  LumiKit
//
//  Merges nearby Liquid Glass surfaces into one shape on iOS 26.
//

import UIKit

/// A `UIGlassContainerEffect` host (iOS 26) that merges nearby ``LMKGlassView`` children
/// added to its `contentView`; before iOS 26 it carries no effect.
public final class LMKGlassContainerView: UIVisualEffectView {
    /// Distance under which children merge into one shape (iOS 26).
    public var spacing: CGFloat {
        didSet { applyEffect() }
    }

    public init(spacing: CGFloat = LMKSpacing.small) {
        self.spacing = spacing
        super.init(effect: nil)
        applyEffect()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func applyEffect() {
        if #available(iOS 26, *) {
            let container = UIGlassContainerEffect()
            container.spacing = spacing
            effect = container
        }
    }
}
