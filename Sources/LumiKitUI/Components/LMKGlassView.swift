//
//  LMKGlassView.swift
//  LumiKit
//
//  Liquid Glass surface with a system-material fallback before iOS 26.
//

import UIKit

/// A Liquid Glass surface (iOS 26+) that degrades to a system-material blur
/// on iOS 18–25, so callers adopt the new design without an availability gate.
///
/// Drop it behind floating chrome — toolbars, badges, overlay controls — that
/// sits over scrolling content or imagery, and add content to `contentView`
/// as with any `UIVisualEffectView`:
///
/// ```swift
/// let glass = LMKGlassView(style: .regular, cornerRadius: LMKCornerRadius.xl)
/// glass.contentView.addSubview(label)
/// ```
///
/// Glass views that sit near each other merge into one shape when they are
/// hosted in a container from ``makeContainer(spacing:)`` (iOS 26); before
/// iOS 26 the container is inert and the views render individually.
public final class LMKGlassView: UIVisualEffectView {
    /// Glass style: `.clear` over rich imagery or video, `.regular` elsewhere.
    public nonisolated enum Style: Sendable, Equatable {
        case regular
        case clear
    }

    // MARK: - Properties

    /// Whether the view renders `UIGlassEffect` (`false` on the pre-iOS 26 blur fallback).
    public let isGlass: Bool

    /// Corner radius of the surface. Default `LMKCornerRadius.large`.
    public var cornerRadius: CGFloat {
        didSet { applyCorners() }
    }

    /// When `true`, corners are container-concentric on iOS 26: UIKit derives
    /// the radius from the nearest ancestor publishing a `cornerConfiguration`
    /// (or the display's corners when there is none, the fit for floating
    /// chrome at a screen edge) minus this view's inset, floored at
    /// ``cornerRadius``. Default `false`: a fixed ``cornerRadius``, so the
    /// value you pass is the value you see. Before iOS 26 the radius is always
    /// fixed. See `UIView.lmk_applyCornerRadius(_:masking:asConcentricContainer:)`
    /// for publishing a container's corners.
    public var usesConcentricCorners: Bool {
        didSet { applyCorners() }
    }

    // MARK: - Init

    /// - Parameters:
    ///   - style: `.regular` (default) or `.clear`.
    ///   - tintColor: Optional tint. On the blur fallback it is applied as a
    ///     translucent `contentView` background.
    ///   - isInteractive: Glass reacts to touches (button backgrounds). iOS 26 only.
    ///   - cornerRadius: Surface corner radius; default `LMKCornerRadius.large`.
    ///   - usesConcentricCorners: See ``usesConcentricCorners``; default `false`.
    public init(
        style: Style = .regular,
        tintColor: UIColor? = nil,
        isInteractive: Bool = false,
        cornerRadius: CGFloat = LMKCornerRadius.large,
        usesConcentricCorners: Bool = false
    ) {
        self.cornerRadius = cornerRadius
        self.usesConcentricCorners = usesConcentricCorners
        let effect: UIVisualEffect
        if #available(iOS 26, *) {
            let glass = UIGlassEffect(style: style == .clear ? .clear : .regular)
            glass.tintColor = tintColor
            glass.isInteractive = isInteractive
            effect = glass
            isGlass = true
        } else {
            effect = UIBlurEffect(style: .systemMaterial)
            isGlass = false
        }
        super.init(effect: effect)
        if !isGlass, let tintColor {
            contentView.backgroundColor = tintColor.withAlphaComponent(LMKAlpha.overlayDark)
        }
        applyCorners()
    }

    // `init(effect:)` is deliberately not overridden: UIKit's own init chain
    // re-enters it through dynamic dispatch, so an unavailable override traps.

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Container

    /// A host whose `contentView` merges nearby ``LMKGlassView`` children into
    /// one glass shape once they come within `spacing` points of each other
    /// (`UIGlassContainerEffect`, iOS 26+). Before iOS 26 the returned view
    /// carries no effect and the children render on their own. Add the glass
    /// views to the returned view's `contentView`.
    public static func makeContainer(spacing: CGFloat = LMKSpacing.small) -> UIVisualEffectView {
        if #available(iOS 26, *) {
            let container = UIGlassContainerEffect()
            container.spacing = spacing
            return UIVisualEffectView(effect: container)
        }
        return UIVisualEffectView(effect: nil)
    }

    // MARK: - Helpers

    private func applyCorners() {
        if #available(iOS 26, *) {
            let radius: UICornerRadius = usesConcentricCorners
                ? .containerConcentric(minimum: cornerRadius)
                : .fixed(cornerRadius)
            cornerConfiguration = .corners(radius: radius)
        } else {
            layer.cornerRadius = cornerRadius
            layer.cornerCurve = .continuous
            clipsToBounds = true
        }
    }
}
