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
