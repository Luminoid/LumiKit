//
//  UIColorLMKTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

// MARK: - UIColor+LMK

@MainActor
struct UIColorLMKTests {
    @Test
    func `UInt32 hex init produces matching RGB`() {
        let color = UIColor(lmk_hex: 0x7C5CFF)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        #expect(abs(r - 0x7C / 255.0) < 0.01)
        #expect(abs(g - 0x5C / 255.0) < 0.01)
        #expect(abs(b - 0xFF / 255.0) < 0.01)
        #expect(abs(a - 1.0) < 0.01)
    }

    @Test
    func `UInt32 hex init with alpha`() {
        let color = UIColor(lmk_hex: 0x7C5CFF, alpha: 0.5)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        #expect(abs(a - 0.5) < 0.01)
    }

    @Test
    func `UInt32 hex init ignores bits above 24`() {
        // 0xFF7C5CFF should produce the same RGB as 0x7C5CFF (alpha byte ignored).
        let masked = UIColor(lmk_hex: 0xFF7C_5CFF)
        let bare = UIColor(lmk_hex: 0x7C5CFF)
        #expect(masked.lmk_hexString == bare.lmk_hexString)
    }

    @Test
    func `Dynamic light dark resolves correctly`() {
        let color = UIColor.lmk_dynamic(lightHex: 0x694ED9, darkHex: 0x553BBF)
        let lightTraits = UITraitCollection(userInterfaceStyle: .light)
        let darkTraits = UITraitCollection(userInterfaceStyle: .dark)

        let lightVariant = color.resolvedColor(with: lightTraits)
        let darkVariant = color.resolvedColor(with: darkTraits)

        #expect(lightVariant.lmk_hexString == "694ED9")
        #expect(darkVariant.lmk_hexString == "553BBF")
    }

    @Test
    func `Hex init with # prefix`() {
        let color = UIColor(lmk_hex: "#FF0000")
        #expect(color != nil)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color?.getRed(&r, green: &g, blue: &b, alpha: &a)
        #expect(abs(r - 1.0) < 0.01)
        #expect(abs(g) < 0.01)
        #expect(abs(b) < 0.01)
    }

    @Test
    func `Hex init without prefix`() {
        let color = UIColor(lmk_hex: "00FF00")
        #expect(color != nil)
    }

    @Test
    func `Hex init with 8-char RGBA`() {
        let color = UIColor(lmk_hex: "#FF000080")
        #expect(color != nil)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color?.getRed(&r, green: &g, blue: &b, alpha: &a)
        #expect(abs(a - 128.0 / 255.0) < 0.01)
    }

    @Test
    func `Hex init with invalid string returns nil`() {
        #expect(UIColor(lmk_hex: "xyz") == nil)
        #expect(UIColor(lmk_hex: "#12345") == nil)
        #expect(UIColor(lmk_hex: "") == nil)
    }

    /// The regression: `Scanner` accepted any valid prefix, so a stray character or a `0x`
    /// prefix parsed as some other color instead of failing.
    @Test
    func `Hex init rejects strings with non-hex characters`() {
        #expect(UIColor(lmk_hex: "#12345G") == nil)
        #expect(UIColor(lmk_hex: "12 456") == nil)
        #expect(UIColor(lmk_hex: "0x1234") == nil)
        #expect(UIColor(lmk_hex: "+ABCDEF") == nil)
        #expect(UIColor(lmk_hex: " #aBcDeF ")?.lmk_hexString == "ABCDEF", "whitespace is trimmed, case is free")
    }

    @Test
    func `lmk_isVisuallyEqual samples both appearances`() {
        let dynamic = UIColor.lmk_dynamic(light: .red, dark: .blue)
        #expect(dynamic.lmk_isVisuallyEqual(to: .lmk_dynamic(light: .red, dark: .blue)))
        #expect(!dynamic.lmk_isVisuallyEqual(to: .lmk_dynamic(light: .red, dark: .green)))
        #expect(!dynamic.lmk_isVisuallyEqual(to: .red), "differs in dark mode")
        #expect(UIColor.red.lmk_isVisuallyEqual(to: UIColor(red: 1, green: 0, blue: 0, alpha: 1)))
    }

    @Test
    func `lmk_hexString round-trips`() {
        let color = UIColor(lmk_hex: "#FF5733")
        #expect(color?.lmk_hexString == "FF5733")
    }

    @Test
    func `lmk_isLight for white returns true`() {
        #expect(UIColor.white.lmk_isLight)
    }

    @Test
    func `lmk_isLight for black returns false`() {
        #expect(!UIColor.black.lmk_isLight)
    }

