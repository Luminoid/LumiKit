//
//  LMKDateFormat.swift
//  LumiKit
//
//  Locale-aware date and time strings: one place for the date styles apps
//  render, range and residence labels, relative days, clock times, and a
//  cached formatter for custom patterns.
//

import Foundation

/// Locale-aware date and time strings.
///
/// ```swift
/// LMKDateFormat.string(date)                                  // "Apr 27, 2026" (or the app's preferred pattern)
/// LMKDateFormat.string(date, date: .long, time: .short)       // "April 27, 2026 at 9:41 AM"
/// LMKDateFormat.rangeLabel(start: start, end: end)            // "Jun 6 – 8, 2026"
/// LMKDateFormat.relativeDayString(date)                       // "Tomorrow"
/// LMKDateFormat.clockTime(date, omitMidnight: true)           // "8:00 PM", nil at 00:00
/// ```
///
/// Every call takes a `Context` (locale, calendar, time zone, hour cycle); the process-wide
/// `Context.default` follows the device until an app replaces it (an in-app language or
/// time-format setting). Standard styles render through `Date.FormatStyle`; custom patterns
/// go through cached `DateFormatter`s.
public nonisolated enum LMKDateFormat {
    // MARK: - Styles

    /// The date half of a string.
    public enum DateStyle: Sendable, Hashable {
        /// No date component.
        case none
        /// `preferredDatePattern` when the app set one, otherwise `.medium`.
        case preferred
        /// Numeric: "4/27/26".
        case short
        /// Abbreviated: "Apr 27, 2026".
        case medium
        /// "April 27, 2026".
        case long
        /// "Monday, April 27, 2026".
        case full
        /// "Apr 27".
        case monthDay
        /// "April 2026".
        case monthYear
        /// "Apr 2026".
        case monthYearAbbreviated
        /// "Mon, Apr 27".
        case weekdayMonthDay
        /// "Mon, Apr 27, 2026".
        case weekdayMonthDayYear
        /// A `DateFormatter` pattern such as "MM/dd/yyyy" (not localized; for user-chosen formats).
        case custom(pattern: String)
    }

    /// The time half of a string.
    public enum TimeStyle: Sendable, Hashable {
        case none
        /// "9:41 AM" / "09:41".
        case short
        /// "9:41:30 AM".
        case medium
    }

    /// Which clock a string uses.
    public enum HourCycle: Sendable, Hashable {
        /// The locale's clock, including the device's 24-Hour Time setting.
        case system
        case twelveHour
        case twentyFourHour
    }

    /// Weekday symbol length for `weekdaySymbols(style:context:)`.
    public enum WeekdaySymbolStyle: Sendable, Hashable {
        /// "Monday".
        case wide
        /// "Mon".
        case abbreviated
        /// "M".
        case narrow
    }

    // MARK: - Context

    /// The locale, calendar, time zone, and clock a string is rendered with.
    public struct Context: Sendable, Equatable {
        public var locale: Locale
        public var calendar: Calendar
        public var timeZone: TimeZone
        public var hourCycle: HourCycle

        public init(
            locale: Locale = .autoupdatingCurrent,
            calendar: Calendar = .autoupdatingCurrent,
            timeZone: TimeZone = .autoupdatingCurrent,
            hourCycle: HourCycle = .system
        ) {
            self.locale = locale
            self.calendar = calendar
            self.timeZone = timeZone
            self.hourCycle = hourCycle
        }

        /// The process-wide context; replace it when the app's language, time zone, or time
        /// format setting changes.
        public static var `default`: Self {
            get { lock.withLock { _default } }
            set { lock.withLock { _default = newValue } }
        }

        /// A copy rendering in `timeZone` (an instant's own stored zone, so a Tokyo 09:00
        /// flight never displays as the viewer's wall clock).
        public func timeZone(_ timeZone: TimeZone) -> Self {
            var copy = self
            copy.timeZone = timeZone
            return copy
        }

        /// A copy with the given hour cycle.
        public func hourCycle(_ hourCycle: HourCycle) -> Self {
            var copy = self
            copy.hourCycle = hourCycle
            return copy
        }

        /// The locale with the hour cycle pinned, so a 12- or 24-hour choice wins over the
        /// device's 24-Hour Time preference.
        var effectiveLocale: Locale {
            switch hourCycle {
            case .system:
                return locale
            case .twelveHour, .twentyFourHour:
                var components = Locale.Components(locale: locale)
                components.hourCycle = hourCycle == .twelveHour ? .oneToTwelve : .zeroToTwentyThree
                return Locale(components: components)
            }
        }

        /// The calendar with the context's locale and time zone applied.
        var effectiveCalendar: Calendar {
            var calendar = self.calendar
            calendar.locale = effectiveLocale
            calendar.timeZone = timeZone
            return calendar
        }

        /// Whether the effective clock shows AM/PM.
        var usesTwelveHourClock: Bool {
            switch hourCycle {
            case .twelveHour: true
            case .twentyFourHour: false
            case .system: locale.hourCycle == .oneToTwelve || locale.hourCycle == .zeroToEleven
            }
        }
    }

    // MARK: - Strings

    public struct Strings: Sendable, Equatable {
        /// Format for an open-ended month range; `%@` is the start ("Aug 2021 – Now").
        public var ongoingRangeFormat: String

        public init(ongoingRangeFormat: String = LMKLocalized("dateFormat.ongoingRange")) {
            self.ongoingRangeFormat = ongoingRangeFormat
        }
    }

    /// Process-wide strings; set at app launch to override.
    public static var strings: Strings {
        get { lock.withLock { _strings } }
        set { lock.withLock { _strings = newValue } }
    }

    // MARK: - Preferred pattern

    /// A user-chosen `DateFormatter` pattern ("MM/dd/yyyy", "dd.MM.yyyy") that `.preferred` and
    /// the default `string(_:)` call render with. `nil` (the default) means `.medium`.
    public static var preferredDatePattern: String? {
        get { lock.withLock { _preferredDatePattern } }
        set { lock.withLock { _preferredDatePattern = newValue } }
    }

    private static let lock = NSLock()
    private nonisolated(unsafe) static var _default = Context()
    private nonisolated(unsafe) static var _strings = Strings()
    private nonisolated(unsafe) static var _preferredDatePattern: String?

    // MARK: - Strings from dates

    /// A date and/or time string.
    public static func string(_ value: Date, date: DateStyle = .preferred, time: TimeStyle = .none, context: Context = .default) -> String {
        let dateStyle = resolved(date)
        if case let .custom(pattern) = dateStyle {
            let dateText = formatter(pattern: pattern, context: context).string(from: value)
            guard time != .none else { return dateText }
            return "\(dateText) \(timeString(value, time: time, context: context))"
        }
        guard let style = formatStyle(date: dateStyle, time: time, context: context) else { return "" }
        return value.formatted(style)
    }

    /// The date in the preferred style, with the locale's short time appended when `includeTime`.
    public static func string(_ value: Date, includeTime: Bool, context: Context = .default) -> String {
        string(value, date: .preferred, time: includeTime ? .short : .none, context: context)
    }

    /// A range such as "Jun 6 – 8, 2026" (the locale's interval punctuation; a date range, not a
    /// parenthetical, so the en dash is expected).
    public static func intervalString(from start: Date, to end: Date, date: DateStyle = .medium, context: Context = .default) -> String {
        let dateStyle = resolved(date)
        let range = min(start, end) ..< max(start, end)
        switch dateStyle {
        case .none:
            return ""
        case let .custom(pattern):
            let interval = DateIntervalFormatter()
            interval.locale = context.effectiveLocale
            interval.calendar = context.effectiveCalendar
            interval.timeZone = context.timeZone
            interval.dateTemplate = pattern
            return interval.string(from: range.lowerBound, to: range.upperBound)
        default:
            return range.formatted(intervalStyle(date: dateStyle, context: context))
        }
    }

    /// A range label, or `nil` without a start. A start with no end, or an end on the same day,
    /// renders as a single date.
    public static func rangeLabel(start: Date?, end: Date?, date: DateStyle = .medium, context: Context = .default) -> String? {
        guard let start else { return nil }
        guard let end, !context.effectiveCalendar.isDate(start, inSameDayAs: end) else {
            return string(start, date: date, time: .none, context: context)
        }
        return intervalString(from: start, to: end, date: date, context: context)
    }

    /// A month-level span ("Sep 2014 – Aug 2021"); an open end renders the ongoing form
    /// ("Aug 2021 – Now"). `nil` without a start.
    public static func residenceLabel(start: Date?, end: Date?, context: Context = .default) -> String? {
        guard let start else { return nil }
        guard let end else {
            return String(format: strings.ongoingRangeFormat, string(start, date: .monthYearAbbreviated, context: context))
        }
        return intervalString(from: start, to: end, date: .monthYearAbbreviated, context: context)
    }

    /// "Today", "Tomorrow", or "Yesterday" for a date within a day of `reference` (day granularity
    /// in the context's calendar), otherwise the date in `fallback`.
    public static func relativeDayString(_ date: Date, relativeTo reference: Date = Date(), fallback: DateStyle = .medium, context: Context = .default) -> String {
        let calendar = context.effectiveCalendar
        let delta = calendar.dateComponents([.day], from: calendar.startOfDay(for: reference), to: calendar.startOfDay(for: date)).day ?? 0
        guard abs(delta) <= 1 else {
            return string(date, date: fallback, time: .none, context: context)
        }
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = context.effectiveLocale
        formatter.calendar = calendar
        formatter.dateTimeStyle = .named
        formatter.unitsStyle = .full
        formatter.formattingContext = .beginningOfSentence
        return formatter.localizedString(from: DateComponents(day: delta))
    }

    /// The clock time ("8:00 PM" / "20:00"), or `nil` when `omitMidnight` and the time is exactly
    /// 00:00 (day-granular records where "12:00 AM" would be noise).
    public static func clockTime(_ date: Date, omitMidnight: Bool = false, context: Context = .default) -> String? {
        if omitMidnight {
            let components = context.effectiveCalendar.dateComponents([.hour, .minute], from: date)
            if components.hour == 0, components.minute == 0 { return nil }
        }
        return timeString(date, time: .short, context: context)
    }

    /// The date plus the clock time ("Jul 27, 2026 · 8:00 PM"), or the date alone for a midnight
    /// timestamp.
    public static func dateWithClockTime(_ date: Date, date dateStyle: DateStyle = .medium, separator: String = " · ", context: Context = .default) -> String {
        let day = string(date, date: dateStyle, time: .none, context: context)
        guard let time = clockTime(date, omitMidnight: true, context: context) else { return day }
        return day + separator + time
    }

    /// Whether clock times show AM/PM in `context`.
    public static func usesTwelveHourClock(context: Context = .default) -> Bool {
        context.usesTwelveHourClock
    }

    /// The widest clock string the context can produce ("12:45 PM" / "23:45"), for sizing a time
    /// column to its content.
    public static func widestClockSample(context: Context = .default) -> String {
        let calendar = context.effectiveCalendar
        let hour = context.usesTwelveHourClock ? 12 : 23
        let sample = calendar.date(bySettingHour: hour, minute: 45, second: 0, of: Date()) ?? Date()
        return timeString(sample, time: .short, context: context)
    }

    /// "April 2026" or, abbreviated, "Apr 2026".
    public static func monthYearString(_ date: Date, abbreviated: Bool = false, context: Context = .default) -> String {
        string(date, date: abbreviated ? .monthYearAbbreviated : .monthYear, time: .none, context: context)
    }

    /// Standalone weekday names starting at the calendar's first weekday (Monday first in most of
    /// Europe, Sunday first in the US), for calendar headers.
    public static func weekdaySymbols(style: WeekdaySymbolStyle = .abbreviated, context: Context = .default) -> [String] {
        let calendar = context.effectiveCalendar
        let symbols: [String] = switch style {
        case .wide: calendar.standaloneWeekdaySymbols
        case .abbreviated: calendar.shortStandaloneWeekdaySymbols
        case .narrow: calendar.veryShortStandaloneWeekdaySymbols
        }
        guard !symbols.isEmpty else { return symbols }
        let offset = (calendar.firstWeekday - 1) % symbols.count
        return Array(symbols[offset...] + symbols[..<offset])
    }

    // MARK: - Formatters

    /// A `DateFormatter` for a fixed pattern in `context`, cached and never mutated after
    /// creation (safe to share across threads).
    public static func formatter(pattern: String, context: Context = .default) -> DateFormatter {
        cachedFormatter(key: "pattern|\(pattern)", context: context) { $0.dateFormat = pattern }
    }

    /// A `DateFormatter` for a localized template ("yMMMd", "EEE MMM d") in `context`, cached.
    public static func formatter(template: String, context: Context = .default) -> DateFormatter {
        cachedFormatter(key: "template|\(template)", context: context) { $0.setLocalizedDateFormatFromTemplate(template) }
    }

    /// Drops the formatter cache; call after a locale or language change (the process-wide
    /// `Context.default` setter does not, because a context is part of every cache key).
    public static func resetCache() {
        cache.removeAllObjects()
    }

    private nonisolated(unsafe) static let cache = NSCache<NSString, DateFormatter>()

    private static func cachedFormatter(key: String, context: Context, configure: (DateFormatter) -> Void) -> DateFormatter {
        let locale = context.effectiveLocale
        let cacheKey = "\(key)|\(locale.identifier)|\(context.calendar.identifier)|\(context.timeZone.identifier)" as NSString
        if let cached = cache.object(forKey: cacheKey) { return cached }
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.calendar = context.effectiveCalendar
        formatter.timeZone = context.timeZone
        configure(formatter)
        cache.setObject(formatter, forKey: cacheKey)
        return formatter
    }

    // MARK: - Helpers

    private static func resolved(_ style: DateStyle) -> DateStyle {
        guard case .preferred = style else { return style }
        if let pattern = preferredDatePattern, !pattern.isEmpty { return .custom(pattern: pattern) }
        return .medium
    }

    private static func timeString(_ date: Date, time: TimeStyle, context: Context) -> String {
        guard let style = formatStyle(date: .none, time: time, context: context) else { return "" }
        return date.formatted(style)
    }

    /// `nil` when neither half renders anything.
    private static func formatStyle(date: DateStyle, time: TimeStyle, context: Context) -> Date.FormatStyle? {
        let timeStyle: Date.FormatStyle.TimeStyle = switch time {
        case .none: .omitted
        case .short: .shortened
        case .medium: .standard
        }
        let base = Date.FormatStyle(date: .omitted, time: timeStyle, locale: context.effectiveLocale, calendar: context.effectiveCalendar, timeZone: context.timeZone)
        switch date {
        case .none:
            return time == .none ? nil : base
        case .short:
            return Date.FormatStyle(date: .numeric, time: timeStyle, locale: context.effectiveLocale, calendar: context.effectiveCalendar, timeZone: context.timeZone)
        case .medium, .preferred:
            return Date.FormatStyle(date: .abbreviated, time: timeStyle, locale: context.effectiveLocale, calendar: context.effectiveCalendar, timeZone: context.timeZone)
        case .long:
            return Date.FormatStyle(date: .long, time: timeStyle, locale: context.effectiveLocale, calendar: context.effectiveCalendar, timeZone: context.timeZone)
        case .full:
            return Date.FormatStyle(date: .complete, time: timeStyle, locale: context.effectiveLocale, calendar: context.effectiveCalendar, timeZone: context.timeZone)
        case .monthDay:
            return base.month(.abbreviated).day()
        case .monthYear:
            return base.month(.wide).year()
        case .monthYearAbbreviated:
            return base.month(.abbreviated).year()
        case .weekdayMonthDay:
            return base.weekday(.abbreviated).month(.abbreviated).day()
        case .weekdayMonthDayYear:
            return base.weekday(.abbreviated).month(.abbreviated).day().year()
        case .custom:
            return nil
        }
    }

    private static func intervalStyle(date: DateStyle, context: Context) -> Date.IntervalFormatStyle {
        let base = Date.IntervalFormatStyle(locale: context.effectiveLocale, calendar: context.effectiveCalendar, timeZone: context.timeZone)
        switch date {
        case .short:
            return Date.IntervalFormatStyle(date: .numeric, time: .omitted, locale: context.effectiveLocale, calendar: context.effectiveCalendar, timeZone: context.timeZone)
        case .long:
            return Date.IntervalFormatStyle(date: .long, time: .omitted, locale: context.effectiveLocale, calendar: context.effectiveCalendar, timeZone: context.timeZone)
        case .full:
            return Date.IntervalFormatStyle(date: .complete, time: .omitted, locale: context.effectiveLocale, calendar: context.effectiveCalendar, timeZone: context.timeZone)
        case .monthDay:
            return base.month(.abbreviated).day()
        case .monthYear:
            return base.month(.wide).year()
        case .monthYearAbbreviated:
            return base.month(.abbreviated).year()
        case .weekdayMonthDay:
            return base.weekday(.abbreviated).month(.abbreviated).day()
        case .weekdayMonthDayYear:
            return base.weekday(.abbreviated).month(.abbreviated).day().year()
        case .none, .preferred, .medium, .custom:
            return Date.IntervalFormatStyle(date: .abbreviated, time: .omitted, locale: context.effectiveLocale, calendar: context.effectiveCalendar, timeZone: context.timeZone)
        }
    }
}

// MARK: - Date conveniences

public extension Date {
    /// `LMKDateFormat.string(self, date:time:context:)`.
    func lmk_string(_ date: LMKDateFormat.DateStyle = .preferred, time: LMKDateFormat.TimeStyle = .none, context: LMKDateFormat.Context = .default) -> String {
        LMKDateFormat.string(self, date: date, time: time, context: context)
    }

    /// `LMKDateFormat.clockTime(self, omitMidnight:context:)`.
    func lmk_clockTime(omitMidnight: Bool = false, context: LMKDateFormat.Context = .default) -> String? {
        LMKDateFormat.clockTime(self, omitMidnight: omitMidnight, context: context)
    }

    /// `LMKDateFormat.relativeDayString(self, relativeTo:fallback:context:)`.
    func lmk_relativeDayString(relativeTo reference: Date = Date(), fallback: LMKDateFormat.DateStyle = .medium, context: LMKDateFormat.Context = .default) -> String {
        LMKDateFormat.relativeDayString(self, relativeTo: reference, fallback: fallback, context: context)
    }
}
