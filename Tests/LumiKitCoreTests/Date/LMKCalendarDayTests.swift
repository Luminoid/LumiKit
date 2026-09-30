//
//  LMKCalendarDayTests.swift
//  LumiKit
//

import Foundation
import Testing
@testable import LumiKitCore

private nonisolated func gregorian(firstWeekday: Int = 1) -> Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "America/Los_Angeles") ?? .current
    calendar.locale = Locale(identifier: "en_US_POSIX")
    calendar.firstWeekday = firstWeekday
    return calendar
}

// MARK: - Day

struct LMKCalendarDayTests {
    @Test
    func `Key is zero-padded and round-trips`() {
        let day = LMKCalendarDay(year: 2026, month: 9, day: 5)
        #expect(day.key == "2026-09-05")
        #expect(day.description == "2026-09-05")
        #expect(LMKCalendarDay(key: "2026-09-05") == day)
        #expect(LMKCalendarDay(key: "2026-9-5") == day)
        #expect(LMKCalendarDay(key: "2026/09/05") == nil)
        #expect(LMKCalendarDay(key: "2026-09") == nil)
        #expect(LMKCalendarDay(key: "abc-de-fg") == nil)
    }

    @Test
    func `A date maps to the day in the given calendar's time zone`() throws {
        let calendar = gregorian()
        // 2026-09-16 03:30 UTC is still 2026-09-15 in Los Angeles.
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = try #require(TimeZone(identifier: "UTC"))
        let date = try #require(utc.date(from: DateComponents(year: 2026, month: 9, day: 16, hour: 3, minute: 30)))
        #expect(LMKCalendarDay(date, calendar: calendar) == LMKCalendarDay(year: 2026, month: 9, day: 15))
        #expect(LMKCalendarDay(date, calendar: utc) == LMKCalendarDay(year: 2026, month: 9, day: 16))
        #expect(date.lmk_calendarDay(in: utc).key == "2026-09-16")
    }

    @Test
    func `date(in:) rebuilds the moment at the requested hour and startOfDay is midnight`() throws {
        let calendar = gregorian()
        let day = LMKCalendarDay(year: 2026, month: 9, day: 16)
        let noon = try #require(day.date(in: calendar, hour: 12))
        #expect(calendar.component(.hour, from: noon) == 12)
        #expect(calendar.component(.day, from: noon) == 16)
        let start = try #require(day.startOfDay(in: calendar))
        #expect(calendar.component(.hour, from: start) == 0)
        #expect(LMKCalendarDay(start, calendar: calendar) == day)
    }

    @Test
    func `Comparison is chronological`() {
        let a = LMKCalendarDay(year: 2025, month: 12, day: 31)
        let b = LMKCalendarDay(year: 2026, month: 1, day: 1)
        let c = LMKCalendarDay(year: 2026, month: 1, day: 2)
        #expect(a < b)
        #expect(b < c)
        #expect(!(c < a))
        #expect([c, a, b].sorted() == [a, b, c])
        #expect(max(a, b, c) == c)
    }

    @Test
    func `Adding days crosses month and year boundaries; zero is identity`() {
        let calendar = gregorian()
        let jan31 = LMKCalendarDay(year: 2026, month: 1, day: 31)
        #expect(jan31.adding(days: 1, calendar: calendar) == LMKCalendarDay(year: 2026, month: 2, day: 1))
        #expect(jan31.adding(days: 0, calendar: calendar) == jan31)
        #expect(LMKCalendarDay(year: 2026, month: 1, day: 1).adding(days: -1, calendar: calendar) == LMKCalendarDay(year: 2025, month: 12, day: 31))
        #expect(LMKCalendarDay(year: 2024, month: 2, day: 28).adding(days: 1, calendar: calendar).day == 29, "leap year")
    }

    @Test
    func `days(to:) counts whole days in either direction`() {
        let calendar = gregorian()
        let start = LMKCalendarDay(year: 2026, month: 3, day: 7)
        let end = LMKCalendarDay(year: 2026, month: 3, day: 10)
        #expect(start.days(to: end, calendar: calendar) == 3)
        #expect(end.days(to: start, calendar: calendar) == -3)
        #expect(start.days(to: start, calendar: calendar) == 0)
        // Across the DST change (March 8, 2026 in Los Angeles) the count stays in days.
        #expect(LMKCalendarDay(year: 2026, month: 3, day: 1).days(to: LMKCalendarDay(year: 2026, month: 3, day: 15), calendar: calendar) == 14)
    }

    @Test
    func `Weekday and weekend follow the calendar`() {
        let calendar = gregorian()
        let tuesday = LMKCalendarDay(year: 2026, month: 9, day: 1)
        #expect(tuesday.weekday(in: calendar) == 3)
        #expect(!tuesday.isWeekend(in: calendar))
        #expect(LMKCalendarDay(year: 2026, month: 9, day: 5).isWeekend(in: calendar), "Saturday")
        #expect(tuesday.calendarMonth == LMKCalendarMonth(year: 2026, month: 9))
    }

    @Test
    func `today matches the calendar's current day`() {
        let calendar = gregorian()
        #expect(LMKCalendarDay.today(calendar: calendar) == LMKCalendarDay(Date(), calendar: calendar))
    }