    @Test
    func `lmk_adjustedBrightness returns valid color`() {
        let color = UIColor.red
        let lighter = color.lmk_adjustedBrightness(by: 1.2)
        let darker = color.lmk_adjustedBrightness(by: 0.8)
        #expect(lighter != color || darker != color)
    }

    @Test
    func `lmk_contrastingTextColor returns appropriate color`() {
        #expect(UIColor.white.lmk_contrastingTextColor == .black)
        #expect(UIColor.black.lmk_contrastingTextColor == .white)
    }
}

// MARK: - Glyph tint

struct UIColorGlyphTintTests {
    private static func brightness(_ color: UIColor, style: UIUserInterfaceStyle = .light) -> CGFloat {
        var brightness: CGFloat = 0
        color.resolvedColor(with: UITraitCollection(userInterfaceStyle: style))
            .getHue(nil, saturation: nil, brightness: &brightness, alpha: nil)
        return brightness
    }

    @Test
    func `A dark accent is its own glyph tint; a light one darkens on a light page`() {
        let dark = UIColor(red: 0.1, green: 0.2, blue: 0.6, alpha: 1)
        #expect(abs(Self.brightness(dark.lmk_glyphTint()) - Self.brightness(dark)) < 0.001)
        let light = UIColor(red: 0.9, green: 0.9, blue: 0.5, alpha: 1)
        let original = Self.brightness(light)
        #expect(abs(Self.brightness(light.lmk_glyphTint()) - original * 0.7) < 0.01)
        #expect(abs(Self.brightness(light.lmk_glyphTint(onLightAccentDarkenBy: 0.5)) - original * 0.5) < 0.01)
    }

    @Test
    func `In Dark Mode a light accent is drawn as is`() {
        // A tonal theme: deep tone in light mode, light tone in Dark Mode.
        let tonal = UIColor.lmk_dynamic(lightHex: 0xA8592A, darkHex: 0xF0A472)
        let tint = tonal.lmk_glyphTint()
        let darkTone = Self.brightness(tonal, style: .dark)
        #expect(abs(Self.brightness(tint, style: .dark) - darkTone) < 0.001)
        #expect(abs(Self.brightness(tint, style: .light) - Self.brightness(tonal, style: .light)) < 0.001)
        let pale = UIColor(red: 0.9, green: 0.9, blue: 0.5, alpha: 1)
        #expect(abs(Self.brightness(pale.lmk_glyphTint(), style: .dark) - Self.brightness(pale)) < 0.001)
    }
}

// MARK: - State shade

struct UIColorStateShadeTests {
    private static func components(_ color: UIColor, style: UIUserInterfaceStyle = .light) -> (brightness: CGFloat, alpha: CGFloat) {
        var brightness: CGFloat = 0, alpha: CGFloat = 0
        color.resolvedColor(with: UITraitCollection(userInterfaceStyle: style)).getHue(nil, saturation: nil, brightness: &brightness, alpha: &alpha)
        return (brightness, alpha)
    }

    @Test
    func `A fill darkens by the factor and keeps its alpha`() {
        let shade = UIColor(white: 0.8, alpha: 0.6).lmk_stateShade(by: 0.9)
        let result = Self.components(shade)
        #expect(abs(result.brightness - 0.72) < 0.005)
        #expect(abs(result.alpha - 0.6) < 0.005)
    }

    @Test
    func `A fill that is already dark lightens by the same amount`() {
        let shade = UIColor(white: 0.2, alpha: 1).lmk_stateShade(by: 0.85)
        #expect(abs(Self.components(shade).brightness - 0.35) < 0.005)
        // Black has nowhere darker to go.
        #expect(abs(Self.components(UIColor.black.lmk_stateShade(by: 0.9)).brightness - 0.1) < 0.005)
    }

    @Test
    func `The shade follows a dynamic color through appearance changes`() {
        let fill = UIColor { $0.userInterfaceStyle == .dark ? UIColor(white: 0.25, alpha: 1) : UIColor(white: 0.85, alpha: 1) }
        let shade = fill.lmk_stateShade(by: 0.9)
        #expect(abs(Self.components(shade, style: .light).brightness - 0.765) < 0.005)
        #expect(abs(Self.components(shade, style: .dark).brightness - 0.35) < 0.005)
    }

    @Test
    func `A factor of one leaves the color alone`() {
        let color = UIColor(red: 0.3, green: 0.6, blue: 0.4, alpha: 1)
        #expect(color.lmk_stateShade(by: 1).resolvedColor(with: UITraitCollection(userInterfaceStyle: .light)).lmk_hexString == color.lmk_hexString)
    }
}
