//
//  LMKDateFormatTests.swift
//  LumiKit
//

import Foundation
import Testing
@testable import LumiKitCore

private let utc = TimeZone(identifier: "UTC") ?? .gmt

private func makeContext(locale: String = "en_US", hourCycle: LMKDateFormat.HourCycle = .system, firstWeekday: Int? = nil) -> LMKDateFormat.Context {
    var calendar = Calendar(identifier: .gregorian)
    if let firstWeekday { calendar.firstWeekday = firstWeekday }
    return LMKDateFormat.Context(locale: Locale(identifier: locale), calendar: calendar, timeZone: utc, hourCycle: hourCycle)
}

/// ICU separates "9:41" from "AM" with a narrow no-break space (U+202F) and uses U+00A0 in some
/// locales; the tests compare against plain spaces.
private func plain(_ string: String?) -> String? {
    string?.replacingOccurrences(of: "\u{202F}", with: " ").replacingOccurrences(of: "\u{00A0}", with: " ")
}

private func makeDate(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 0, _ minute: Int = 0) -> Date {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = utc
    return calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute)) ?? Date()
}

// MARK: - Pure formatting (no shared state)

struct LMKDateFormatTests {
    private let context = makeContext()
    private let date = makeDate(2026, 4, 27, 9, 41)

    @Test
    func `Standard date styles render through the locale`() {
        #expect(LMKDateFormat.string(date, date: .short, context: context) == "4/27/2026")
        #expect(LMKDateFormat.string(date, date: .medium, context: context) == "Apr 27, 2026")
        #expect(LMKDateFormat.string(date, date: .long, context: context) == "April 27, 2026")
        #expect(LMKDateFormat.string(date, date: .full, context: context) == "Monday, April 27, 2026")
        #expect(LMKDateFormat.string(date, date: .none, context: context).isEmpty)
    }

    @Test
    func `Field-based date styles`() {
        #expect(LMKDateFormat.string(date, date: .monthDay, context: context) == "Apr 27")
        #expect(LMKDateFormat.string(date, date: .monthYear, context: context) == "April 2026")
        #expect(LMKDateFormat.string(date, date: .monthYearAbbreviated, context: context) == "Apr 2026")
        #expect(LMKDateFormat.string(date, date: .weekdayMonthDay, context: context) == "Mon, Apr 27")
        #expect(LMKDateFormat.string(date, date: .weekdayMonthDayYear, context: context) == "Mon, Apr 27, 2026")
        #expect(LMKDateFormat.monthYearString(date, context: context) == "April 2026")
        #expect(LMKDateFormat.monthYearString(date, abbreviated: true, context: context) == "Apr 2026")
    }

    @Test
    func `Time styles append to the date and stand alone`() {
        #expect(plain(LMKDateFormat.string(date, date: .none, time: .short, context: context)) == "9:41 AM")
        #expect(plain(LMKDateFormat.string(date, date: .none, time: .medium, context: context)) == "9:41:00 AM")
        let combined = plain(LMKDateFormat.string(date, date: .medium, time: .short, context: context)) ?? ""
        #expect(combined.hasPrefix("Apr 27, 2026"))
        #expect(combined.hasSuffix("9:41 AM"))
        let withWeekday = plain(LMKDateFormat.string(date, date: .weekdayMonthDay, time: .short, context: context)) ?? ""
        #expect(withWeekday.contains("Mon, Apr 27"))
        #expect(withWeekday.contains("9:41 AM"))
    }

    @Test
    func `Custom patterns render verbatim and take a time`() {
        #expect(LMKDateFormat.string(date, date: .custom(pattern: "MM/dd/yyyy"), context: context) == "04/27/2026")
        #expect(plain(LMKDateFormat.string(date, date: .custom(pattern: "yyyy-MM-dd"), time: .short, context: context)) == "2026-04-27 9:41 AM")
    }

    @Test
    func `Hour cycle pins the clock over the locale`() {
        let evening = makeDate(2026, 7, 27, 20, 0)
        #expect(plain(LMKDateFormat.clockTime(evening, context: context)) == "8:00 PM")
        #expect(LMKDateFormat.clockTime(evening, context: makeContext(hourCycle: .twentyFourHour)) == "20:00")
        #expect(LMKDateFormat.clockTime(evening, context: makeContext(locale: "en_GB")) == "20:00")
        #expect(LMKDateFormat.clockTime(evening, context: makeContext(locale: "en_GB", hourCycle: .twelveHour))?.lowercased().contains("pm") == true)
        #expect(LMKDateFormat.usesTwelveHourClock(context: context))
        #expect(!LMKDateFormat.usesTwelveHourClock(context: makeContext(locale: "en_GB")))
        #expect(LMKDateFormat.usesTwelveHourClock(context: makeContext(locale: "en_GB", hourCycle: .twelveHour)))
        #expect(!LMKDateFormat.usesTwelveHourClock(context: makeContext(hourCycle: .twentyFourHour)))
    }

