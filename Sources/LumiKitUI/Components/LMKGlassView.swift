//
//  LMKGlassView.swift
//  LumiKit
//
//  Liquid Glass surface with a system-material fallback before iOS 26.
//

import UIKit

/// A Liquid Glass surface (iOS 26+) that degrades to a system-material blur on
/// iOS 18 to 25, so callers adopt the new design without an availability gate.
///
/// Drop it behind floating chrome (toolbars, badges, overlay controls) that sits
/// over scrolling content or imagery, and add content to `contentView`:
///
/// ```swift
/// let glass = LMKGlassView(style: .regular, cornerRadius: LMKCornerRadius.xl)
/// glass.contentView.addSubview(label)
/// ```
///
/// Glass views near each other merge into one shape when hosted in an
/// ``LMKGlassContainerView`` (iOS 26); before iOS 26 the container is inert.
public final class LMKGlassView: UIVisualEffectView, LMKThemeApplying {
    /// Glass style: `.clear` over rich imagery or video, `.regular` elsewhere.
    public nonisolated enum Variant: Sendable, Hashable, CaseIterable {
        case regular
        case clear
    }

    // MARK: - Style

    public nonisolated struct Style: Sendable, Equatable, LMKThemeExtension {
        /// `nil` = `.regular`.
        public var variant: Variant?
        /// Optional tint (a translucent `contentView` background on the blur fallback).
        public var tintColor: UIColor?
        /// Corners; `nil` = `.fixed(large)`. `.concentric` resolves against the nearest published container on iOS 26.
        public var corners: LMKCornerStyle?
        /// Glass reacts to touches (button backgrounds), iOS 26 only; `nil` = no.
        public var isInteractive: Bool?

        public init(variant: Variant? = nil, tintColor: UIColor? = nil, corners: LMKCornerStyle? = nil, isInteractive: Bool? = nil) {
            self.variant = variant
            self.tintColor = tintColor
            self.corners = corners
            self.isInteractive = isInteractive
        }

        public static let defaultValue = Self()

        /// `other`'s non-nil fields over this style's.
        public func merging(_ other: Self) -> Self {
            Self(
                variant: other.variant ?? variant,
                tintColor: other.tintColor ?? tintColor,
                corners: other.corners ?? corners,
                isInteractive: other.isInteractive ?? isInteractive
            )
        }
    }

    // MARK: - Properties

    /// Whether the view renders `UIGlassEffect` (`false` on the pre-iOS 26 blur fallback).
    public let isGlass: Bool

    /// Per-instance style; `nil` fields resolve from `theme.glass`, then the built-in look.
    public var style: Style {
        didSet {
            guard style != oldValue else { return }
            applyTheme(traitCollection.lmkTheme)
        }
    }

    /// The variant in effect; setting it rebuilds the effect.
    public var variant: Variant {
        get { resolved.variant ?? .regular }
        set { style.variant = newValue }
    }

    /// Corner radius of the surface (a fixed radius; see `style.corners` for capsules and concentric corners).
    public var cornerRadius: CGFloat {
        get { resolved.corners?.resolvedRadius(for: bounds) ?? LMKCornerRadius.large }
        set { style.corners = .fixed(newValue) }
    }

    /// Container-concentric corners on iOS 26 (see `LMKCornerStyle.concentric(minimum:)`).
    public var usesConcentricCorners: Bool {
        get {
            if case .concentric = resolved.corners?.radius { return true }
            return false
        }
        set {
            let minimum = cornerRadius
            style.corners = newValue ? .concentric(minimum: minimum) : .fixed(minimum)
        }
    }

    /// Whether the glass reacts to touches (iOS 26 only).
    public var isInteractive: Bool {
        get { resolved.isInteractive ?? false }
        set { style.isInteractive = newValue }
    }

    /// Called at the end of every `applyTheme`, for tweaks the style does not cover.
    public var didApplyStyle: ((LMKGlassView) -> Void)?

    private var resolved = Style()

    // MARK: - Init

    /// - Parameters:
    ///   - variant: `.regular` (default) or `.clear`.
    ///   - tintColor: Optional tint. On the blur fallback it is applied as a translucent `contentView` background.
    ///   - isInteractive: Glass reacts to touches (button backgrounds). iOS 26 only.
    ///   - cornerRadius: Surface corner radius; default `LMKCornerRadius.large`.
    ///   - usesConcentricCorners: Container-concentric on iOS 26 with `cornerRadius` as the floor; default `false`.
    public convenience init(
        style variant: Variant = .regular,
        tintColor: UIColor? = nil,
        isInteractive: Bool = false,
        cornerRadius: CGFloat = LMKCornerRadius.large,
        usesConcentricCorners: Bool = false
    ) {
        self.init(style: Style(
            variant: variant,
            tintColor: tintColor,
            corners: usesConcentricCorners ? .concentric(minimum: cornerRadius) : .fixed(cornerRadius),
            isInteractive: isInteractive
        ))
    }

    /// A glass surface configured by `style`.
    public init(style: Style) {
        self.style = style
        if #available(iOS 26, *) {
            isGlass = true
        } else {
            isGlass = false
        }
        super.init(effect: nil)
        lmk_startApplyingTheme()
    }

    // `init(effect:)` is deliberately not overridden: UIKit's own init chain re-enters
    // it through dynamic dispatch, so an unavailable override traps.

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Container

    /// A host whose `contentView` merges nearby glass views into one shape once they come within
    /// `spacing` points of each other (iOS 26); before iOS 26 the children render on their own.
    public static func makeContainer(spacing: CGFloat = LMKSpacing.small) -> LMKGlassContainerView {
        LMKGlassContainerView(spacing: spacing)
    }

    // MARK: - Theme

    public func applyTheme(_ theme: LMKTheme) {
        resolved = theme.glass.merging(style)
        let variant = resolved.variant ?? .regular
        if #available(iOS 26, *) {
            let glass = UIGlassEffect(style: variant == .clear ? .clear : .regular)
            glass.tintColor = resolved.tintColor
            glass.isInteractive = resolved.isInteractive ?? false
            effect = glass
            contentView.backgroundColor = nil
        } else {
            effect = UIBlurEffect(style: .systemMaterial)
            contentView.backgroundColor = resolved.tintColor?.withAlphaComponent(theme.alpha.small)
        }
        applyCorners(theme: theme)
        didApplyStyle?(self)
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        if resolved.corners?.tracksBounds == true, !isGlass {
            layer.cornerRadius = cornerRadius
        }
    }

    private func applyCorners(theme: LMKTheme) {
        let corners = resolved.corners ?? .fixed(theme.cornerRadius.large)
        if #available(iOS 26, *) {
            switch corners.radius {
            case .none: cornerConfiguration = .corners(radius: .fixed(0))
            case let .fixed(radius): cornerConfiguration = .corners(radius: .fixed(radius))
            case .capsule, .circle: cornerConfiguration = .capsule()
            case let .concentric(minimum): cornerConfiguration = .corners(radius: .containerConcentric(minimum: minimum))
            }
        } else {
            layer.cornerRadius = corners.resolvedRadius(for: bounds)
            layer.cornerCurve = corners.curve.layerCurve
            layer.maskedCorners = corners.maskedCorners
            clipsToBounds = true
        }
    }
}

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

public nonisolated extension LMKTheme {
    /// App-wide default style for `LMKGlassView`.
    var glass: LMKGlassView.Style {
        get { self[LMKGlassView.Style.self] }
        set { self[LMKGlassView.Style.self] = newValue }
    }
}
