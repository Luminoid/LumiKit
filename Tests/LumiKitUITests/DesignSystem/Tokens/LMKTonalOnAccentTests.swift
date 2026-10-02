//
//  LMKTonalOnAccentTests.swift
//  LumiKit
//
//  A tonal theme gives `onAccent` a dark value in Dark Mode (light accents carry dark
//  text). Anything that used `onAccent` as a stand-in for white turned dark with it:
//  the dark-mode cell highlight darkened instead of lightening, and the photo-strip
//  badge glyph went dark over photos.
//

import Testing
import UIKit
@testable import LumiKitUI

@MainActor
struct LMKTonalOnAccentTests {
    private static let tonalTheme = LMKTheme(colors: LMKColorTheme(
        primary: .lmk_dynamic(lightHex: 0x2F7D57, darkHex: 0x5DBE8C),
        onAccent: .lmk_dynamic(lightHex: 0xFAFAFA, darkHex: 0x10261A)
    ))

    private func brightness(_ color: UIColor) -> CGFloat {
        var brightness: CGFloat = 0
        color.getHue(nil, saturation: nil, brightness: &brightness, alpha: nil)
        return brightness
    }

    @Test
    func `The dark-mode highlight overlay stays light when onAccent is dark`() {
        let dark = LMKThemeTesting.traits(for: Self.tonalTheme, style: .dark)
        #expect(brightness(LMKColor.onAccent.resolvedColor(with: dark)) < 0.3, "the fixture's onAccent is dark")
        let overlay = LMKHighlightConstants.highlightOverlayColor.resolvedColor(with: dark)
        #expect(brightness(overlay) > 0.8, "the overlay lightens a dark surface")
        #expect(abs(overlay.cgColor.alpha - LMKAlpha.small) < 0.001)
    }

    @Test
    func `The photo-strip badge glyph is light over photos in every appearance`() {
        let cell = LMKDetailPhotoTileCell(frame: CGRect(x: 0, y: 0, width: 80, height: 80))
        cell.overrideUserInterfaceStyle = .dark
        cell.configure(caption: nil, isSelected: false, badgeSymbol: "leaf", style: LMKDetailCardView.Style(), theme: Self.tonalTheme, tileSide: 80)
        let tint = cell.badgeView.tintColor.resolvedColor(with: LMKThemeTesting.traits(for: Self.tonalTheme, style: .dark))
        #expect(brightness(tint) > 0.9)
        #expect(cell.badgeView.isHidden == false)
    }
}
