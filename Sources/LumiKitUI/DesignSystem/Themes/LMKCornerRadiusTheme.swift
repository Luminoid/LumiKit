//
//  LMKCornerRadiusTheme.swift
//  LumiKit
//
//  Corner radius configuration for customizing border radii.
//

import UIKit

/// Corner radius configuration for the Lumi design system.
///
/// Override at app launch to customize radii:
/// ```swift
/// LMKThemeManager.shared.apply(cornerRadius: .init(small: 12, medium: 16))
/// ```
public nonisolated struct LMKCornerRadiusTheme: Sendable {
    public var xs: CGFloat
    public var small: CGFloat
    public var medium: CGFloat
    public var large: CGFloat
    public var xl: CGFloat

    public init(
        xs: CGFloat = 4,
        small: CGFloat = 8,
        medium: CGFloat = 12,
        large: CGFloat = 16,
        xl: CGFloat = 20
    ) {
        self.xs = max(0, xs)
        self.small = max(0, small)
        self.medium = max(0, medium)
        self.large = max(0, large)
        self.xl = max(0, xl)
    }
}
