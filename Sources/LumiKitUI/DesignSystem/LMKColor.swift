//
//  LMKColor.swift
//  LumiKit
//
//  Static convenience accessors for theme colors.
//  `LMKColor.primary` resolves to `LMKThemeManager.shared.current.primary`.
//

import UIKit

/// Static convenience accessors that proxy to the active theme.
///
/// Usage: `view.backgroundColor = LMKColor.backgroundPrimary`
public enum LMKColor {
    // MARK: - Primary

    public static var primary: UIColor { LMKThemeManager.shared.current.primary }
    public static var primaryDark: UIColor { LMKThemeManager.shared.current.primaryDark }

    // MARK: - Secondary / Tertiary

    public static var secondary: UIColor { LMKThemeManager.shared.current.secondary }
    public static var tertiary: UIColor { LMKThemeManager.shared.current.tertiary }

    // MARK: - Semantic

    public static var success: UIColor { LMKThemeManager.shared.current.success }
    public static var warning: UIColor { LMKThemeManager.shared.current.warning }
    public static var error: UIColor { LMKThemeManager.shared.current.error }
    public static var info: UIColor { LMKThemeManager.shared.current.info }

    // MARK: - Text

    public static var textPrimary: UIColor { LMKThemeManager.shared.current.textPrimary }
    public static var textSecondary: UIColor { LMKThemeManager.shared.current.textSecondary }
    public static var textTertiary: UIColor { LMKThemeManager.shared.current.textTertiary }

    // MARK: - Backgrounds

    public static var backgroundPrimary: UIColor { LMKThemeManager.shared.current.backgroundPrimary }
    public static var backgroundSecondary: UIColor { LMKThemeManager.shared.current.backgroundSecondary }
    public static var backgroundTertiary: UIColor { LMKThemeManager.shared.current.backgroundTertiary }
    public static var backgroundGrouped: UIColor { LMKThemeManager.shared.current.backgroundTertiary }

    // MARK: - Neutral / Dividers

    public static var divider: UIColor { LMKThemeManager.shared.current.divider }
    public static var imageBorder: UIColor { LMKThemeManager.shared.current.imageBorder }
    public static var graySoft: UIColor { LMKThemeManager.shared.current.graySoft }
    public static var grayMuted: UIColor { LMKThemeManager.shared.current.grayMuted }
    public static var white: UIColor { LMKThemeManager.shared.current.white }
    public static var black: UIColor { LMKThemeManager.shared.current.black }

    // MARK: - Utility

    public static var clear: UIColor { .clear }
}
