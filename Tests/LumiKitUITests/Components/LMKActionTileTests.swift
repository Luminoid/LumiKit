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
    func `Accent tints the background lightly and the glyph fully; light accents darken`() {
        let (tile, window) = makeTile()
        defer { window.isHidden = true }
        tile.configure(title: "T", systemName: "star")
        let dark = UIColor(red: 0.1, green: 0.2, blue: 0.6, alpha: 1)
        tile.accentColor = dark
        #expect(tile.iconView.tintColor == dark)
        #expect(tile.backgroundColor == dark.withAlphaComponent(LMKAlpha.xxs))

        let light = UIColor(red: 0.9, green: 0.9, blue: 0.5, alpha: 1)
        tile.accentColor = light
        #expect(tile.iconView.tintColor == light.lmk_glyphTint())
        #expect(tile.iconView.tintColor != light)

        tile.accentColor = nil
        #expect(tile.iconView.tintColor == LMKColor.primary)
        #expect(tile.backgroundColor == LMKColor.backgroundSecondary)
    }

    @Test
    func `A locked accent ignores accentColor`() {
        let (tile, window) = makeTile()
        defer { window.isHidden = true }
        tile.lockedAccentColor = .red
        tile.accentColor = .blue
        #expect(tile.iconView.tintColor == UIColor.red)
        tile.lockedAccentColor = nil
        #expect(tile.iconView.tintColor == UIColor.blue)
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

    @Test
    func `Merging keeps base fields the override leaves nil`() {
        let merged = LMKActionTile.Style(iconTint: .red, titleLines: 3).merging(LMKActionTile.Style(titleLines: 1, pressAnimation: false))
        #expect(merged.iconTint == UIColor.red)
        #expect(merged.titleLines == 1)
        #expect(merged.pressAnimation == false)
        #expect(LMKActionTile.Style.defaultValue == LMKActionTile.Style())
    }
}
