//
//  LMKMonthCalendarViewTests.swift
//  LumiKit
//

import LumiKitCore
import Testing
import UIKit
@testable import LumiKitUI

@MainActor
struct LMKMonthCalendarViewTests {
    private static func gregorian(firstWeekday: Int = 1) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Los_Angeles") ?? .current
        calendar.locale = Locale(identifier: "en_US")
        calendar.firstWeekday = firstWeekday
        return calendar
    }

    private static let september = LMKCalendarMonth(year: 2026, month: 9)
    private static let october = LMKCalendarMonth(year: 2026, month: 10)
    private static let today = LMKCalendarDay(year: 2026, month: 9, day: 16)

    private func day(_ day: Int, month: Int = 9) -> LMKCalendarDay {
        LMKCalendarDay(year: 2026, month: month, day: day)
    }

    /// A detached calendar (no window, so month changes apply synchronously) laid out at 375pt.
    private func makeCalendar(style: LMKMonthCalendarView.Style = LMKMonthCalendarView.Style(), firstWeekday: Int = 1) -> LMKMonthCalendarView {
        let view = LMKMonthCalendarView(calendar: Self.gregorian(firstWeekday: firstWeekday), locale: Locale(identifier: "en_US"), style: style)
        view.configure(month: Self.september, today: Self.today)
        view.frame = CGRect(x: 0, y: 0, width: 375, height: view.intrinsicContentSize.height)
        view.layoutIfNeeded()
        return view
    }

    // MARK: - Grid

    @Test
    func `September 2026 renders five rows starting on August 30, six under alwaysSix`() {
        let view = makeCalendar()
        #expect(view.currentRowCount == 5)
        #expect(view.rowStacks[4].isHidden == false)
        #expect(view.rowStacks[5].isHidden)
        let first = view.dayCells[0]
        #expect(first.dayState?.day == day(30, month: 8))
        #expect(first.dayState?.isInMonth == false)
        #expect(first.dayState?.isEnabled == false)
        #expect(first.dayState?.numeral == "30", "adjacent days show dimmed by default")
        #expect(first.isAccessibilityElement == false)
        #expect(view.cell(for: day(1))?.dayState?.numeral == "1")
        #expect(view.cell(for: day(1)) === view.dayCells[2], "September 1 is a Tuesday")
        #expect(view.cell(for: day(30))?.dayState?.isInMonth == true)
        #expect(view.cell(for: day(16))?.dayState?.isToday == true)
        #expect(view.cell(for: day(3, month: 10))?.dayState?.isInMonth == false)

        view.style = LMKMonthCalendarView.Style(weekRows: .alwaysSix, showsAdjacentMonthDays: false)
        #expect(view.currentRowCount == 6)
        #expect(view.rowStacks[5].isHidden == false)
        #expect(view.dayCells[0].dayState?.numeral == "")
        #expect(view.dayCells[0].numeralStack.isHidden)
        #expect(view.titleButton.title == "September 2026")
    }

    @Test
    func `The centered header keeps both chevrons at the edges and the title between them`() {
        let view = makeCalendar()
        let header = view.headerStack.bounds
        let previous = view.previousButton.convert(view.previousButton.bounds, to: view.headerStack)
        let next = view.nextButton.convert(view.nextButton.bounds, to: view.headerStack)
        let title = view.titleButton.convert(view.titleButton.bounds, to: view.headerStack)
        #expect(previous.minX == header.minX)
        #expect(abs(next.maxX - header.maxX) < 0.5)
        #expect(abs(next.width - previous.width) < 0.5, "the next chevron hugs its glyph instead of taking the spare width")
        #expect(abs(title.midX - header.midX) < 0.5)
    }

    @Test
    func `The leading-title header parks the chevrons at the trailing edge`() {
        let view = makeCalendar(style: LMKMonthCalendarView.Style(headerLayout: .leadingTitle))
        let header = view.headerStack.bounds
        let previous = view.previousButton.convert(view.previousButton.bounds, to: view.headerStack)
        let next = view.nextButton.convert(view.nextButton.bounds, to: view.headerStack)
        let title = view.titleButton.convert(view.titleButton.bounds, to: view.headerStack)
        #expect(title.minX == header.minX)
        #expect(abs(next.maxX - header.maxX) < 0.5)
        #expect(abs(previous.maxX - next.minX) < 0.5)
        #expect(abs(next.width - previous.width) < 0.5)
    }

    @Test
    func `The leading title stays on one line while the header has room for it`() {
        // Narrow enough that the title is wider than half the header, the width a stack view
        // caps a wrapping text view at, and wide enough that everything still fits on one line.
        let view = LMKMonthCalendarView(
            calendar: Self.gregorian(),
            locale: Locale(identifier: "en_US"),
            style: LMKMonthCalendarView.Style(headerLayout: .leadingTitle, titleIsTappable: true, showsTodayButton: true)
        )
        view.configure(month: Self.september, today: Self.today)
        view.frame = CGRect(x: 0, y: 0, width: 345, height: view.intrinsicContentSize.height)
        view.layoutIfNeeded()
        let header = view.headerStack.bounds
        let title = view.titleButton.convert(view.titleButton.bounds, to: view.headerStack)
        let today = view.todayButton.convert(view.todayButton.bounds, to: view.headerStack)
        let next = view.nextButton.convert(view.nextButton.bounds, to: view.headerStack)
        let lineHeight = LMKTextMeasurement.lineHeight(of: .h3, traits: view.traitCollection)
        #expect(title.width > header.width / 2, "the fixture no longer exercises the half-width cap: \(title) in \(header)")
        #expect(title.height < lineHeight * 1.5, "\"September 2026\" wrapped: \(title) in \(header)")
        #expect(title.maxX <= today.minX + 0.5)
        #expect(abs(next.maxX - header.maxX) < 0.5)
    }

    @Test
    func `Weekday symbols start on the calendar's first weekday and read in full to VoiceOver`() {
        let sunday = makeCalendar()
        #expect(sunday.weekdayLabels.map(\.text) == ["S", "M", "T", "W", "T", "F", "S"])
        #expect(sunday.weekdayLabels[0].accessibilityLabel == "Sunday")
        let monday = makeCalendar(style: LMKMonthCalendarView.Style(weekdaySymbolStyle: .abbreviated), firstWeekday: 2)
        #expect(monday.weekdayLabels.map(\.text) == ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"])
        #expect(monday.dayCells[0].dayState?.day == day(31, month: 8))
        #expect(monday.cell(for: day(1)) === monday.dayCells[1])
    }

    @Test
    func `Height is intrinsic: rows times the row height plus header, weekday row, spacing, and insets`() {
        let view = makeCalendar()
        // 8 + 44 + 8 + 24 + 4 + 5 * 44 + 8
        #expect(view.preferredHeight(for: Self.september) == 316)
        #expect(view.intrinsicContentSize.height == 316)
        #expect(view.preferredHeight(for: LMKCalendarMonth(year: 2026, month: 8)) == 360, "August 2026 needs six rows")
        #expect(view.preferredHeight(for: LMKCalendarMonth(year: 2026, month: 2)) == 272, "February 2026 fits in four")
        view.style = LMKMonthCalendarView.Style(headerLayout: .hidden, dayRowHeight: 50, weekRows: .alwaysSix, contentInsets: .zero)
        #expect(view.headerView.isHidden)
        #expect(view.preferredHeight(for: Self.september) == 328)
        #expect(view.intrinsicContentSize.height == view.preferredHeight(for: Self.september))
    }

    // MARK: - Selection

    @Test
    func `Tapping a day reports it, runs the single-mode reducer, and marks the cell`() throws {
        let view = makeCalendar()
        var tapped: [LMKCalendarDay] = []
        var selections: [LMKCalendarSelection] = []
        view.onDaySelected = { tapped.append($0) }
        view.onSelectionChange = { selections.append($0) }
        let cell = try #require(view.cell(for: day(12)))
        cell.handleTap()
        #expect(tapped == [day(12)])
        #expect(selections == [.single(day(12))])
        #expect(view.selection == .single(day(12)))
        #expect(cell.dayState?.isSelected == true)
        #expect(cell.selectionView.isHidden == false)
        #expect(cell.accessibilityTraits.contains(.selected))
        #expect(cell.numeralLabel.textColor == LMKColor.onAccent)
        cell.handleTap()
        #expect(selections.count == 1, "re-tapping the selected day changes nothing")
        #expect(tapped.count == 2, "but it is still reported as a tap")

        let adjacent = view.dayCells[0]
        adjacent.handleTap()
        #expect(tapped.count == 2, "adjacent-month days are not tappable")
    }

    @Test
    func `Range mode marks start, middle, and end cells; none mode selects nothing`() throws {
        let view = makeCalendar()
        view.selectionMode = .range
        try #require(view.cell(for: day(5))).handleTap()
        #expect(view.selection == .start(day(5)))
        #expect(view.cell(for: day(5))?.dayState?.rangePosition == .single)
        try #require(view.cell(for: day(9))).handleTap()
        #expect(view.selection == .range(day(5), day(9)))
        #expect(view.cell(for: day(5))?.dayState?.rangePosition == .start)
        #expect(view.cell(for: day(7))?.dayState?.rangePosition == .middle)
        #expect(view.cell(for: day(9))?.dayState?.rangePosition == .end)
        #expect(view.cell(for: day(7))?.rangeBandView.isHidden == false)
        #expect(view.cell(for: day(7))?.dayState?.isSelected == true)
        #expect(view.cell(for: day(10))?.rangeBandView.isHidden == true)

        view.selectionMode = .none
        view.setSelection(.empty)
        var tapped = 0
        view.onDaySelected = { _ in tapped += 1 }
        try #require(view.cell(for: day(2))).handleTap()
        #expect(tapped == 1)
        #expect(view.selection == .empty)
    }

    @Test
    func `setSelection and configure replace the selection silently`() {
        let view = makeCalendar()
        var reported = 0
        view.onSelectionChange = { _ in reported += 1 }
        view.setSelection(.multiple([day(1), day(2)]))
        #expect(view.cell(for: day(1))?.dayState?.isSelected == true)
        #expect(view.cell(for: day(2))?.dayState?.isSelected == true)
        #expect(view.cell(for: day(3))?.dayState?.isSelected == false)
        view.configure(month: Self.september, today: Self.today, selection: .single(day(20)))
        #expect(view.cell(for: day(1))?.dayState?.isSelected == false)
        #expect(view.cell(for: day(20))?.dayState?.isSelected == true)
        #expect(reported == 0)
    }

    // MARK: - Month changes

    @Test
    func `Chevrons page the view and report onMonthChanged`() {
        let view = makeCalendar()
        var changed: [LMKCalendarMonth] = []
        view.onMonthChanged = { changed.append($0) }
        view.nextButton.onTap?()
        #expect(view.visibleMonth == Self.october)
        #expect(changed == [Self.october])
        #expect(view.titleButton.title == "October 2026")
        #expect(view.cell(for: day(1, month: 10))?.dayState?.isInMonth == true)
        #expect(view.cell(for: day(16)) == nil, "September 16 is not in the October grid")
        view.previousButton.onTap?()
        view.showPreviousMonth()
        #expect(view.visibleMonth == LMKCalendarMonth(year: 2026, month: 8))
        #expect(changed.count == 3)
        view.setVisibleMonth(Self.september, animated: false)
        #expect(view.visibleMonth == Self.september)
        #expect(changed.count == 3, "setVisibleMonth does not report")
    }

    @Test
    func `With onMonthChangeProposed set the view never repages itself`() {
        let view = makeCalendar()
        var proposed: [LMKCalendarMonth] = []
        var changed = 0
        view.onMonthChangeProposed = { proposed.append($0) }
        view.onMonthChanged = { _ in changed += 1 }
        view.showNextMonth()
        #expect(proposed == [Self.october])
        #expect(view.visibleMonth == Self.september)
        #expect(view.titleButton.title == "September 2026")
        #expect(changed == 0)
        view.configure(month: Self.october, today: Self.today)
        #expect(view.visibleMonth == Self.october)
        // An interactive swipe that settled is proposed too; a host that ignores it snaps back.
        view.finishInteractivePaging(to: LMKCalendarMonth(year: 2026, month: 11))
        #expect(proposed.last == LMKCalendarMonth(year: 2026, month: 11))
        #expect(view.visibleMonth == Self.october)
        #expect(view.renderedMonth == Self.october)
    }

    @Test
    func `The Today button jumps to today's month unless the host takes it`() {
        let view = makeCalendar(style: LMKMonthCalendarView.Style(showsTodayButton: true))
        #expect(view.todayButton.isHidden == false)
        #expect(view.todayButton.title == "Today")
        view.configure(month: LMKCalendarMonth(year: 2020, month: 1), today: Self.today)
        view.todayButton.onTap?()
        #expect(view.visibleMonth == Self.september)
        var taps = 0
        view.onTodayTapped = { taps += 1 }
        view.configure(month: LMKCalendarMonth(year: 2020, month: 1), today: Self.today)
        view.todayButton.onTap?()
        #expect(taps == 1)
        #expect(view.visibleMonth == LMKCalendarMonth(year: 2020, month: 1))
        #expect(makeCalendar().todayButton.isHidden, "hidden by default")
    }

    @Test
    func `Minimum and maximum days disable cells, chevrons, and months`() {
        let view = makeCalendar()
        view.minimumDay = day(10)
        view.maximumDay = day(20)
        #expect(view.cell(for: day(9))?.dayState?.isEnabled == false)
        #expect(view.cell(for: day(10))?.dayState?.isEnabled == true)
        #expect(view.cell(for: day(21))?.dayState?.isEnabled == false)
        #expect(view.cell(for: day(9))?.accessibilityTraits.contains(.notEnabled) == true)
        #expect(view.previousButton.isEnabled == false)
        #expect(view.nextButton.isEnabled == false)
        #expect(!view.canShow(Self.october))
        var changed = 0
        view.onMonthChanged = { _ in changed += 1 }
        view.showNextMonth()
        #expect(view.visibleMonth == Self.september)
        #expect(changed == 0)
        var tapped = 0
        view.onDaySelected = { _ in tapped += 1 }
        view.cell(for: day(9))?.handleTap()
        #expect(tapped == 0)
    }

    // MARK: - Decorations

    @Test
    func `Decorations render dots (capped), badges, glyphs, values, and enablement`() throws {
        let view = makeCalendar()
        view.setDecorations([
            day(3): LMKCalendarDayDecoration(dots: [.red, .blue, .green, .yellow], accessibilityValue: "4 events"),
            day(4): LMKCalendarDayDecoration(badges: [.init(text: "2"), .init(text: "1", color: .orange)]),
            day(5): LMKCalendarDayDecoration(glyph: UIImage(systemName: "sun.max"), glyphTint: .orange),
            day(6): LMKCalendarDayDecoration(isEnabled: false),
        ])
        let dotted = try #require(view.cell(for: day(3)))
        #expect(dotted.dotsStack.arrangedSubviews.count(where: { !$0.isHidden }) == 3)
        #expect(dotted.dotsStack.arrangedSubviews[0].backgroundColor == UIColor.red)
        #expect(dotted.accessibilityValue == "4 events")
        #expect(dotted.decorationStack.isHidden == false)

        let badged = try #require(view.cell(for: day(4)))
        let badges = badged.badgesStack.arrangedSubviews.compactMap { $0 as? LMKBadgeView }.filter { !$0.isHidden }
        #expect(badges.count == 2)
        #expect(badges[0].countLabel.text == "2")
        #expect(badges[0].backgroundColor == LMKColor.primary)
        #expect(badges[1].backgroundColor == UIColor.orange)

        let glyphed = try #require(view.cell(for: day(5)))
        #expect(glyphed.glyphView.isHidden == false)
        #expect(glyphed.glyphView.tintColor == UIColor.orange)

        let disabled = try #require(view.cell(for: day(6)))
        #expect(disabled.isEnabled == false)
        #expect(disabled.numeralLabel.textColor == LMKColor.textTertiary)

        let plain = try #require(view.cell(for: day(7)))
        #expect(plain.decorationStack.isHidden)
        #expect(plain.glyphView.isHidden)

        view.style = LMKMonthCalendarView.Style(maxDots: 1)
        #expect(dotted.dotsStack.arrangedSubviews.count(where: { !$0.isHidden }) == 1)
    }

    @Test
    func `Rows grow to hold a badge band, so the last week's badges stay inside the grid`() throws {
        let view = makeCalendar()
        let plainHeight = view.intrinsicContentSize.height
        view.setDecorations([
            day(3): LMKCalendarDayDecoration(dots: [.red]),
            day(30): LMKCalendarDayDecoration(badges: [.count(2), .count(1, color: .orange)].compactMap(\.self)),
        ])
        #expect(view.intrinsicContentSize.height > plainHeight, "a badge band needs more than the 44pt row")
        view.frame.size.height = view.intrinsicContentSize.height
        view.layoutIfNeeded()

        let badged = try #require(view.cell(for: day(30)))
        badged.layoutIfNeeded()
        let band = badged.convert(badged.decorationStack.frame, to: view.gridContainer)
        #expect(band.maxY <= view.gridContainer.bounds.maxY, "the badge band ends at \(band.maxY) in a \(view.gridContainer.bounds.height)pt grid")
        #expect(badged.decorationStack.frame.maxY <= badged.bounds.maxY)

        // Dots alone fit the default row; the height returns when the badges go.
        view.setDecorations([day(3): LMKCalendarDayDecoration(dots: [.red, .blue])])
        #expect(view.intrinsicContentSize.height == plainHeight)
    }

    @Test
    func `One row height serves every month the decorations cover`() {
        let view = makeCalendar()
        view.setDecorations([day(12, month: 10): LMKCalendarDayDecoration(badges: [.init(text: "3")])])
        // September shows no badge, yet keeps the row height October needs: paging never resizes rows.
        let september = view.preferredHeight(for: Self.september)
        view.setVisibleMonth(Self.october, animated: false)
        #expect(view.preferredHeight(for: Self.september) == september)
        #expect(september > 316)
    }

    // MARK: - Style and theme

    @Test
    func `Style and theme.monthCalendar restyle marks, header, and rows`() throws {
        let view = makeCalendar(style: LMKMonthCalendarView.Style(
            accent: .purple,
            headerLayout: .leadingTitle,
            titleIsTappable: true,
            weekdayColor: .brown,
            selectionStyle: .ringCircle,
            todayStyle: .numeralOnly,
            circleRadius: 14,
            ringWidth: 3
        ))
        view.setSelection(.single(day(12)))
        let selected = try #require(view.cell(for: day(12)))
        #expect(selected.selectionView.isHidden == false)
        #expect(selected.selectionView.backgroundColor == UIColor.clear)
        #expect(selected.selectionView.layer.borderWidth == 3)
        #expect(selected.selectionView.layer.cornerRadius == 14)
        #expect(selected.numeralLabel.textColor == UIColor.purple)
        #expect(view.cell(for: day(16))?.todayView.isHidden == true)
        #expect(view.cell(for: day(16))?.numeralLabel.textColor == UIColor.purple)
        #expect(view.weekdayLabels[0].textColor == UIColor.brown)
        #expect(view.titleButton.isUserInteractionEnabled)
        #expect(view.titleButton.image != nil)
        #expect(view.headerStack.arrangedSubviews.first === view.titleButton)
        var titleTaps = 0
        view.onMonthTitleTapped = { titleTaps += 1 }
        view.titleButton.onTap?()
        #expect(titleTaps == 1)

        let plain = makeCalendar()
        #expect(plain.titleButton.isUserInteractionEnabled == false)
        #expect(plain.titleButton.accessibilityTraits.contains(.header))
        #expect(plain.headerStack.arrangedSubviews.first === plain.previousButton)
        let today = try #require(plain.cell(for: day(16)))
        #expect(today.todayView.isHidden == false)
        #expect(today.todayView.backgroundColor == LMKColor.primary.withAlphaComponent(LMKAlpha.xs))
        plain.setSelection(.single(day(16)))
        #expect(today.todayView.isHidden, "today hides under a filled selection")
        #expect(today.selectionView.backgroundColor == LMKColor.primary)

        var theme = LMKTheme()
        theme.monthCalendar = LMKMonthCalendarView.Style(accent: .magenta, dayRowHeight: 52, todayStyle: .ringRoundedRect)
        let themed = makeCalendar()
        themed.applyTheme(theme)
        #expect(themed.preferredHeight(for: Self.september) == 356)
        #expect(themed.cell(for: day(16))?.todayView.layer.borderColor == UIColor.magenta.cgColor)
        #expect(themed.previousButton.style.tintColor == UIColor.magenta)
    }

    @Test
    func `A custom cell factory rebuilds the grid with the subclass`() {
        final class Cell: LMKCalendarDayCell {}
        let view = makeCalendar()
        view.dayCellFactory = { Cell() }
        #expect(view.dayCells.count == 42)
        #expect(view.dayCells.allSatisfy { $0 is Cell })
        #expect(view.cell(for: day(1))?.dayState?.numeral == "1")
    }

    // MARK: - Paging rules

    @Test
    func `The reserved edge band yields to an outer pager and the commit rule follows distance or a flick`() {
        let view = makeCalendar()
        #expect(view.shouldReceivePanTouch(atX: 10) == false)
        #expect(view.shouldReceivePanTouch(atX: 100))
        #expect(view.shouldReceivePanTouch(atX: 370) == false)
        view.style = LMKMonthCalendarView.Style(reservedEdgeBandWidth: 0)
        #expect(view.shouldReceivePanTouch(atX: 1))

        #expect(view.pagingDecision(translation: -160, velocity: 0, width: 375, direction: 1, discrete: false) == .commit)
        #expect(view.pagingDecision(translation: -100, velocity: 0, width: 375, direction: 1, discrete: false) == .revert)
        #expect(view.pagingDecision(translation: -20, velocity: -400, width: 375, direction: 1, discrete: false) == .commit)
        #expect(view.pagingDecision(translation: -20, velocity: 400, width: 375, direction: 1, discrete: false) == .revert, "a flick the wrong way")
        #expect(view.pagingDecision(translation: 160, velocity: 0, width: 375, direction: -1, discrete: false) == .commit)
        #expect(view.pagingDecision(translation: -44, velocity: 0, width: 375, direction: 1, discrete: true) == .commit)
        #expect(view.pagingDecision(translation: -30, velocity: 0, width: 375, direction: 1, discrete: true) == .revert)
        #expect(view.pagingDecision(translation: -30, velocity: -500, width: 375, direction: 1, discrete: true) == .commit)
        #expect(view.panGesture.isEnabled)
        view.style = LMKMonthCalendarView.Style(paging: .buttonsOnly)
        #expect(view.panGesture.isEnabled == false)
    }

    @Test
    func `configure cancels a drag in flight`() {
        let view = makeCalendar()
        view.isPaging = true
        view.minimumRenderedRows = 6
        view.renderedMonth = Self.october
        view.configure(month: Self.september, today: Self.today)
        #expect(view.isPaging == false)
        #expect(view.minimumRenderedRows == 0)
        #expect(view.renderedMonth == Self.september)
        #expect(view.currentRowCount == 5)
    }

    // MARK: - Strings

    @Test
    func `Strings rename the header controls`() {
        let view = makeCalendar(style: LMKMonthCalendarView.Style(showsTodayButton: true))
        #expect(LMKMonthCalendarView.Strings().today == "Today")
        #expect(view.previousButton.accessibilityLabel == "Previous month")
        #expect(view.nextButton.accessibilityLabel == "Next month")
        view.strings = LMKMonthCalendarView.Strings(today: "Now", previousMonthAccessibilityLabel: "Back", nextMonthAccessibilityLabel: "Forward")
        #expect(view.todayButton.title == "Now")
        #expect(view.previousButton.accessibilityLabel == "Back")
        #expect(view.cell(for: day(16))?.accessibilityLabel == "Now, Wednesday, September 16, 2026")
        #expect(view.cell(for: day(17))?.accessibilityLabel == "Thursday, September 17, 2026")
    }
}
