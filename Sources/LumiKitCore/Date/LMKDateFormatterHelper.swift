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
    private static let lock = NSLock()

    /// Closure that returns the current date format string.
    /// Override via `configure(dateFormat:)`. Defaults to `"MM/dd/yyyy"`.
    private nonisolated(unsafe) static var dateFormatProvider: @Sendable () -> String = { "MM/dd/yyyy" }

    /// Configure the date format provider.
    /// - Parameter dateFormat: A closure that returns the current date format string.
    ///   Use a closure so it can dynamically read from UserDefaults or other settings.
    public static func configure(dateFormat: @escaping @Sendable () -> String) {
        lock.lock()
        defer { lock.unlock() }
        dateFormatProvider = dateFormat
    }

    /// Get a date formatter with the configured date format and system locale.
    ///
    /// Creates a new `DateFormatter` each call — `DateFormatter` is not thread-safe
    /// and cannot be safely cached across threads.
    public static func dateFormatter(includeTime: Bool = false) -> DateFormatter {
        let format: String = {
            lock.lock()
            defer { lock.unlock() }
            return dateFormatProvider()
        }()

        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = includeTime ? format + " HH:mm" : format
        return formatter
    }

    /// Format a date using the configured date format and system locale.
    public static func formatDate(_ date: Date, includeTime: Bool = false) -> String {
        dateFormatter(includeTime: includeTime).string(from: date)
    }

    /// Get a number formatter with system locale.
    public static func numberFormatter() -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.locale = Locale.current
        return formatter
    }

    /// Format a number using system locale.
    public static func formatNumber(_ number: NSNumber) -> String {
        numberFormatter().string(from: number) ?? "\(number)"
    }
}
