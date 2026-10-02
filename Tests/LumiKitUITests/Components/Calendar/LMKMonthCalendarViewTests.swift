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

    /// A calendar of `identifier`, the shape a device set to that calendar hands the view.
    private static func calendar(_ identifier: Calendar.Identifier, firstWeekday: Int = 1) -> Calendar {
        var calendar = Calendar(identifier: identifier)
        calendar.timeZone = TimeZone(identifier: "America/Los_Angeles") ?? .current
        calendar.firstWeekday = firstWeekday
        return calendar
    }

    private static let september = LMKCalendarMonth(year: 2026, month: 9)
    private static let october = LMKCalendarMonth(year: 2026, month: 10)
    private static let november = LMKCalendarMonth(year: 2026, month: 11)
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

    /// A calendar hosted in a window, where month changes slide and settle through an animator.
    private func makeWindowedCalendar(style: LMKMonthCalendarView.Style = LMKMonthCalendarView.Style()) -> (LMKMonthCalendarView, UIWindow) {
        let view = LMKMonthCalendarView(calendar: Self.gregorian(), locale: Locale(identifier: "en_US"), style: style)
        view.configure(month: Self.september, today: Self.today)
        let window = LMKThemeTesting.host(view)
        view.frame = CGRect(x: 0, y: 0, width: 375, height: view.intrinsicContentSize.height)
        view.layoutIfNeeded()
        return (view, window)
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
        #expect(view.monthTitle(for: Self.october) == "October 2026")
    }

    @Test
    func `Day numerals are bare numbers in the locale's numbering system`() {
        // A localized "d" template renders "21日" in Chinese and Japanese; the cell wants "21".
        let chinese = LMKMonthCalendarView(calendar: Self.gregorian(), locale: Locale(identifier: "zh_Hans_CN"))
        chinese.configure(month: Self.september, today: Self.today)
        #expect(chinese.cell(for: day(21))?.numeralLabel.text == "21")
        #expect(chinese.cell(for: day(1))?.dayState?.numeral == "1")
        #expect(chinese.titleButton.title == "2026年9月")
        let japanese = LMKMonthCalendarView(calendar: Self.gregorian(), locale: Locale(identifier: "ja_JP"))
        japanese.configure(month: Self.september, today: Self.today)
        #expect(japanese.cell(for: day(21))?.numeralLabel.text == "21")
        let arabic = LMKMonthCalendarView(calendar: Self.gregorian(), locale: Locale(identifier: "ar_EG"))
        arabic.configure(month: Self.september, today: Self.today)
        #expect(arabic.cell(for: day(21))?.numeralLabel.text == 21.formatted(.number.locale(Locale(identifier: "ar_EG"))), "the locale's digits, not ASCII")
        #expect(arabic.cell(for: day(21))?.numeralLabel.text != "21")
    }

    @Test
    func `Japanese and Buddhist calendars keep the Gregorian grid and title through their own names`() throws {
        let japanese = LMKMonthCalendarView(calendar: Self.calendar(.japanese), locale: Locale(identifier: "ja_JP"))
        japanese.configure(month: Self.september, today: Self.today)
        #expect(japanese.currentRowCount == 5)
        #expect(japanese.dayCells[0].dayState?.day == day(30, month: 8))
        #expect(japanese.cell(for: day(1)) === japanese.dayCells[2], "the same grid as the Gregorian one")
        #expect(japanese.cell(for: day(16))?.dayState?.isToday == true)
        #expect(japanese.titleButton.title == "令和8年9月", "the calendar's own era in the title")
        #expect(japanese.cell(for: day(1))?.numeralLabel.text == "1")
        #expect(try #require(japanese.cell(for: day(16))?.accessibilityLabel).contains("令和8年9月16日"))
        // Paging back across the Reiwa boundary stays in order (Heisei 31 April is not 2049).
        japanese.configure(month: LMKCalendarMonth(year: 2019, month: 5), today: Self.today)
        japanese.showPreviousMonth()
        #expect(japanese.visibleMonth == LMKCalendarMonth(year: 2019, month: 4))
        #expect(japanese.titleButton.title == "平成31年4月")
        japanese.showPreviousMonth()
        #expect(japanese.visibleMonth == LMKCalendarMonth(year: 2019, month: 3))

        let buddhist = LMKMonthCalendarView(calendar: Self.calendar(.buddhist), locale: Locale(identifier: "th_TH"))
        buddhist.configure(month: Self.september, today: Self.today)
        #expect(buddhist.visibleMonth.key == "2026-09", "a Gregorian key on a Thai device")
        #expect(buddhist.titleButton.title?.contains("2569") == true, "Buddhist era in the title")
        #expect(buddhist.cell(for: day(1)) === buddhist.dayCells[2])
    }

    @Test
    func `Chinese and Hebrew calendars fall back to the civil calendar for display and page through civil months`() {
        let chinese = LMKMonthCalendarView(calendar: Self.calendar(.chinese), locale: Locale(identifier: "zh_Hans_CN"))
        chinese.configure(month: LMKCalendarMonth(year: 2025, month: 6), today: Self.today)
        #expect(chinese.titleButton.title == "2025年6月", "no lunar month name over a Gregorian grid")
        #expect(chinese.currentRowCount == 5)
        var visited: [LMKCalendarMonth] = []
        chinese.onMonthChange = { visited.append($0) }
        for _ in 0 ..< 3 {
            chinese.showNextMonth()
        }
        #expect(visited == (7 ... 9).map { LMKCalendarMonth(year: 2025, month: $0) }, "the leap month does not stall paging")
        #expect(chinese.cell(for: LMKCalendarDay(year: 2025, month: 9, day: 1))?.numeralLabel.text == "1")

        let hebrew = LMKMonthCalendarView(calendar: Self.calendar(.hebrew), locale: Locale(identifier: "en_US"))
        hebrew.configure(month: Self.september, today: Self.today)
        #expect(hebrew.titleButton.title == "September 2026")
        #expect(hebrew.currentRowCount == 5)
        #expect(hebrew.dayCells[0].dayState?.day == day(30, month: 8))
        #expect(hebrew.cell(for: day(30))?.dayState?.isInMonth == true)
        #expect(hebrew.cell(for: day(16))?.accessibilityLabel == "Today, Wednesday, September 16, 2026")
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
    func `The header surface's insets pad the band and grow it`() {
        let insets = NSDirectionalEdgeInsets(top: 6, leading: 12, bottom: 4, trailing: 20)
        let view = makeCalendar(style: LMKMonthCalendarView.Style(headerSurface: LMKSurfaceStyle(background: .solid(.yellow), corners: .fixed(5), contentInsets: insets)))
        #expect(view.headerView.backgroundColor == UIColor.yellow)
        #expect(view.headerView.layer.cornerRadius == 5)
        #expect(view.headerView.bounds.height == 54, "44 plus the vertical insets")
        #expect(view.headerStack.frame.minX == 12)
        #expect(view.headerStack.frame.minY == 6)
        #expect(abs(view.headerView.bounds.maxX - view.headerStack.frame.maxX - 20) < 0.5)
        #expect(view.preferredHeight(for: Self.september) == 326)
        #expect(view.intrinsicContentSize.height == view.preferredHeight(for: Self.september))
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

    @Test
    func `Content insets are directional and the hidden rows carry no required height`() throws {
        let view = makeCalendar(style: LMKMonthCalendarView.Style(contentInsets: NSDirectionalEdgeInsets(top: 1, leading: 30, bottom: 2, trailing: 10)))
        #expect(view.contentStack.frame.minX == 30)
        #expect(view.contentStack.frame.maxX == 365)
        view.semanticContentAttribute = .forceRightToLeft
        view.setNeedsLayout()
        view.layoutIfNeeded()
        #expect(view.contentStack.frame.minX == 10, "asymmetric insets mirror in RTL")
        #expect(view.contentStack.frame.maxX == 345)
        // A hidden sixth row: the stack's hiding constraint and the row height both hold.
        let hidden = view.rowStacks[5]
        #expect(hidden.isHidden)
        let heights = hidden.constraints.filter { $0.firstAttribute == .height && $0.identifier == nil }
        #expect(!heights.isEmpty)
        #expect(heights.allSatisfy { $0.priority.rawValue < UILayoutPriority.required.rawValue })
        #expect(try #require(view.headerView.constraints.first { $0.firstAttribute == .height && $0.identifier == nil }).priority.rawValue < UILayoutPriority.required.rawValue)
    }

    // MARK: - Selection

    @Test
    func `Tapping a day reports it, runs the single-mode reducer, and marks the cell`() throws {
        let view = makeCalendar()
        var tapped: [LMKCalendarDay] = []
        var selections: [LMKCalendarSelection] = []
        view.onDayTap = { tapped.append($0) }
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
        view.onDayTap = { _ in tapped += 1 }
        try #require(view.cell(for: day(2))).handleTap()
        #expect(tapped == 1)
        #expect(view.selection == .empty)
    }

    @Test
    func `A range renders as a band in every mode, even reversed, and a mode change re-renders`() throws {
        // A read-only calendar showing a booked range: `.none` mode, a `.range` selection.
        let view = makeCalendar()
        view.selectionMode = .none
        view.setSelection(.range(day(9), day(5)), animated: true)
        #expect(view.cell(for: day(5))?.dayState?.rangePosition == .start)
        #expect(view.cell(for: day(7))?.dayState?.rangePosition == .middle)
        #expect(view.cell(for: day(9))?.dayState?.rangePosition == .end)
        #expect(view.cell(for: day(7))?.rangeBandView.isHidden == false)
        #expect(view.cell(for: day(4))?.dayState?.isSelected == false)
        // Multiple mode draws single marks; switching the mode re-renders without another call.
        view.setSelection(.multiple([day(1), day(2)]))
        #expect(view.cell(for: day(1))?.dayState?.rangePosition == .single)
        view.selectionMode = .range
        try #require(view.cell(for: day(20))).handleTap()
        try #require(view.cell(for: day(22))).handleTap()
        #expect(view.cell(for: day(21))?.dayState?.rangePosition == .middle)
        view.selectionMode = .single
        #expect(view.cell(for: day(21))?.dayState?.rangePosition == .middle, "the selection is the host's until a tap")
        try #require(view.cell(for: day(3))).handleTap()
        #expect(view.selection == .single(day(3)))
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

    // MARK: - Today

    @Test
    func `The today mark follows the system day unless the host pinned one`() throws {
        let calendar = Self.gregorian()
        let view = LMKMonthCalendarView(calendar: calendar, locale: Locale(identifier: "en_US"))
        // The system day is read in the device's time zone.
        var local = calendar
        local.timeZone = .current
        let noon16 = try #require(local.date(from: DateComponents(year: 2026, month: 9, day: 16, hour: 12)))
        view.currentDate = { noon16 }
        view.configure(month: Self.september)
        #expect(view.today == Self.today)
        #expect(view.cell(for: day(16))?.dayState?.isToday == true)
        // Midnight passes: the significant-time-change notification moves the mark.
        view.currentDate = { noon16.addingTimeInterval(24 * 3600) }
        view.handleSignificantTimeChange()
        #expect(view.today == day(17))
        #expect(view.cell(for: day(16))?.dayState?.isToday == false)
        #expect(view.cell(for: day(17))?.dayState?.isToday == true)
        #expect(view.cell(for: day(17))?.accessibilityLabel == "Today, Thursday, September 17, 2026")

        view.setToday(day(20))
        view.currentDate = { noon16.addingTimeInterval(48 * 3600) }
        view.handleSignificantTimeChange()
        #expect(view.today == day(20), "a pinned day stays")
        view.configure(month: Self.september, today: day(21))
        view.handleSignificantTimeChange()
        #expect(view.today == day(21))
        view.configure(month: Self.september)
        #expect(view.today == day(18), "nil follows the clock again")
    }

    @Test
    func `The system today is the device's date even when the grid uses another time zone`() throws {
        // A grid far from the device's zone (a UTC-keyed trip calendar, say): the civil day
        // marked as today is the one on the device's clock.
        let offset = TimeZone.current.secondsFromGMT()
        let gridZone = try #require(TimeZone(identifier: offset >= 0 ? "Pacific/Pago_Pago" : "Pacific/Kiritimati"))
        var grid = Calendar(identifier: .gregorian)
        grid.timeZone = gridZone
        var local = Calendar(identifier: .gregorian)
        local.timeZone = .current
        // Just after local midnight east of the grid, just before it west of the grid: the two
        // zones are on different dates at this instant.
        let hour = offset >= 0 ? 0 : 23
        let instant = try #require(local.date(from: DateComponents(year: 2026, month: 9, day: 16, hour: hour, minute: 30)))
        #expect(LMKCalendarDay(instant, calendar: grid) != day(16), "the fixture really straddles a date line")

        let view = LMKMonthCalendarView(calendar: grid, locale: Locale(identifier: "en_US"))
        view.currentDate = { instant }
        view.configure(month: Self.september)
        #expect(view.today == day(16))
    }

    // MARK: - Month changes

    @Test
    func `Chevrons page the view and report onMonthChange`() {
        let view = makeCalendar()
        var changed: [LMKCalendarMonth] = []
        view.onMonthChange = { changed.append($0) }
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
    func `With onMonthChangeRequest set the view never repages itself`() async {
        let view = makeCalendar()
        var proposed: [LMKCalendarMonth] = []
        var changed = 0
        view.onMonthChangeRequest = { proposed.append($0) }
        view.onMonthChange = { _ in changed += 1 }
        view.showNextMonth()
        #expect(proposed == [Self.october])
        #expect(view.visibleMonth == Self.september)
        #expect(view.titleButton.title == "September 2026")
        #expect(changed == 0)
        view.configure(month: Self.october, today: Self.today)
        #expect(view.visibleMonth == Self.october)
        // An interactive swipe that settled is proposed too; the grid keeps showing the proposal
        // for one main-queue turn, then a host that ignored it gets its own month back.
        view.finishInteractivePaging(to: Self.november)
        #expect(proposed.last == Self.november)
        #expect(view.visibleMonth == Self.october)
        #expect(view.renderedMonth == Self.november)
        #expect(view.titleButton.title == "November 2026")
        await LMKWait.until { view.renderedMonth == Self.october }
        #expect(view.renderedMonth == Self.october)
        #expect(view.titleButton.title == "October 2026")
        #expect(changed == 0)
    }

    @Test
    func `A host answering a proposal with the proposed month applies it without a second slide`() async {
        let (view, window) = makeWindowedCalendar()
        defer { window.isHidden = true }
        var slid = 0
        view.onMonthChangeRequest = { [weak view] month in
            view?.setVisibleMonth(month, animated: true)
            slid += 1
        }
        view.finishInteractivePaging(to: Self.october)
        #expect(slid == 1)
        #expect(view.visibleMonth == Self.october)
        #expect(view.renderedMonth == Self.october)
        #expect(view.isPaging == false, "the grid already showed October; no slide")
        #expect(view.gridContainer.subviews == [view.gridStack])

        // A host that echoes the month on screen while a drag is live does not cancel the drag.
        view.beginDrag(translation: -20)
        #expect(view.isDragging)
        view.setVisibleMonth(Self.october, animated: true)
        #expect(view.isDragging)
        view.endDrag(translation: -10, velocity: 0, cancelled: true)
        await LMKWait.until { !view.isPaging }
        #expect(view.visibleMonth == Self.october)

        // A host that answers one main-queue turn later (a Combine sink) sees no snap-back in between.
        var shownWhenAnswering: LMKCalendarMonth?
        view.onMonthChangeRequest = { [weak view] month in
            DispatchQueue.main.async {
                shownWhenAnswering = view?.renderedMonth
                view?.configure(month: month, today: Self.today)
            }
        }
        view.finishInteractivePaging(to: Self.november)
        #expect(view.renderedMonth == Self.november)
        await LMKWait.until { shownWhenAnswering != nil }
        #expect(shownWhenAnswering == Self.november, "the proposal was still on screen when the host answered")
        #expect(view.visibleMonth == Self.november)
        #expect(view.renderedMonth == Self.november)
        try? await Task.sleep(for: .milliseconds(60))
        #expect(view.renderedMonth == Self.november, "and nothing snapped back afterwards")
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
        view.onTodayTap = { taps += 1 }
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
        view.onMonthChange = { _ in changed += 1 }
        view.showNextMonth()
        #expect(view.visibleMonth == Self.september)
        #expect(changed == 0)
        var tapped = 0
        view.onDayTap = { _ in tapped += 1 }
        view.cell(for: day(9))?.handleTap()
        #expect(tapped == 0)
    }

    // MARK: - Paging

    @Test
    func `Two quick chevron taps report both months and leave no snapshot behind`() async {
        let (view, window) = makeWindowedCalendar()
        defer { window.isHidden = true }
        var changed: [LMKCalendarMonth] = []
        view.onMonthChange = { changed.append($0) }
        view.showNextMonth()
        #expect(view.isPaging, "a slide is in flight in a window")
        #expect(view.visibleMonth == Self.october)
        view.showNextMonth()
        #expect(changed == [Self.october], "the first slide finished before the second began")
        #expect(view.visibleMonth == Self.november)
        #expect(view.gridContainer.subviews.count == 2, "one snapshot at a time")
        await LMKWait.until { !view.isPaging }
        #expect(changed == [Self.october, Self.november])
        #expect(view.gridContainer.subviews == [view.gridStack])
        #expect(view.gridStack.transform == .identity)
        #expect(view.renderedMonth == Self.november)
    }

    @Test
    func `A drag that lands during a settle commits the settle first, and the stale completion cannot clobber it`() async throws {
        let (view, window) = makeWindowedCalendar(style: LMKMonthCalendarView.Style(transitionDuration: 0.2))
        defer { window.isHidden = true }
        var changed: [LMKCalendarMonth] = []
        view.onMonthChange = { changed.append($0) }
        // Swipe 1: forward, released past the commit fraction; the settle animates.
        view.beginDrag(translation: -20)
        #expect(view.isDragging && view.renderedMonth == Self.october)
        view.endDrag(translation: -200, velocity: 0, cancelled: false)
        #expect(view.isPaging && !view.isDragging)
        #expect(view.pagingCompletion != nil)
        // Swipe 2 lands inside the settle: swipe 1 commits now, swipe 2 starts from October.
        view.beginDrag(translation: -30)
        #expect(changed == [Self.october])
        #expect(view.visibleMonth == Self.october)
        #expect(view.isDragging && view.renderedMonth == Self.november)
        #expect(view.gridContainer.subviews.count == 2)
        // The first settle's fallback fires past its duration; the live drag must survive it.
        try await Task.sleep(for: .milliseconds(400))
        #expect(view.isDragging)
        #expect(view.renderedMonth == Self.november)
        #expect(view.gridContainer.subviews.count == 2, "still exactly one snapshot")
        view.updateDrag(translation: -120)
        #expect(view.gridStack.transform.tx != 0)
        view.endDrag(translation: -300, velocity: 0, cancelled: false)
        await LMKWait.until { !view.isPaging }
        #expect(changed == [Self.october, Self.november])
        #expect(view.visibleMonth == Self.november)
        #expect(view.gridContainer.subviews == [view.gridStack])
        #expect(view.gridStack.transform == .identity)
        for cell in view.dayCells where !(cell.superview?.isHidden ?? true) {
            #expect(cell.dayState?.day.month != 9 || cell.dayState?.isInMonth == false)
        }
    }

    @Test
    func `A cancelled drag snaps back and a chevron tap during a drag pages from the resting month`() async {
        let (view, window) = makeWindowedCalendar()
        defer { window.isHidden = true }
        view.beginDrag(translation: 20)
        #expect(view.renderedMonth == LMKCalendarMonth(year: 2026, month: 8))
        #expect(view.minimumRenderedRows == 6, "August needs six rows; September keeps them during the drag")
        view.endDrag(translation: 40, velocity: 0, cancelled: true)
        await LMKWait.until { !view.isPaging }
        #expect(view.visibleMonth == Self.september)
        #expect(view.renderedMonth == Self.september)
        #expect(view.currentRowCount == 5)
        #expect(view.gridContainer.subviews == [view.gridStack])

        view.beginDrag(translation: -20)
        var changed: [LMKCalendarMonth] = []
        view.onMonthChange = { changed.append($0) }
        view.showNextMonth()
        #expect(!view.isDragging, "the drag is dropped")
        #expect(view.visibleMonth == Self.october)
        await LMKWait.until { !view.isPaging }
        #expect(changed == [Self.october])
        #expect(view.gridContainer.subviews == [view.gridStack])
    }

    @Test
    func `The pan routes changes to the live drag only and settles discretely under buttons-only`() {
        final class StubPan: UIPanGestureRecognizer {
            var stubState: UIGestureRecognizer.State = .possible
            var stubTranslation = CGPoint.zero
            var stubVelocity = CGPoint.zero
            override var state: UIGestureRecognizer.State {
                get { stubState }
                set { stubState = newValue }
            }

            override func translation(in _: UIView?) -> CGPoint {
                stubTranslation
            }

            override func velocity(in _: UIView?) -> CGPoint {
                stubVelocity
            }
        }
        let view = makeCalendar(style: LMKMonthCalendarView.Style(paging: .discrete))
        var changed: [LMKCalendarMonth] = []
        view.onMonthChange = { changed.append($0) }
        let pan = StubPan()
        pan.stubState = .changed
        pan.stubTranslation = CGPoint(x: -60, y: 2)
        view.handlePan(pan)
        #expect(view.isDragging == false, "discrete paging never follows the finger")
        pan.stubState = .ended
        view.handlePan(pan)
        #expect(view.visibleMonth == Self.october)
        #expect(changed == [Self.october])
        pan.stubTranslation = CGPoint(x: -10, y: 80)
        view.handlePan(pan)
        #expect(changed.count == 1, "a vertical pan is not a swipe")
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
    func `Count badges stay clear of a rounded-rectangle ring and draw no ring of their own`() throws {
        let view = makeCalendar(style: LMKMonthCalendarView.Style(selectionStyle: .ringRoundedRect, todayStyle: .ringRoundedRect, ringWidth: 2))
        view.setDecorations([Self.today: LMKCalendarDayDecoration(badges: [.count(2), .count(1, color: .orange)].compactMap(\.self))])
        view.frame.size.height = view.intrinsicContentSize.height
        view.layoutIfNeeded()

        let cell = try #require(view.cell(for: Self.today))
        cell.layoutIfNeeded()
        let badges = cell.badgesStack.arrangedSubviews.compactMap { $0 as? LMKBadgeView }.filter { !$0.isHidden }
        #expect(badges.count == 2)
        // The ring strokes 2pt inside a 1pt inset along the cell's edges.
        let ringInnerEdge = cell.bounds.maxY - 3
        for badge in badges {
            let frame = badge.convert(badge.bounds, to: cell)
            #expect(frame.maxY < ringInnerEdge, "a badge ends at \(frame.maxY), the ring's inner edge is at \(ringInnerEdge)")
            #expect(badge.layer.borderWidth == 0, "an inline count draws no separating ring")
        }

        // A host that wants a ring around its badges still gets one.
        view.style.badge = LMKBadgeView.Style(surface: LMKSurfaceStyle(border: .solid(.white, width: 1)))
        let ringed = cell.badgesStack.arrangedSubviews.compactMap { $0 as? LMKBadgeView }.filter { !$0.isHidden }
        #expect(ringed.allSatisfy { $0.layer.borderWidth > 0 })
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
        view.onMonthTitleTap = { titleTaps += 1 }
        view.titleButton.onTap?()
        #expect(titleTaps == 1)

        let plain = makeCalendar(style: LMKMonthCalendarView.Style(headerLayout: .centeredTitle, selectionStyle: .filledCircle, todayStyle: .tintedCircle))
        #expect(plain.titleButton.isUserInteractionEnabled == false)
        #expect(plain.titleButton.accessibilityTraits.contains(.header))
        #expect(plain.headerStack.arrangedSubviews.first === plain.previousButton)
        let today = try #require(plain.cell(for: day(16)))
        #expect(today.todayView.isHidden == false)
        #expect(today.todayView.backgroundColor == LMKColor.primary.withAlphaComponent(LMKAlpha.xs))
        plain.setSelection(.single(day(16)))
        #expect(today.todayView.isHidden, "today hides under a filled selection")
        #expect(today.selectionView.backgroundColor == LMKColor.primary)
        #expect(today.numeralLabel.textColor == LMKColor.onAccent)

        var theme = LMKTheme()
        theme.monthCalendar = LMKMonthCalendarView.Style(accent: .magenta, dayRowHeight: 52, todayStyle: .ringRoundedRect)
        let themed = makeCalendar()
        themed.applyTheme(theme)
        #expect(themed.preferredHeight(for: Self.september) == 356)
        #expect(themed.cell(for: day(16))?.todayView.layer.borderColor == UIColor.magenta.cgColor)
        #expect(themed.previousButton.style.tintColor == UIColor.magenta)
    }

    @Test
    func `Every style field reaches the view`() throws {
        let style = LMKMonthCalendarView.Style(
            headerHeight: 50,
            headerSurface: LMKSurfaceStyle(background: .solid(.yellow)),
            titleTextStyle: .h1,
            titleColor: .brown,
            showsTodayButton: true,
            navigationButton: LMKButton.Style(tintColor: .cyan),
            todayButton: LMKButton.Style(tintColor: .magenta),
            monthTitleTemplate: "yMMM",
            spacingAfterHeader: 3,
            weekdayRowHeight: 30,
            weekdayTextStyle: .h4,
            weekdayColor: .orange,
            spacingAfterWeekdays: 7,
            dayRowHeight: 48,
            cellSurface: LMKSurfaceStyle(background: .solid(.green), corners: .fixed(4)),
            numeralTextStyle: .caption,
            numeralEmphasisTextStyle: .h2,
            numeralColor: .red,
            numeralSelectedColor: .blue,
            numeralTodayColor: .purple,
            numeralDisabledColor: .gray,
            numeralCenterOffset: -7,
            selectionTint: .systemPink,
            todayTint: .systemTeal,
            todayCircleAlpha: 0.5,
            todayHiddenUnderSelection: false,
            roundedRectRadius: 9,
            rangeBandAlpha: 0.3,
            dotSize: 7,
            dotSpacing: 5,
            maxDots: 2,
            badge: LMKBadgeView.Style(textColor: .black),
            glyphSize: 21,
            glyphTint: .systemIndigo,
            reservedEdgeBandWidth: 0,
            commitFraction: 0.1,
            flickVelocity: 50,
            discreteSwipeThreshold: 10,
            transitionDuration: 0.01,
            haptics: false,
            pressAnimation: false,
            maximumContentSizeCategory: .large
        )
        let view = makeCalendar(style: style)
        let traits = view.traitCollection
        let februaryHeight: CGFloat = 298 // 8 + 50 + 3 + 30 + 7 + 4 * 48 + 8
        #expect(view.preferredHeight(for: LMKCalendarMonth(year: 2026, month: 2)) == februaryHeight)
        view.selectionMode = .range
        view.setDecorations([
            day(3): LMKCalendarDayDecoration(dots: [.red, .blue, .green], badges: [.init(text: "1")], glyph: UIImage(systemName: "sun.max")),
        ])
        view.setSelection(.range(day(10), day(12)))
        view.layoutIfNeeded()
        #expect(view.headerView.bounds.height == 50)
        #expect(view.headerView.backgroundColor == UIColor.yellow)
        #expect(view.titleButton.style.textStyle == .h1)
        #expect(view.titleButton.style.foregroundColor == UIColor.brown)
        #expect(view.titleButton.title == "Sep 2026")
        #expect(view.previousButton.style.tintColor == UIColor.cyan)
        #expect(view.todayButton.style.tintColor == UIColor.magenta)
        #expect(view.contentStack.customSpacing(after: view.headerView) == 3)
        #expect(view.weekdayRow.bounds.height == 30)
        #expect(view.weekdayLabels[0].font == LMKTypography.font(for: .h4, compatibleWith: traits))
        #expect(view.weekdayLabels[0].textColor == UIColor.orange)
        #expect(view.contentStack.customSpacing(after: view.weekdayRow) == 7)
        #expect(view.maximumContentSizeCategory == .large)

        let plain = try #require(view.cell(for: day(20)))
        #expect(plain.backgroundColor == UIColor.green)
        #expect(plain.layer.cornerRadius == 4)
        #expect(plain.numeralLabel.font == LMKTypography.font(for: .caption, compatibleWith: traits))
        #expect(plain.numeralLabel.textColor == UIColor.red)
        #expect(abs(plain.numeralStack.center.y - (plain.bounds.midY - 7)) < 0.5)
        let selected = try #require(view.cell(for: day(10)))
        #expect(selected.numeralLabel.font == LMKTypography.font(for: .h2, compatibleWith: traits))
        #expect(selected.numeralLabel.textColor == UIColor.blue)
        #expect(selected.selectionView.backgroundColor == UIColor.systemPink)
        #expect(selected.rangeBandView.backgroundColor == UIColor.systemPink.withAlphaComponent(0.3))
        let today = try #require(view.cell(for: day(16)))
        #expect(today.numeralLabel.textColor == UIColor.purple)
        #expect(today.todayView.backgroundColor == UIColor.systemTeal.withAlphaComponent(0.5))
        view.setSelection(.single(day(16)))
        #expect(today.todayView.isHidden == false, "todayHiddenUnderSelection: false")
        #expect(view.dayCells[0].numeralLabel.textColor == UIColor.gray, "an adjacent day is disabled")
        let decorated = try #require(view.cell(for: day(3)))
        decorated.setNeedsLayout()
        decorated.layoutIfNeeded()
        let dots = decorated.dotsStack.arrangedSubviews.filter { !$0.isHidden }
        #expect(dots.count == 2)
        #expect(dots[0].bounds.width == 7)
        #expect(decorated.dotsStack.spacing == 5)
        #expect(decorated.glyphView.bounds.width == 21)
        #expect(decorated.glyphView.tintColor == UIColor.systemIndigo)
        #expect((decorated.badgesStack.arrangedSubviews.first as? LMKBadgeView)?.style.textColor == UIColor.black)
        view.style.selectionStyle = .ringRoundedRect
        #expect(view.cell(for: day(16))?.selectionView.layer.cornerRadius == 9)
        #expect(view.shouldReceivePanTouch(atX: 1))
        #expect(view.pagingDecision(translation: -40, velocity: 0, width: 375, direction: 1, discrete: false) == .commit, "10% of the width commits")
        #expect(view.pagingDecision(translation: -1, velocity: -60, width: 375, direction: 1, discrete: false) == .commit, "a 50pt/s flick commits")
        #expect(view.pagingDecision(translation: -10, velocity: 0, width: 375, direction: 1, discrete: true) == .commit)
        #expect(view.resolvedStyle.transitionDuration == 0.01)
        #expect(view.resolvedStyle.haptics == false && view.resolvedStyle.pressAnimation == false)
        let merged = LMKMonthCalendarView.Style().merging(style)
        #expect(merged == style, "merging over an empty style keeps every field")
        #expect(style.merging(LMKMonthCalendarView.Style()) == style)
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
