//
//  LMKDateFormatterHelper.swift
//  LumiKit
//
//  Configurable date and number formatting helpers.
//

import Foundation

/// Configurable date and number formatting utilities.
///
/// Configure once at app launch:
/// ```swift
/// LMKDateFormatterHelper.configure(dateFormat: { "MM/dd/yyyy" })
/// ```
public enum LMKDateFormatterHelper {
    /// Closure that returns the current date format string.
    /// Override via `configure(dateFormat:)`. Defaults to `"MM/dd/yyyy"`.
    private nonisolated(unsafe) static var dateFormatProvider: () -> String = { "MM/dd/yyyy" }

    /// Configure the date format provider.
    /// - Parameter dateFormat: A closure that returns the current date format string.
    ///   Use a closure so it can dynamically read from UserDefaults or other settings.
    public static func configure(dateFormat: @escaping () -> String) {
        dateFormatProvider = dateFormat
    }

    /// Cached date-only formatter, invalidated when format changes.
    private nonisolated(unsafe) static var cachedDateFormatter: DateFormatter?
    /// Cached date+time formatter, invalidated when format changes.
    private nonisolated(unsafe) static var cachedDateTimeFormatter: DateFormatter?
    /// Format string that produced the cached formatters.
    private nonisolated(unsafe) static var cachedFormat: String?

    /// Get a date formatter with the configured date format and system locale.
    public static func dateFormatter(includeTime: Bool = false) -> DateFormatter {
        let format = dateFormatProvider()

        // Invalidate cache when format changes
        if format != cachedFormat {
            cachedDateFormatter = nil
            cachedDateTimeFormatter = nil
            cachedFormat = format
        }

        if includeTime {
            if let cached = cachedDateTimeFormatter { return cached }
            let formatter = DateFormatter()
            formatter.locale = Locale.current
            formatter.dateFormat = format + " HH:mm"
            cachedDateTimeFormatter = formatter
            return formatter
        } else {
            if let cached = cachedDateFormatter { return cached }
            let formatter = DateFormatter()
            formatter.locale = Locale.current
            formatter.dateFormat = format
            cachedDateFormatter = formatter
            return formatter
        }
    }

    /// Format a date using the configured date format and system locale.
    public static func formatDate(_ date: Date, includeTime: Bool = false) -> String {
        dateFormatter(includeTime: includeTime).string(from: date)
    }

    /// Cached number formatter.
    private static let cachedNumberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale.current
        return formatter
    }()

    /// Get a number formatter with system locale.
    public static func numberFormatter() -> NumberFormatter {
        cachedNumberFormatter
    }

    /// Format a number using system locale.
    public static func formatNumber(_ number: NSNumber) -> String {
        cachedNumberFormatter.string(from: number) ?? "\(number)"
    }
}
