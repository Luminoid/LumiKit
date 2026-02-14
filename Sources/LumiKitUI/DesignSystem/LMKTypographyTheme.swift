//
//  LMKTypographyTheme.swift
//  LumiKit
//
//  Typography configuration for customizing fonts, sizes, and text metrics.
//

import UIKit

/// Typography configuration for the Lumi design system.
///
/// Override at app launch to customize fonts:
/// ```swift
/// // Change font family
/// LMKThemeManager.shared.apply(typography: .init(fontFamily: "Inter"))
///
/// // Change specific sizes
/// LMKThemeManager.shared.apply(typography: .init(h1Size: 32, bodySize: 15))
/// ```
public nonisolated struct LMKTypographyTheme: Sendable {
    /// Custom font family name. `nil` uses the system font (default).
    public var fontFamily: String?

    // MARK: - Heading Sizes

    public var h1Size: CGFloat
    public var h1Weight: UIFont.Weight
    public var h2Size: CGFloat
    public var h2Weight: UIFont.Weight
    public var h3Size: CGFloat
    public var h3Weight: UIFont.Weight
    public var h4Size: CGFloat
    public var h4Weight: UIFont.Weight

    // MARK: - Body Sizes

    public var bodySize: CGFloat
    public var subbodySize: CGFloat

    // MARK: - Caption & Small Sizes

    public var captionSize: CGFloat
    public var smallSize: CGFloat
    public var extraSmallSize: CGFloat
    public var extraExtraSmallSize: CGFloat

    // MARK: - Line Height Multipliers

    public var headingLineHeightMultiplier: CGFloat
    public var bodyLineHeightMultiplier: CGFloat
    public var captionLineHeightMultiplier: CGFloat
    public var smallLineHeightMultiplier: CGFloat

    // MARK: - Letter Spacing

    public var headingLetterSpacing: CGFloat
    public var bodyLetterSpacing: CGFloat
    public var smallLetterSpacing: CGFloat

    public init(
        fontFamily: String? = nil,
        h1Size: CGFloat = 28,
        h1Weight: UIFont.Weight = .bold,
        h2Size: CGFloat = 22,
        h2Weight: UIFont.Weight = .semibold,
        h3Size: CGFloat = 18,
        h3Weight: UIFont.Weight = .semibold,
        h4Size: CGFloat = 16,
        h4Weight: UIFont.Weight = .semibold,
        bodySize: CGFloat = 16,
        subbodySize: CGFloat = 14,
        captionSize: CGFloat = 13,
        smallSize: CGFloat = 12,
        extraSmallSize: CGFloat = 11,
        extraExtraSmallSize: CGFloat = 10,
        headingLineHeightMultiplier: CGFloat = 1.2,
        bodyLineHeightMultiplier: CGFloat = 1.5,
        captionLineHeightMultiplier: CGFloat = 1.4,
        smallLineHeightMultiplier: CGFloat = 1.4,
        headingLetterSpacing: CGFloat = -0.5,
        bodyLetterSpacing: CGFloat = 0,
        smallLetterSpacing: CGFloat = 0.5
    ) {
        self.fontFamily = fontFamily
        self.h1Size = h1Size
        self.h1Weight = h1Weight
        self.h2Size = h2Size
        self.h2Weight = h2Weight
        self.h3Size = h3Size
        self.h3Weight = h3Weight
        self.h4Size = h4Size
        self.h4Weight = h4Weight
        self.bodySize = bodySize
        self.subbodySize = subbodySize
        self.captionSize = captionSize
        self.smallSize = smallSize
        self.extraSmallSize = extraSmallSize
        self.extraExtraSmallSize = extraExtraSmallSize
        self.headingLineHeightMultiplier = headingLineHeightMultiplier
        self.bodyLineHeightMultiplier = bodyLineHeightMultiplier
        self.captionLineHeightMultiplier = captionLineHeightMultiplier
        self.smallLineHeightMultiplier = smallLineHeightMultiplier
        self.headingLetterSpacing = headingLetterSpacing
        self.bodyLetterSpacing = bodyLetterSpacing
        self.smallLetterSpacing = smallLetterSpacing
    }
}
