//
//  UIView+LMKSurface.swift
//  LumiKit
//
//  One implementation of `LMKSurfaceStyle`: background (solid color, gradient
//  view, blur, or glass), corners, border (layer border or a dashed / inset
//  shape layer), and shadow. Colors re-stamp on trait changes through the
//  layer-color restamper; bounds-dependent geometry refreshes from
//  `lmk_layoutSurfaceIfNeeded()`.
//

import SnapKit
import UIKit

private nonisolated(unsafe) var lmk_surfaceStateKey: UInt8 = 0

/// What `lmk_apply(surface:)` remembers between calls and layouts.
@MainActor
private final class LMKSurfaceState {
    var resolved = LMKSurfaceStyle()
    var backgroundView: UIView?
    var borderLayer: CAShapeLayer?
    var borderStyle: LMKBorderStyle?
    var registration: (any UITraitChangeRegistration)?
}

public extension UIView {
    /// The surface last resolved by `lmk_apply(surface:defaults:clipsContent:)`.
    var lmk_resolvedSurface: LMKSurfaceStyle? {
        lmk_surfaceState?.resolved
    }

    /// The gradient, blur, or glass view inserted behind the content, if the background needs one.
    var lmk_surfaceBackgroundView: UIView? {
        lmk_surfaceState?.backgroundView
    }

    /// Applies `defaults` layered under `surface` (`surface` wins field by field).
    ///
    /// - A solid background colors this view's layer; a gradient, blur, or glass
    ///   background is a view inserted at index 0 and pinned to the edges.
    /// - Corners apply to this view (and to the background view); when a shadow is
    ///   present this view does not mask, so give the content its own rounded
    ///   container or set `clipsContent` on a view without a shadow.
    /// - A solid, non-inset border uses the layer border; dashed or inset borders
    ///   stroke a shape layer that follows the corner style.
    /// - Shadow and border colors re-resolve on theme, dark mode, and contrast changes.
    ///
    /// Call `lmk_layoutSurfaceIfNeeded()` from `layoutSubviews` when the view resizes,
    /// so capsule corners, shape-layer borders, and shadow paths follow the bounds.
    ///
    /// - Returns: The resolved surface, so callers can read `contentInsets`.
    @discardableResult
    func lmk_apply(surface: LMKSurfaceStyle, defaults: LMKSurfaceStyle = LMKSurfaceStyle(), clipsContent: Bool = true) -> LMKSurfaceStyle {
        let state = lmk_surfaceState ?? LMKSurfaceState()
        lmk_surfaceState = state
        let resolved = defaults.merging(surface)
        let background = resolved.background ?? .clear
        let corners = resolved.corners ?? .square
        let shadow = resolved.shadow ?? .hidden

        // Background
        if state.resolved.background != background || (state.backgroundView == nil && background.needsView) {
            state.backgroundView?.removeFromSuperview()
            state.backgroundView = nil
            switch background {
            case .clear, .solid:
                break
            case let .gradient(colors, direction, locations):
                let gradient = LMKGradientView(colors: colors, direction: direction, locations: locations?.map { NSNumber(value: $0) })
                state.backgroundView = gradient
            case let .blur(blurStyle):
                state.backgroundView = UIVisualEffectView(effect: UIBlurEffect(style: blurStyle))
            case let .glass(variant, tint):
                state.backgroundView = LMKGlassView(variant: variant, tintColor: tint, cornerRadius: corners.resolvedRadius(for: bounds))
            }
            if let backgroundView = state.backgroundView {
                backgroundView.isUserInteractionEnabled = false
                insertSubview(backgroundView, at: 0)
                backgroundView.snp.makeConstraints { $0.edges.equalToSuperview() }
            }
        }
        switch background {
        case .clear: backgroundColor = .clear
        case let .solid(color): backgroundColor = color ?? .clear
        case .gradient, .blur, .glass: backgroundColor = .clear
        }

        // Shadow (before the corners: a visible shadow turns clipping off)
        switch shadow {
        case .hidden: lmk_removeShadow()
        case let .level(level): lmk_applyShadow(level)
        case let .custom(style): lmk_applyShadow(style)
        }

        // Border (before the corners: a clipped border keeps a concentric container unpublished)
        if let border = resolved.border, (border.width ?? 1) > 0 {
            if border.needsShapeLayer {
                lmk_removeBorder()
                state.borderStyle = border
                lmk_installBorderLayerIfNeeded(state)
            } else {
                lmk_removeBorderLayer(state)
                lmk_applyBorder(color: border.color ?? LMKColor.outline, width: border.width)
            }
        } else {
            lmk_removeBorder()
            lmk_removeBorderLayer(state)
        }

        // Corners
        lmk_applyCornerStyle(corners, masking: clipsContent && !shadow.isVisible)
        if let backgroundView = state.backgroundView {
            if let glass = backgroundView as? LMKGlassView {
                glass.cornerRadius = corners.resolvedRadius(for: bounds)
            } else {
                backgroundView.lmk_applyCornerStyle(corners, masking: true)
            }
        }

        state.resolved = resolved
        lmk_layoutSurfaceIfNeeded()
        return resolved
    }

