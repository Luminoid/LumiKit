//
//  LMKCornerStyle.swift
//  LumiKit
//
//  The corner vocabulary shared by every component Style: radius kind, which
//  corners, and the curve. Applied with `UIView.lmk_applyCornerStyle(_:)`.
//

import UIKit

/// How a surface rounds its corners.
///
/// ```swift
/// chip.lmk_applyCornerStyle(.capsule)
/// sheet.lmk_applyCornerStyle(.fixed(LMKCornerRadius.large, corners: .lmk_top))
/// innerCard.lmk_applyCornerStyle(.concentric(minimum: LMKCornerRadius.small))
/// ```
public nonisolated struct LMKCornerStyle: Sendable, Equatable {
    /// The radius rule.
    public enum Radius: Sendable, Equatable {
        /// Square corners.
        case none
        /// A fixed radius in points.
        case fixed(CGFloat)
        /// Half the shorter side, tracking the bounds (pill shapes).
        case capsule
        /// Same geometry as `capsule`; names the intent for square views.
        case circle
        /// iOS 26 container-concentric radius floored at `minimum`; a fixed `minimum` before iOS 26.
        case concentric(minimum: CGFloat)
    }

    /// The corner curve.
    public enum Curve: Sendable, Hashable, CaseIterable {
        /// Apple's continuous ("squircle") curve, the default.
        case continuous
        /// A circular arc.
        case circular

        var layerCurve: CALayerCornerCurve {
            switch self {
            case .continuous: .continuous
            case .circular: .circular
            }
        }
    }

    public var radius: Radius
    /// Which corners round; the others stay square.
    public var maskedCorners: CACornerMask
    public var curve: Curve

    public init(radius: Radius, maskedCorners: CACornerMask = .lmk_all, curve: Curve = .continuous) {
        self.radius = radius
        self.maskedCorners = maskedCorners
        self.curve = curve
    }

    public static let none = Self(radius: .none)
    public static let capsule = Self(radius: .capsule)
    public static let circle = Self(radius: .circle)

    public static func fixed(_ radius: CGFloat, corners: CACornerMask = .lmk_all, curve: Curve = .continuous) -> Self {
        Self(radius: .fixed(radius), maskedCorners: corners, curve: curve)
    }

    public static func concentric(minimum: CGFloat, corners: CACornerMask = .lmk_all) -> Self {
        Self(radius: .concentric(minimum: minimum), maskedCorners: corners)
    }

    /// Whether the radius depends on the view's bounds (`capsule`, `circle`).
    public var tracksBounds: Bool {
        switch radius {
        case .capsule, .circle: true
        case .none, .fixed, .concentric: false
        }
    }

    /// The layer radius for `bounds`: `capsule`/`circle` use half the shorter side,
    /// `concentric` reports its minimum (UIKit refines it on iOS 26), `none` is 0.
    public func resolvedRadius(for bounds: CGRect) -> CGFloat {
        switch radius {
        case .none: 0
        case let .fixed(value): max(0, value)
        case .capsule, .circle: max(0, min(bounds.width, bounds.height) / 2)
        case let .concentric(minimum): max(0, minimum)
        }
    }
}

public nonisolated extension CACornerMask {
    static let lmk_all: CACornerMask = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
    static let lmk_top: CACornerMask = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
    static let lmk_bottom: CACornerMask = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
    static let lmk_left: CACornerMask = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
    static let lmk_right: CACornerMask = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
}