    @Test
    func `Clock time omits midnight on request and composes with the date`() {
        let midnight = makeDate(2026, 7, 27)
        let evening = makeDate(2026, 7, 27, 20, 0)
        #expect(plain(LMKDateFormat.clockTime(midnight, context: context)) == "12:00 AM")
        #expect(LMKDateFormat.clockTime(midnight, omitMidnight: true, context: context) == nil)
        #expect(plain(LMKDateFormat.clockTime(evening, omitMidnight: true, context: context)) == "8:00 PM")
        #expect(plain(LMKDateFormat.dateWithClockTime(evening, context: context)) == "Jul 27, 2026 · 8:00 PM")
        #expect(LMKDateFormat.dateWithClockTime(midnight, context: context) == "Jul 27, 2026")
        #expect(plain(LMKDateFormat.dateWithClockTime(evening, date: .weekdayMonthDay, separator: " at ", context: context)) == "Mon, Jul 27 at 8:00 PM")
    }

    @Test
    func `Widest clock sample follows the hour cycle`() {
        #expect(plain(LMKDateFormat.widestClockSample(context: context)) == "12:45 PM")
        #expect(LMKDateFormat.widestClockSample(context: makeContext(hourCycle: .twentyFourHour)) == "23:45")
    }

    @Test
    func `Intervals and range labels`() {
        let start = makeDate(2026, 6, 6)
        let end = makeDate(2026, 6, 8)
        let interval = LMKDateFormat.intervalString(from: start, to: end, context: context)
        #expect(interval.contains("Jun 6"))
        #expect(interval.contains("8, 2026"))
        #expect(interval.contains("–"))
        #expect(LMKDateFormat.intervalString(from: end, to: start, context: context) == interval, "reversed bounds are normalized")
        #expect(LMKDateFormat.intervalString(from: start, to: end, date: .none, context: context).isEmpty)
        #expect(!LMKDateFormat.intervalString(from: start, to: end, date: .custom(pattern: "yMMMd"), context: context).isEmpty)

        #expect(LMKDateFormat.rangeLabel(start: nil, end: end, context: context) == nil)
        #expect(LMKDateFormat.rangeLabel(start: start, end: nil, context: context) == "Jun 6, 2026")
        #expect(LMKDateFormat.rangeLabel(start: start, end: makeDate(2026, 6, 6, 18), context: context) == "Jun 6, 2026", "an end on the same day is a single date")
        #expect(LMKDateFormat.rangeLabel(start: start, end: end, context: context) == interval)
        #expect(LMKDateFormat.rangeLabel(start: start, end: end, date: .long, context: context)?.contains("June 6") == true)
    }

    @Test
    func `Residence labels render month spans and the ongoing form`() {
        let start = makeDate(2014, 9, 1)
        let end = makeDate(2021, 8, 1)
        #expect(LMKDateFormat.residenceLabel(start: nil, end: end, context: context) == nil)
        let closed = LMKDateFormat.residenceLabel(start: start, end: end, context: context)
        #expect(closed?.contains("Sep 2014") == true)
        #expect(closed?.contains("Aug 2021") == true)
        let ongoing = LMKDateFormat.residenceLabel(start: end, end: nil, context: context)
        #expect(ongoing?.hasPrefix("Aug 2021") == true)
        #expect(ongoing != "Aug 2021", "the ongoing form appends the localized suffix")
    }

    @Test
    func `Relative day strings name the neighbours and fall back past them`() {
        let today = makeDate(2026, 4, 27, 15)
        #expect(LMKDateFormat.relativeDayString(makeDate(2026, 4, 27, 2), relativeTo: today, context: context) == "Today")
        #expect(LMKDateFormat.relativeDayString(makeDate(2026, 4, 28), relativeTo: today, context: context) == "Tomorrow")
        #expect(LMKDateFormat.relativeDayString(makeDate(2026, 4, 26, 23), relativeTo: today, context: context) == "Yesterday")
        #expect(LMKDateFormat.relativeDayString(makeDate(2026, 4, 29), relativeTo: today, context: context) == "Apr 29, 2026")
        #expect(LMKDateFormat.relativeDayString(makeDate(2026, 4, 20), relativeTo: today, fallback: .weekdayMonthDay, context: context) == "Mon, Apr 20")
    }

