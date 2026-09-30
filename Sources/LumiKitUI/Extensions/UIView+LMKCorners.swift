//
//  UIView+LMKCorners.swift
//  LumiKit
//
//  Corner application from `LMKCornerStyle`: fixed radii, capsules that follow
//  the bounds, and the iOS 26 container-concentric radius with its fallback.
//

import UIKit

private nonisolated(unsafe) var lmk_cornerStateKey: UInt8 = 0

/// What `lmk_applyCornerStyle` remembers: the style (so bounds-tracking radii can
/// be re-applied at layout) and whether a `cornerConfiguration` is published (once
/// published, UIKit re-applies it at layout, so it stays published and consistent).
@MainActor
private final class LMKCornerState {
    var style: LMKCornerStyle
    var isConcentricContainer = false
    var publishesConfiguration = false
    /// Follows the bounds for a capsule or circle.
    weak var tracker: LMKCornerTrackingView?

    init(style: LMKCornerStyle) {
        self.style = style
    }
}

/// A hidden subview that resizes with its superview and refreshes the bounds-tracking
/// corner radius of `target`, so a capsule keeps its shape without a layout override.
private final class LMKCornerTrackingView: UIView {
    weak var target: UIView?

    override init(frame: CGRect) {
        super.init(frame: frame)
        isHidden = true
        isUserInteractionEnabled = false
        autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        target?.lmk_layoutCornersIfNeeded()
    }
}

public extension UIView {
    /// The corner style last applied with `lmk_applyCornerStyle(_:masking:asConcentricContainer:)`.
    var lmk_cornerStyle: LMKCornerStyle? {
        lmk_cornerState?.style
    }

    /// Applies `style` to the layer.
    ///
    /// - `fixed` sets the radius, masked corners, and curve.
    /// - `capsule` / `circle` use half the shorter side and follow the view's bounds (a
    ///   hidden subview reports resizes; `lmk_layoutCornersIfNeeded()` does the same from
    ///   a `layoutSubviews` override).
    /// - `concentric` resolves against the nearest ancestor that publishes a
    ///   `cornerConfiguration` on iOS 26 (floored at its minimum); a fixed minimum before.
    ///
    /// Capsules and circles are drawn with `layer.cornerRadius`, not with iOS 26's
    /// `UICornerConfiguration.capsule()`: a view that publishes a configuration clips its
    /// subviews along a tighter curve than its border follows, which thins the border around
    /// the corners (a hairline all but disappears there).
    ///
    /// - Parameters:
    ///   - style: The corners to apply.
    ///   - masking: Whether to clip subviews to the rounded shape (default `true`).
    ///   - asConcentricContainer: On iOS 26 also publishes the radius as this view's
    ///     `cornerConfiguration`, which is what descendants using `.concentric` resolve
    ///     against (a bare `layer.cornerRadius` is invisible to that math). Opt-in,
    ///     because a published configuration is re-applied by UIKit at layout and would
    ///     override a later manual `layer.cornerRadius`. A view that clips and already has
    ///     a border is not published, for the reason above: put the border on a wrapper
    ///     that does not clip, or pass `masking: false`.
    ///
    /// ```swift
    /// card.lmk_applyCornerStyle(.fixed(LMKCornerRadius.xl), asConcentricContainer: true)
    /// chip.lmk_applyCornerStyle(.capsule)
    /// innerChip.lmk_applyCornerStyle(.concentric(minimum: LMKCornerRadius.small))
    /// ```
    func lmk_applyCornerStyle(_ style: LMKCornerStyle, masking: Bool = true, asConcentricContainer: Bool = false) {
        let state = lmk_cornerState ?? LMKCornerState(style: style)
        state.style = style
        state.isConcentricContainer = state.isConcentricContainer || asConcentricContainer
        lmk_cornerState = state

        layer.maskedCorners = style.maskedCorners
        layer.cornerCurve = style.curve.layerCurve
        layer.masksToBounds = masking
        lmk_applyCorners(state)
    }

    /// Re-applies a bounds-tracking corner style (`capsule` / `circle`) after a resize;
    /// a no-op for fixed radii. The view does this on its own when it resizes; call it
    /// where the radius must be current before that pass (a shadow path, a snapshot).
    func lmk_layoutCornersIfNeeded() {
        guard let state = lmk_cornerState else { return }
        if state.style.tracksBounds || lmk_shouldPublishCornerConfiguration(state) != state.publishesConfiguration {
            lmk_applyCorners(state)
        }
    }

    /// Applies a fixed corner radius; see `lmk_applyCornerStyle(_:masking:asConcentricContainer:)`.
    ///
    /// ```swift
    /// card.lmk_applyCornerRadius(LMKCornerRadius.xl, asConcentricContainer: true)
    /// ```
    func lmk_applyCornerRadius(_ radius: CGFloat, masking: Bool = true, asConcentricContainer: Bool = false) {
        lmk_applyCornerStyle(.fixed(radius), masking: masking, asConcentricContainer: asConcentricContainer)
    }

