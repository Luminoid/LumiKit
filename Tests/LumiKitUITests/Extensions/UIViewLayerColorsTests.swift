//
//  UIViewLayerColorsTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

// MARK: - Shadow

@MainActor
struct UIViewLayerColorsShadowTests {
    @Test
    func `lmk_applyShadow sets layer properties from the style`() {
        let view = UIView()
        view.lmk_applyShadow(LMKShadowStyle(color: .red, offset: CGSize(width: 1, height: 3), radius: 5, opacity: 0.4))
        #expect(view.layer.shadowOffset == CGSize(width: 1, height: 3))
        #expect(view.layer.shadowRadius == 5)
        #expect(view.layer.shadowOpacity == 0.4)
        #expect(view.layer.masksToBounds == false)
        #expect(view.layer.shadowColor.map { UIColor(cgColor: $0).lmk_hexString } == UIColor.red.lmk_hexString)
        #expect(view.lmk_isRestampingLayerColors)
    }

    @Test
    func `lmk_applyShadow with a level reads the theme's geometry`() {
        let view = UIView()
        view.lmk_applyShadow(.level3)
        let expected = LMKTheme.current.shadow.level3
        #expect(view.layer.shadowRadius == expected.radius)
        #expect(view.layer.shadowOffset == expected.offset)
        #expect(view.layer.shadowOpacity == expected.opacity)
    }

    @Test
    func `lmk_removeShadow zeros the shadow and releases the restamper`() {
        let view = UIView()
        view.lmk_applyShadow(.level2)
        view.lmk_removeShadow()
        #expect(view.layer.shadowOpacity == 0)
        #expect(view.layer.shadowColor == nil)
        #expect(!view.lmk_isRestampingLayerColors)
    }

    /// The regression: an invisible shadow stayed registered, and every trait re-stamp turned
    /// `masksToBounds` off, so a clipping card spilled its content after a dark-mode change.
    @Test
    func `An invisible shadow clears instead of registering, and re-stamps keep clipping`() {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 10))
        let window = LMKThemeTesting.host(view, style: .light)
        defer { window.isHidden = true }
        view.layer.masksToBounds = true

        view.lmk_applyShadow(.none)
        #expect(!view.lmk_isRestampingLayerColors)
        #expect(view.layer.masksToBounds)
        view.lmk_applyShadow(LMKShadowStyle(color: .black, offset: .zero, radius: 4, opacity: 0))
        #expect(!view.lmk_isRestampingLayerColors)
        #expect(view.layer.masksToBounds)

        window.traitOverrides.userInterfaceStyle = .dark
        view.updateTraitsIfNeeded()
        #expect(view.layer.masksToBounds, "nothing to re-stamp, so clipping stays")

        view.lmk_applyShadow(.level2)
        #expect(!view.layer.masksToBounds, "a visible shadow turns clipping off once, when applied")
    }

    @Test
    func `Shadow color follows dark mode without re-applying`() {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 10))
        let window = LMKThemeTesting.host(view, style: .light)
        defer { window.isHidden = true }
        view.lmk_applyShadow(.level3)
        let lightAlpha = view.layer.shadowColor.map { UIColor(cgColor: $0).cgColor.alpha }
        #expect(lightAlpha == LMKTheme.current.shadow.level3.lightAlpha)

        window.traitOverrides.userInterfaceStyle = .dark
        view.updateTraitsIfNeeded()
        let darkAlpha = view.layer.shadowColor.map { UIColor(cgColor: $0).cgColor.alpha }
        #expect(darkAlpha == LMKTheme.current.shadow.level3.darkAlpha)
    }

    @Test
    func `A level shadow follows the theme carried by the traits`() {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 10))
        let window = LMKThemeTesting.host(view)
        defer { window.isHidden = true }
        view.lmk_applyShadow(.level1)
        #expect(view.layer.shadowRadius == LMKTheme.current.shadow.level1.radius)

        window.traitOverrides.lmkTheme = LMKThemeReference(LMKThemeTesting.distinct)
        view.updateTraitsIfNeeded()
        #expect(view.layer.shadowRadius == LMKThemeTesting.distinct.shadow.level1.radius)
    }
}

// MARK: - Border

@MainActor
struct UIViewLayerColorsBorderTests {
    @Test
    func `lmk_applyBorder sets width and resolved color`() {
        let view = UIView()
        view.lmk_applyBorder(color: .red, width: 2)
        #expect(view.layer.borderWidth == 2)
        #expect(view.layer.borderColor.map { UIColor(cgColor: $0).lmk_hexString } == UIColor.red.lmk_hexString)
        #expect(view.lmk_isRestampingLayerColors)
    }

    @Test
    func `lmk_applyBorder defaults to a hairline`() {
        let view = UIView()
        view.lmk_applyBorder(color: .red)
        #expect(view.layer.borderWidth == LMKLayout.hairline(for: view))
    }

    @Test
    func `lmk_applyBorder snaps the width to whole pixels`() {
        let view = UIView()
        let scale = LMKScene.displayScale(of: view) ?? LMKScene.screenScale
        view.lmk_applyBorder(color: .red, width: 1.5)
        let pixels = view.layer.borderWidth * scale
        #expect(abs(pixels - pixels.rounded()) < 0.0001, "a fraction of a pixel renders thicker on some edges than on others")
        #expect(view.layer.borderWidth == LMKLayout.pixelAligned(1.5, scale: scale))
    }

    @Test
    func `lmk_removeBorder clears the border and releases the restamper`() {
        let view = UIView()
        view.lmk_applyBorder(color: .red, width: 2)
        view.lmk_removeBorder()
        #expect(view.layer.borderWidth == 0)
        #expect(view.layer.borderColor == nil)
        #expect(!view.lmk_isRestampingLayerColors)
    }

    @Test
    func `Removing only one source keeps the restamper for the other`() {
        let view = UIView()
        view.lmk_applyBorder(color: .red, width: 2)
        view.lmk_applyShadow(.level2)
        view.lmk_removeBorder()
        #expect(view.lmk_isRestampingLayerColors)
        view.lmk_removeShadow()
        #expect(!view.lmk_isRestampingLayerColors)
    }

    @Test
    func `A dynamic border color is re-stamped on dark mode`() {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 10))
        let window = LMKThemeTesting.host(view, style: .light)
        defer { window.isHidden = true }
        view.lmk_applyBorder(color: .lmk_dynamic(light: .red, dark: .blue), width: 1)
        #expect(view.layer.borderColor.map { UIColor(cgColor: $0).lmk_hexString } == UIColor.red.lmk_hexString)

        window.traitOverrides.userInterfaceStyle = .dark
        view.updateTraitsIfNeeded()
        #expect(view.layer.borderColor.map { UIColor(cgColor: $0).lmk_hexString } == UIColor.blue.lmk_hexString)
    }

    @Test
    func `A token border color follows the theme carried by the traits`() {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 10))
        let window = LMKThemeTesting.host(view, style: .light)
        defer { window.isHidden = true }
        view.lmk_applyBorder(color: LMKColor.primary, width: 1)
        let purple = LMKTheme(colors: LMKColorTheme(primary: .systemPurple))
        window.traitOverrides.lmkTheme = LMKThemeReference(purple)
        view.updateTraitsIfNeeded()
        let expected = UIColor.systemPurple.resolvedColor(with: view.traitCollection).lmk_hexString
        #expect(view.layer.borderColor.map { UIColor(cgColor: $0).lmk_hexString } == expected)
    }
}
