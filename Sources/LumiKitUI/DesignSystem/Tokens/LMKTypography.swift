//
//  LMKTypography.swift
//  LumiKit
//
//  Typography tokens with Dynamic Type support.
//  Proxies to `LMKThemeManager.shared.typography` for customization.
//

import LumiKitCore
import UIKit

/// Typography tokens for the Lumi design system.
/// All fonts scale with Dynamic Type via `UIFontMetrics`.
///
/// Customize by applying a typography theme:
/// ```swift
/// LMKThemeManager.shared.apply(typography: .init(fontFamily: "Inter"))
/// ```
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

    // MARK: - Configuration Access

    private static var config: LMKTypographyTheme {
        LMKThemeManager.shared.typography
    }

    // MARK: - Font Builder

    private static func makeFont(size: CGFloat, weight: UIFont.Weight) -> UIFont {
        if let family = config.fontFamily {
            let traits: [UIFontDescriptor.TraitKey: Any] = [.weight: weight]
            let descriptor = UIFontDescriptor(fontAttributes: [
                .family: family,
                .traits: traits,
            ])
            let font = UIFont(descriptor: descriptor, size: size)
            #if DEBUG
            let actualFamily = font.familyName
            if actualFamily != family {
                LMKLogger.debug("Font family '\(family)' not found, using '\(actualFamily)'", category: .ui)
            }
            #endif
            return font
        }
        return .systemFont(ofSize: size, weight: weight)
    }

    private static func makeItalicFont(size: CGFloat, weight: UIFont.Weight = .regular) -> UIFont {
        if let family = config.fontFamily {
            let descriptor = UIFontDescriptor(fontAttributes: [
                .family: family,
                .traits: [UIFontDescriptor.TraitKey.weight: weight],
            ])
            if let italicDescriptor = descriptor.withSymbolicTraits(.traitItalic) {
                return UIFont(descriptor: italicDescriptor, size: size)
            }
        }
        if weight == .regular {
            return .italicSystemFont(ofSize: size)
        }
        let systemFont = UIFont.systemFont(ofSize: size, weight: weight)
        if let italicDescriptor = systemFont.fontDescriptor.withSymbolicTraits([.traitItalic]) {
            return UIFont(descriptor: italicDescriptor, size: size)
        }
        return .italicSystemFont(ofSize: size)
    }

    // MARK: - Headings

    public static var h1: UIFont {
        metricsTitle1.scaledFont(for: makeFont(size: config.h1Size, weight: config.h1Weight))
    }

    public static var h2: UIFont {
        metricsTitle2.scaledFont(for: makeFont(size: config.h2Size, weight: config.h2Weight))
    }

    public static var h3: UIFont {
        metricsTitle3.scaledFont(for: makeFont(size: config.h3Size, weight: config.h3Weight))
    }

    public static var h4: UIFont {
        metricsBody.scaledFont(for: makeFont(size: config.h4Size, weight: config.h4Weight))
    }

    // MARK: - Body

    public static var body: UIFont {
        metricsBody.scaledFont(for: makeFont(size: config.bodySize, weight: .regular))
    }

    public static var bodyMedium: UIFont {
        metricsBody.scaledFont(for: makeFont(size: config.bodySize, weight: .medium))
    }

    public static var bodyBold: UIFont {
        metricsBody.scaledFont(for: makeFont(size: config.bodySize, weight: .semibold))
    }

    /// Subbody (between caption and body, e.g. property labels).
    public static var subbodyMedium: UIFont {
        metricsSubheadline.scaledFont(for: makeFont(size: config.subbodySize, weight: .medium))
    }

    // MARK: - Caption

    public static var caption: UIFont {
        metricsCaption1.scaledFont(for: makeFont(size: config.captionSize, weight: .regular))
    }

    public static var captionMedium: UIFont {
        metricsCaption1.scaledFont(for: makeFont(size: config.captionSize, weight: .medium))
    }

    // MARK: - Small

    public static var small: UIFont {
        metricsCaption2.scaledFont(for: makeFont(size: config.smallSize, weight: .regular))
    }

    public static var smallMedium: UIFont {
        metricsCaption2.scaledFont(for: makeFont(size: config.smallSize, weight: .medium))
    }

    // MARK: - Extra Small

    public static var extraSmall: UIFont {
        metricsFootnote.scaledFont(for: makeFont(size: config.extraSmallSize, weight: .regular))
    }

    public static var extraSmallMedium: UIFont {
        metricsFootnote.scaledFont(for: makeFont(size: config.extraSmallSize, weight: .medium))
    }

    public static var extraSmallSemibold: UIFont {
        metricsFootnote.scaledFont(for: makeFont(size: config.extraSmallSize, weight: .semibold))
    }

    // MARK: - Extra Extra Small

    public static var extraExtraSmall: UIFont {
        metricsFootnote.scaledFont(for: makeFont(size: config.extraExtraSmallSize, weight: .regular))
    }

    public static var extraExtraSmallSemibold: UIFont {
        metricsFootnote.scaledFont(for: makeFont(size: config.extraExtraSmallSize, weight: .semibold))
    }

    // MARK: - Italic

    /// Italic variant of body for scientific names.
    public static var italicBody: UIFont {
        metricsBody.scaledFont(for: makeItalicFont(size: config.bodySize))
    }

    /// Italic variant of caption.
    public static var italicCaption: UIFont {
        metricsCaption1.scaledFont(for: makeItalicFont(size: config.captionSize))
    }

    /// Returns italic variant of the given font, preserving weight when possible.
    public static func italic(_ font: UIFont) -> UIFont {
        guard let descriptor = font.fontDescriptor.withSymbolicTraits(.traitItalic) else {
            return UIFont.italicSystemFont(ofSize: font.pointSize)
        }
        return UIFont(descriptor: descriptor, size: font.pointSize)
    }

    // MARK: - Line Heights

    public static var headingLineHeightMultiplier: CGFloat { config.headingLineHeightMultiplier }
    public static var bodyLineHeightMultiplier: CGFloat { config.bodyLineHeightMultiplier }
    public static var captionLineHeightMultiplier: CGFloat { config.captionLineHeightMultiplier }
    public static var smallLineHeightMultiplier: CGFloat { config.smallLineHeightMultiplier }

    /// Get line height for a font based on its type.
    public static func lineHeight(for font: UIFont, type: LMKTypographyType) -> CGFloat {
        let multiplier: CGFloat = switch type {
        case .heading: headingLineHeightMultiplier
        case .body: bodyLineHeightMultiplier
        case .caption: captionLineHeightMultiplier
        case .small: smallLineHeightMultiplier
        }
        return font.pointSize * multiplier
    }

    // MARK: - Letter Spacing

    public static var headingLetterSpacing: CGFloat { config.headingLetterSpacing }
    public static var bodyLetterSpacing: CGFloat { config.bodyLetterSpacing }
    public static var smallLetterSpacing: CGFloat { config.smallLetterSpacing }

    /// Get letter spacing for a font type.
    public static func letterSpacing(for type: LMKTypographyType) -> CGFloat {
        switch type {
        case .heading: headingLetterSpacing
        case .body, .caption: bodyLetterSpacing
        case .small: smallLetterSpacing
        }
    }
}

/// Typography type for determining line height and letter spacing.
public nonisolated enum LMKTypographyType: Sendable {
    case heading
    case body
    case caption
    case small
}
