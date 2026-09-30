//
//  LMKTextStyle.swift
//  LumiKit
//
//  The text-style vocabulary: named steps of the type ramp plus a custom spec.
//  Resolved into fonts by `LMKTypographyTheme.font(for:compatibleWith:)` and
//  applied with `UILabel.lmk_apply(_:color:)`.
//

import UIKit

/// A font recipe: size and weight before Dynamic Type scaling, the text style
/// whose metrics scale it, and the kind that picks line height and tracking.
public nonisolated struct LMKFontSpec: Sendable, Hashable {
    public var size: CGFloat
    public var weight: UIFont.Weight
    public var isItalic: Bool
    /// The Dynamic Type metrics the font scales with.
    public var textStyle: UIFont.TextStyle
    /// Picks the theme's line-height multiplier and letter spacing.
    public var kind: LMKTypography.Kind
    /// Upper bound for the scaled size; `nil` uses the theme's `maximumScale`.
    public var maximumPointSize: CGFloat?

    public init(
        size: CGFloat,
        weight: UIFont.Weight = .regular,
        isItalic: Bool = false,
        textStyle: UIFont.TextStyle = .body,
        kind: LMKTypography.Kind = .body,
        maximumPointSize: CGFloat? = nil
    ) {
        self.size = max(1, size)
        self.weight = weight
        self.isItalic = isItalic
        self.textStyle = textStyle
        self.kind = kind
        self.maximumPointSize = maximumPointSize
    }
}

/// A step of the type ramp, or a custom spec.
///
/// Every step scales with Dynamic Type and follows the theme's font family,
/// sizes, and weights; components store a `LMKTextStyle?` in their `Style`
/// rather than a `UIFont`, so a theme switch re-resolves the font.
public nonisolated enum LMKTextStyle: Sendable, Hashable {
    case h1
    case h2
    case h3
    case h4
    case body
    case bodyMedium
    case bodyBold
    case subbodyMedium
    case caption
    case captionMedium
    case small
    case smallMedium
    case extraSmall
    case extraSmallMedium
    case extraSmallSemibold
    case extraExtraSmall
    case extraExtraSmallSemibold
    case italicBody
    case italicCaption
    case custom(LMKFontSpec)

    /// The named steps, largest first (the custom case is excluded).
    public static let named: [Self] = [
        .h1, .h2, .h3, .h4,
        .body, .bodyMedium, .bodyBold, .subbodyMedium,
        .caption, .captionMedium,
        .small, .smallMedium,
        .extraSmall, .extraSmallMedium, .extraSmallSemibold,
        .extraExtraSmall, .extraExtraSmallSemibold,
        .italicBody, .italicCaption,
    ]

    /// The text color a label of this style gets when none is given: headings and body
    /// use `textPrimary`, captions `textSecondary`, small steps `textTertiary`.
    public var defaultColor: UIColor {
        switch kind {
        case .heading, .body: LMKColor.textPrimary
        case .caption: LMKColor.textSecondary
        case .small: LMKColor.textTertiary
        }
    }

    /// The kind that picks line height and tracking.
    public var kind: LMKTypography.Kind {
        switch self {
        case .h1, .h2, .h3, .h4: .heading
        case .body, .bodyMedium, .bodyBold, .subbodyMedium, .italicBody: .body
        case .caption, .captionMedium, .italicCaption: .caption
        case .small, .smallMedium, .extraSmall, .extraSmallMedium, .extraSmallSemibold, .extraExtraSmall, .extraExtraSmallSemibold: .small
        case let .custom(spec): spec.kind
        }
    }
}
