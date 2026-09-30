//
//  LMKSurfaceStyle.swift
//  LumiKit
//
//  The surface vocabulary every component Style embeds: background, corners,
//  border, shadow, and content insets, plus the per-state override struct
//  controls carry. All fields are optional; `nil` means "the component's
//  default for this field", so a partially filled style layers over the
//  theme-wide default and the built-in look.
//

import UIKit

// MARK: - Background

/// What fills a surface.
public nonisolated enum LMKBackgroundStyle: Sendable, Equatable {
    /// No fill.
    case clear
    /// A solid color; `nil` keeps the component's default token.
    case solid(UIColor?)
    /// A linear gradient drawn behind the content.
    case gradient(colors: [UIColor], direction: LMKGradientView.Direction, locations: [Double]? = nil)
    /// A system blur behind the content.
    case blur(UIBlurEffect.Style)
    /// Liquid Glass on iOS 26 (a system-material blur before), optionally tinted.
    case glass(LMKGlassView.Variant, tint: UIColor? = nil)

    /// `solid(nil)` resolved against a default: takes the default's solid color when it has one.
    func resolved(against fallback: Self?) -> Self {
        guard case .solid(nil) = self else { return self }
        if case let .solid(color?) = fallback { return .solid(color) }
        return self
    }
}

// MARK: - Border

/// A stroke around a surface, following its corner style.
public nonisolated struct LMKBorderStyle: Sendable, Equatable {
    /// `nil` resolves to `LMKColor.outline`.
    public var color: UIColor?
    /// `nil` resolves to one physical pixel on the view's display.
    public var width: CGFloat?
    /// Dash pattern in points (`[4, 2]`); `nil` draws a solid stroke.
    public var dash: [CGFloat]?
    /// Distance from the edge; `0` uses the layer border, a positive value strokes a path inside the bounds.
    public var inset: CGFloat

    public init(color: UIColor? = nil, width: CGFloat? = nil, dash: [CGFloat]? = nil, inset: CGFloat = 0) {
        self.color = color
        self.width = width
        self.dash = dash
        self.inset = max(0, inset)
    }

    /// A solid stroke.
    public static func solid(_ color: UIColor? = nil, width: CGFloat? = nil) -> Self {
        Self(color: color, width: width)
    }

    /// A dashed stroke.
    public static func dashed(_ pattern: [CGFloat], color: UIColor? = nil, width: CGFloat? = nil) -> Self {
        Self(color: color, width: width, dash: pattern)
    }

    /// No stroke (an explicit override that removes a default border).
    public static let none = Self(width: 0)

    /// Whether the stroke needs its own shape layer (dashed or inset).
    var needsShapeLayer: Bool {
        dash != nil || inset > 0
    }
}

// MARK: - Shadow

/// Where a surface's shadow comes from.
public nonisolated enum LMKShadowSource: Sendable, Equatable {
    case none
    /// A theme elevation level.
    case level(LMKShadow.Level)
    /// A fully specified shadow.
    case custom(LMKShadowStyle)

    /// Whether anything is drawn.
    var isVisible: Bool {
        switch self {
        case .none: false
        case let .level(level): level != .none
        case let .custom(style): style.opacity > 0
        }
    }
}

// MARK: - Surface

/// Background, corners, border, shadow, and content insets of a surface.
///
/// Every field is optional: `nil` keeps the component's default. Applied with
/// `UIView.lmk_apply(surface:defaults:)`; layered with `merging(_:)`.
public nonisolated struct LMKSurfaceStyle: Sendable, Equatable {
    public var background: LMKBackgroundStyle?
    public var corners: LMKCornerStyle?
    public var border: LMKBorderStyle?
    public var shadow: LMKShadowSource?
    public var contentInsets: NSDirectionalEdgeInsets?

    public init(
        background: LMKBackgroundStyle? = nil,
        corners: LMKCornerStyle? = nil,
        border: LMKBorderStyle? = nil,
        shadow: LMKShadowSource? = nil,
        contentInsets: NSDirectionalEdgeInsets? = nil
    ) {
        self.background = background
        self.corners = corners
        self.border = border
        self.shadow = shadow
        self.contentInsets = contentInsets
    }

    /// `other`'s non-nil fields over this style's (a `solid(nil)` background keeps this style's solid color).
    public func merging(_ other: Self) -> Self {
        Self(
            background: other.background.map { $0.resolved(against: background) } ?? background,
            corners: other.corners ?? corners,
            border: other.border ?? border,
            shadow: other.shadow ?? shadow,
            contentInsets: other.contentInsets ?? contentInsets
        )
    }
}

// MARK: - Control state

/// Per-state overrides for a control (`highlighted`, `selected`, `disabled`, `focused`).
/// `nil` fields derive from the base appearance.
public nonisolated struct LMKControlStateStyle: Sendable, Equatable {
    public var background: LMKBackgroundStyle?
    public var foregroundColor: UIColor?
    public var border: LMKBorderStyle?
    public var alpha: CGFloat?
    public var scale: CGFloat?
    public var shadow: LMKShadowSource?

    public init(
        background: LMKBackgroundStyle? = nil,
        foregroundColor: UIColor? = nil,
        border: LMKBorderStyle? = nil,
        alpha: CGFloat? = nil,
        scale: CGFloat? = nil,
        shadow: LMKShadowSource? = nil
    ) {
        self.background = background
        self.foregroundColor = foregroundColor
        self.border = border
        self.alpha = alpha.map { min(max($0, 0), 1) }
        self.scale = scale.map { max(0, $0) }
        self.shadow = shadow
    }

    /// `other`'s non-nil fields over this style's.
    public func merging(_ other: Self) -> Self {
        Self(
            background: other.background ?? background,
            foregroundColor: other.foregroundColor ?? foregroundColor,
            border: other.border ?? border,
            alpha: other.alpha ?? alpha,
            scale: other.scale ?? scale,
            shadow: other.shadow ?? shadow
        )
    }

    /// Layers `other` over `self` when both exist; `nil` on both sides stays `nil`.
    static func merge(_ base: Self?, _ other: Self?) -> Self? {
        switch (base, other) {
        case (nil, nil): nil
        case let (base?, nil): base
        case let (nil, other?): other
        case let (base?, other?): base.merging(other)
        }
    }
}

// MARK: - Insets

public nonisolated extension NSDirectionalEdgeInsets {
    /// Uniform insets.
    static func lmk_all(_ value: CGFloat) -> NSDirectionalEdgeInsets {
        NSDirectionalEdgeInsets(top: value, leading: value, bottom: value, trailing: value)
    }

    /// Symmetric insets.
    static func lmk_symmetric(vertical: CGFloat, horizontal: CGFloat) -> NSDirectionalEdgeInsets {
        NSDirectionalEdgeInsets(top: vertical, leading: horizontal, bottom: vertical, trailing: horizontal)
    }
}
