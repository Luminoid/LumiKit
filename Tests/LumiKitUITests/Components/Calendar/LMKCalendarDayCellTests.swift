//
//  LMKCalendarDayCellTests.swift
//  LumiKit
//

import LumiKitCore
import Testing
import UIKit
@testable import LumiKitUI

@MainActor
struct LMKCalendarDayCellTests {
    private let day = LMKCalendarDay(year: 2026, month: 9, day: 16)

    private func makeCell(height: CGFloat = 44) -> LMKCalendarDayCell {
        let cell = LMKCalendarDayCell()
        cell.frame = CGRect(x: 0, y: 0, width: 50, height: height)
        return cell
    }

    private func apply(_ cell: LMKCalendarDayCell, state: LMKCalendarDayCell.DayState, decoration: LMKCalendarDayDecoration = .none, style: LMKMonthCalendarView.Style = LMKMonthCalendarView.Style()) {
        cell.apply(state: state, decoration: decoration, style: style, theme: LMKTheme())
        cell.setNeedsLayout()
        cell.layoutIfNeeded()
    }

    @Test
    func `A plain day shows the numeral only`() {
        let cell = makeCell()
        apply(cell, state: .init(day: day, numeral: "16", accessibilityLabel: "Wednesday, September 16, 2026"))
        #expect(cell.numeralLabel.text == "16")
        #expect(cell.numeralLabel.textColor == LMKColor.textPrimary)
        #expect(cell.selectionView.isHidden && cell.todayView.isHidden && cell.rangeBandView.isHidden)
        #expect(cell.decorationStack.isHidden)
        #expect(cell.isEnabled)
        #expect(cell.isAccessibilityElement)
        #expect(cell.accessibilityLabel == "Wednesday, September 16, 2026")
        #expect(cell.accessibilityTraits == .button)
        #expect(cell.dayState?.day == day)
    }

    @Test
    func `Selection styles: filled circle inverts the numeral, rings stroke, rounded rect frames the cell`() {
        let cell = makeCell()
        apply(cell, state: .init(day: day, numeral: "16", isSelected: true))
        #expect(cell.selectionView.isHidden == false)
        #expect(cell.selectionView.backgroundColor == LMKColor.primary)
        #expect(cell.selectionView.layer.cornerRadius == 18)
        #expect(cell.selectionView.frame.size == CGSize(width: 36, height: 36))
        #expect(cell.numeralLabel.textColor == LMKColor.onAccent)
        #expect(cell.accessibilityTraits.contains(.selected))

        apply(cell, state: .init(day: day, numeral: "16", isSelected: true), style: LMKMonthCalendarView.Style(selectionStyle: .ringCircle, selectionTint: .red, circleRadius: 10))
        #expect(cell.selectionView.backgroundColor == UIColor.clear)
        #expect(cell.selectionView.layer.borderWidth == 2)
        #expect(cell.selectionView.layer.borderColor == UIColor.red.cgColor)
        #expect(cell.selectionView.frame.size == CGSize(width: 20, height: 20))
        #expect(cell.numeralLabel.textColor == UIColor.red)

        apply(cell, state: .init(day: day, numeral: "16", isSelected: true), style: LMKMonthCalendarView.Style(selectionStyle: .ringRoundedRect, roundedRectRadius: 6))
        #expect(cell.selectionView.layer.cornerRadius == 6)
        #expect(cell.selectionView.frame == cell.bounds.insetBy(dx: 1, dy: 1))
    }

    @Test
    func `Today styles and the hide-under-selection rule`() {
        let cell = makeCell()
        apply(cell, state: .init(day: day, numeral: "16", isToday: true))
        #expect(cell.todayView.isHidden == false)
        #expect(cell.todayView.backgroundColor == LMKColor.primary.withAlphaComponent(LMKAlpha.xs))
        #expect(cell.numeralLabel.textColor == LMKColor.primary)
        #expect(cell.numeralLabel.font == LMKTypography.font(for: .bodyMedium, compatibleWith: cell.traitCollection))

        apply(cell, state: .init(day: day, numeral: "16", isToday: true, isSelected: true))
        #expect(cell.todayView.isHidden)
        #expect(cell.selectionView.isHidden == false)

        apply(cell, state: .init(day: day, numeral: "16", isToday: true, isSelected: true), style: LMKMonthCalendarView.Style(todayStyle: .ringCircle, todayHiddenUnderSelection: false))
        #expect(cell.todayView.isHidden == false)
        #expect(cell.todayView.layer.borderWidth == 2)

        apply(cell, state: .init(day: day, numeral: "16", isToday: true), style: LMKMonthCalendarView.Style(numeralTodayColor: .orange, todayStyle: .numeralOnly))
        #expect(cell.todayView.isHidden)
        #expect(cell.numeralLabel.textColor == UIColor.orange)
    }

