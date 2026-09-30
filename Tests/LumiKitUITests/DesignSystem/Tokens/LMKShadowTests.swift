//
//  LMKShadowTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

// MARK: - LMKShadowTheme

@MainActor
struct LMKShadowConfigurationTests {
    @Test
    func `Default levels keep the pre 1.0 geometry`() {
        let config = LMKShadowTheme()
        #expect(config.level1.radius == 2)
        #expect(config.level2.radius == 4)
        #expect(config.level3.radius == 8)
        #expect(config.level4.radius == 12)
        #expect(config.level5.radius == 24)
        #expect(config.iconOverlayOpacity == 0.8)
    }

    @Test
    func `Levels are ordered and none is invisible`() {
        let config = LMKShadowTheme()
        let radii = LMKShadow.Level.allCases.dropFirst().map { config.shadow(for: $0).radius }
        #expect(radii == radii.sorted())
        #expect(config.shadow(for: .none).opacity == 0)
        #expect(LMKShadow.Level.level1 < LMKShadow.Level.level5)
    }

    @Test
    func `Shadow style resolves a trait aware color`() {
        let style = LMKShadowTheme().level3.style
        let light = style.color.resolvedColor(with: UITraitCollection(userInterfaceStyle: .light))
        let dark = style.color.resolvedColor(with: UITraitCollection(userInterfaceStyle: .dark))
        #expect(light.cgColor.alpha < dark.cgColor.alpha)
        #expect(style.radius == 8)
    }

    @Test
    func `LMKShadowStyle has a public initializer that clamps`() {
        let style = LMKShadowStyle(color: .red, offset: CGSize(width: 1, height: 2), radius: -3, opacity: 4)
        #expect(style.radius == 0)
        #expect(style.opacity == 1)
        #expect(style == LMKShadowStyle(color: .red, offset: CGSize(width: 1, height: 2), radius: 0, opacity: 1))
    }

    @Test
    func `Custom shadow is applied via proxy`() {
        let original = LMKTheme.current.shadow
        defer { LMKTheme.update { $0.shadow = original } }

        LMKTheme.update { $0.shadow = .init(
            level2: .init(radius: 10),
            level3: .init(radius: 14),
            level4: .init(radius: 16),
            level5: .init(radius: 30)
        ) }
        #expect(LMKShadow.style(for: .level2).radius == 10)
        #expect(LMKShadow.style(for: .level3).radius == 14)
        #expect(LMKShadow.style(for: .level4).radius == 16)
        #expect(LMKShadow.style(for: .level5).radius == 30)
    }
}
