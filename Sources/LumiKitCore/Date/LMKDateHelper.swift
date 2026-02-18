//
//  LMKDateHelper.swift
//  LumiKit
//
//  Optimized date helper utilities for efficient date calculations.
//

import Foundation

/// Helper for optimized date operations with caching.
public enum LMKDateHelper {
    /// Lock protecting all mutable cache state.
    private static let lock = NSLock()

    /// Shared calendar instance to avoid repeated `Calendar.current` calls.
    private nonisolated(unsafe) static var _calendar: Calendar = {
        var cal = Calendar.current
        cal.timeZone = TimeZone.current
        return cal
    }()

    public static var calendar: Calendar {
        lock.lock()
        defer { lock.unlock() }
        return _calendar
    }

    /// Set up timezone-change observer. Call once at app launch.
    public static func initialize() {
        NotificationCenter.default.addObserver(
            forName: .NSSystemTimeZoneDidChange,
            object: nil,
            queue: .main,
        ) { _ in
            lock.lock()
            var cal = Calendar.current
            cal.timeZone = TimeZone.current
            _calendar = cal
            lock.unlock()
        }
    }

    /// Start of today (computed from the shared calendar).
    public static var today: Date {
        lock.lock()
        let result = _calendar.startOfDay(for: Date())
        lock.unlock()
        return result
    }

    /// Start of day for a given date using the shared calendar.
    public static func startOfDay(for date: Date) -> Date {
        lock.lock()
        defer { lock.unlock() }
        return _calendar.startOfDay(for: date)
    }

    /// Check if a date is today.
    public static func isToday(_ date: Date) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return _calendar.isDateInToday(date)
    }

    /// Check if two dates are on the same day.
    public static func isSameDay(_ date1: Date, _ date2: Date) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return _calendar.isDate(date1, inSameDayAs: date2)
    }

    /// Validate date is within reasonable bounds.
    /// - Parameters:
    ///   - date: Date to validate.
    ///   - yearsInPast: Years to allow in the past (default: 100).
    ///   - yearsInFuture: Years to allow in the future (default: 10).
    /// - Returns: `true` if date is within bounds.
    public static func isValidDateRange(_ date: Date, yearsInPast: Int = 100, yearsInFuture: Int = 10) -> Bool {
        lock.lock()
        let cal = _calendar
        lock.unlock()
        let now = Date()
        guard let minDate = cal.date(byAdding: .year, value: -yearsInPast, to: now),
              let maxDate = cal.date(byAdding: .year, value: yearsInFuture, to: now) else {
            return false
        }
        return date >= minDate && date <= maxDate
    }
}

// MARK: - Date Convenience Extensions

public extension Date {
    /// Start of day using `LMKDateHelper`.
    var lmk_startOfDay: Date {
        LMKDateHelper.startOfDay(for: self)
    }

    /// Whether this date is today.
    var lmk_isToday: Bool {
        LMKDateHelper.isToday(self)
    }

    /// Whether this date is on the same day as another date.
    func lmk_isSameDay(as date: Date) -> Bool {
        LMKDateHelper.isSameDay(self, date)
    }
}