    @Test
    func `Overflowing components normalize through the calendar, as DateComponents do`() {
        let calendar = gregorian()
        let overflow = LMKCalendarDay(year: 2026, month: 13, day: 1)
        #expect(overflow.key == "2026-13-01", "the raw components are kept")
        #expect(overflow.date(in: calendar).map { LMKCalendarDay($0, calendar: calendar) } == LMKCalendarDay(year: 2027, month: 1, day: 1))
        #expect(overflow.adding(days: 0, calendar: calendar) == overflow)
        #expect(overflow.adding(days: 1, calendar: calendar) == LMKCalendarDay(year: 2027, month: 1, day: 2))
    }
}

// MARK: - Month

struct LMKCalendarMonthTests {
    @Test
    func `Key, first day, last day, and day count`() {
        let calendar = gregorian()
        let february = LMKCalendarMonth(year: 2024, month: 2)
        #expect(february.key == "2024-02")
        #expect(LMKCalendarMonth(key: "2024-02") == february)
        #expect(LMKCalendarMonth(key: "2024") == nil)
        #expect(february.firstDay == LMKCalendarDay(year: 2024, month: 2, day: 1))
        #expect(february.numberOfDays(in: calendar) == 29)
        #expect(february.lastDay(in: calendar) == LMKCalendarDay(year: 2024, month: 2, day: 29))
        #expect(february.days(in: calendar).count == 29)
        #expect(february.days(in: calendar).first?.day == 1)
        #expect(february.contains(LMKCalendarDay(year: 2024, month: 2, day: 10)))
        #expect(!february.contains(LMKCalendarDay(year: 2024, month: 3, day: 1)))
        #expect(LMKCalendarMonth(containing: LMKCalendarDay(year: 2024, month: 2, day: 10)) == february)
    }

    @Test
    func `Month arithmetic and distance`() {
        let calendar = gregorian()
        let december = LMKCalendarMonth(year: 2025, month: 12)
        #expect(december.adding(months: 1, calendar: calendar) == LMKCalendarMonth(year: 2026, month: 1))
        #expect(december.adding(months: -12, calendar: calendar) == LMKCalendarMonth(year: 2024, month: 12))
        #expect(december.adding(months: 0, calendar: calendar) == december)
        #expect(december.months(to: LMKCalendarMonth(year: 2026, month: 3), calendar: calendar) == 3)
        #expect(LMKCalendarMonth(year: 2026, month: 3).months(to: december, calendar: calendar) == -3)
        #expect(december < LMKCalendarMonth(year: 2026, month: 1))
        #expect(LMKCalendarMonth.current(calendar: calendar) == LMKCalendarMonth(Date(), calendar: calendar))
        #expect(Date().lmk_calendarMonth(in: calendar) == LMKCalendarMonth.current(calendar: calendar))
    }

    @Test
    func `Weeks pad to whole rows starting on the calendar's first weekday`() {
        // September 2026 starts on a Tuesday and has 30 days.
        let sunday = gregorian(firstWeekday: 1)
        let september = LMKCalendarMonth(year: 2026, month: 9)
        let weeks = september.weeks(in: sunday)
        #expect(weeks.count == 5)
        #expect(weeks.allSatisfy { $0.count == 7 })
        #expect(weeks[0][0] == LMKCalendarDay(year: 2026, month: 8, day: 30))
        #expect(weeks[0][2] == LMKCalendarDay(year: 2026, month: 9, day: 1))
        #expect(weeks[4][6] == LMKCalendarDay(year: 2026, month: 10, day: 3))

        let monday = gregorian(firstWeekday: 2)
        let mondayWeeks = september.weeks(in: monday)
        #expect(mondayWeeks.count == 5)
        #expect(mondayWeeks[0][0] == LMKCalendarDay(year: 2026, month: 8, day: 31))
        #expect(mondayWeeks[0][1] == LMKCalendarDay(year: 2026, month: 9, day: 1))
    }

    @Test
    func `alwaysSix pads to six rows and fitMonth needs six for a long month`() {
        let sunday = gregorian(firstWeekday: 1)
        let september = LMKCalendarMonth(year: 2026, month: 9)
        #expect(september.weeks(in: sunday, rows: .alwaysSix).count == 6)
        #expect(september.weeks(in: sunday, rows: .alwaysSix)[5][0] == LMKCalendarDay(year: 2026, month: 10, day: 4))
        // August 2026 starts on a Saturday and has 31 days: six rows either way.
        let august = LMKCalendarMonth(year: 2026, month: 8)
        #expect(august.weeks(in: sunday).count == 6)
        // February 2026 starts on a Sunday and has 28 days: exactly four rows.
        let february = LMKCalendarMonth(year: 2026, month: 2)
        #expect(february.weeks(in: sunday).count == 4)
        #expect(february.weeks(in: sunday)[0][0] == february.firstDay)
        #expect(february.weeks(in: sunday, rows: .alwaysSix).count == 6)
    }

    @Test
    func `An overflowing month normalizes through the calendar`() {
        let calendar = gregorian()
        let overflow = LMKCalendarMonth(year: 2026, month: 14)
        #expect(overflow.numberOfDays(in: calendar) == 28, "February 2027")
        #expect(overflow.weeks(in: calendar).first?.first == LMKCalendarDay(year: 2027, month: 1, day: 31))
        #expect(overflow.adding(months: 1, calendar: calendar) == LMKCalendarMonth(year: 2027, month: 3))
    }
}
