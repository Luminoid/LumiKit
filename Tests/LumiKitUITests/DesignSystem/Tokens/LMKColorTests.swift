//
//  LMKColorTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

// MARK: - LMKColor

@MainActor
struct LMKColorTests {
    private static let solid = UIColor(red: 0.4, green: 0.6, blue: 0.5, alpha: 1)

    @Test
    func `Tokens resolve the role from the traits' theme`() {
        let traits = UITraitCollection(userInterfaceStyle: .light)
        let colors = traits.lmkTheme.colors
        #expect(LMKColor.primary.resolvedColor(with: traits) == colors.primary.resolvedColor(with: traits))
        #expect(LMKColor.error.resolvedColor(with: traits) == colors.error.resolvedColor(with: traits))
        #expect(LMKColor.textPrimary.resolvedColor(with: traits) == colors.textPrimary.resolvedColor(with: traits))
        #expect(LMKColor.outline.resolvedColor(with: traits) == colors.outline.resolvedColor(with: traits))
        #expect(LMKColor.scrim.resolvedColor(with: traits) == colors.scrim.resolvedColor(with: traits))
    }

    @Test
    func `Tokens are stable instances`() {
        #expect(LMKColor.primary === LMKColor.primary)
        #expect(LMKColor.backgroundPrimary === LMKColor.backgroundPrimary)
    }

    @Test
    func `Tokens follow a theme carried by the traits`() {
        let purple = LMKTheme(colors: LMKColorTheme(primary: .systemPurple))
        let traits = LMKThemeTesting.traits(for: purple)
        #expect(LMKColor.primary.resolvedColor(with: traits) == UIColor.systemPurple.resolvedColor(with: traits))
        #expect(LMKColor.link.resolvedColor(with: traits) == UIColor.systemPurple.resolvedColor(with: traits))
    }

    @Test
    func `Accent roles shift under increased contrast, plain roles do not`() {
        let theme = LMKTheme(colors: LMKColorTheme(primary: Self.solid, textPrimary: Self.solid, highContrastBoost: 0.12))
        let light = LMKThemeTesting.traits(for: theme, style: .light, contrast: .high)
        // `lmk_adjustedBrightness(by:)` multiplies: 12% darker on light, 12% lighter on dark.
        #expect(LMKColor.primary.resolvedColor(with: light).lmk_hexString == Self.solid.lmk_adjustedBrightness(by: 0.88).lmk_hexString)
        #expect(LMKColor.textPrimary.resolvedColor(with: light).lmk_hexString == Self.solid.lmk_hexString)

        let dark = LMKThemeTesting.traits(for: theme, style: .dark, contrast: .high)
        #expect(LMKColor.primary.resolvedColor(with: dark).lmk_hexString == Self.solid.lmk_adjustedBrightness(by: 1.12).lmk_hexString)

        let normal = LMKThemeTesting.traits(for: theme, style: .light, contrast: .normal)
        #expect(LMKColor.primary.resolvedColor(with: normal).lmk_hexString == Self.solid.lmk_hexString)
    }

    @Test
    func `A zero boost disables the contrast policy`() {
        let theme = LMKTheme(colors: LMKColorTheme(primary: Self.solid, highContrastBoost: 0))
        let traits = LMKThemeTesting.traits(for: theme, contrast: .high)
        #expect(LMKColor.primary.resolvedColor(with: traits).lmk_hexString == Self.solid.lmk_hexString)
    }

    @Test
    func `resolved returns the raw role without the contrast policy`() {
        let theme = LMKTheme(colors: LMKColorTheme(primary: Self.solid))
        let traits = LMKThemeTesting.traits(for: theme, contrast: .high)
        #expect(LMKColor.resolved(\.primary, with: traits).lmk_hexString == Self.solid.lmk_hexString)
    }

    @Test
    func `A view's color re-resolves when its window is scoped to another theme`() {
        let purple = LMKTheme(colors: LMKColorTheme(primary: .systemPurple))
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 10))
        view.backgroundColor = LMKColor.primary
        let window = LMKThemeTesting.host(view, theme: purple, style: .light)
        defer { window.isHidden = true }
        let expected = UIColor.systemPurple.resolvedColor(with: view.traitCollection)
        #expect(view.backgroundColor?.resolvedColor(with: view.traitCollection) == expected)
        #expect(view.layer.backgroundColor.map { UIColor(cgColor: $0).lmk_hexString } == expected.lmk_hexString)
    }
}
