//
//  LMKBadgeTheme.swift
//  LumiKit
//
//  Badge configuration for customizing badge appearance.
//

import UIKit

/// Badge configuration for the Lumi design system.
///
/// Override at app launch to customize badge appearance:
/// ```swift
/// LMKThemeManager.shared.apply(badge: .init(minWidth: 20, height: 20))
/// ```
public nonisolated struct LMKBadgeTheme: Sendable {
    /// Minimum badge width.
    public var minWidth: CGFloat
    /// Badge height.
    public var height: CGFloat
    /// Horizontal padding inside badge.
    public var horizontalPadding: CGFloat
    /// Border width around badge (0 for no border).
    public var borderWidth: CGFloat
    /// Ratio of dot badge size to badge height.
    public var dotSizeRatio: CGFloat

    public init(
        minWidth: CGFloat = 18,
        height: CGFloat = 18,
        horizontalPadding: CGFloat = 5,
        borderWidth: CGFloat = 1.5,
        dotSizeRatio: CGFloat = 0.55
    ) {
        self.minWidth = minWidth
        self.height = height
        self.horizontalPadding = horizontalPadding
        self.borderWidth = borderWidth
        self.dotSizeRatio = dotSizeRatio
    }
}