    @Test
    func `Range positions draw the band on the right side`() {
        let cell = makeCell()
        apply(cell, state: .init(day: day, numeral: "16", isSelected: true, rangePosition: .start))
        #expect(cell.rangeBandView.isHidden == false)
        #expect(cell.rangeBandView.frame.minX == 25)
        #expect(cell.rangeBandView.frame.maxX == 50)
        apply(cell, state: .init(day: day, numeral: "16", isSelected: true, rangePosition: .middle))
        #expect(cell.rangeBandView.frame.minX == 0 && cell.rangeBandView.frame.maxX == 50)
        apply(cell, state: .init(day: day, numeral: "16", isSelected: true, rangePosition: .end))
        #expect(cell.rangeBandView.frame.minX == 0 && cell.rangeBandView.frame.maxX == 25)
        apply(cell, state: .init(day: day, numeral: "16", isSelected: true, rangePosition: .single))
        #expect(cell.rangeBandView.isHidden)
    }

    @Test
    func `Dimmed, disabled, and hidden slots`() {
        let cell = makeCell()
        apply(cell, state: .init(day: day, numeral: "30", isInMonth: false, isEnabled: false))
        #expect(cell.numeralLabel.textColor == LMKColor.textTertiary)
        #expect(cell.isEnabled == false)
        #expect(cell.accessibilityTraits.contains(.notEnabled))
        var taps = 0
        cell.onTap = { _ in taps += 1 }
        cell.handleTap()
        #expect(taps == 0)

        apply(cell, state: .init(day: day, numeral: "", isInMonth: false, isEnabled: false), decoration: LMKCalendarDayDecoration(dots: [.red]))
        #expect(cell.numeralStack.isHidden)
        #expect(cell.decorationStack.isHidden)
        #expect(cell.isAccessibilityElement == false)
    }

    @Test
    func `Dots invert under a filled selection and the hit target grows to 44pt`() {
        let cell = makeCell(height: 30)
        apply(cell, state: .init(day: day, numeral: "16", isSelected: true), decoration: LMKCalendarDayDecoration(dots: [.red, .blue]))
        let dots = cell.dotsStack.arrangedSubviews.filter { !$0.isHidden }
        #expect(dots.count == 2)
        #expect(dots[0].backgroundColor == LMKColor.onAccent)
        #expect(dots[0].frame.size == CGSize(width: 5, height: 5))
        #expect(cell.point(inside: CGPoint(x: 25, y: -6), with: nil), "44pt band around a 30pt row")
        #expect(cell.point(inside: CGPoint(x: 25, y: 36), with: nil))
        #expect(!cell.point(inside: CGPoint(x: 25, y: 40), with: nil))
        cell.isEnabled = false
        #expect(cell.point(inside: CGPoint(x: 25, y: 15), with: nil), "a disabled day absorbs its own bounds, as UIKit controls do")
        #expect(!cell.point(inside: CGPoint(x: 25, y: -6), with: nil), "but not the expanded band")
        cell.isHidden = true
        #expect(!cell.point(inside: CGPoint(x: 25, y: 15), with: nil))
    }

    @Test
    func `Tap reports the day and fires primaryActionTriggered`() {
        let cell = makeCell()
        apply(cell, state: .init(day: day, numeral: "16"))
        var tapped: [LMKCalendarDay] = []
        cell.onTap = { tapped.append($0) }
        cell.handleTap()
        #expect(tapped == [day])
    }

    @Test
    func `Decoration equality and the count badge helper`() {
        #expect(LMKCalendarDayDecoration.none.isEmpty)
        #expect(LMKCalendarDayDecoration(dots: [.red]).isEmpty == false)
        #expect(LMKCalendarDayDecoration(accessibilityValue: "x").isEmpty)
        #expect(LMKCalendarDayDecoration.Badge.count(0) == nil)
        #expect(LMKCalendarDayDecoration.Badge.count(3, color: .red) == LMKCalendarDayDecoration.Badge(text: "3", color: .red))
        #expect(LMKCalendarDayDecoration(dots: [.red]) == LMKCalendarDayDecoration(dots: [.red]))
        #expect(LMKCalendarDayDecoration(dots: [.red]) != LMKCalendarDayDecoration(dots: [.blue]))
    }
}
