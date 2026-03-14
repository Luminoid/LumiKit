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
    /// Badge background color. `nil` uses `LMKColor.error` default.
    public var backgroundColor: UIColor?
    /// Badge text color. `nil` uses `LMKColor.white` default.
    public var textColor: UIColor?
    /// Badge border color. `nil` uses `LMKColor.backgroundPrimary` default.
    public var borderColor: UIColor?

    public init(
        minWidth: CGFloat = 18,
        height: CGFloat = 18,
        horizontalPadding: CGFloat = 6,
        borderWidth: CGFloat = 1.5,
        dotSizeRatio: CGFloat = 0.55,
        backgroundColor: UIColor? = nil,
        textColor: UIColor? = nil,
        borderColor: UIColor? = nil
    ) {
        self.minWidth = minWidth
        self.height = height
        self.horizontalPadding = horizontalPadding
        self.borderWidth = borderWidth
        self.dotSizeRatio = dotSizeRatio
        self.backgroundColor = backgroundColor
        self.textColor = textColor
        self.borderColor = borderColor
    }
}
