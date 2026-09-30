//
//  LMKRatingControlTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

@MainActor
struct LMKRatingControlTests {
    private func makeControl(maximum: Int = 5, style: LMKRatingControl.Style = LMKRatingControl.Style()) -> (LMKRatingControl, UIWindow) {
        let control = LMKRatingControl(maximum: maximum, style: style)
        let window = LMKThemeTesting.host(control)
        control.frame = CGRect(origin: .zero, size: control.intrinsicContentSize)
        control.layoutIfNeeded()
        return (control, window)
    }

    @Test
    func `Defaults: five empty stars, adjustable, 44pt hit band`() {
        let (control, window) = makeControl()
        defer { window.isHidden = true }
        #expect(control.maximum == 5)
        #expect(control.value == 0)
        #expect(control.glyphViews.count == 5)
        #expect(control.glyphViews.allSatisfy { $0.tintColor == LMKColor.textTertiary })
        #expect(control.intrinsicContentSize.width == LMKLayout.iconSmall * 5 + LMKSpacing.xs * 4)
        #expect(control.intrinsicContentSize.height == LMKLayout.iconSmall)
        #expect(control.accessibilityTraits.contains(.adjustable))
        #expect(control.accessibilityLabel == LMKRatingControl.Strings().accessibilityLabel)
        #expect(control.accessibilityValue == String(format: LMKRatingControl.Strings().accessibilityValueFormat, Int64(0), Int64(5)))
        let band = (LMKLayout.minimumTouchTarget - LMKLayout.iconSmall) / 2
        #expect(control.point(inside: CGPoint(x: 10, y: -band + 1), with: nil))
        #expect(!control.point(inside: CGPoint(x: 10, y: -band - 1), with: nil))
    }

    @Test
    func `value is clamped, silent, and fills the glyphs`() {
        let (control, window) = makeControl()
        defer { window.isHidden = true }
        var changes: [Int] = []
        control.onChange = { changes.append($0) }
        control.value = 3
        #expect(control.glyphViews.prefix(3).allSatisfy { $0.tintColor == LMKColor.primary })
        #expect(control.glyphViews.suffix(2).allSatisfy { $0.tintColor == LMKColor.textTertiary })
        control.value = 9
        #expect(control.value == 5)
        control.value = -2
        #expect(control.value == 0)
        #expect(changes.isEmpty)
    }

    @Test
    func `Every glyph gets the same box at the intrinsic width`() {
        // A star symbol measures wider than its point size, so ten of them overflow the
        // intrinsic width; the row must share the shortfall instead of crushing one glyph.
        let (control, window) = makeControl(maximum: 10)
        defer { window.isHidden = true }
        control.value = 8
        control.frame = CGRect(origin: .zero, size: control.intrinsicContentSize)
        control.setNeedsLayout()
        control.layoutIfNeeded()
        let widths = control.glyphViews.map(\.frame.width)
        #expect(widths.allSatisfy { abs($0 - LMKLayout.iconSmall) < 0.5 }, "glyph widths \(widths)")
    }

    @Test
    func `maximum rebuilds the row and clamps the value`() {
        let (control, window) = makeControl()
        defer { window.isHidden = true }
        control.value = 5
        control.maximum = 10
        #expect(control.glyphViews.count == 10)
        #expect(control.value == 5)
        control.maximum = 3
        #expect(control.glyphViews.count == 3)
        #expect(control.value == 3)
        control.maximum = 0
        #expect(control.maximum == 1)
    }

    @Test
    func `VoiceOver adjustments change the value and report it`() {
        let (control, window) = makeControl()
        defer { window.isHidden = true }
        var changes: [Int] = []
        control.onChange = { changes.append($0) }
        control.accessibilityIncrement()
        control.accessibilityIncrement()
        #expect(control.value == 2)
        control.accessibilityDecrement()
        #expect(control.value == 1)
        #expect(changes == [1, 2, 1])
        control.value = 0
        control.accessibilityDecrement()
        #expect(changes.count == 3, "no change below zero")
        control.isInteractive = false
        control.accessibilityIncrement()
        #expect(control.value == 0)
        #expect(control.accessibilityTraits.contains(.staticText))
        #expect(!control.isUserInteractionEnabled)
    }

    @Test
    func `Disabling dims and blocks adjustments`() {
        let (control, window) = makeControl()
        defer { window.isHidden = true }
        control.isEnabled = false
        #expect(abs(control.alpha - LMKAlpha.disabled) < 0.001)
        #expect(control.accessibilityTraits.contains(.notEnabled))
        control.accessibilityIncrement()
        #expect(control.value == 0)
        #expect(!control.point(inside: CGPoint(x: 5, y: 5), with: nil))
    }

    @Test
    func `Style and theme.ratingControl restyle the glyphs`() {
        let style = LMKRatingControl.Style(filledSymbol: "heart.fill", emptySymbol: "heart", filledColor: .red, emptyColor: .gray, glyphSize: 30, spacing: 10)
        let (control, window) = makeControl(maximum: 3, style: style)
        defer { window.isHidden = true }
        control.value = 1
        #expect(control.glyphViews[0].tintColor == UIColor.red)
        #expect(control.glyphViews[1].tintColor == UIColor.gray)
        #expect(control.stackView.spacing == 10)
        #expect(control.intrinsicContentSize == CGSize(width: 30 * 3 + 10 * 2, height: 30))
        #expect(control.glyphViews[0].image == UIImage(systemName: "heart.fill"))

        var theme = LMKTheme()
        theme.ratingControl = LMKRatingControl.Style(emptyColor: .magenta)
        let (themed, themedWindow) = makeControl()
        defer { themedWindow.isHidden = true }
        themed.applyTheme(theme)
        #expect(themed.glyphViews.allSatisfy { $0.tintColor == UIColor.magenta })
        #expect(themed.stackView.spacing == theme.spacing.xs)
    }

    @Test
    func `Merging keeps the base fields the override leaves nil`() {
        let base = LMKRatingControl.Style(filledColor: .red, spacing: 3)
        let merged = base.merging(LMKRatingControl.Style(spacing: 8, allowsClearByRetap: false))
        #expect(merged.filledColor == UIColor.red)
        #expect(merged.spacing == 8)
        #expect(merged.allowsClearByRetap == false)
        #expect(LMKRatingControl.Style.defaultValue == LMKRatingControl.Style())
    }

    @Test
    func `Per-instance strings drive the accessibility value`() {
        let (control, window) = makeControl()
        defer { window.isHidden = true }
        control.strings = LMKRatingControl.Strings(accessibilityLabel: "Stars", accessibilityValueFormat: "%lld/%lld")
        control.value = 2
        #expect(control.accessibilityLabel == "Stars")
        #expect(control.accessibilityValue == "2/5")
    }
}
