//
//  LMKActionTileTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

@MainActor
struct LMKActionTileTests {
    private func makeTile(style: LMKActionTile.Style = LMKActionTile.Style()) -> (LMKActionTile, UIWindow) {
        let tile = LMKActionTile(style: style)
        let window = LMKThemeTesting.host(tile)
        tile.frame = CGRect(x: 0, y: 0, width: 120, height: 80)
        tile.layoutIfNeeded()
        return (tile, window)
    }

    @Test
    func `Defaults: secondary background, medium corners, primary glyph, caption title`() {
        let (tile, window) = makeTile()
        defer { window.isHidden = true }
        tile.configure(title: "Expenses", systemName: "creditcard")
        #expect(tile.backgroundColor == LMKColor.backgroundSecondary)
        #expect(tile.layer.cornerRadius == LMKCornerRadius.medium)
        #expect(tile.iconView.tintColor == LMKColor.primary)
        #expect(tile.iconView.image == UIImage(systemName: "creditcard"))
        #expect(tile.iconView.frame.width == LMKLayout.iconLarge)
        #expect(tile.titleLabel.text == "Expenses")
        #expect(tile.titleLabel.textColor == LMKColor.textSecondary)
        #expect(tile.titleLabel.font == LMKTypography.font(for: .caption, compatibleWith: tile.traitCollection))
        #expect(tile.titleLabel.numberOfLines == 2)
        #expect(tile.contentStack.spacing == LMKSpacing.xs)
        #expect(tile.accessibilityLabel == "Expenses")
        #expect(tile.accessibilityTraits.contains(.button))
        #expect(tile.showsLargeContentViewer)
        #expect(tile.largeContentTitle == "Expenses")
        #expect(tile.isAccessibilityElement)
    }

    @Test
    func `A count reads inline on the label and in the accessibility label`() {
        let (tile, window) = makeTile()
        defer { window.isHidden = true }
        tile.configure(title: "Photos", systemName: "photo", count: 3)
        #expect(tile.titleLabel.text == "Photos · 3")
        #expect(tile.accessibilityLabel == "Photos, 3")
        tile.count = 0
        #expect(tile.titleLabel.text == "Photos")
        tile.count = 12
        tile.style = LMKActionTile.Style(countSeparator: " (")
        #expect(tile.titleLabel.text == "Photos (12")
    }

    @Test
    func `Accent tints the background lightly and the glyph fully; light accents darken`() throws {
        let (tile, window) = makeTile()
        defer { window.isHidden = true }
        tile.configure(title: "T", systemName: "star")
        let dark = UIColor(red: 0.1, green: 0.2, blue: 0.6, alpha: 1)
        tile.accentColor = dark
        #expect(tile.iconView.tintColor?.resolvedColor(with: UITraitCollection(userInterfaceStyle: .light)) == dark)
        #expect(tile.backgroundColor == dark.withAlphaComponent(LMKAlpha.xxs))

        let light = UIColor(red: 0.9, green: 0.9, blue: 0.5, alpha: 1)
        tile.accentColor = light
        let lightTraits = UITraitCollection(userInterfaceStyle: .light)
        let glyph = try #require(tile.iconView.tintColor).resolvedColor(with: lightTraits)
        #expect(glyph == light.lmk_glyphTint().resolvedColor(with: lightTraits))
        #expect(glyph != light)

        tile.accentColor = nil
        #expect(tile.iconView.tintColor == LMKColor.primary)
        #expect(tile.backgroundColor == LMKColor.backgroundSecondary)
    }

    @Test
    func `A locked accent ignores accentColor`() {
        let (tile, window) = makeTile()
        defer { window.isHidden = true }
        let light = UITraitCollection(userInterfaceStyle: .light)
        tile.lockedAccentColor = .red
        tile.accentColor = .blue
        #expect(tile.iconView.tintColor?.resolvedColor(with: light) == UIColor.red.resolvedColor(with: light))
        tile.lockedAccentColor = nil
        #expect(tile.iconView.tintColor?.resolvedColor(with: light) == UIColor.blue.resolvedColor(with: light))
    }

    @Test
    func `Tap calls onTap; disabled dims and blocks it`() {
        let (tile, window) = makeTile()
        defer { window.isHidden = true }
        var taps = 0
        tile.onTap = { taps += 1 }
        tile.perform(NSSelectorFromString("handleTap"))
        #expect(taps == 1)
        tile.isEnabled = false
        #expect(abs(tile.alpha - LMKAlpha.disabled) < 0.001)
        #expect(tile.accessibilityTraits.contains(.notEnabled))
        tile.perform(NSSelectorFromString("handleTap"))
        #expect(taps == 1)
    }

