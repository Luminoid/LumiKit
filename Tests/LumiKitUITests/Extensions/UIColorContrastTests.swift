//
//  UIColorContrastTests.swift
//  LumiKit
//
//  The WCAG helpers on UIColor: relative luminance, contrast ratio, and the
//  softest tone that keeps a ratio against a wash. Deliberately not
//  @MainActor: the helpers are nonisolated and must run anywhere.
//

import Testing
import UIKit
@testable import LumiKitUI

struct UIColorContrastTests {
    private static let light = UITraitCollection(userInterfaceStyle: .light)
    private static let dark = UITraitCollection(userInterfaceStyle: .dark)

    private static func hue(_ color: UIColor) -> CGFloat {
        var hue: CGFloat = 0
        color.getHue(&hue, saturation: nil, brightness: nil, alpha: nil)
        return hue
    }

    // MARK: - Luminance and ratio

    @Test
    func `Relative luminance follows the WCAG formula`() {
        #expect(UIColor.white.lmk_relativeLuminance(resolvedWith: Self.light) == 1)
        #expect(UIColor.black.lmk_relativeLuminance(resolvedWith: Self.light) == 0)
        #expect(abs(UIColor(lmk_hex: 0x777777).lmk_relativeLuminance(resolvedWith: Self.light) - 0.1845) < 0.0005)
        // Pure primaries weigh by the WCAG coefficients.
        #expect(abs(UIColor(lmk_hex: 0x00FF00).lmk_relativeLuminance(resolvedWith: Self.light) - 0.7152) < 0.0005)
        #expect(abs(UIColor(lmk_hex: 0xFF0000).lmk_relativeLuminance(resolvedWith: Self.light) - 0.2126) < 0.0005)
    }

    @Test
    func `Known pairs: black on white is 21, #777 on white about 4.48, a color on itself 1`() {
        #expect(abs(UIColor.black.lmk_contrastRatio(to: .white, resolvedWith: Self.light) - 21) < 0.001)
        #expect(abs(UIColor.white.lmk_contrastRatio(to: .black, resolvedWith: Self.light) - 21) < 0.001, "the ratio is symmetric")
        #expect(abs(UIColor(lmk_hex: 0x777777).lmk_contrastRatio(to: .white, resolvedWith: Self.light) - 4.478) < 0.005)
        #expect(abs(UIColor(lmk_hex: 0x767676).lmk_contrastRatio(to: .white, resolvedWith: Self.light) - 4.54) < 0.01, "the lightest gray that passes AA on white")
        #expect(UIColor.systemTeal.lmk_contrastRatio(to: .systemTeal, resolvedWith: Self.light) == 1)
    }

    @Test
    func `A translucent foreground is composited over the background first`() {
        // Black at 50% over white is mid gray: about 3.98, not black's 21.
        let ratio = UIColor.black.withAlphaComponent(0.5).lmk_contrastRatio(to: .white, resolvedWith: Self.light)
        #expect(abs(ratio - 3.98) < 0.02)
        #expect(UIColor.black.withAlphaComponent(0).lmk_contrastRatio(to: .white, resolvedWith: Self.light) == 1)
    }

    @Test
    func `Dynamic colors resolve with the given traits`() {
        let ink = UIColor.lmk_dynamic(light: .black, dark: .white)
        let page = UIColor.lmk_dynamic(light: .white, dark: .black)
        #expect(abs(ink.lmk_contrastRatio(to: page, resolvedWith: Self.light) - 21) < 0.001)
        #expect(abs(ink.lmk_contrastRatio(to: page, resolvedWith: Self.dark) - 21) < 0.001)
        #expect(abs(ink.lmk_contrastRatio(to: .white, resolvedWith: Self.dark) - 1) < 0.001)
    }

    // MARK: - Softest tone

    @Test
    func `A color with contrast to spare softens toward the page and stops at the ratio`() {
        let base = UIColor(lmk_hex: 0x1F4FA8)
        let page = UIColor.white
        let washAlpha: CGFloat = 0.1
        let tone = base.lmk_softestTone(over: page, washAlpha: washAlpha, minimumContrast: 3.3, resolvedWith: Self.light)
        let wash = base.lmk_composited(over: page, alpha: washAlpha)
        let ratio = tone.lmk_contrastRatio(to: wash, resolvedWith: Self.light)
        #expect(ratio >= 3.3 - 0.001)
        #expect(ratio < 3.35, "the softest tone sits at the ratio, not above it")
        #expect(tone.lmk_relativeLuminance(resolvedWith: Self.light) > base.lmk_relativeLuminance(resolvedWith: Self.light), "lighter than the base on a light page")
        #expect(base.lmk_contrastRatio(to: wash, resolvedWith: Self.light) > ratio)
    }

