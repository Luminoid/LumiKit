//
//  LMKDateHelper.swift
//  LumiKit
//
//  Optimized date helper utilities for efficient date calculations.
//

import Foundation

/// Helper for optimized date operations with caching.
public enum LMKDateHelper {
    /// Shared calendar instance to avoid repeated `Calendar.current` calls.
    nonisolated(unsafe) public static var calendar: Calendar = {
        var cal = Calendar.current
        cal.timeZone = TimeZone.current
        return cal
    }()

    // MARK: - Cache

    nonisolated(unsafe) private static var _cachedToday: Date?
    nonisolated(unsafe) private static var _cachedTodayDay: Int?
    nonisolated(unsafe) private static var _cachedTimeZone: TimeZone?

    /// Set up timezone-change observer. Call once at app launch.
    public static func initialize() {
        NotificationCenter.default.addObserver(
            forName: .NSSystemTimeZoneDidChange,
            object: nil,
            queue: .main
        ) { _ in
            invalidateTodayCache()
            var cal = Calendar.current
            cal.timeZone = TimeZone.current
            calendar = cal
        }
        _cachedTimeZone = TimeZone.current
    }

    /// Invalidate the today cache (call when timezone or day changes).
    public static func invalidateTodayCache() {
        _cachedToday = nil
        _cachedTodayDay = nil
        _cachedTimeZone = TimeZone.current
    }

    /// Start of today, cached for performance.
    /// Handles edge cases: timezone changes, day changes, midnight boundary.
    public static var today: Date {
        let now = Date()
        let currentTimeZone = TimeZone.current
        let currentDay = calendar.component(.day, from: now)

        if let cachedTimeZone = _cachedTimeZone, cachedTimeZone != currentTimeZone {
            invalidateTodayCache()
        }

        if let cachedDay = _cachedTodayDay,
           let cached = _cachedToday,
           cachedDay == currentDay,
           _cachedTimeZone == currentTimeZone {
            if calendar.isDate(cached, inSameDayAs: now) {
                return cached
            }
        }

        let today = calendar.startOfDay(for: now)
        _cachedToday = today
        _cachedTodayDay = currentDay
        _cachedTimeZone = currentTimeZone
        return today
    }

    /// Start of day for a given date using the shared calendar.
    public static func startOfDay(for date: Date) -> Date {
        calendar.startOfDay(for: date)
    }

    /// Check if a date is today.
    public static func isToday(_ date: Date) -> Bool {
        calendar.isDateInToday(date)
    }

    /// Check if two dates are on the same day.
    public static func isSameDay(_ date1: Date, _ date2: Date) -> Bool {
        calendar.isDate(date1, inSameDayAs: date2)
    }

    /// Validate date is within reasonable bounds.
    /// - Parameters:
    ///   - date: Date to validate.
    ///   - yearsInPast: Years to allow in the past (default: 100).
    ///   - yearsInFuture: Years to allow in the future (default: 10).
    /// - Returns: `true` if date is within bounds.
    public static func isValidDateRange(_ date: Date, yearsInPast: Int = 100, yearsInFuture: Int = 10) -> Bool {
        let now = Date()
        guard let minDate = calendar.date(byAdding: .year, value: -yearsInPast, to: now),
              let maxDate = calendar.date(byAdding: .year, value: yearsInFuture, to: now) else {
            return false
        }
        return date >= minDate && date <= maxDate
    }
}

// MARK: - Date Convenience Extensions

extension Date {
    /// Start of day using `LMKDateHelper`.
    public var lmk_startOfDay: Date {
        LMKDateHelper.startOfDay(for: self)
    }

    /// Whether this date is today.
    public var lmk_isToday: Bool {
        LMKDateHelper.isToday(self)
    }

    /// Whether this date is on the same day as another date.
    public func lmk_isSameDay(as date: Date) -> Bool {
        LMKDateHelper.isSameDay(self, date)
    }
}
