//
//  LMKCornerRadius.swift
//  LumiKit
//
//  Corner radius tokens.
//  Proxies to `LMKThemeManager.shared.cornerRadius` for customization.
//

import UIKit

/// Corner radius tokens for the Lumi design system.
///
/// Customize by applying a corner radius theme:
/// ```swift
/// LMKThemeManager.shared.apply(cornerRadius: .init(small: 12, medium: 16))
/// ```
public enum LMKCornerRadius {
    private static var config: LMKCornerRadiusTheme {
        LMKThemeManager.shared.cornerRadius
    }

    public static var xs: CGFloat { config.xs }
    public static var small: CGFloat { config.small }
    public static var medium: CGFloat { config.medium }
    public static var large: CGFloat { config.large }
    public static var xlarge: CGFloat { config.xlarge }
    /// For circular views.
    public static var circular: CGFloat { config.circular }
}
