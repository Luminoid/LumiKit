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
/// `calendar` follows the system time zone from its first read; every accessor is safe from
/// any thread.
public enum LMKDate {
    /// A calendar snapshot that is replaced whenever the system time zone changes.
    ///
    /// The observer registers in `init`, so the calendar tracks the zone for as long as the
    /// instance lives; selector observers unregister themselves on deallocation.
    final class FollowingCalendar: NSObject, Sendable {
        private let store: Mutex<Calendar>
        private let makeCalendar: @Sendable () -> Calendar

        /// - Parameters:
        ///   - center: The center that posts `NSSystemTimeZoneDidChange`.
        ///   - makeCalendar: Builds the snapshot; the default is the current calendar in the current zone.
        init(center: NotificationCenter = .default, makeCalendar: @escaping @Sendable () -> Calendar = FollowingCalendar.currentCalendar) {
            self.makeCalendar = makeCalendar
            store = Mutex(makeCalendar())
            super.init()
            center.addObserver(self, selector: #selector(timeZoneDidChange), name: .NSSystemTimeZoneDidChange, object: nil)
        }

        /// The current snapshot.
        var calendar: Calendar {
            store.withLock { $0 }
        }

        private static func currentCalendar() -> Calendar {
            var calendar = Calendar.current
            calendar.timeZone = TimeZone.current
            return calendar
        }

        @objc private func timeZoneDidChange() {
            let refreshed = makeCalendar()
            store.withLock { $0 = refreshed }
        }
    }

    /// Created on the first read of `calendar` (or on `initialize()`), and following the
    /// time zone from then on.
    private static let shared = FollowingCalendar()

    /// The shared calendar in the current time zone.
    public static var calendar: Calendar {
        shared.calendar
    }

    /// Starts following system time-zone changes now rather than on the first `calendar` read.
    /// Safe to call more than once; call it at app launch to have the observer in place early.
    public static func initialize() {
        _ = shared
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
