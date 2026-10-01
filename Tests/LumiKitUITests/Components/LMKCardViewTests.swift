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
        #expect(card.contentView.backgroundColor == UIColor.clear, "the card's layer draws the fill once")
        #expect(card.contentView.layer.cornerRadius == 0, "the large insets leave no concentric radius")
        #expect(card.contentView.layer.masksToBounds)
        #expect(!card.isAccessibilityElement)
    }

    @Test
    func `Edge-to-edge content clips to the corners of an elevated card`() {
        let card = LMKCardView(style: .elevated)
        card.style.surface.contentInsets = .lmk_all(0)
        card.frame = CGRect(x: 0, y: 0, width: 200, height: 100)
        card.layoutIfNeeded()
        #expect(!card.layer.masksToBounds, "the shadow needs an unclipped layer")
        #expect(card.contentView.layer.cornerRadius == LMKCornerRadius.medium, "so the content clips to the same radius")
        #expect(card.contentView.layer.masksToBounds)
        #expect(card.contentView.layer.cornerCurve == .continuous)

        card.style.surface.contentInsets = .lmk_all(4)
        #expect(card.contentView.layer.cornerRadius == LMKCornerRadius.medium - 4, "concentric inside the inset")

        card.style.surface.corners = .capsule
        card.style.surface.contentInsets = .lmk_all(0)
        card.layoutIfNeeded()
        #expect(card.contentView.layer.cornerRadius == 50, "a capsule tracks the bounds")
        card.frame = CGRect(x: 0, y: 0, width: 200, height: 60)
        card.layoutIfNeeded()
        #expect(card.contentView.layer.cornerRadius == 30)
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
        #expect(card.contentView.backgroundColor == UIColor.clear, "a translucent fill is never composited twice")
        #expect(card.contentView.layer.cornerRadius == 17)
        #expect(card.lmk_resolvedSurface?.contentInsets == .lmk_all(3))
    }

    @Test
    func `theme.card supplies app-wide defaults`() {
        var theme = LMKTheme()
        theme.card = LMKCardView.Style(surface: LMKSurfaceStyle(corners: .fixed(2), shadow: LMKShadowSource.hidden))
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
    func `A tappable card names itself from its content unless the host names it`() {
        let card = LMKCardView()
        let title = UILabel.lmk_make(.body, text: "Ficus")
        let detail = UILabel.lmk_make(.caption, text: "Watered today")
        let hidden = UILabel.lmk_make(.caption, text: "Secret")
        hidden.isHidden = true
        let stack = UIStackView(arrangedSubviews: [title, detail, hidden])
        card.contentView.addSubview(stack)
        #expect(card.accessibilityLabel == nil, "a plain card is a container")
        card.onTap = {}
        #expect(card.accessibilityLabel == "Ficus, Watered today")
        card.accessibilityLabel = "Ficus card"
        #expect(card.accessibilityLabel == "Ficus card")
        card.accessibilityLabel = nil
        #expect(card.accessibilityLabel == "Ficus, Watered today")
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
