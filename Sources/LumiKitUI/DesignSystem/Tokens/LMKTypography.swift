//
//  LMKTypography.swift
//  LumiKit
//
//  Typography tokens with Dynamic Type support.
//  Proxies to `LMKTheme.current.typography` for customization.
//

import UIKit

/// Typography tokens for the Lumi design system.
///
/// Every font scales with Dynamic Type through `UIFontMetrics` and is capped by
/// the theme's `maximumScale`. These proxies resolve against the process-wide
/// theme and the current content size category; inside components prefer
/// `label.lmk_apply(.body)`, which resolves per view and re-applies on theme
/// and Dynamic Type changes.
///
/// Customize by applying a typography theme:
/// ```swift
/// LMKTheme.update { $0.typography = .init(fontFamily: "Inter") }
/// ```
public nonisolated enum LMKTypography {
    private static var config: LMKTypographyTheme {
        LMKTheme.current.typography
    }

    /// The font for `style`, scaled for `traits` (the current category when `nil`).
    public static func font(for style: LMKTextStyle, compatibleWith traits: UITraitCollection? = nil) -> UIFont {
        config.font(for: style, compatibleWith: traits)
    }

    // MARK: - Headings

    public static var h1: UIFont { font(for: .h1) }
    public static var h2: UIFont { font(for: .h2) }
    public static var h3: UIFont { font(for: .h3) }
    public static var h4: UIFont { font(for: .h4) }

    // MARK: - Body

    public static var body: UIFont { font(for: .body) }
    public static var bodyMedium: UIFont { font(for: .bodyMedium) }
    public static var bodyBold: UIFont { font(for: .bodyBold) }
    /// Subbody (between caption and body, e.g. property labels).
    public static var subbodyMedium: UIFont { font(for: .subbodyMedium) }

    // MARK: - Caption

    public static var caption: UIFont { font(for: .caption) }
    public static var captionMedium: UIFont { font(for: .captionMedium) }

    // MARK: - Small

    public static var small: UIFont { font(for: .small) }
    public static var smallMedium: UIFont { font(for: .smallMedium) }

    // MARK: - Extra Small

    public static var extraSmall: UIFont { font(for: .extraSmall) }
    public static var extraSmallMedium: UIFont { font(for: .extraSmallMedium) }
    public static var extraSmallSemibold: UIFont { font(for: .extraSmallSemibold) }

    // MARK: - Extra Extra Small

    public static var extraExtraSmall: UIFont { font(for: .extraExtraSmall) }
    public static var extraExtraSmallSemibold: UIFont { font(for: .extraExtraSmallSemibold) }

    // MARK: - Italic

    /// Italic variant of body for scientific names.
    public static var italicBody: UIFont { font(for: .italicBody) }
    /// Italic variant of caption.
    public static var italicCaption: UIFont { font(for: .italicCaption) }

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

    /// Get the line height multiplier for a typography kind.
    public static func lineHeightMultiplier(for kind: Kind) -> CGFloat {
        config.lineHeightMultiplier(for: kind)
    }

    /// Get line height for a font based on its kind.
    public static func lineHeight(for font: UIFont, type kind: Kind) -> CGFloat {
        font.pointSize * lineHeightMultiplier(for: kind)
    }

    // MARK: - Letter Spacing

    public static var headingLetterSpacing: CGFloat { config.headingLetterSpacing }
    public static var bodyLetterSpacing: CGFloat { config.bodyLetterSpacing }
    public static var smallLetterSpacing: CGFloat { config.smallLetterSpacing }

    /// Get letter spacing for a typography kind.
    public static func letterSpacing(for kind: Kind) -> CGFloat {
        config.letterSpacing(for: kind)
    }
}

/// Typography kind for determining line height and letter spacing.
public extension LMKTypography {
    nonisolated enum Kind: Sendable, Hashable, CaseIterable {
        case heading
        case body
        case caption
        case small
    }
}
