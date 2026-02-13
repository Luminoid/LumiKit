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
    var graySoft: UIColor { get }
    var grayMuted: UIColor { get }
    var white: UIColor { get }
    var black: UIColor { get }
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
    public var graySoft: UIColor { UIColor(white: 0.75, alpha: 1) }
    public var grayMuted: UIColor { UIColor(white: 0.85, alpha: 1) }
    public var white: UIColor { UIColor(white: 0.98, alpha: 1) }
    public var black: UIColor { UIColor(white: 0.1, alpha: 1) }
}

// MARK: - Theme Manager

/// Singleton that holds the active theme. Apply once at app launch.
///
/// ```swift
/// LMKThemeManager.shared.apply(MyAppTheme())
/// ```
public final class LMKThemeManager {
    public static let shared = LMKThemeManager()

    public private(set) var current: any LMKTheme = LMKDefaultTheme()

    private init() {}

    /// Apply a theme. Call once during app setup (e.g., in `SceneDelegate`).
    public func apply(_ theme: some LMKTheme) {
        current = theme
    }
}