    @Test
    func `Weekday symbols rotate to the calendar's first weekday`() {
        #expect(LMKDateFormat.weekdaySymbols(context: makeContext(firstWeekday: 1)) == ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"])
        #expect(LMKDateFormat.weekdaySymbols(context: makeContext(firstWeekday: 2)).first == "Mon")
        #expect(LMKDateFormat.weekdaySymbols(style: .wide, context: makeContext(firstWeekday: 2)).last == "Sunday")
        #expect(LMKDateFormat.weekdaySymbols(style: .narrow, context: makeContext(firstWeekday: 1)).count == 7)
    }

    @Test
    func `Context copies swap the time zone and hour cycle`() {
        let tokyo = TimeZone(identifier: "Asia/Tokyo") ?? utc
        let instant = makeDate(2026, 4, 27, 0, 0)
        #expect(plain(LMKDateFormat.clockTime(instant, context: context.timeZone(tokyo))) == "9:00 AM")
        #expect(LMKDateFormat.clockTime(instant, context: context.timeZone(tokyo).hourCycle(.twentyFourHour)) == "09:00")
        #expect(context.timeZone(tokyo).timeZone == tokyo)
        #expect(context.hourCycle(.twelveHour).hourCycle == .twelveHour)
    }

    @Test
    func `Date conveniences forward to the namespace`() {
        #expect(date.lmk_string(.medium, context: context) == "Apr 27, 2026")
        #expect(plain(date.lmk_clockTime(context: context)) == "9:41 AM")
        #expect(makeDate(2026, 4, 28).lmk_relativeDayString(relativeTo: date, context: context) == "Tomorrow")
    }

    @Test
    func `Formatters are cached per pattern and context`() {
        let first = LMKDateFormat.formatter(pattern: "yyyy-MM-dd", context: context)
        #expect(first === LMKDateFormat.formatter(pattern: "yyyy-MM-dd", context: context))
        #expect(first !== LMKDateFormat.formatter(pattern: "yyyy-MM-dd", context: makeContext(locale: "es_ES")))
        #expect(first !== LMKDateFormat.formatter(pattern: "yyyy-MM-dd", context: context.timeZone(TimeZone(identifier: "Asia/Tokyo") ?? utc)))
        #expect(first.string(from: date) == "2026-04-27")
        let template = LMKDateFormat.formatter(template: "yMMMd", context: context)
        #expect(template === LMKDateFormat.formatter(template: "yMMMd", context: context))
        #expect(template.string(from: date) == "Apr 27, 2026")
        LMKDateFormat.resetCache()
        #expect(first !== LMKDateFormat.formatter(pattern: "yyyy-MM-dd", context: context))
    }
}

// MARK: - Shared state (preferred pattern, default context, strings)

@Suite(.serialized)
struct LMKDateFormatSharedStateTests {
    private let context = makeContext()
    private let date = makeDate(2026, 4, 27, 9, 41)

    @Test
    func `The preferred pattern drives the default style and includeTime`() {
        defer { LMKDateFormat.preferredDatePattern = nil }
        #expect(LMKDateFormat.string(date, context: context) == "Apr 27, 2026")
        LMKDateFormat.preferredDatePattern = "MM/dd/yyyy"
        #expect(LMKDateFormat.string(date, context: context) == "04/27/2026")
        #expect(LMKDateFormat.string(date, date: .preferred, context: context) == "04/27/2026")
        #expect(plain(LMKDateFormat.string(date, includeTime: true, context: context)) == "04/27/2026 9:41 AM")
        #expect(LMKDateFormat.string(date, includeTime: false, context: context) == "04/27/2026")
        #expect(LMKDateFormat.string(date, date: .medium, context: context) == "Apr 27, 2026", "explicit styles ignore the preference")
        #expect(date.lmk_string(context: context) == "04/27/2026")
        LMKDateFormat.preferredDatePattern = ""
        #expect(LMKDateFormat.string(date, context: context) == "Apr 27, 2026", "an empty pattern means the default")
    }

    @Test
    func `The default context is replaceable`() {
        let original = LMKDateFormat.Context.default
        defer { LMKDateFormat.Context.default = original }
        LMKDateFormat.Context.default = makeContext(hourCycle: .twentyFourHour)
        #expect(LMKDateFormat.Context.default.hourCycle == .twentyFourHour)
        #expect(LMKDateFormat.clockTime(makeDate(2026, 7, 27, 20)) == "20:00")
        #expect(LMKDateFormat.string(date) == "Apr 27, 2026")
    }

    @Test
    func `Strings override the ongoing form`() {
        let original = LMKDateFormat.strings
        defer { LMKDateFormat.strings = original }
        LMKDateFormat.strings = LMKDateFormat.Strings(ongoingRangeFormat: "since %@")
        #expect(LMKDateFormat.residenceLabel(start: makeDate(2021, 8, 1), end: nil, context: context) == "since Aug 2021")
    }
}
