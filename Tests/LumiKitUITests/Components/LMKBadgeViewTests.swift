//
//  LMKBadgeViewTests.swift
//  LumiKit
//

import SnapKit
import Testing
import UIKit
@testable import LumiKitUI

// MARK: - LMKBadgeView

@MainActor
struct LMKBadgeViewTests {
    @Test
    func `A zero count hides the badge, a positive count shows it`() {
        let badge = LMKBadgeView()
        #expect(badge.isHidden, "unconfigured badges are hidden")
        badge.configure(.count(0))
        #expect(badge.isHidden)
        badge.configure(.count(5))
        #expect(!badge.isHidden)
        #expect(badge.countLabel.text == "5")
        #expect(badge.accessibilityLabel == "5")
        #expect(badge.content == .count(5))
    }

    @Test
    func `Counts past 99 show the overflow text but keep the real count for VoiceOver`() {
        let badge = LMKBadgeView()
        badge.configure(.count(150))
        #expect(badge.countLabel.text == "99+")
        #expect(badge.accessibilityLabel == "150")
        badge.style.overflowText = "∞"
        #expect(badge.countLabel.text == "∞")
    }

    @Test
    func `Text and dot content`() {
        let badge = LMKBadgeView()
        badge.configure(.text("New"))
        #expect(badge.accessibilityLabel == "New")
        #expect(!badge.isHidden)
        badge.configure(.text(""))
        #expect(badge.isHidden)
        badge.configure(.dot)
        #expect(!badge.isHidden)
        #expect(badge.countLabel.text == nil)
        #expect(badge.accessibilityLabel == LMKBadgeView.Strings().dotAccessibilityLabel)
        badge.strings = LMKBadgeView.Strings(dotAccessibilityLabel: "Nuevo")
        #expect(badge.accessibilityLabel == "Nuevo")
        badge.customAccessibilityLabel = "3 unread"
        #expect(badge.accessibilityLabel == "3 unread")
    }

    @Test
    func `Dot badge has a smaller intrinsic size than a count`() {
        let badge = LMKBadgeView()
        badge.configure(.dot)
        let dotSize = badge.intrinsicContentSize
        badge.configure(.count(5))
        let countSize = badge.intrinsicContentSize
        #expect(dotSize.width < countSize.width)
        #expect(countSize.height == 18)
        #expect(countSize.width >= 18)
    }

    @Test
    func `Default surface is a capsule with the error tint and a background border`() {
        let badge = LMKBadgeView()
        badge.configure(.count(1))
        #expect(badge.lmk_cornerStyle == .capsule)
        #expect(badge.backgroundColor === LMKColor.error)
        // 1.5pt, in whole pixels of the display.
        #expect(badge.layer.borderWidth == LMKLayout.pixelAligned(1.5, for: badge))
        // Resolved, not identical: the text is `onFill`, which becomes black or white under Increase Contrast.
        let traits = badge.traitCollection
        #expect(badge.countLabel.textColor.resolvedColor(with: traits) == LMKColor.onAccent.resolvedColor(with: traits))
        let high = LMKThemeTesting.traits(for: .default, style: .dark, contrast: .high)
        #expect(badge.countLabel.textColor.resolvedColor(with: high) == LMKColor.error.resolvedColor(with: high).lmk_contrastingTextColor)
    }

    @Test
    func `Style overrides apply per instance and through the theme`() {
        let badge = LMKBadgeView(style: LMKBadgeView.Style(surface: LMKSurfaceStyle(background: .solid(.blue)), textColor: .black, minWidth: 30, height: 24))
        badge.configure(.count(2))
        #expect(badge.backgroundColor == UIColor.blue)
        #expect(badge.countLabel.textColor == UIColor.black)
        #expect(badge.intrinsicContentSize == CGSize(width: 30, height: 24))

        var theme = LMKTheme()
        theme.badge = LMKBadgeView.Style(height: 20, horizontalPadding: 10)
        let themed = LMKBadgeView()
        themed.configure(.text("Hi"))
        let window = LMKThemeTesting.host(themed, theme: theme)
        defer { window.isHidden = true }
        #expect(themed.intrinsicContentSize.height == 20)
        #expect(themed.intrinsicContentSize.width >= themed.countLabel.intrinsicContentSize.width + 20)
    }

    // MARK: - Layout

    @Test
    func `A badge keeps its own size in a row that has room to spare`() {
        let badge = LMKBadgeView()
        badge.configure(.count(7))
        for axis in [NSLayoutConstraint.Axis.horizontal, .vertical] {
            #expect(badge.contentHuggingPriority(for: axis) == .required)
            #expect(badge.contentCompressionResistancePriority(for: axis) == .required)
        }

        // Between a switch-sized view and a field that takes what is left: the badge was the
        // one that stretched, into a bar across the row.
        let leading = UIView()
        leading.snp.makeConstraints { $0.size.equalTo(CGSize(width: 51, height: 31)) }
        let field = UITextField()
        let row = UIStackView(arrangedSubviews: [leading, badge, field])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 16
        row.frame = CGRect(x: 0, y: 0, width: 360, height: 44)
        row.layoutIfNeeded()
        #expect(badge.frame.size == badge.intrinsicContentSize)
        #expect(badge.frame.width < 30, "as wide as one digit, not as the row")
        #expect(field.frame.width > 200, "the field takes the spare width")
    }
}