    @Test
    func `Hit target: 44pt while enabled, the bounds while disabled, nothing while hidden`() {
        let tile = LMKActionTile()
        tile.frame = CGRect(x: 0, y: 0, width: 80, height: 30)
        #expect(tile.point(inside: CGPoint(x: 40, y: -6), with: nil), "a short tile still answers 44pt")
        #expect(!tile.point(inside: CGPoint(x: 40, y: -8), with: nil))
        tile.isEnabled = false
        #expect(tile.point(inside: CGPoint(x: 40, y: 15), with: nil), "a disabled tile swallows the touch like a disabled UIControl")
        #expect(!tile.point(inside: CGPoint(x: 40, y: -6), with: nil), "without the expanded area")
        tile.isEnabled = true
        tile.isHidden = true
        #expect(!tile.point(inside: CGPoint(x: 40, y: 15), with: nil))
    }

    private static func brightness(_ color: UIColor?, _ traits: UITraitCollection) -> CGFloat {
        var value: CGFloat = 0
        color?.resolvedColor(with: traits).getHue(nil, saturation: nil, brightness: &value, alpha: nil)
        return value
    }

    @Test
    func `Pressed shades the fill, and the state styles apply every field`() {
        let (tile, window) = makeTile(style: LMKActionTile.Style(surface: LMKSurfaceStyle(background: .solid(UIColor(white: 0.6, alpha: 1)))))
        defer { window.isHidden = true }
        tile.isHighlighted = true
        #expect(abs(Self.brightness(tile.backgroundColor, tile.traitCollection) - 0.6 * 0.85) < 0.01, "a press shows without motion")
        #expect(tile.alpha == 1)
        #expect(tile.transform == .identity, "the press animation owns the transform")
        tile.isHighlighted = false
        #expect(abs(Self.brightness(tile.backgroundColor, tile.traitCollection) - 0.6) < 0.01)

        var styled = LMKActionTile.Style()
        styled.highlighted = LMKControlStateStyle(foregroundColor: .black, scale: 0.9, shadow: .level(.level2))
        styled.disabled = LMKControlStateStyle(foregroundColor: .gray, border: .solid(.red, width: 2), scale: 0.8, shadow: .level(.level1))
        tile.style = styled
        tile.isHighlighted = true
        #expect(tile.iconView.tintColor == UIColor.black)
        #expect(abs(tile.transform.a - 0.9) < 0.001, "a state scale is applied as set")
        #expect(tile.layer.shadowOpacity > 0)
        tile.isHighlighted = false
        #expect(tile.transform == .identity)
        #expect(tile.layer.shadowOpacity == 0)
        tile.isEnabled = false
        #expect(tile.iconView.tintColor == UIColor.gray)
        #expect(tile.layer.borderWidth == LMKLayout.pixelAligned(2, for: tile))
        #expect(abs(tile.transform.a - 0.8) < 0.001)
        #expect(tile.layer.shadowOpacity > 0)
        #expect(abs(tile.alpha - LMKAlpha.disabled) < 0.001, "the disabled alpha still applies")
    }

    @Test
    func `Content insets and the icon size update in place`() {
        let (tile, window) = makeTile()
        defer { window.isHidden = true }
        tile.configure(title: "T", systemName: "star")
        tile.style.surface.contentInsets = .lmk_all(12)
        tile.style.iconSize = 18
        tile.frame = CGRect(x: 0, y: 0, width: 60, height: 60)
        tile.layoutIfNeeded()
        #expect(tile.iconView.frame.width == 18)
        #expect(tile.contentStack.frame.minY >= 12)
        #expect(tile.contentStack.frame.minX >= 12)
    }

    @Test
    func `Style and theme.actionTile restyle the tile`() {
        let (tile, window) = makeTile(style: LMKActionTile.Style(
            surface: LMKSurfaceStyle(background: .solid(.yellow), corners: .fixed(4)),
            iconTint: .purple,
            iconSize: 20,
            titleTextStyle: .bodyBold,
            titleColor: .brown,
            titleLines: 1,
            spacing: 9
        ))
        defer { window.isHidden = true }
        tile.configure(title: "T", systemName: "star")
        #expect(tile.backgroundColor == UIColor.yellow)
        #expect(tile.layer.cornerRadius == 4)
        #expect(tile.iconView.tintColor == UIColor.purple)
        #expect(tile.iconView.frame.width == 20)
        #expect(tile.titleLabel.textColor == UIColor.brown)
        #expect(tile.titleLabel.numberOfLines == 1)
        #expect(tile.contentStack.spacing == 9)

        var theme = LMKTheme()
        theme.actionTile = LMKActionTile.Style(iconTint: .magenta, accentBackgroundAlpha: 0.5)
        let (themed, themedWindow) = makeTile()
        defer { themedWindow.isHidden = true }
        themed.configure(title: "T", systemName: "star")
        themed.applyTheme(theme)
        #expect(themed.iconView.tintColor == UIColor.magenta)
        themed.accentColor = .black
        themed.applyTheme(theme)
        #expect(themed.backgroundColor == UIColor.black.withAlphaComponent(0.5))
    }

