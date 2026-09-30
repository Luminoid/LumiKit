//
//  LMKGradientView.swift
//  LumiKit
//
//  Gradient background view (linear or radial) backed by `CAGradientLayer`,
//  re-stamping its colors on trait changes.
//

import UIKit

/// Gradient view.
///
/// ```swift
/// let gradient = LMKGradientView(colors: [LMKColor.primary, LMKColor.primaryVariant], direction: .topToBottom)
/// let diagonal = LMKGradientView(colors: [.red, .blue], direction: .angle(30))
/// let glow = LMKGradientView(colors: [.white, .clear], kind: .radial)
/// ```
public final class LMKGradientView: UIView {
    // MARK: - Direction

    /// Where a linear gradient runs (also the start and end of a radial gradient's radius).
    public nonisolated enum Direction: Sendable, Equatable {
        case topToBottom
        case leftToRight
        case topLeftToBottomRight
        case topRightToBottomLeft
        /// Degrees clockwise from `topToBottom` (0 = top to bottom, 90 = left to right).
        case angle(CGFloat)
        /// Explicit unit-space points.
        case custom(start: CGPoint, end: CGPoint)

        public static let named: [Self] = [.topToBottom, .leftToRight, .topLeftToBottomRight, .topRightToBottomLeft]

        public var startPoint: CGPoint {
            switch self {
            case .topToBottom: CGPoint(x: 0.5, y: 0)
            case .leftToRight: CGPoint(x: 0, y: 0.5)
            case .topLeftToBottomRight: CGPoint(x: 0, y: 0)
            case .topRightToBottomLeft: CGPoint(x: 1, y: 0)
            case let .angle(degrees): Self.points(for: degrees).start
            case let .custom(start, _): start
            }
        }

        public var endPoint: CGPoint {
            switch self {
            case .topToBottom: CGPoint(x: 0.5, y: 1)
            case .leftToRight: CGPoint(x: 1, y: 0.5)
            case .topLeftToBottomRight: CGPoint(x: 1, y: 1)
            case .topRightToBottomLeft: CGPoint(x: 0, y: 1)
            case let .angle(degrees): Self.points(for: degrees).end
            case let .custom(_, end): end
            }
        }

        /// Unit-space endpoints for a direction `degrees` clockwise from top-to-bottom.
        private static func points(for degrees: CGFloat) -> (start: CGPoint, end: CGPoint) {
            let radians = degrees * .pi / 180
            let dx = sin(radians) / 2
            let dy = cos(radians) / 2
            return (CGPoint(x: 0.5 - dx, y: 0.5 - dy), CGPoint(x: 0.5 + dx, y: 0.5 + dy))
        }
    }

    /// Linear or radial.
    public nonisolated enum Kind: Sendable, Hashable, CaseIterable {
        case linear
        /// Radiates from the center; `direction` is ignored.
        case radial
    }

    // MARK: - Properties

    override public static var layerClass: AnyClass { CAGradientLayer.self }

    private var gradientLayer: CAGradientLayer? { layer as? CAGradientLayer }

    /// Gradient colors (dynamic colors follow the traits).
    public var colors: [UIColor] {
        didSet { applyColors() }
    }

    /// Gradient direction (linear only).
    public var direction: Direction {
        didSet { applyGeometry() }
    }

    /// Linear or radial.
    public var kind: Kind {
        didSet { applyGeometry() }
    }

    /// Color stop locations (`0...1`); `nil` for even distribution.
    public var locations: [NSNumber]? {
        didSet { gradientLayer?.locations = locations }
    }

    // MARK: - Initialization

    public init(colors: [UIColor], direction: Direction = .topToBottom, kind: Kind = .linear, locations: [NSNumber]? = nil) {
        self.colors = colors
        self.direction = direction
        self.kind = kind
        self.locations = locations
        super.init(frame: .zero)
        isAccessibilityElement = false
        accessibilityElementsHidden = true
        gradientLayer?.locations = locations
        applyGeometry()
        applyColors()
        registerForTraitChanges([UITraitUserInterfaceStyle.self, UITraitAccessibilityContrast.self, LMKThemeTrait.self]) { (view: Self, _) in
            view.applyColors()
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Helpers

    private func applyColors() {
        gradientLayer?.colors = colors.map { $0.resolvedColor(with: traitCollection).cgColor }
    }

    private func applyGeometry() {
        guard let gradientLayer else { return }
        switch kind {
        case .linear:
            gradientLayer.type = .axial
            gradientLayer.startPoint = direction.startPoint
            gradientLayer.endPoint = direction.endPoint
        case .radial:
            gradientLayer.type = .radial
            gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.5)
            gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        }
    }
}
