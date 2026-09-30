//
//  LMKCornerRadius.swift
//  LumiKit
//
//  Corner radius tokens.
//  Proxies to `LMKTheme.current.cornerRadius` for customization.
//

import UIKit

/// Corner radius tokens for the Lumi design system.
///
/// Customize by applying a corner radius theme:
/// ```swift
/// LMKTheme.update { $0.cornerRadius = .init(small: 12, medium: 16) }
/// ```
public nonisolated enum LMKCornerRadius {
    private static var config: LMKCornerRadiusTheme {
        LMKTheme.current.cornerRadius
    }

    public static var xs: CGFloat { config.xs }
    public static var small: CGFloat { config.small }
    public static var medium: CGFloat { config.medium }
    public static var large: CGFloat { config.large }
    public static var xl: CGFloat { config.xl }
    public static var xxl: CGFloat { config.xxl }
}
