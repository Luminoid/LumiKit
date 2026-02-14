//
//  LMKDividerView.swift
//  LumiKit
//
//  Simple horizontal or vertical divider line using design tokens.
//

import UIKit

/// Orientation for the divider.
public enum LMKDividerOrientation {
    case horizontal
    case vertical
}

/// Simple divider line component using design tokens.
///
/// ```swift
/// let divider = LMKDividerView(orientation: .horizontal)
/// container.addSubview(divider)
/// divider.snp.makeConstraints { make in
///     make.leading.trailing.equalToSuperview().inset(LMKSpacing.large)
///     make.height.equalTo(divider.thickness)
/// }
/// ```
public final class LMKDividerView: UIView {
    /// Default pixel-perfect thickness (1 pixel).
    public static let defaultThickness: CGFloat = 1.0 / UIScreen.main.scale

    /// Divider orientation.
    public var orientation: LMKDividerOrientation {
        didSet { invalidateIntrinsicContentSize() }
    }

    /// Divider thickness in points.
    public var thickness: CGFloat {
        didSet { invalidateIntrinsicContentSize() }
    }

    public init(
        orientation: LMKDividerOrientation = .horizontal,
        color: UIColor? = nil,
        thickness: CGFloat = LMKDividerView.defaultThickness
    ) {
        self.orientation = orientation
        self.thickness = thickness
        super.init(frame: .zero)
        backgroundColor = color ?? LMKColor.divider
        isAccessibilityElement = false
        accessibilityElementsHidden = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public var intrinsicContentSize: CGSize {
        switch orientation {
        case .horizontal: CGSize(width: UIView.noIntrinsicMetric, height: thickness)
        case .vertical: CGSize(width: thickness, height: UIView.noIntrinsicMetric)
        }
    }
}