    @Test
    func `A color too pale for the ratio darkens just enough and keeps its hue`() {
        let base = UIColor(lmk_hex: 0xF2D16B)
        let wash = base.lmk_composited(over: .white, alpha: 0.1)
        #expect(base.lmk_contrastRatio(to: wash, resolvedWith: Self.light) < 3)
        let tone = base.lmk_softestTone(over: .white, washAlpha: 0.1, minimumContrast: 3, resolvedWith: Self.light)
        let ratio = tone.lmk_contrastRatio(to: wash, resolvedWith: Self.light)
        #expect(ratio >= 3 - 0.001)
        #expect(ratio < 3.05)
        #expect(abs(Self.hue(tone) - Self.hue(base)) < 0.01, "darkened by brightness, so the hue stays")
    }

    @Test
    func `On a dark page a failing color lightens`() {
        let page = UIColor(lmk_hex: 0x121212)
        let base = UIColor(lmk_hex: 0x3A2F6B)
        let wash = base.lmk_composited(over: page, alpha: 0.15)
        #expect(base.lmk_contrastRatio(to: wash, resolvedWith: Self.dark) < 3)
        let tone = base.lmk_softestTone(over: page, washAlpha: 0.15, minimumContrast: 3, resolvedWith: Self.dark)
        #expect(tone.lmk_contrastRatio(to: wash, resolvedWith: Self.dark) >= 3 - 0.001)
        #expect(tone.lmk_relativeLuminance(resolvedWith: Self.dark) > base.lmk_relativeLuminance(resolvedWith: Self.dark))
    }

    @Test
    func `A wash alpha of zero measures against the page itself`() {
        let tone = UIColor.black.lmk_softestTone(over: .white, washAlpha: 0, minimumContrast: 4.5, resolvedWith: Self.light)
        let ratio = tone.lmk_contrastRatio(to: .white, resolvedWith: Self.light)
        #expect(abs(ratio - 4.5) < 0.01, "black softens to the lightest gray that passes AA on white")
        // An out-of-range alpha is clamped.
        let unclamped = UIColor.black.lmk_softestTone(over: .white, washAlpha: -2, minimumContrast: 4.5, resolvedWith: Self.light)
        #expect(abs(unclamped.lmk_contrastRatio(to: .white, resolvedWith: Self.light) - ratio) < 0.001)
    }

    @Test
    func `An unreachable ratio returns the extreme that comes closest`() {
        let gray = UIColor(white: 0.5, alpha: 1)
        let tone = gray.lmk_softestTone(over: gray, washAlpha: 0, minimumContrast: 21, resolvedWith: Self.light)
        var white: CGFloat = 1
        tone.getWhite(&white, alpha: nil)
        // Black stands out more against mid gray (about 5.3) than white does (about 4), so the tone goes black.
        #expect(white < 0.001)
        #expect(tone.lmk_contrastRatio(to: gray, resolvedWith: Self.light) > 5)
    }

    @Test
    func `The result is opaque even for a translucent base`() {
        var alpha: CGFloat = 0
        UIColor.systemRed.withAlphaComponent(0.4)
            .lmk_softestTone(over: .white, washAlpha: 0.1, minimumContrast: 2, resolvedWith: Self.light)
            .getWhite(nil, alpha: &alpha)
        #expect(alpha == 1)
    }

    @Test
    func `The helpers run off the main actor`() async {
        let ratio = await Task.detached {
            let tone = UIColor.systemBlue.lmk_softestTone(over: .white, washAlpha: 0.1, minimumContrast: 3, resolvedWith: Self.light)
            return tone.lmk_contrastRatio(to: UIColor.systemBlue.lmk_composited(over: .white, alpha: 0.1), resolvedWith: Self.light)
        }.value
        #expect(ratio >= 3 - 0.001)
    }
}
