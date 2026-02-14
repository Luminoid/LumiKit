//
//  LMKGradientView.swift
//  LumiKit
//
//  Configurable linear gradient background view.
//

import UIKit

/// Direction for a linear gradient.
public enum LMKGradientDirection: Sendable {
    case topToBottom
    case leftToRight
    case topLeftToBottomRight
    case topRightToBottomLeft

    var startPoint: CGPoint {
        switch self {
        case .topToBottom: CGPoint(x: 0.5, y: 0)
        case .leftToRight: CGPoint(x: 0, y: 0.5)
        case .topLeftToBottomRight: CGPoint(x: 0, y: 0)
        case .topRightToBottomLeft: CGPoint(x: 1, y: 0)
        }
    }

    var endPoint: CGPoint {
        switch self {
        case .topToBottom: CGPoint(x: 0.5, y: 1)
        case .leftToRight: CGPoint(x: 1, y: 0.5)
        case .topLeftToBottomRight: CGPoint(x: 1, y: 1)
        case .topRightToBottomLeft: CGPoint(x: 0, y: 1)
        }
    }
}

/// Configurable linear gradient view backed by `CAGradientLayer`.
///
/// ```swift
/// let gradient = LMKGradientView(
///     colors: [LMKColor.primary, LMKColor.primaryDark],
///     direction: .topToBottom
/// )
/// ```
public final class LMKGradientView: UIView {
    // swiftlint:disable:next force_cast
    override public class var layerClass: AnyClass { CAGradientLayer.self }

    private var gradientLayer: CAGradientLayer {
        // Safe: layerClass override guarantees the type.
        // swiftlint:disable:next force_cast
        layer as! CAGradientLayer
    }

    /// Gradient colors.
    public var colors: [UIColor] = [] {
        didSet { gradientLayer.colors = colors.map(\.cgColor) }
    }

    /// Gradient direction.
    public var direction: LMKGradientDirection = .topToBottom {
        didSet {
            gradientLayer.startPoint = direction.startPoint
            gradientLayer.endPoint = direction.endPoint
        }
    }

    /// Color stop locations (values in 0...1). `nil` for even distribution.
    public var locations: [NSNumber]? {
        didSet { gradientLayer.locations = locations }
    }

    public init(
        colors: [UIColor],
        direction: LMKGradientDirection = .topToBottom,
        locations: [NSNumber]? = nil
    ) {
        super.init(frame: .zero)
        self.colors = colors
        self.direction = direction
        self.locations = locations
        gradientLayer.colors = colors.map(\.cgColor)
        gradientLayer.startPoint = direction.startPoint
        gradientLayer.endPoint = direction.endPoint
        gradientLayer.locations = locations

        isAccessibilityElement = false
        accessibilityElementsHidden = true

        _ = registerForTraitChanges([UITraitUserInterfaceStyle.self], action: #selector(refreshDynamicColors))
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func refreshDynamicColors() {
        gradientLayer.colors = colors.map(\.cgColor)
    }
}
