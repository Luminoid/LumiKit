//
//  LMKCardViewTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

// MARK: - LMKCardView

@MainActor
struct LMKCardViewTests {
    @Test
    func `Default card is elevated with medium corners and secondary background`() {
        let card = LMKCardView()
        #expect(card.layer.cornerRadius == LMKCornerRadius.medium)
        #expect(card.layer.shadowOpacity > 0)
        #expect(!card.layer.masksToBounds)
        #expect(card.layer.shadowRadius == LMKTheme.current.shadow.level3.radius)
        #expect(card.backgroundColor == LMKColor.backgroundSecondary)
        #expect(card.contentView.superview === card)
        #expect(card.contentView.layer.cornerRadius == 0)
        #expect(card.contentView.layer.masksToBounds)
        #expect(!card.isAccessibilityElement)
    }

    @Test
    func `Presets map to shadow levels and borders`() {
        #expect(LMKCardView(style: .cell).layer.shadowRadius == LMKTheme.current.shadow.level2.radius)
        #expect(LMKCardView(style: .elevated).layer.shadowRadius == LMKTheme.current.shadow.level3.radius)
        let flat = LMKCardView(style: .flat)
        #expect(flat.layer.shadowOpacity == 0)
        #expect(flat.layer.masksToBounds)
        let outlined = LMKCardView(style: .outlined)
        #expect(outlined.layer.shadowOpacity == 0)
        #expect(outlined.layer.borderWidth > 0)
    }

    @Test
    func `Surface overrides apply per instance`() {
        let card = LMKCardView()
        card.style.surface.corners = .fixed(20)
        card.style.surface.background = .solid(.red)
        card.style.surface.contentInsets = .lmk_all(3)
        #expect(card.layer.cornerRadius == 20)
        #expect(card.backgroundColor == UIColor.red)
        #expect(card.contentView.backgroundColor == UIColor.red)
        #expect(card.lmk_resolvedSurface?.contentInsets == .lmk_all(3))
    }

    @Test
    func `theme.card supplies app-wide defaults`() {
        var theme = LMKTheme()
        theme.card = LMKCardView.Style(surface: LMKSurfaceStyle(corners: .fixed(2), shadow: LMKShadowSource.none))
        let card = LMKCardView()
        let window = LMKThemeTesting.host(card, theme: theme)
        defer { window.isHidden = true }
        #expect(card.layer.cornerRadius == 2)
        #expect(card.layer.shadowOpacity == 0)
    }

    @Test
    func `Cards follow the theme carried by the traits`() {
        let card = LMKCardView()
        let window = LMKThemeTesting.host(card, theme: LMKThemeTesting.distinct)
        defer { window.isHidden = true }
        #expect(card.layer.cornerRadius == LMKThemeTesting.distinct.cornerRadius.medium)
        #expect(card.layer.shadowRadius == LMKThemeTesting.distinct.shadow.level3.radius)
    }

    @Test
    func `onTap makes the card a button and fires on activation`() {
        let card = LMKCardView()
        var taps = 0
        card.onTap = { taps += 1 }
        #expect(card.isAccessibilityElement)
        #expect(card.accessibilityTraits == .button)
        #expect(card.accessibilityActivate())
        #expect(taps == 1)
        card.onTap = nil
        #expect(!card.isAccessibilityElement)
        #expect(!card.accessibilityActivate())
    }

    @Test
    func `didApplyStyle runs after style changes`() {
        let card = LMKCardView()
        var count = 0
        card.didApplyStyle = { _ in count += 1 }
        card.style = .flat
        #expect(count == 1)
    }
}
