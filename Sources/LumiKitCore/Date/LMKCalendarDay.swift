//
//  LMKCalendarDay.swift
//  LumiKit
//
//  Calendar-day and calendar-month identities: value types keyed by
//  year / month / day so a calendar grid, a selection, and a store can agree
//  on "which day" without comparing `Date`s at midnight. The numbers are
//  Gregorian civil dates whatever calendar the app runs in (see
//  `Calendar.lmk_civilCalendar`).
//

import Foundation

// MARK: - Civil calendar

public extension Calendar {
    /// The Gregorian calendar `LMKCalendarDay` and `LMKCalendarMonth` do their math in: this
    /// calendar's time zone, locale, first weekday, and minimum days in the first week on a
    /// Gregorian (`gregorian` and `iso8601` return themselves).
    ///
    /// A day or month stores no era and no leap-month flag, so its numbers are always Gregorian
    /// civil numbers: `key` is a true ISO key on a Thai or Japanese device, paging moves through
    /// the civil months in a lunisolar calendar, and a day round-trips through `date(in:)` under
    /// every calendar.
    var lmk_civilCalendar: Calendar {
        switch identifier {
        case .gregorian, .iso8601:
            return self
        default:
            var twin = Calendar(identifier: .gregorian)
            twin.timeZone = timeZone
            twin.locale = locale
            twin.firstWeekday = firstWeekday
            twin.minimumDaysInFirstWeek = minimumDaysInFirstWeek
            return twin
        }
    }

    /// Whether this calendar's months are the Gregorian months (a different era or year numbering
    /// only): `gregorian`, `iso8601`, `japanese`, `buddhist`, and `republicOfChina`.
    var lmk_hasGregorianMonths: Bool {
        switch identifier {
        case .gregorian, .iso8601, .japanese, .buddhist, .republicOfChina: true
        default: false
        }
    }

    /// The calendar a civil day or month is formatted with: this calendar when its months are the
    /// Gregorian months (so a Japanese device reads "令和8年9月" over the same grid), otherwise
    /// `lmk_civilCalendar`, because a lunisolar month name over a Gregorian grid would mislabel it.
    var lmk_civilDisplayCalendar: Calendar {
        lmk_hasGregorianMonths ? self : lmk_civilCalendar
    }
}

// MARK: - Day

