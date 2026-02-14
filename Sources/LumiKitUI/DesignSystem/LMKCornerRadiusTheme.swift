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
    public var xlarge: CGFloat
    /// For circular views.
    public var circular: CGFloat

    public init(
        xs: CGFloat = 4,
        small: CGFloat = 8,
        medium: CGFloat = 12,
        large: CGFloat = 16,
        xlarge: CGFloat = 20,
        circular: CGFloat = 999
    ) {
        self.xs = xs
        self.small = small
        self.medium = medium
        self.large = large
        self.xlarge = xlarge
        self.circular = circular
    }
}
