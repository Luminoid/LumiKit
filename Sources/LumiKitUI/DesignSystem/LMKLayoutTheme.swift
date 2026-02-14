//
//  LMKLayoutTheme.swift
//  LumiKit
//
//  Layout dimension configuration for customizing sizes and targets.
//

import UIKit

/// Layout dimension configuration for the Lumi design system.
///
/// Override at app launch to customize layout dimensions:
/// ```swift
/// LMKThemeManager.shared.apply(layout: .init(iconMedium: 28))
/// ```
public nonisolated struct LMKLayoutTheme: Sendable {
    /// Minimum touch target size (44pt per HIG).
    public var minimumTouchTarget: CGFloat
    /// Medium icon size.
    public var iconMedium: CGFloat
    /// Small icon size.
    public var iconSmall: CGFloat
    /// Extra small icon size (chevrons, compact indicators).
    public var iconExtraSmall: CGFloat
    /// Pull-to-refresh threshold; compact preview height.
    public var pullThreshold: CGFloat
    /// Minimum cell height; name limit.
    public var cellHeightMin: CGFloat
    /// Search bar container height.
    public var searchBarHeight: CGFloat
    /// Search bar magnifying glass icon size.
    public var searchBarIconSize: CGFloat
    /// Clear button size.
    public var clearButtonSize: CGFloat

    public init(
        minimumTouchTarget: CGFloat = 44,
        iconMedium: CGFloat = 24,
        iconSmall: CGFloat = 20,
        iconExtraSmall: CGFloat = 16,
        pullThreshold: CGFloat = 80,
        cellHeightMin: CGFloat = 100,
        searchBarHeight: CGFloat = 36,
        searchBarIconSize: CGFloat = 18,
        clearButtonSize: CGFloat = 22
    ) {
        self.minimumTouchTarget = minimumTouchTarget
        self.iconMedium = iconMedium
        self.iconSmall = iconSmall
        self.iconExtraSmall = iconExtraSmall
        self.pullThreshold = pullThreshold
        self.cellHeightMin = cellHeightMin
        self.searchBarHeight = searchBarHeight
        self.searchBarIconSize = searchBarIconSize
        self.clearButtonSize = clearButtonSize
    }
}