/// One Gregorian civil day (year, month, day), independent of time zone once created.
///
/// `key` is the stable `yyyy-MM-dd` form apps use as dictionary keys; `date(in:)` turns the
/// day back into a `Date` in a calendar. Comparison is chronological. Components are stored as
/// given; out-of-range values normalize through the calendar when converted, as `DateComponents`
/// do (month 13 of 2026 is January 2027).
///
/// The numbers are Gregorian whatever `calendar` is passed: every conversion runs through
/// `calendar.lmk_civilCalendar` (its time zone, locale, and first weekday on a Gregorian), so
/// a day built under the Japanese, Buddhist, Chinese, or Hebrew calendar has the same `key` and
/// round-trips through `date(in:)`. Format the `Date` with `calendar.lmk_civilDisplayCalendar`
/// to show it the way the user's calendar names it.
///
/// ```swift
/// let day = LMKCalendarDay(Date(), calendar: LMKDate.calendar)
/// events[day.key, default: []].append(event)
/// let nextWeek = day.adding(days: 7)
/// ```
public nonisolated struct LMKCalendarDay: Hashable, Comparable, Sendable, CustomStringConvertible {
    public let year: Int
    public let month: Int
    public let day: Int

    public init(year: Int, month: Int, day: Int) {
        self.year = year
        self.month = month
        self.day = day
    }

    /// The day `date` falls on in `calendar` (its time zone decides the day).
    public init(_ date: Date, calendar: Calendar = LMKDate.calendar) {
        let components = calendar.lmk_civilCalendar.dateComponents([.year, .month, .day], from: date)
        self.init(year: components.year ?? 1, month: components.month ?? 1, day: components.day ?? 1)
    }

    /// Parses a `yyyy-MM-dd` key; `nil` for anything else.
    public init?(key: String) {
        let parts = key.split(separator: "-", omittingEmptySubsequences: false)
        guard parts.count == 3, let year = Int(parts[0]), let month = Int(parts[1]), let day = Int(parts[2]) else { return nil }
        self.init(year: year, month: month, day: day)
    }

    /// Today in `calendar`.
    public static func today(calendar: Calendar = LMKDate.calendar) -> Self {
        Self(Date(), calendar: calendar)
    }

    /// The `yyyy-MM-dd` form (zero-padded, Gregorian).
    public var key: String {
        String(format: "%04d-%02d-%02d", year, month, day)
    }

    public var description: String { key }

    /// The month this day belongs to.
    public var calendarMonth: LMKCalendarMonth {
        LMKCalendarMonth(year: year, month: month)
    }

    /// Year, month, and day as Gregorian components (no calendar or time zone).
    public var components: DateComponents {
        DateComponents(year: year, month: month, day: day)
    }

    /// The moment `hour:minute` on this day in `calendar`; `nil` when the components do not exist there.
    public func date(in calendar: Calendar = LMKDate.calendar, hour: Int = 0, minute: Int = 0) -> Date? {
        date(inCivil: calendar.lmk_civilCalendar, hour: hour, minute: minute)
    }

    /// The start of this day in `calendar`; `nil` when the day does not exist there.
    public func startOfDay(in calendar: Calendar = LMKDate.calendar) -> Date? {
        let civil = calendar.lmk_civilCalendar
        return noon(inCivil: civil).map(civil.startOfDay(for:))
    }

    /// This day moved by `days` (negative moves back). A day the calendar cannot represent returns itself.
    public func adding(days: Int, calendar: Calendar = LMKDate.calendar) -> Self {
        let civil = calendar.lmk_civilCalendar
        guard days != 0, let date = noon(inCivil: civil), let moved = civil.date(byAdding: .day, value: days, to: date) else { return self }
        return Self(moved, calendar: civil)
    }

    /// Whole days from `self` to `other` (negative when `other` is earlier); `0` when either is invalid.
    ///
    /// Both ends are anchored at noon, so a daylight-saving change at midnight (Cairo, Santiago,
    /// Havana, Beirut) cannot shorten a day into a zero delta.
    public func days(to other: Self, calendar: Calendar = LMKDate.calendar) -> Int {
        let civil = calendar.lmk_civilCalendar
        guard let from = noon(inCivil: civil), let to = other.noon(inCivil: civil) else { return 0 }
        return civil.dateComponents([.day], from: from, to: to).day ?? 0
    }

    /// The weekday (1 = Sunday) in `calendar`; `nil` when invalid.
    public func weekday(in calendar: Calendar = LMKDate.calendar) -> Int? {
        let civil = calendar.lmk_civilCalendar
        return noon(inCivil: civil).map { civil.component(.weekday, from: $0) }
    }

    /// Whether the day falls on `calendar`'s weekend.
    public func isWeekend(in calendar: Calendar = LMKDate.calendar) -> Bool {
        let civil = calendar.lmk_civilCalendar
        return noon(inCivil: civil).map(civil.isDateInWeekend) ?? false
    }

    public static func < (lhs: Self, rhs: Self) -> Bool {
        (lhs.year, lhs.month, lhs.day) < (rhs.year, rhs.month, rhs.day)
    }

    // MARK: - Civil helpers

    /// `date(in:hour:minute:)` on a calendar that is already civil.
    func date(inCivil civil: Calendar, hour: Int = 0, minute: Int = 0) -> Date? {
        var components = components
        components.hour = hour
        components.minute = minute
        return civil.date(from: components)
    }

    /// Noon on this day: the anchor for day arithmetic, clear of a midnight daylight-saving gap.
    func noon(inCivil civil: Calendar) -> Date? {
        date(inCivil: civil, hour: 12)
    }
}

// MARK: - Month

