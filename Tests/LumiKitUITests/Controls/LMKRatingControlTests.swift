//
//  LMKRatingControlTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

/// A touch at a fixed point, for driving the tracking methods.
private final class StubTouch: UITouch {
    var point: CGPoint = .zero
    override func location(in view: UIView?) -> CGPoint {
        point
    }

    override func previousLocation(in view: UIView?) -> CGPoint {
        point
    }
}

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
        control.onValueChange = { changes.append($0) }
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
    func `A new maximum configures the new glyphs and re-measures the row`() {
        let control = LMKRatingControl(maximum: 5, style: LMKRatingControl.Style(glyphSize: 30, symbolWeight: .bold))
        let host = UIView(frame: CGRect(x: 0, y: 0, width: 400, height: 100))
        let window = UIWindow(frame: host.bounds)
        window.addSubview(host)
        host.addSubview(control)
        control.snp.makeConstraints { $0.center.equalToSuperview() }
        window.layoutIfNeeded()
        let fiveWide = control.bounds.width
        control.maximum = 10
        window.layoutIfNeeded()
        let configuration = UIImage.SymbolConfiguration(pointSize: 30, weight: .bold)
        #expect(control.glyphViews.allSatisfy { $0.preferredSymbolConfiguration == configuration }, "rebuilt glyphs keep the style's size and weight")
        #expect(control.bounds.width > fiveWide, "the row grows without waiting for a theme change")
        #expect(abs(control.bounds.width - control.intrinsicContentSize.width) < 0.5)
    }

    @Test
    func `VoiceOver adjustments change the value and report it`() {
        let (control, window) = makeControl()
        defer { window.isHidden = true }
        var changes: [Int] = []
        control.onValueChange = { changes.append($0) }
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
    func `Disabling dims, blocks adjustments, and absorbs touches inside the bounds`() {
        let (control, window) = makeControl()
        defer { window.isHidden = true }
        control.isEnabled = false
        #expect(abs(control.alpha - LMKAlpha.disabled) < 0.001)
        #expect(control.accessibilityTraits.contains(.notEnabled))
        control.accessibilityIncrement()
        #expect(control.value == 0)
        #expect(control.point(inside: CGPoint(x: 5, y: 5), with: nil), "a disabled row absorbs a touch like a disabled control")
        #expect(!control.point(inside: CGPoint(x: 5, y: -8), with: nil), "without the expanded band")
        control.isHidden = true
        #expect(!control.point(inside: CGPoint(x: 5, y: 5), with: nil))
    }

    @Test
    func `A tap rates, a retap on the same glyph clears, and jitter within the glyph is not a drag`() {
        let (control, window) = makeControl()
        defer { window.isHidden = true }
        var changes: [Int] = []
        control.onValueChange = { changes.append($0) }
        let touch = StubTouch()
        let secondGlyph = control.glyphViews[1].convert(control.glyphViews[1].bounds, to: control)
        touch.point = CGPoint(x: secondGlyph.minX + 2, y: secondGlyph.midY)
        #expect(control.beginTracking(touch, with: nil))
        control.endTracking(touch, with: nil)
        #expect(control.value == 2)
        #expect(changes == [2])

        #expect(control.beginTracking(touch, with: nil))
        touch.point.x += 3
        _ = control.continueTracking(touch, with: nil)
        control.endTracking(touch, with: nil)
        #expect(control.value == 0, "a retap that jitters a few points inside the same glyph still clears")
        #expect(changes == [2, 0])

        #expect(control.beginTracking(touch, with: nil))
        touch.point.x = control.bounds.maxX - 1
        _ = control.continueTracking(touch, with: nil)
        control.endTracking(touch, with: nil)
        #expect(control.value == 5, "a drag to the end rates the last glyph")
        #expect(changes == [2, 0, 5])

        control.style.allowsClearByRetap = false
        #expect(control.beginTracking(touch, with: nil))
        control.endTracking(touch, with: nil)
        #expect(control.value == 5, "retap-to-clear off")
    }

    @Test
    func `Past either edge a drag lands on the outermost glyph, in RTL too`() {
        let (control, window) = makeControl()
        defer { window.isHidden = true }
        let touch = StubTouch()
        touch.point = CGPoint(x: control.bounds.maxX + 50, y: 5)
        #expect(control.beginTracking(touch, with: nil))
        _ = control.continueTracking(touch, with: nil)
        #expect(control.value == 5)
        control.cancelTracking(with: nil)
        #expect(control.value == 0, "a cancelled drag restores the start value")

        let rtl = LMKRatingControl(maximum: 5)
        rtl.semanticContentAttribute = .forceRightToLeft
        rtl.stackView.semanticContentAttribute = .forceRightToLeft
        let rtlWindow = LMKThemeTesting.host(rtl)
        defer { rtlWindow.isHidden = true }
        rtl.frame = CGRect(origin: .zero, size: rtl.intrinsicContentSize)
        rtl.layoutIfNeeded()
        #expect(rtl.beginTracking(touch, with: nil))
        touch.point = CGPoint(x: rtl.bounds.maxX + 50, y: 5)
        _ = rtl.continueTracking(touch, with: nil)
        #expect(rtl.value == 1, "past the right edge is the first glyph, which sits on the right in RTL")
        touch.point = CGPoint(x: -50, y: 5)
        _ = rtl.continueTracking(touch, with: nil)
        #expect(rtl.value == 5, "past the left edge is the last glyph")
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

    @Test
    func `A host-assigned accessibility label survives renders`() {
        let (control, window) = makeControl()
        defer { window.isHidden = true }
        control.accessibilityLabel = "Food quality"
        control.value = 3
        control.style.filledColor = .red
        control.isEnabled = false
        #expect(control.accessibilityLabel == "Food quality")
        control.accessibilityLabel = nil
        #expect(control.accessibilityLabel == LMKRatingControl.Strings().accessibilityLabel)
    }
}
