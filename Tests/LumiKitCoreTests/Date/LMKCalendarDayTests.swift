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

/// A calendar of `identifier` in `zone`, the shape a device set to that calendar hands the kit.
private nonisolated func calendar(_ identifier: Calendar.Identifier, zone: String = "America/Los_Angeles", locale: String = "en_US_POSIX", firstWeekday: Int = 1) -> Calendar {
    var calendar = Calendar(identifier: identifier)
    calendar.timeZone = TimeZone(identifier: zone) ?? .current
    calendar.locale = Locale(identifier: locale)
    calendar.firstWeekday = firstWeekday
    return calendar
}

private nonisolated func day(_ year: Int, _ month: Int, _ day: Int) -> LMKCalendarDay {
    LMKCalendarDay(year: year, month: month, day: day)
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

    @Test(arguments: [
        ("Africa/Cairo", day(2026, 4, 24)),
        ("America/Santiago", day(2026, 9, 6)),
        ("America/Havana", day(2026, 3, 8)),
        ("Asia/Beirut", day(2026, 3, 29)),
    ])
    func `Day deltas survive a daylight-saving change at midnight`(zone: String, springForward: LMKCalendarDay) throws {
        // These zones start DST at 00:00, so the day begins at 01:00 and a start-of-day delta came out 0.
        let calendar = calendar(.gregorian, zone: zone)
        let before = springForward.adding(days: -1, calendar: calendar)
        let after = springForward.adding(days: 1, calendar: calendar)
        #expect(before.days(to: springForward, calendar: calendar) == 1)
        #expect(springForward.days(to: after, calendar: calendar) == 1)
        #expect(after.days(to: before, calendar: calendar) == -2)
        #expect(before.adding(days: 2, calendar: calendar) == after)
        let start = try #require(springForward.startOfDay(in: calendar))
        #expect(calendar.component(.hour, from: start) == 1, "the day really starts at 01:00 in \(zone)")
        #expect(LMKCalendarDay(start, calendar: calendar) == springForward)
        let month = springForward.calendarMonth
        #expect(month.adding(months: -1, calendar: calendar).months(to: month.adding(months: 1, calendar: calendar), calendar: calendar) == 2)
    }

    @Test
    func `A day is a Gregorian civil date under the Japanese and Buddhist calendars`() throws {
        let gregorian = gregorian()
        let japanese = calendar(.japanese, locale: "ja_JP")
        let buddhist = calendar(.buddhist, locale: "th_TH")
        // Heisei 30 (2018): the year number and the era differ, the civil day does not.
        let heisei = try #require(gregorian.date(from: DateComponents(year: 2018, month: 6, day: 15, hour: 12)))
        let day = LMKCalendarDay(heisei, calendar: japanese)
        #expect(day == LMKCalendarDay(year: 2018, month: 6, day: 15))
        #expect(day.key == "2018-06-15")
        #expect(day.date(in: japanese).map { LMKCalendarDay($0, calendar: gregorian) } == day, "round-trips through date(in:)")
        #expect(day.date(in: japanese) == day.date(in: gregorian))
        #expect(LMKCalendarDay(heisei, calendar: buddhist).key == "2018-06-15", "not 2561")
        #expect(LMKCalendarMonth(heisei, calendar: buddhist).key == "2018-06")
        // Paging back across the Reiwa boundary stays in order.
        let reiwa = LMKCalendarMonth(year: 2019, month: 5)
        let previous = reiwa.adding(months: -1, calendar: japanese)
        #expect(previous == LMKCalendarMonth(year: 2019, month: 4))
        #expect(previous < reiwa)
        #expect(previous.months(to: reiwa, calendar: japanese) == 1)
        #expect(reiwa.weeks(in: japanese) == reiwa.weeks(in: gregorian))
        #expect(day.weekday(in: japanese) == day.weekday(in: gregorian))
    }

    @Test
    func `A day is a Gregorian civil date under the Chinese and Hebrew calendars`() throws {
        let gregorian = gregorian()
        let chinese = calendar(.chinese, locale: "zh_CN")
        let hebrew = calendar(.hebrew, locale: "he_IL")
        // 2025 has a leap month 6 in the Chinese calendar; paging must not stall on it.
        var month = LMKCalendarMonth(year: 2025, month: 6)
        var visited: [LMKCalendarMonth] = []
        for _ in 0 ..< 4 {
            month = month.adding(months: 1, calendar: chinese)
            visited.append(month)
        }
        #expect(visited == (7 ... 10).map { LMKCalendarMonth(year: 2025, month: $0) })
        let september = LMKCalendarMonth(year: 2026, month: 9)
        #expect(september.numberOfDays(in: hebrew) == 30)
        #expect(september.numberOfDays(in: chinese) == 30)
        #expect(september.weeks(in: hebrew) == september.weeks(in: gregorian))
        #expect(september.weeks(in: chinese) == september.weeks(in: gregorian))
        let instant = try #require(gregorian.date(from: DateComponents(year: 2026, month: 9, day: 30, hour: 12)))
        let day = LMKCalendarDay(instant, calendar: hebrew)
        #expect(day.key == "2026-09-30")
        #expect(day.date(in: chinese).map { LMKCalendarDay($0, calendar: gregorian) } == day)
        #expect(LMKCalendarDay(instant, calendar: chinese).adding(days: 1, calendar: chinese) == LMKCalendarDay(year: 2026, month: 10, day: 1))
    }

    @Test
    func `The civil calendar keeps the zone, locale, and week rules; display follows the calendar only when its months are Gregorian`() {
        let japanese = calendar(.japanese, zone: "Asia/Tokyo", locale: "ja_JP", firstWeekday: 2)
        let civil = japanese.lmk_civilCalendar
        #expect(civil.identifier == .gregorian)
        #expect(civil.timeZone.identifier == "Asia/Tokyo")
        #expect(civil.locale?.identifier == "ja_JP")
        #expect(civil.firstWeekday == 2)
        #expect(civil.minimumDaysInFirstWeek == japanese.minimumDaysInFirstWeek)
        #expect(japanese.lmk_hasGregorianMonths)
        #expect(japanese.lmk_civilDisplayCalendar.identifier == .japanese)
        let chinese = calendar(.chinese)
        #expect(!chinese.lmk_hasGregorianMonths)
        #expect(chinese.lmk_civilDisplayCalendar.identifier == .gregorian)
        #expect(gregorian(firstWeekday: 3).lmk_civilCalendar == gregorian(firstWeekday: 3), "a Gregorian is its own twin")
        #expect(calendar(.iso8601).lmk_civilCalendar.identifier == .iso8601)
        for identifier in [Calendar.Identifier.buddhist, .republicOfChina, .iso8601] {
            #expect(calendar(identifier).lmk_hasGregorianMonths, "\(identifier)")
        }
        for identifier in [Calendar.Identifier.hebrew, .islamicUmmAlQura, .persian, .indian, .coptic, .ethiopicAmeteMihret] {
            #expect(!calendar(identifier).lmk_hasGregorianMonths, "\(identifier)")
        }
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
