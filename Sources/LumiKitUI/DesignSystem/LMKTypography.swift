//
//  LMKTypography.swift
//  LumiKit
//
//  Typography tokens with Dynamic Type support.
//

import UIKit

/// Typography tokens for the Lumi design system.
/// All fonts scale with Dynamic Type via `UIFontMetrics`.
public enum LMKTypography {
    // MARK: - Font Metrics

    private static let metricsTitle1 = UIFontMetrics(forTextStyle: .title1)
    private static let metricsTitle2 = UIFontMetrics(forTextStyle: .title2)
    private static let metricsTitle3 = UIFontMetrics(forTextStyle: .title3)
    private static let metricsBody = UIFontMetrics(forTextStyle: .body)
    private static let metricsSubheadline = UIFontMetrics(forTextStyle: .subheadline)
    private static let metricsCaption1 = UIFontMetrics(forTextStyle: .caption1)
    private static let metricsCaption2 = UIFontMetrics(forTextStyle: .caption2)
    private static let metricsFootnote = UIFontMetrics(forTextStyle: .footnote)

    // MARK: - Headings

    public static let h1 = metricsTitle1.scaledFont(for: .systemFont(ofSize: 28, weight: .bold))
    public static let h2 = metricsTitle2.scaledFont(for: .systemFont(ofSize: 22, weight: .semibold))
    public static let h3 = metricsTitle3.scaledFont(for: .systemFont(ofSize: 18, weight: .semibold))
    public static let h4 = metricsBody.scaledFont(for: .systemFont(ofSize: 16, weight: .semibold))

    // MARK: - Body

    public static let body = metricsBody.scaledFont(for: .systemFont(ofSize: 16, weight: .regular))
    public static let bodyMedium = metricsBody.scaledFont(for: .systemFont(ofSize: 16, weight: .medium))
    public static let bodyBold = metricsBody.scaledFont(for: .systemFont(ofSize: 16, weight: .semibold))

    /// Subbody (between caption and body, e.g. property labels).
    public static let subbodyMedium = metricsSubheadline.scaledFont(for: .systemFont(ofSize: 14, weight: .medium))

    // MARK: - Caption

    public static let caption = metricsCaption1.scaledFont(for: .systemFont(ofSize: 13, weight: .regular))
    public static let captionMedium = metricsCaption1.scaledFont(for: .systemFont(ofSize: 13, weight: .medium))

    // MARK: - Small

    public static let small = metricsCaption2.scaledFont(for: .systemFont(ofSize: 12, weight: .regular))
    public static let smallMedium = metricsCaption2.scaledFont(for: .systemFont(ofSize: 12, weight: .medium))

    // MARK: - Extra Small

    public static let extraSmall = metricsFootnote.scaledFont(for: .systemFont(ofSize: 11, weight: .regular))
    public static let extraSmallMedium = metricsFootnote.scaledFont(for: .systemFont(ofSize: 11, weight: .medium))
    public static let extraSmallSemibold = metricsFootnote.scaledFont(for: .systemFont(ofSize: 11, weight: .semibold))

    // MARK: - Extra Extra Small

    public static let extraExtraSmall = metricsFootnote.scaledFont(for: .systemFont(ofSize: 10, weight: .regular))
    public static let extraExtraSmallSemibold = metricsFootnote.scaledFont(for: .systemFont(ofSize: 10, weight: .semibold))

    // MARK: - Italic

    /// Italic variant of body (16pt) for scientific names.
    public static let italicBody = metricsBody.scaledFont(for: .italicSystemFont(ofSize: 16))

    /// Italic variant of caption (13pt).
    public static let italicCaption = metricsCaption1.scaledFont(for: .italicSystemFont(ofSize: 13))

    /// Returns italic variant of the given font, preserving weight when possible.
    public static func italic(_ font: UIFont) -> UIFont {
        guard let descriptor = font.fontDescriptor.withSymbolicTraits(.traitItalic) else {
            return UIFont.italicSystemFont(ofSize: font.pointSize)
        }
        return UIFont(descriptor: descriptor, size: font.pointSize)
    }

    // MARK: - Line Heights

    public static let headingLineHeightMultiplier: CGFloat = 1.2
    public static let bodyLineHeightMultiplier: CGFloat = 1.5
    public static let captionLineHeightMultiplier: CGFloat = 1.4
    public static let smallLineHeightMultiplier: CGFloat = 1.4

    /// Get line height for a font based on its type.
    public static func lineHeight(for font: UIFont, type: LMKTypographyType) -> CGFloat {
        let multiplier: CGFloat
        switch type {
        case .heading: multiplier = headingLineHeightMultiplier
        case .body: multiplier = bodyLineHeightMultiplier
        case .caption: multiplier = captionLineHeightMultiplier
        case .small: multiplier = smallLineHeightMultiplier
        }
        return font.pointSize * multiplier
    }

    // MARK: - Letter Spacing

    public static let headingLetterSpacing: CGFloat = -0.5
    public static let bodyLetterSpacing: CGFloat = 0
    public static let smallLetterSpacing: CGFloat = 0.5

    /// Get letter spacing for a font type.
    public static func letterSpacing(for type: LMKTypographyType) -> CGFloat {
        switch type {
        case .heading: return headingLetterSpacing
        case .body, .caption: return bodyLetterSpacing
        case .small: return smallLetterSpacing
        }
    }
}

/// Typography type for determining line height and letter spacing.
public enum LMKTypographyType {
    case heading
    case body
    case caption
    case small
}