/// One Gregorian civil month (year, month).
///
/// Answers the grid questions a month view asks: the days it contains, the padded weeks
/// (leading and trailing days of the neighbouring months included), and neighbours. Like
/// `LMKCalendarDay`, every conversion runs through `calendar.lmk_civilCalendar`, so a month is
/// the same value under every calendar; format its date with `calendar.lmk_civilDisplayCalendar`.
public nonisolated struct LMKCalendarMonth: Hashable, Comparable, Sendable, CustomStringConvertible {
    /// How many week rows a month grid shows.
    public enum WeekRowPolicy: Sendable, Hashable, CaseIterable {
        /// As many rows as the month needs (four to six).
        case fitMonth
        /// Always six rows, so every month has the same height.
        case alwaysSix
    }

    public let year: Int
    public let month: Int

    public init(year: Int, month: Int) {
        self.year = year
        self.month = month
    }

    /// The month `date` falls in, in `calendar`.
    public init(_ date: Date, calendar: Calendar = LMKDate.calendar) {
        let components = calendar.lmk_civilCalendar.dateComponents([.year, .month], from: date)
        self.init(year: components.year ?? 1, month: components.month ?? 1)
    }

    /// The month containing `day`.
    public init(containing day: LMKCalendarDay) {
        self.init(year: day.year, month: day.month)
    }

    /// Parses a `yyyy-MM` key; `nil` for anything else.
    public init?(key: String) {
        let parts = key.split(separator: "-", omittingEmptySubsequences: false)
        guard parts.count == 2, let year = Int(parts[0]), let month = Int(parts[1]) else { return nil }
        self.init(year: year, month: month)
    }

    /// The current month in `calendar`.
    public static func current(calendar: Calendar = LMKDate.calendar) -> Self {
        Self(Date(), calendar: calendar)
    }

    /// The `yyyy-MM` form (zero-padded, Gregorian).
    public var key: String {
        String(format: "%04d-%02d", year, month)
    }

    public var description: String { key }

    /// The first day of the month.
    public var firstDay: LMKCalendarDay {
        LMKCalendarDay(year: year, month: month, day: 1)
    }

    /// The first moment of the month in `calendar`; `nil` when the month does not exist there.
    public func date(in calendar: Calendar = LMKDate.calendar) -> Date? {
        firstDay.date(in: calendar)
    }

    /// Number of days in the month in `calendar` (`0` when invalid).
    public func numberOfDays(in calendar: Calendar = LMKDate.calendar) -> Int {
        numberOfDays(inCivil: calendar.lmk_civilCalendar)
    }

    /// The last day of the month in `calendar`.
    public func lastDay(in calendar: Calendar = LMKDate.calendar) -> LMKCalendarDay {
        LMKCalendarDay(year: year, month: month, day: max(1, numberOfDays(in: calendar)))
    }

    /// Every day of the month, in order.
    public func days(in calendar: Calendar = LMKDate.calendar) -> [LMKCalendarDay] {
        (1 ... max(1, numberOfDays(in: calendar))).map { LMKCalendarDay(year: year, month: month, day: $0) }
    }

    /// Whether `day` belongs to this month.
    public func contains(_ day: LMKCalendarDay) -> Bool {
        day.year == year && day.month == month
    }

    /// This month moved by `months` (negative moves back). A month the calendar cannot represent returns itself.
    public func adding(months: Int, calendar: Calendar = LMKDate.calendar) -> Self {
        let civil = calendar.lmk_civilCalendar
        guard months != 0, let date = firstDay.noon(inCivil: civil), let moved = civil.date(byAdding: .month, value: months, to: date) else { return self }
        return Self(moved, calendar: civil)
    }

    /// Whole months from `self` to `other` (negative when `other` is earlier); `0` when either is invalid.
    /// Both ends are anchored at noon of the first day, clear of a midnight daylight-saving gap.
    public func months(to other: Self, calendar: Calendar = LMKDate.calendar) -> Int {
        let civil = calendar.lmk_civilCalendar
        guard let from = firstDay.noon(inCivil: civil), let to = other.firstDay.noon(inCivil: civil) else { return 0 }
        return civil.dateComponents([.month], from: from, to: to).month ?? 0
    }

    /// The month's week rows, seven days each, starting on `calendar.firstWeekday`. Days before
    /// the first and after the last belong to the neighbouring months; `rows` pads to six.
    public func weeks(in calendar: Calendar = LMKDate.calendar, rows: WeekRowPolicy = .fitMonth) -> [[LMKCalendarDay]] {
        let civil = calendar.lmk_civilCalendar
        guard let firstDate = firstDay.noon(inCivil: civil) else { return [] }
        let weekday = civil.component(.weekday, from: firstDate)
        let weekdayCount = max(1, civil.maximumRange(of: .weekday)?.count ?? 7)
        let leading = (weekday - civil.firstWeekday + weekdayCount) % weekdayCount
        let dayCount = numberOfDays(inCivil: civil)
        var rowCount = Int((Double(leading + dayCount) / Double(weekdayCount)).rounded(.up))
        if rows == .alwaysSix {
            rowCount = max(rowCount, 6)
        }
        guard rowCount > 0, let gridStart = civil.date(byAdding: .day, value: -leading, to: firstDate) else { return [] }
        return (0 ..< rowCount).map { row in
            (0 ..< weekdayCount).map { column in
                let date = civil.date(byAdding: .day, value: row * weekdayCount + column, to: gridStart) ?? gridStart
                return LMKCalendarDay(date, calendar: civil)
            }
        }
    }

    public static func < (lhs: Self, rhs: Self) -> Bool {
        (lhs.year, lhs.month) < (rhs.year, rhs.month)
    }

    // MARK: - Civil helpers

    private func numberOfDays(inCivil civil: Calendar) -> Int {
        guard let date = firstDay.noon(inCivil: civil), let range = civil.range(of: .day, in: .month, for: date) else { return 0 }
        return range.count
    }
}

// MARK: - Date convenience

public extension Date {
    /// The calendar day this date falls on.
    func lmk_calendarDay(in calendar: Calendar = LMKDate.calendar) -> LMKCalendarDay {
        LMKCalendarDay(self, calendar: calendar)
    }

    /// The calendar month this date falls in.
    func lmk_calendarMonth(in calendar: Calendar = LMKDate.calendar) -> LMKCalendarMonth {
        LMKCalendarMonth(self, calendar: calendar)
    }
}
