//
//  LMKColorContrastBoostTests.swift
//  LumiKit
//
//  `lmk_adjustedBrightness(by:)` is a multiplier; the Increase Contrast boost,
//  the derived primary variant, and the pressed / selected tints once passed it
//  small deltas and collapsed to black (found by the Example sweep in dark mode).
//

import Testing
import UIKit
@testable import LumiKitUI

@MainActor
struct LMKColorContrastBoostTests {
    private func brightness(_ color: UIColor) -> CGFloat {
        var brightness: CGFloat = 0
        color.getHue(nil, saturation: nil, brightness: &brightness, alpha: nil)
        return brightness
    }

    private func traits(style: UIUserInterfaceStyle, contrast: UIAccessibilityContrast) -> UITraitCollection {
        UITraitCollection { mutable in
            mutable.userInterfaceStyle = style
            mutable.accessibilityContrast = contrast
        }
    }

    @Test
    func `Increase Contrast lightens accents on dark and darkens them on light, never to black`() {
        let base = UIColor(red: 0.29, green: 0.69, blue: 0.49, alpha: 1)
        let theme = LMKTheme(colors: LMKColorTheme(primary: base, highContrastBoost: 0.2))

        func resolve(style: UIUserInterfaceStyle, contrast: UIAccessibilityContrast) -> UIColor {
            LMKColor.primary.resolvedColor(with: LMKThemeTesting.traits(for: theme, style: style, contrast: contrast))
        }

        let plain = brightness(resolve(style: .light, contrast: .normal))
        let lightBoosted = brightness(resolve(style: .light, contrast: .high))
        let darkBoosted = brightness(resolve(style: .dark, contrast: .high))
        #expect(abs(plain - brightness(base)) < 0.01)
        #expect(lightBoosted < plain, "darker on a light background")
        #expect(lightBoosted > plain * 0.7, "a boost, not a collapse")
        #expect(darkBoosted > plain, "lighter on a dark background")
    }

    @Test
    func `The derived primary variant is a shade of the primary, not black`() {
        let base = UIColor(red: 0.29, green: 0.69, blue: 0.49, alpha: 1)
        let colors = LMKColorTheme(primary: base)
        let variant = brightness(colors.primaryVariant.resolvedColor(with: traits(style: .light, contrast: .normal)))
        #expect(variant < brightness(base))
        #expect(variant > brightness(base) * 0.7)
    }

    @Test
    func `Pressed and selected fills are darker shades of the tint`() throws {
        let button = LMKButton(title: "Save", style: .filled())
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 200, height: 100))
        window.addSubview(button)
        button.frame = CGRect(x: 0, y: 0, width: 120, height: 44)
        window.layoutIfNeeded()
        let idle = try #require(button.configuration?.background.backgroundColor).resolvedColor(with: button.traitCollection)
        button.isSelected = true
        button.updateConfiguration()
        let selected = try #require(button.configuration?.background.backgroundColor).resolvedColor(with: button.traitCollection)
        #expect(brightness(selected) < brightness(idle))
        #expect(brightness(selected) > brightness(idle) * 0.7, "a shade, not black")

        let chip = LMKChipView(text: "Tag", style: .filled)
        window.addSubview(chip)
        chip.isSelected = true
        chip.layoutIfNeeded()
        let chipFill = try #require(chip.backgroundColor).resolvedColor(with: chip.traitCollection)
        #expect(brightness(chipFill) > 0.3, "the selected chip keeps its tint")
    }
}