    // MARK: - Glyph contrast

    private static func traits(_ style: UIUserInterfaceStyle, contrast: UIAccessibilityContrast = .normal) -> UITraitCollection {
        LMKThemeTesting.traits(for: LMKTheme(), style: style, contrast: contrast)
    }

    /// The tile's resolved glyph against its resolved accent wash over the page.
    private static func glyphContrast(_ tile: LMKActionTile, accent: UIColor, _ traits: UITraitCollection) -> CGFloat {
        let wash = accent.lmk_composited(over: LMKColor.backgroundPrimary, alpha: LMKAlpha.xxs)
        return (tile.iconView.tintColor ?? .clear).lmk_contrastRatio(to: wash, resolvedWith: traits)
    }

    @Test
    func `glyphMinimumContrast softens a deep accent to the ratio on the light page`() throws {
        let (tile, window) = makeTile(style: LMKActionTile.Style(glyphMinimumContrast: 3.3))
        defer { window.isHidden = true }
        let accent = UIColor(lmk_hex: 0x1F4FA8)
        tile.accentColor = accent
        let light = Self.traits(.light)
        let ratio = Self.glyphContrast(tile, accent: accent, light)
        #expect(ratio >= 3.3 - 0.001)
        #expect(ratio < 3.4, "the softest tone that still passes")
        let glyph = try #require(tile.iconView.tintColor).resolvedColor(with: light)
        #expect(glyph.lmk_relativeLuminance(resolvedWith: light) > accent.lmk_relativeLuminance(resolvedWith: light))
        #expect(tile.backgroundColor == accent.withAlphaComponent(LMKAlpha.xxs), "the wash stays the accent's")
    }

    @Test
    func `glyphMinimumContrast darkens a pale accent just enough`() {
        let (tile, window) = makeTile(style: LMKActionTile.Style(glyphMinimumContrast: 3))
        defer { window.isHidden = true }
        let accent = UIColor(lmk_hex: 0xF2D16B)
        tile.accentColor = accent
        let ratio = Self.glyphContrast(tile, accent: accent, Self.traits(.light))
        #expect(ratio >= 3 - 0.001)
        #expect(ratio < 3.1)
    }

    @Test
    func `Dark Mode keeps the accent while it passes, and Increase Contrast raises the floor to 4.5`() throws {
        let (tile, window) = makeTile(style: LMKActionTile.Style(glyphMinimumContrast: 3))
        defer { window.isHidden = true }
        let accent = UIColor.lmk_dynamic(light: UIColor(lmk_hex: 0x2F7D57), dark: UIColor(lmk_hex: 0x7FD8A8))
        tile.accentColor = accent
        let dark = Self.traits(.dark)
        let glyph = try #require(tile.iconView.tintColor)
        #expect(glyph.resolvedColor(with: dark).lmk_hexString == accent.resolvedColor(with: dark).lmk_hexString, "the dark tone already passes")
        #expect(Self.glyphContrast(tile, accent: accent, Self.traits(.light, contrast: .high)) >= 4.5 - 0.001)
        #expect(Self.glyphContrast(tile, accent: accent, Self.traits(.dark, contrast: .high)) >= 4.5 - 0.001)

        // A dark accent on the dark page fails and lightens until it passes.
        let deep = UIColor(lmk_hex: 0x3A2F6B)
        tile.accentColor = deep
        #expect(Self.glyphContrast(tile, accent: deep, dark) >= 3 - 0.001)
    }

    @Test
    func `Without an accent the glyph is measured against the tile's fill; a gradient fill leaves it alone`() {
        let (tile, window) = makeTile(style: LMKActionTile.Style(iconTint: .black, glyphMinimumContrast: 4.5))
        defer { window.isHidden = true }
        let light = Self.traits(.light)
        let ratio = (tile.iconView.tintColor ?? .clear).lmk_contrastRatio(to: LMKColor.backgroundSecondary, resolvedWith: light)
        #expect(abs(ratio - 4.5) < 0.02, "black softens to the gray that keeps 4.5 on the secondary background")

        tile.style.surface.background = .gradient(colors: [.red, .blue], direction: .leftToRight)
        #expect(tile.iconView.tintColor == UIColor.black)

        var plain = LMKActionTile.Style()
        plain.iconTint = .black
        tile.style = plain
        #expect(tile.iconView.tintColor == UIColor.black, "nil keeps the tint as given")
    }