    /// Applies iOS 26 container-concentric corners floored at `minimumRadius`
    /// (a fixed `minimumRadius` before iOS 26); see `lmk_applyCornerStyle(_:masking:asConcentricContainer:)`.
    ///
    /// ```swift
    /// card.lmk_applyCornerRadius(LMKCornerRadius.xl, asConcentricContainer: true)
    /// innerCard.lmk_applyConcentricCorners(minimumRadius: LMKCornerRadius.small)
    /// ```
    func lmk_applyConcentricCorners(minimumRadius: CGFloat, masking: Bool = true) {
        lmk_applyCornerStyle(.concentric(minimum: minimumRadius), masking: masking)
    }

    /// Makes the view circular (half of the shorter side) and keeps it circular as it resizes.
    func lmk_makeCircular() {
        lmk_applyCornerStyle(.circle)
    }

    // MARK: - Internals

    /// Publishes a concentric container's radius once the border that held it back is gone.
    internal func lmk_updateCornerPublication() {
        guard let state = lmk_cornerState, lmk_shouldPublishCornerConfiguration(state) != state.publishesConfiguration else { return }
        lmk_applyCorners(state)
    }

    /// Whether `state.style` goes through `cornerConfiguration` (iOS 26). UIKit keeps applying
    /// a configuration it was given once, so a published view stays published.
    private func lmk_shouldPublishCornerConfiguration(_ state: LMKCornerState) -> Bool {
        guard #available(iOS 26, *) else { return false }
        if case .concentric = state.style.radius {
            // Only UIKit can resolve it.
            return true
        }
        return state.publishesConfiguration || (state.isConcentricContainer && !lmk_clipsBorder)
    }

    /// A clipping view with a border (the layer's own, or a surface's shape layer): a
    /// published configuration would eat into the border at the corners.
    private var lmk_clipsBorder: Bool {
        layer.masksToBounds && (layer.borderWidth > 0 || lmk_hasSurfaceBorderLayer)
    }

    private func lmk_applyCorners(_ state: LMKCornerState) {
        let style = state.style
        lmk_setTracksCornerBounds(style.tracksBounds, state: state)
        let radius = style.resolvedRadius(for: bounds)
        guard #available(iOS 26, *), lmk_shouldPublishCornerConfiguration(state) else {
            layer.cornerRadius = radius
            return
        }
        let configuration: UICornerConfiguration
        if case let .concentric(minimum) = style.radius {
            configuration = .corners(radius: .containerConcentric(minimum: minimum))
        } else {
            // Immediate value for readers of `layer.cornerRadius`; UIKit applies the configuration at layout.
            layer.cornerRadius = radius
            configuration = Self.lmk_fixedConfiguration(radius: radius, corners: style.maskedCorners)
        }
        // Assigning an equal configuration still schedules a layout pass; a tracked radius is re-applied from layout.
        if !state.publishesConfiguration || cornerConfiguration != configuration {
            cornerConfiguration = configuration
        }
        state.publishesConfiguration = true
    }

    /// Installs or removes the hidden subview that keeps a capsule or circle sized to the bounds.
    private func lmk_setTracksCornerBounds(_ tracks: Bool, state: LMKCornerState) {
        guard tracks else {
            state.tracker?.removeFromSuperview()
            return
        }
        guard state.tracker?.superview == nil else { return }
        state.tracker?.removeFromSuperview()
        // An effect view only takes subviews in its content view, which resizes with it.
        let host = (self as? UIVisualEffectView)?.contentView ?? self
        let tracker = LMKCornerTrackingView(frame: host.bounds)
        tracker.target = self
        host.insertSubview(tracker, at: 0)
        state.tracker = tracker
    }

    private var lmk_cornerState: LMKCornerState? {
        get { objc_getAssociatedObject(self, &lmk_cornerStateKey) as? LMKCornerState }
        set { objc_setAssociatedObject(self, &lmk_cornerStateKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    @available(iOS 26, *)
    private static func lmk_fixedConfiguration(radius: CGFloat, corners: CACornerMask) -> UICornerConfiguration {
        guard corners != .lmk_all else {
            return .corners(radius: .fixed(radius))
        }
        func cornerRadius(for corner: CACornerMask) -> UICornerRadius {
            corners.contains(corner) ? .fixed(radius) : .fixed(0)
        }
        return .corners(
            topLeftRadius: cornerRadius(for: .layerMinXMinYCorner),
            topRightRadius: cornerRadius(for: .layerMaxXMinYCorner),
            bottomLeftRadius: cornerRadius(for: .layerMinXMaxYCorner),
            bottomRightRadius: cornerRadius(for: .layerMaxXMaxYCorner)
        )
    }
}
