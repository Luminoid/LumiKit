//
//  LMKTheme.swift
//  LumiKit
//
//  Theme protocol and manager for the Lumi design system.
//  Apps provide their own `LMKTheme` implementation to define brand colors.
//

import UIKit

// MARK: - Theme Protocol

/// Defines all semantic color properties for the Lumi design system.
///
/// Implement this protocol to provide brand-specific colors:
/// ```swift
/// struct MyAppTheme: LMKTheme {
///     var primary: UIColor { UIColor(red: ...) }
///     // ...
/// }
/// ```
public nonisolated protocol LMKTheme: Sendable {
    // Primary
    var primary: UIColor { get }
    var primaryDark: UIColor { get }

    // Secondary / Tertiary
    var secondary: UIColor { get }
    var tertiary: UIColor { get }

    // Semantic
    var success: UIColor { get }
    var warning: UIColor { get }
    var error: UIColor { get }
    var info: UIColor { get }

    // Text
    var textPrimary: UIColor { get }
    var textSecondary: UIColor { get }
    var textTertiary: UIColor { get }

    // Backgrounds
    var backgroundPrimary: UIColor { get }
    var backgroundSecondary: UIColor { get }
    var backgroundTertiary: UIColor { get }

    // Neutral / Dividers
    var divider: UIColor { get }
    var imageBorder: UIColor { get }
    var graySoft: UIColor { get }
    var grayMuted: UIColor { get }
    var white: UIColor { get }
    var black: UIColor { get }

    // Specialist
    var photoBrowserBackground: UIColor { get }
}

// MARK: - Theme Defaults

extension LMKTheme {
    /// Near-black background for full-screen photo browser.
    /// Always dark regardless of light/dark mode.
    public var photoBrowserBackground: UIColor { UIColor(white: 0.1, alpha: 1) }
}

// MARK: - Default Theme

/// Neutral gray default theme. Override by applying your own `LMKTheme`.
public nonisolated struct LMKDefaultTheme: LMKTheme {
    public init() {}

    public var primary: UIColor { .systemGreen }
    public var primaryDark: UIColor { .systemGreen.withAlphaComponent(0.85) }
    public var secondary: UIColor { .systemGray }
    public var tertiary: UIColor { .systemBrown }
    public var success: UIColor { .systemGreen }
    public var warning: UIColor { .systemOrange }
    public var error: UIColor { .systemRed }
    public var info: UIColor { .systemBlue }
    public var textPrimary: UIColor { .label }
    public var textSecondary: UIColor { .secondaryLabel }
    public var textTertiary: UIColor { .tertiaryLabel }
    public var backgroundPrimary: UIColor { .systemBackground }
    public var backgroundSecondary: UIColor { .secondarySystemBackground }
    public var backgroundTertiary: UIColor { .tertiarySystemBackground }
    public var divider: UIColor { .separator }
    public var imageBorder: UIColor { .separator }
    public var graySoft: UIColor {
        UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(white: 0.35, alpha: 1)
                : UIColor(white: 0.75, alpha: 1)
        }
    }
    public var grayMuted: UIColor {
        UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(white: 0.25, alpha: 1)
                : UIColor(white: 0.85, alpha: 1)
        }
    }
    public var white: UIColor { UIColor(white: 0.98, alpha: 1) }
    public var black: UIColor { UIColor(white: 0.1, alpha: 1) }
    public var photoBrowserBackground: UIColor { UIColor(white: 0.1, alpha: 1) }
}

// MARK: - Theme Manager

/// Singleton that holds the active design system configuration.
///
/// Configure at app launch:
/// ```swift
/// LMKThemeManager.shared.configure(
///     colors: MyAppTheme(),
///     typography: .init(fontFamily: "Inter"),
///     spacing: .init(large: 20)
/// )
/// ```
///
/// Or apply individual categories:
/// ```swift
/// LMKThemeManager.shared.apply(MyAppTheme())
/// LMKThemeManager.shared.apply(typography: .init(fontFamily: "Inter"))
/// ```
public final class LMKThemeManager {
    public static let shared = LMKThemeManager()

    // MARK: - Token Categories

    /// Color theme (existing).
    public private(set) var current: any LMKTheme = LMKDefaultTheme()

    /// Typography configuration (font family, sizes, weights, line heights).
    public private(set) var typography: LMKTypographyTheme = .init()

    /// Spacing configuration (grid values, padding).
    public private(set) var spacing: LMKSpacingTheme = .init()

    /// Corner radius configuration.
    public private(set) var cornerRadius: LMKCornerRadiusTheme = .init()

    /// Shadow configuration.
    public private(set) var shadow: LMKShadowTheme = .init()

    /// Alpha/opacity configuration.
    public private(set) var alpha: LMKAlphaTheme = .init()

    /// Layout dimension configuration (touch targets, icon sizes).
    public private(set) var layout: LMKLayoutTheme = .init()

    /// Animation timing configuration.
    public private(set) var animation: LMKAnimationTheme = .init()

    /// Badge configuration.
    public private(set) var badge: LMKBadgeTheme = .init()

    private init() {}

    // MARK: - Apply (Per-Category)

    /// Apply a color theme.
    public func apply(_ theme: some LMKTheme) {
        current = theme
    }

    /// Apply typography configuration.
    public func apply(typography: LMKTypographyTheme) {
        self.typography = typography
    }

    /// Apply spacing configuration.
    public func apply(spacing: LMKSpacingTheme) {
        self.spacing = spacing
    }

    /// Apply corner radius configuration.
    public func apply(cornerRadius: LMKCornerRadiusTheme) {
        self.cornerRadius = cornerRadius
    }

    /// Apply shadow configuration.
    public func apply(shadow: LMKShadowTheme) {
        self.shadow = shadow
    }

    /// Apply alpha/opacity configuration.
    public func apply(alpha: LMKAlphaTheme) {
        self.alpha = alpha
    }

    /// Apply layout dimension configuration.
    public func apply(layout: LMKLayoutTheme) {
        self.layout = layout
    }

    /// Apply animation timing configuration.
    public func apply(animation: LMKAnimationTheme) {
        self.animation = animation
    }

    /// Apply badge configuration.
    public func apply(badge: LMKBadgeTheme) {
        self.badge = badge
    }

    // MARK: - Reset

    /// Reset all configurations to defaults.
    public func reset() {
        current = LMKDefaultTheme()
        typography = .init()
        spacing = .init()
        cornerRadius = .init()
        shadow = .init()
        alpha = .init()
        layout = .init()
        animation = .init()
        badge = .init()
    }

    // MARK: - Configure (All-in-One)

    /// Configure multiple token categories at once. Only provided values are applied.
    public func configure(
        colors: (any LMKTheme)? = nil,
        typography: LMKTypographyTheme? = nil,
        spacing: LMKSpacingTheme? = nil,
        cornerRadius: LMKCornerRadiusTheme? = nil,
        shadow: LMKShadowTheme? = nil,
        alpha: LMKAlphaTheme? = nil,
        layout: LMKLayoutTheme? = nil,
        animation: LMKAnimationTheme? = nil,
        badge: LMKBadgeTheme? = nil
    ) {
        if let colors { current = colors }
        if let typography { self.typography = typography }
        if let spacing { self.spacing = spacing }
        if let cornerRadius { self.cornerRadius = cornerRadius }
        if let shadow { self.shadow = shadow }
        if let alpha { self.alpha = alpha }
        if let layout { self.layout = layout }
        if let animation { self.animation = animation }
        if let badge { self.badge = badge }
    }
}
