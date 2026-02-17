//
//  UIColorLMKTests.swift
//  LumiKit
//

import Testing
import UIKit

@testable import LumiKitUI

// MARK: - UIColor+LMK

@Suite("UIColor+LMK")
@MainActor
struct UIColorLMKTests {
    @Test("Hex init with # prefix")
    func hexInitWithHash() {
        let color = UIColor(lmk_hex: "#FF0000")
        #expect(color != nil)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color?.getRed(&r, green: &g, blue: &b, alpha: &a)
        #expect(abs(r - 1.0) < 0.01)
        #expect(abs(g) < 0.01)
        #expect(abs(b) < 0.01)
    }

    @Test("Hex init without prefix")
    func hexInitWithoutHash() {
        let color = UIColor(lmk_hex: "00FF00")
        #expect(color != nil)
    }

    @Test("Hex init with 8-char RGBA")
    func hexInitRGBA() {
        let color = UIColor(lmk_hex: "#FF000080")
        #expect(color != nil)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color?.getRed(&r, green: &g, blue: &b, alpha: &a)
        #expect(abs(a - 128.0 / 255.0) < 0.01)
    }

    @Test("Hex init with invalid string returns nil")
    func hexInitInvalid() {
        #expect(UIColor(lmk_hex: "xyz") == nil)
        #expect(UIColor(lmk_hex: "#12345") == nil)
        #expect(UIColor(lmk_hex: "") == nil)
    }

    @Test("lmk_hexString round-trips")
    func hexStringRoundTrip() {
        let color = UIColor(lmk_hex: "#FF5733")
        #expect(color?.lmk_hexString == "FF5733")
    }

    @Test("lmk_isLight for white returns true")
    func isLightWhite() {
        #expect(UIColor.white.lmk_isLight)
    }

    @Test("lmk_isLight for black returns false")
    func isLightBlack() {
        #expect(!UIColor.black.lmk_isLight)
    }

    @Test("lmk_adjustedBrightness returns valid color")
    func adjustedBrightness() {
        let color = UIColor.red
        let lighter = color.lmk_adjustedBrightness(by: 1.2)
        let darker = color.lmk_adjustedBrightness(by: 0.8)
        #expect(lighter != color || darker != color)
    }

    @Test("lmk_contrastingTextColor returns appropriate color")
    func contrastingTextColor() {
        #expect(UIColor.white.lmk_contrastingTextColor == .black)
        #expect(UIColor.black.lmk_contrastingTextColor == .white)
    }
}
