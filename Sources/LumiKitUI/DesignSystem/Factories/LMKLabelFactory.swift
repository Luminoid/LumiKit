//
//  LMKLabelFactory.swift
//  LumiKit
//
//  Factory methods for creating styled labels with proper line height and letter spacing.
//

import UIKit

/// Factory methods for creating styled `UILabel` instances.
public enum LMKLabelFactory {
    /// Create a heading label with proper line height and letter spacing.
    public static func heading(text: String, level: Int = 1) -> UILabel {
        let font: UIFont = switch level {
        case 1: LMKTypography.h1
        case 2: LMKTypography.h2
        case 3: LMKTypography.h3
        default: LMKTypography.h4
        }
        return createLabel(text: text, font: font, color: LMKColor.textPrimary, type: .heading)
    }

    /// Create a body label with proper line height and letter spacing.
    public static func body(text: String, color: UIColor? = nil) -> UILabel {
        createLabel(text: text, font: LMKTypography.body, color: color ?? LMKColor.textPrimary, type: .body)
    }

    /// Create a caption label with proper line height and letter spacing.
    public static func caption(text: String, color: UIColor? = nil) -> UILabel {
        createLabel(text: text, font: LMKTypography.caption, color: color ?? LMKColor.textSecondary, type: .caption)
    }

    /// Create a small label with proper line height and letter spacing.
    public static func small(text: String, color: UIColor? = nil) -> UILabel {
        createLabel(text: text, font: LMKTypography.small, color: color ?? LMKColor.textTertiary, type: .small)
    }

    /// Create a scientific name label (italic, info color, body line height).
    public static func scientificName(text: String) -> UILabel {
        createLabel(text: text, font: LMKTypography.italicBody, color: LMKColor.info, type: .body)
    }

    // MARK: - Private

    private static func createLabel(
        text: String,
        font: UIFont,
        color: UIColor,
        type: LMKTypographyType,
    ) -> UILabel {
        let label = UILabel()
        label.attributedText = attributedString(text: text, font: font, color: color, type: type)
        label.numberOfLines = 0
        return label
    }

    /// Create attributed string with line height and letter spacing.
    public static func attributedString(
        text: String,
        font: UIFont,
        color: UIColor,
        type: LMKTypographyType,
    ) -> NSAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()

        let lineHeightMultiplier: CGFloat = switch type {
        case .heading: LMKTypography.headingLineHeightMultiplier
        case .body: LMKTypography.bodyLineHeightMultiplier
        case .caption: LMKTypography.captionLineHeightMultiplier
        case .small: LMKTypography.smallLineHeightMultiplier
        }

        let fontSize = font.pointSize
        let desiredLineHeight = fontSize * lineHeightMultiplier
        paragraphStyle.minimumLineHeight = desiredLineHeight
        paragraphStyle.maximumLineHeight = desiredLineHeight
        paragraphStyle.lineSpacing = 0

        let baselineOffset = (desiredLineHeight - fontSize) / 2.0
        let letterSpacing = LMKTypography.letterSpacing(for: type)

        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: paragraphStyle,
            .kern: letterSpacing,
            .baselineOffset: baselineOffset,
        ]
        return NSAttributedString(string: text, attributes: attributes)
    }
}
