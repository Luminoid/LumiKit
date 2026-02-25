//
//  LMKSpacingTheme.swift
//  LumiKit
//
//  Spacing configuration for customizing the spacing grid.
//

import UIKit

/// Spacing configuration for the Lumi design system.
///
/// Override at app launch to customize spacing:
/// ```swift
/// LMKThemeManager.shared.apply(spacing: .init(large: 20, xxl: 28))
/// ```
public nonisolated struct LMKSpacingTheme: Sendable {
    /// Very tight spacing (stacked labels).
    public var xxs: CGFloat
    /// Tight spacing (icon to text).
    public var xs: CGFloat
    /// Standard spacing (elements in cards).
    public var small: CGFloat
    /// Comfortable spacing (between sections).
    public var medium: CGFloat
    /// Section spacing (card padding).
    public var large: CGFloat
    /// Large spacing (between major sections).
    public var xl: CGFloat
    /// Screen margins, large gaps.
    public var xxl: CGFloat
    /// Button vertical padding.
    public var buttonPaddingVertical: CGFloat
    /// Button horizontal padding.
    public var buttonPaddingHorizontal: CGFloat
    /// Between icons.
    public var iconSpacing: CGFloat
    /// Icon to text.
    public var iconToText: CGFloat
    /// Card padding for Mac Catalyst.
    public var cardPaddingMac: CGFloat
    /// Card padding for small iPads (≤768pt longest side).
    public var cardPaddingIPadCompact: CGFloat
    /// Card padding for regular iPads (≤1024pt longest side).
    public var cardPaddingIPadRegular: CGFloat
    /// Card padding for large iPads (>1024pt longest side).
    public var cardPaddingIPadLarge: CGFloat
    /// Cell vertical padding for Mac Catalyst.
    public var cellPaddingVerticalMac: CGFloat
    /// Cell vertical padding for small iPads (≤768pt longest side).
    public var cellPaddingVerticalIPadCompact: CGFloat
    /// Cell vertical padding for regular iPads (≤834pt longest side).
    public var cellPaddingVerticalIPadRegular: CGFloat
    /// Cell vertical padding for large iPads (>834pt longest side).
    public var cellPaddingVerticalIPadLarge: CGFloat
    /// Text view vertical content inset.
    public var textViewPaddingVertical: CGFloat
    /// Text view horizontal content inset (slightly larger than vertical
    /// because line height makes vertical spacing appear larger).
    public var textViewPaddingHorizontal: CGFloat

    public init(
        xxs: CGFloat = 2,
        xs: CGFloat = 4,
        small: CGFloat = 8,
        medium: CGFloat = 12,
        large: CGFloat = 16,
        xl: CGFloat = 20,
        xxl: CGFloat = 24,
        buttonPaddingVertical: CGFloat = 12,
        buttonPaddingHorizontal: CGFloat = 16,
        iconSpacing: CGFloat = 6,
        iconToText: CGFloat = 8,
        cardPaddingMac: CGFloat = 48,
        cardPaddingIPadCompact: CGFloat = 24,
        cardPaddingIPadRegular: CGFloat = 32,
        cardPaddingIPadLarge: CGFloat = 40,
        cellPaddingVerticalMac: CGFloat = 16,
        cellPaddingVerticalIPadCompact: CGFloat = 12,
        cellPaddingVerticalIPadRegular: CGFloat = 14,
        cellPaddingVerticalIPadLarge: CGFloat = 16,
        textViewPaddingVertical: CGFloat = 8,
        textViewPaddingHorizontal: CGFloat = 10
    ) {
        self.xxs = xxs
        self.xs = xs
        self.small = small
        self.medium = medium
        self.large = large
        self.xl = xl
        self.xxl = xxl
        self.buttonPaddingVertical = buttonPaddingVertical
        self.buttonPaddingHorizontal = buttonPaddingHorizontal
        self.iconSpacing = iconSpacing
        self.iconToText = iconToText
        self.cardPaddingMac = cardPaddingMac
        self.cardPaddingIPadCompact = cardPaddingIPadCompact
        self.cardPaddingIPadRegular = cardPaddingIPadRegular
        self.cardPaddingIPadLarge = cardPaddingIPadLarge
        self.cellPaddingVerticalMac = cellPaddingVerticalMac
        self.cellPaddingVerticalIPadCompact = cellPaddingVerticalIPadCompact
        self.cellPaddingVerticalIPadRegular = cellPaddingVerticalIPadRegular
        self.cellPaddingVerticalIPadLarge = cellPaddingVerticalIPadLarge
        self.textViewPaddingVertical = textViewPaddingVertical
        self.textViewPaddingHorizontal = textViewPaddingHorizontal
    }
}
