//
//  LMKTextStyleTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

// MARK: - LMKTypographyTheme.font(for:)

struct LMKTextStyleFontTests {
    private static let theme = LMKTypographyTheme()
    private static let large = UITraitCollection(preferredContentSizeCategory: .large)
    private static let ax5 = UITraitCollection(preferredContentSizeCategory: .accessibilityExtraExtraExtraLarge)

    @Test
    func `Named steps resolve to the theme's sizes and weights at the default category`() {
        let theme = Self.theme
        #expect(theme.font(for: .h1, compatibleWith: Self.large).pointSize == theme.h1Size)
        #expect(theme.font(for: .body, compatibleWith: Self.large).pointSize == theme.bodySize)
        #expect(theme.font(for: .caption, compatibleWith: Self.large).pointSize == theme.captionSize)
        #expect(theme.font(for: .small, compatibleWith: Self.large).pointSize == theme.smallSize)
        #expect(theme.font(for: .extraExtraSmall, compatibleWith: Self.large).pointSize == theme.extraExtraSmallSize)
        #expect(theme.spec(for: .h1).weight == theme.h1Weight)
        #expect(theme.spec(for: .bodyBold).weight == .semibold)
        #expect(theme.spec(for: .italicBody).isItalic)
        #expect(theme.font(for: .italicCaption, compatibleWith: Self.large).fontDescriptor.symbolicTraits.contains(.traitItalic))
    }

    @Test
    func `Every named step has a spec and a kind`() {
        for style in LMKTextStyle.named {
            let spec = Self.theme.spec(for: style)
            #expect(spec.size > 0, "\(style)")
            #expect(spec.kind == style.kind, "\(style)")
        }
        #expect(LMKTextStyle.h2.kind == .heading)
        #expect(LMKTextStyle.subbodyMedium.kind == .body)
        #expect(LMKTextStyle.captionMedium.kind == .caption)
        #expect(LMKTextStyle.extraSmallSemibold.kind == .small)
    }

    @Test
    func `Fonts grow with Dynamic Type up to maximumScale`() {
        let theme = Self.theme
        let regular = theme.font(for: .body, compatibleWith: Self.large).pointSize
        let accessibility = theme.font(for: .body, compatibleWith: Self.ax5).pointSize
        #expect(accessibility > regular)
        #expect(accessibility <= theme.bodySize * theme.maximumScale)

        let uncapped = LMKTypographyTheme(maximumScale: 0)
        #expect(uncapped.font(for: .body, compatibleWith: Self.ax5).pointSize > theme.bodySize * theme.maximumScale)
    }

    @Test
    func `A custom spec picks its own cap and metrics`() {
        let spec = LMKFontSpec(size: 20, weight: .bold, textStyle: .title2, kind: .heading, maximumPointSize: 24)
        let font = Self.theme.font(for: .custom(spec), compatibleWith: Self.ax5)
        #expect(font.pointSize == 24)
        #expect(LMKTextStyle.custom(spec).kind == .heading)
        #expect(Self.theme.baseFont(for: .custom(spec)).pointSize == 20)
    }

    @Test
    func `Attributes carry a fixed line height, tracking, and baseline offset`() throws {
        let theme = Self.theme
        let font = theme.baseFont(for: .body)
        let attributes = theme.attributes(for: .body, font: font, color: .red)
        let paragraph = try #require(attributes[.paragraphStyle] as? NSParagraphStyle)
        #expect(paragraph.minimumLineHeight == font.pointSize * theme.bodyLineHeightMultiplier)
        #expect(paragraph.maximumLineHeight == paragraph.minimumLineHeight)
        #expect(attributes[.kern] as? CGFloat == theme.bodyLetterSpacing)
        #expect(attributes[.baselineOffset] as? CGFloat == (paragraph.minimumLineHeight - font.pointSize) / 2)
        #expect(attributes[.foregroundColor] as? UIColor == UIColor.red)
    }

    @Test
    func `Default colors follow the kind`() {
        #expect(LMKTextStyle.h1.defaultColor === LMKColor.textPrimary)
        #expect(LMKTextStyle.body.defaultColor === LMKColor.textPrimary)
        #expect(LMKTextStyle.caption.defaultColor === LMKColor.textSecondary)
        #expect(LMKTextStyle.small.defaultColor === LMKColor.textTertiary)
    }
}