    @Test
    func `A state's foreground color still wins over the contrast tone`() {
        var style = LMKActionTile.Style(glyphMinimumContrast: 3)
        style.highlighted = LMKControlStateStyle(foregroundColor: .orange)
        let (tile, window) = makeTile(style: style)
        defer { window.isHidden = true }
        tile.accentColor = .blue
        tile.isHighlighted = true
        #expect(tile.iconView.tintColor == UIColor.orange)
    }

    // MARK: - Title scaling and height

    @Test
    func `titleMinimumScaleFactor shrinks the title, and clearing it restores the label`() {
        let (tile, window) = makeTile(style: LMKActionTile.Style(titleMinimumScaleFactor: 0.7))
        defer { window.isHidden = true }
        #expect(tile.titleLabel.adjustsFontSizeToFitWidth)
        #expect(abs(tile.titleLabel.minimumScaleFactor - 0.7) < 0.001)
        #expect(tile.titleLabel.lineBreakMode == .byTruncatingTail)
        tile.style.titleMinimumScaleFactor = nil
        #expect(!tile.titleLabel.adjustsFontSizeToFitWidth)
        #expect(tile.titleLabel.minimumScaleFactor == 0)

        // Left nil, a theme pass keeps what the host set on the label itself.
        let (hosted, hostedWindow) = makeTile()
        defer { hostedWindow.isHidden = true }
        hosted.titleLabel.adjustsFontSizeToFitWidth = true
        hosted.titleLabel.minimumScaleFactor = 0.5
        hosted.applyTheme(LMKTheme())
        #expect(hosted.titleLabel.adjustsFontSizeToFitWidth)
        #expect(hosted.titleLabel.minimumScaleFactor == 0.5)
    }

    @Test
    func `minimumHeight is a floor that the content can exceed, and frame hosts keep their frames`() {
        let tile = LMKActionTile(style: LMKActionTile.Style(minimumHeight: 90))
        tile.configure(title: "Vet", systemName: "cross.case")
        let window = LMKThemeTesting.host(tile)
        defer { window.isHidden = true }
        func fittingHeight(_ width: CGFloat) -> CGFloat {
            tile.systemLayoutSizeFitting(
                CGSize(width: width, height: UIView.layoutFittingCompressedSize.height),
                withHorizontalFittingPriority: .required,
                verticalFittingPriority: .fittingSizeLevel
            ).height
        }
        #expect(abs(fittingHeight(80) - 90) < 0.5)
        tile.style.minimumHeight = nil
        #expect(fittingHeight(80) < 90)
        tile.style.minimumHeight = 20
        #expect(fittingHeight(80) > 20, "the content outgrows a short floor")
        #expect(tile.translatesAutoresizingMaskIntoConstraints, "the floor sits on a layout guide, not the tile")
        tile.frame = CGRect(x: 0, y: 0, width: 80, height: 30)
        tile.style.minimumHeight = 90
        tile.layoutIfNeeded()
        #expect(tile.frame.height == 30)
    }

    @Test
    func `The large content viewer shows the title and glyph, and lifting on the tile taps it`() throws {
        let (tile, window) = makeTile()
        defer { window.isHidden = true }
        tile.configure(title: "Medications", systemName: "pills")
        #expect(tile.showsLargeContentViewer)
        #expect(tile.scalesLargeContentImage)
        #expect(tile.largeContentTitle == "Medications")
        #expect(tile.largeContentImage == UIImage(systemName: "pills"))
        let interaction = try #require(tile.interactions.compactMap { $0 as? UILargeContentViewerInteraction }.first)
        var taps = 0
        tile.onTap = { taps += 1 }
        tile.largeContentViewerInteraction(interaction, didEndOn: tile, at: CGPoint(x: 10, y: 10))
        #expect(taps == 1)
        tile.largeContentViewerInteraction(interaction, didEndOn: tile, at: CGPoint(x: -50, y: 10))
        tile.largeContentViewerInteraction(interaction, didEndOn: nil, at: CGPoint(x: 10, y: 10))
        #expect(taps == 1, "outside the tile or on no item is no tap")
    }

    @Test
    func `Merging keeps base fields the override leaves nil`() {
        let merged = LMKActionTile.Style(iconTint: .red, titleLines: 3).merging(LMKActionTile.Style(titleLines: 1, pressAnimation: false))
        #expect(merged.iconTint == UIColor.red)
        #expect(merged.titleLines == 1)
        #expect(merged.pressAnimation == false)
        #expect(LMKActionTile.Style.defaultValue == LMKActionTile.Style())
        let contrast = LMKActionTile.Style(glyphMinimumContrast: 3, titleMinimumScaleFactor: 0.7, minimumHeight: 60)
            .merging(LMKActionTile.Style(minimumHeight: 72))
        #expect(contrast.glyphMinimumContrast == 3)
        #expect(contrast.titleMinimumScaleFactor == 0.7)
        #expect(contrast.minimumHeight == 72)
    }
}
