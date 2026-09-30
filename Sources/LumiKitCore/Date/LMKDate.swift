//
//  LMKDate.swift
//  LumiKit
//
//  The shared calendar (kept in step with the system time zone) and day math on it.
//

import Foundation
import Synchronization

/// The shared calendar and the day math built on it.
///
/// `calendar` follows the system time zone once `initialize()` has been called; every
/// accessor is safe from any thread.
public enum LMKDate {
    private static let store = Mutex(makeCalendar())

    private static func makeCalendar() -> Calendar {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current
        return calendar
    }

    /// Registered once, on the first `initialize()`; refreshes the calendar when the time zone changes.
    private nonisolated(unsafe) static let timeZoneObserver: any NSObjectProtocol = NotificationCenter.default.addObserver(
        forName: .NSSystemTimeZoneDidChange,
        object: nil,
        queue: nil
    ) { _ in
        store.withLock { $0 = makeCalendar() }
    }

    /// The shared calendar in the current time zone.
    public static var calendar: Calendar {
        store.withLock { $0 }
    }

    /// Starts following system time-zone changes. Safe to call more than once; call it at app launch.
    public static func initialize() {
        _ = timeZoneObserver
    }

    /// Start of today in the shared calendar.
    public static var today: Date {
        calendar.startOfDay(for: Date())
    }

    /// Start of day for a given date in the shared calendar.
    public static func startOfDay(for date: Date) -> Date {
        calendar.startOfDay(for: date)
    }

    /// Whether the date falls on today.
    public static func isToday(_ date: Date) -> Bool {
        calendar.isDateInToday(date)
    }

    /// Whether two dates fall on the same day.
    public static func isSameDay(_ date1: Date, _ date2: Date) -> Bool {
        calendar.isDate(date1, inSameDayAs: date2)
    }

    /// Whether the date lies inside a policy window around now.
    ///
    /// The defaults (a century back, a decade ahead) are a general-purpose sanity check for
    /// user-entered dates; pass the window your feature allows.
    /// - Parameters:
    ///   - date: Date to validate.
    ///   - yearsInPast: Years to allow in the past (default: 100).
    ///   - yearsInFuture: Years to allow in the future (default: 10).
    public static func isValidDateRange(_ date: Date, yearsInPast: Int = 100, yearsInFuture: Int = 10) -> Bool {
        let calendar = calendar
        let now = Date()
        guard let minDate = calendar.date(byAdding: .year, value: -yearsInPast, to: now),
              let maxDate = calendar.date(byAdding: .year, value: yearsInFuture, to: now) else {
            return false
        }
        return date >= minDate && date <= maxDate
    }
}

// MARK: - Date Convenience Extensions

public extension Date {
    /// Start of day using `LMKDate`.
    var lmk_startOfDay: Date {
        LMKDate.startOfDay(for: self)
    }

    /// Whether this date is today.
    var lmk_isToday: Bool {
        LMKDate.isToday(self)
    }

    /// Whether this date is on the same day as another date.
    func lmk_isSameDay(as date: Date) -> Bool {
        LMKDate.isSameDay(self, date)
    }
}