// MARK: - UILabel.lmk_apply

@MainActor
struct UILabelTextStyleTests {
    @Test
    func `lmk_apply sets the font, Dynamic Type, and color`() {
        let label = UILabel()
        label.lmk_apply(.h2, color: .red)
        #expect(label.font.pointSize == LMKTheme.current.typography.font(for: .h2, compatibleWith: label.traitCollection).pointSize)
        #expect(label.adjustsFontForContentSizeCategory)
        #expect(label.textColor == UIColor.red)
        #expect(label.lmk_textStyle == .h2)
    }

    @Test
    func `lmk_apply without a color leaves the label's color alone`() {
        let label = UILabel()
        label.textColor = .blue
        label.lmk_apply(.body)
        #expect(label.textColor == UIColor.blue)
    }

    @Test
    func `lmk_make renders line metrics and keeps them through lmk_setText`() throws {
        let label = UILabel.lmk_make(.body, text: "Hello")
        #expect(label.numberOfLines == 0)
        #expect(label.text == "Hello")
        let attributed = try #require(label.attributedText)
        #expect(attributed.attribute(.paragraphStyle, at: 0, effectiveRange: nil) != nil)
        #expect((attributed.attribute(.font, at: 0, effectiveRange: nil) as? UIFont)?.pointSize == label.font.pointSize)
        #expect(attributed.attribute(.foregroundColor, at: 0, effectiveRange: nil) as? UIColor == LMKColor.textPrimary)

        label.lmk_setText("World")
        #expect(label.text == "World")
        #expect(label.attributedText?.attribute(.paragraphStyle, at: 0, effectiveRange: nil) != nil)
    }

    @Test
    func `lmk_make uses the style's default color`() {
        #expect(UILabel.lmk_make(.caption, text: "x").textColor == LMKColor.textSecondary)
        #expect(UILabel.lmk_make(.small, text: "x").textColor == LMKColor.textTertiary)
        #expect(UILabel.lmk_make(.h3, text: "x", color: .red).textColor == UIColor.red)
    }

    @Test
    func `The font re-applies when the content size category changes`() {
        let label = UILabel()
        label.text = "Dynamic"
        let window = LMKThemeTesting.host(label)
        defer { window.isHidden = true }
        window.traitOverrides.preferredContentSizeCategory = .large
        label.updateTraitsIfNeeded()
        label.lmk_apply(.body)
        let regular = label.font.pointSize

        window.traitOverrides.preferredContentSizeCategory = .accessibilityExtraExtraExtraLarge
        label.updateTraitsIfNeeded()
        #expect(label.font.pointSize > regular)
        #expect(label.font.pointSize <= LMKTheme.current.typography.bodySize * LMKTheme.current.typography.maximumScale)
    }

    @Test
    func `The font re-applies when the traits' theme changes`() {
        let label = UILabel()
        let window = LMKThemeTesting.host(label)
        defer { window.isHidden = true }
        window.traitOverrides.preferredContentSizeCategory = .large
        label.updateTraitsIfNeeded()
        label.lmk_apply(.body)
        #expect(label.font.pointSize == LMKTheme.current.typography.bodySize)

        window.traitOverrides.lmkTheme = LMKThemeReference(LMKThemeTesting.distinct)
        label.updateTraitsIfNeeded()
        #expect(label.font.pointSize == LMKThemeTesting.distinct.typography.bodySize)
    }

    @Test
    func `Text fields and text views apply styles too`() {
        let field = UITextField()
        field.lmk_apply(.caption, color: .red)
        #expect(field.font?.pointSize == LMKTheme.current.typography.font(for: .caption, compatibleWith: field.traitCollection).pointSize)
        #expect(field.adjustsFontForContentSizeCategory)
        #expect(field.textColor == UIColor.red)

        let textView = UITextView()
        textView.lmk_apply(.body)
        #expect(textView.font?.pointSize == LMKTheme.current.typography.font(for: .body, compatibleWith: textView.traitCollection).pointSize)
        #expect(textView.adjustsFontForContentSizeCategory)
    }
}
