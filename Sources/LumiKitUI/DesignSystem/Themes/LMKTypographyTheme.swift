//
//  LMKTypographyTheme.swift
//  LumiKit
//
//  Typography configuration: font family, the size and weight of each step of
//  the ramp, line heights, tracking, and the Dynamic Type cap. Also the one
//  font builder (`font(for:compatibleWith:)`) every label goes through.
//

import LumiKitCore
import UIKit

/// Typography configuration for the Lumi design system.
///
/// Override at app launch to customize fonts:
/// ```swift
/// // Change font family
/// LMKTheme.update { $0.typography = .init(fontFamily: "Inter") }
///
/// // Change specific sizes
/// LMKTheme.update { $0.typography = .init(h1Size: 32, bodySize: 15) }
/// ```
public nonisolated struct LMKTypographyTheme: Sendable, Equatable {
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

    // MARK: - Dynamic Type

    /// Caps Dynamic Type growth: a step never scales past `maximumScale × size`
    /// (chrome stays usable at accessibility sizes). `0` removes the cap.
    public var maximumScale: CGFloat

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
        smallLetterSpacing: CGFloat = 0.5,
        maximumScale: CGFloat = 1.75
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
        self.maximumScale = max(0, maximumScale)
    }

    // MARK: - Specs

    /// The recipe behind a named step: size, weight, italic, Dynamic Type metrics, kind.
    public func spec(for style: LMKTextStyle) -> LMKFontSpec {
        switch style {
        case .h1: LMKFontSpec(size: h1Size, weight: h1Weight, textStyle: .title1, kind: .heading)
        case .h2: LMKFontSpec(size: h2Size, weight: h2Weight, textStyle: .title2, kind: .heading)
        case .h3: LMKFontSpec(size: h3Size, weight: h3Weight, textStyle: .title3, kind: .heading)
        case .h4: LMKFontSpec(size: h4Size, weight: h4Weight, textStyle: .body, kind: .heading)
        case .body: LMKFontSpec(size: bodySize, weight: .regular, textStyle: .body, kind: .body)
        case .bodyMedium: LMKFontSpec(size: bodySize, weight: .medium, textStyle: .body, kind: .body)
        case .bodyBold: LMKFontSpec(size: bodySize, weight: .semibold, textStyle: .body, kind: .body)
        case .subbodyMedium: LMKFontSpec(size: subbodySize, weight: .medium, textStyle: .subheadline, kind: .body)
        case .caption: LMKFontSpec(size: captionSize, weight: .regular, textStyle: .caption1, kind: .caption)
        case .captionMedium: LMKFontSpec(size: captionSize, weight: .medium, textStyle: .caption1, kind: .caption)
        case .small: LMKFontSpec(size: smallSize, weight: .regular, textStyle: .caption2, kind: .small)
        case .smallMedium: LMKFontSpec(size: smallSize, weight: .medium, textStyle: .caption2, kind: .small)
        case .extraSmall: LMKFontSpec(size: extraSmallSize, weight: .regular, textStyle: .footnote, kind: .small)
        case .extraSmallMedium: LMKFontSpec(size: extraSmallSize, weight: .medium, textStyle: .footnote, kind: .small)
        case .extraSmallSemibold: LMKFontSpec(size: extraSmallSize, weight: .semibold, textStyle: .footnote, kind: .small)
        case .extraExtraSmall: LMKFontSpec(size: extraExtraSmallSize, weight: .regular, textStyle: .footnote, kind: .small)
        case .extraExtraSmallSemibold: LMKFontSpec(size: extraExtraSmallSize, weight: .semibold, textStyle: .footnote, kind: .small)
        case .italicBody: LMKFontSpec(size: bodySize, weight: .regular, isItalic: true, textStyle: .body, kind: .body)
        case .italicCaption: LMKFontSpec(size: captionSize, weight: .regular, isItalic: true, textStyle: .caption1, kind: .caption)
        case let .custom(spec): spec
        }
    }

    // MARK: - Fonts

    /// The one font builder: the family, size, and weight of `style`, scaled with
    /// Dynamic Type for `traits` (the current category when `nil`) and capped by
    /// `maximumScale`.
    public func font(for style: LMKTextStyle, compatibleWith traits: UITraitCollection? = nil) -> UIFont {
        let spec = spec(for: style)
        let base = spec.isItalic ? makeItalicFont(size: spec.size, weight: spec.weight) : makeFont(size: spec.size, weight: spec.weight)
        let metrics = UIFontMetrics(forTextStyle: spec.textStyle)
        let cap = spec.maximumPointSize ?? (maximumScale > 0 ? spec.size * maximumScale : 0)
        if cap > 0 {
            return metrics.scaledFont(for: base, maximumPointSize: cap, compatibleWith: traits)
        }
        return metrics.scaledFont(for: base, compatibleWith: traits)
    }

    /// The unscaled font of `style` (the size before Dynamic Type).
    public func baseFont(for style: LMKTextStyle) -> UIFont {
        let spec = spec(for: style)
        return spec.isItalic ? makeItalicFont(size: spec.size, weight: spec.weight) : makeFont(size: spec.size, weight: spec.weight)
    }

    // MARK: - Line metrics

    /// The line-height multiplier for `kind`.
    public func lineHeightMultiplier(for kind: LMKTypography.Kind) -> CGFloat {
        switch kind {
        case .heading: headingLineHeightMultiplier
        case .body: bodyLineHeightMultiplier
        case .caption: captionLineHeightMultiplier
        case .small: smallLineHeightMultiplier
        }
    }

    /// The letter spacing for `kind`.
    public func letterSpacing(for kind: LMKTypography.Kind) -> CGFloat {
        switch kind {
        case .heading: headingLetterSpacing
        case .body, .caption: bodyLetterSpacing
        case .small: smallLetterSpacing
        }
    }

    /// Attributed-string attributes for `style` rendered in `font`: the font, `color`,
    /// a fixed line height, tracking, and a baseline offset that centers the glyphs
    /// in the line.
    public func attributes(for style: LMKTextStyle, font: UIFont, color: UIColor) -> [NSAttributedString.Key: Any] {
        let kind = style.kind
        let lineHeight = font.pointSize * lineHeightMultiplier(for: kind)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.minimumLineHeight = lineHeight
        paragraphStyle.maximumLineHeight = lineHeight
        paragraphStyle.lineSpacing = 0
        return [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: paragraphStyle,
            .kern: letterSpacing(for: kind),
            .baselineOffset: (lineHeight - font.pointSize) / 2,
        ]
    }

    // MARK: - Font construction

    private func makeFont(size: CGFloat, weight: UIFont.Weight) -> UIFont {
        guard let family = fontFamily else {
            return .systemFont(ofSize: size, weight: weight)
        }
        let descriptor = UIFontDescriptor(fontAttributes: [
            .family: family,
            .traits: [UIFontDescriptor.TraitKey.weight: weight],
        ])
        let font = UIFont(descriptor: descriptor, size: size)
        // Font validation is DEBUG-only: in release a missing family silently falls back to the system font.
        #if DEBUG
            if font.familyName != family {
                LMKLogger.debug("Font family '\(family)' not found, using '\(font.familyName)'", category: .ui)
            }
        #endif
        return font
    }

    private func makeItalicFont(size: CGFloat, weight: UIFont.Weight) -> UIFont {
        if let family = fontFamily {
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
}