    /// Refreshes bounds-dependent surface geometry: capsule corners, the shape-layer
    /// border path, the glass radius, and the shadow path behind a non-solid background.
    func lmk_layoutSurfaceIfNeeded() {
        lmk_layoutCornersIfNeeded()
        guard let state = lmk_surfaceState else { return }
        state.backgroundView?.lmk_layoutCornersIfNeeded()
        let corners = state.resolved.corners ?? .square
        let radius = corners.resolvedRadius(for: bounds)
        if let glass = state.backgroundView as? LMKGlassView, corners.tracksBounds {
            glass.cornerRadius = radius
        }
        if let borderLayer = state.borderLayer, let border = state.borderStyle {
            let width = LMKLayout.pixelAligned(border.width ?? LMKLayout.hairline(for: self), for: self)
            borderLayer.frame = bounds
            borderLayer.lineWidth = width
            borderLayer.lineDashPattern = border.dash?.map { NSNumber(value: Double($0)) }
            borderLayer.path = Self.lmk_roundedPath(
                in: bounds.insetBy(dx: border.inset + width / 2, dy: border.inset + width / 2),
                radius: max(0, radius - border.inset - width / 2),
                corners: corners.maskedCorners
            ).cgPath
            borderLayer.strokeColor = (border.color ?? LMKColor.outline).resolvedColor(with: traitCollection).cgColor
        }
        if state.backgroundView != nil, (state.resolved.shadow ?? .hidden).isVisible, !bounds.isEmpty {
            layer.shadowPath = Self.lmk_roundedPath(in: bounds, radius: radius, corners: corners.maskedCorners).cgPath
        } else {
            layer.shadowPath = nil
        }
    }

    // MARK: - Internals

    /// Whether the surface strokes its border on a shape layer (dashed or inset).
    internal var lmk_hasSurfaceBorderLayer: Bool {
        lmk_surfaceState?.borderLayer != nil
    }

    private var lmk_surfaceState: LMKSurfaceState? {
        get { objc_getAssociatedObject(self, &lmk_surfaceStateKey) as? LMKSurfaceState }
        set { objc_setAssociatedObject(self, &lmk_surfaceStateKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    private func lmk_installBorderLayerIfNeeded(_ state: LMKSurfaceState) {
        if state.borderLayer == nil {
            let shape = CAShapeLayer()
            shape.fillColor = nil
            shape.lineJoin = .round
            layer.addSublayer(shape)
            state.borderLayer = shape
            lmk_updateCornerPublication()
        }
        if state.registration == nil {
            state.registration = registerForTraitChanges([UITraitUserInterfaceStyle.self, UITraitAccessibilityContrast.self, LMKThemeTrait.self]) { (view: Self, _) in
                view.lmk_layoutSurfaceIfNeeded()
            }
        }
    }

    private func lmk_removeBorderLayer(_ state: LMKSurfaceState) {
        let hadLayer = state.borderLayer != nil
        state.borderLayer?.removeFromSuperlayer()
        state.borderLayer = nil
        state.borderStyle = nil
        if hadLayer {
            lmk_updateCornerPublication()
        }
        if let registration = state.registration {
            unregisterForTraitChanges(registration)
            state.registration = nil
        }
    }

    private static func lmk_roundedPath(in rect: CGRect, radius: CGFloat, corners: CACornerMask) -> UIBezierPath {
        var rectCorners: UIRectCorner = []
        if corners.contains(.layerMinXMinYCorner) { rectCorners.insert(.topLeft) }
        if corners.contains(.layerMaxXMinYCorner) { rectCorners.insert(.topRight) }
        if corners.contains(.layerMinXMaxYCorner) { rectCorners.insert(.bottomLeft) }
        if corners.contains(.layerMaxXMaxYCorner) { rectCorners.insert(.bottomRight) }
        guard radius > 0, !rectCorners.isEmpty else { return UIBezierPath(rect: rect) }
        return UIBezierPath(roundedRect: rect, byRoundingCorners: rectCorners, cornerRadii: CGSize(width: radius, height: radius))
    }
}

private extension LMKBackgroundStyle {
    var needsView: Bool {
        switch self {
        case .clear, .solid: false
        case .gradient, .blur, .glass: true
        }
    }
}

/// A plain view whose surface geometry (capsule corners, dashed borders, the shadow path)
/// refreshes on its own layout pass, for the surface-bearing subviews of components.
final class LMKSurfaceView: UIView {
    override func layoutSubviews() {
        super.layoutSubviews()
        lmk_layoutSurfaceIfNeeded()
    }
}
