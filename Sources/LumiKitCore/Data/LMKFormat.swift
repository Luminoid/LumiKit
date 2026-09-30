//
//  LMKFormat.swift
//  LumiKit
//
//  Locale-aware number strings: plain numbers, percentages, and progress.
//

import Foundation

/// Locale-aware number strings.
///
/// ```swift
/// LMKFormat.number(1234.5)          // "1,234.5"
/// LMKFormat.number(42)              // "42"
/// LMKFormat.percent(0.756)          // "76%"
/// LMKFormat.progressPercent(0.75)   // "75%"
/// ```
public nonisolated enum LMKFormat {
    /// A decimal `NumberFormatter` in `locale` (grouping separators, up to two fraction digits).
    /// Creates a new instance each call; cache it yourself for hot paths.
    public static func numberFormatter(locale: Locale = .autoupdatingCurrent) -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        return formatter
    }

    /// `value` through `numberFormatter(locale:)`.
    public static func number(_ value: NSNumber, locale: Locale = .autoupdatingCurrent) -> String {
        numberFormatter(locale: locale).string(from: value) ?? "\(value)"
    }

    /// A localized decimal with `fractionDigits` fraction digits (default at most two).
    public static func number(_ value: Double, fractionDigits: ClosedRange<Int> = 0 ... 2, locale: Locale = .autoupdatingCurrent) -> String {
        value.formatted(.number.precision(.fractionLength(fractionDigits)).locale(locale))
    }

    /// A localized integer with grouping separators.
    public static func number(_ value: Int, locale: Locale = .autoupdatingCurrent) -> String {
        value.formatted(.number.locale(locale))
    }

    /// `fraction` (0.0 to 1.0) as a localized percentage; `fractionDigits` fraction digits (default none).
    public static func percent(_ fraction: Double, fractionDigits: ClosedRange<Int> = 0 ... 0, locale: Locale = .autoupdatingCurrent) -> String {
        fraction.formatted(.percent.precision(.fractionLength(fractionDigits)).locale(locale))
    }

    /// A progress value (0.0 to 1.0, clamped) as a whole-number percentage ("75%").
    public static func progressPercent(_ progress: Float, locale: Locale = .autoupdatingCurrent) -> String {
        let clamped = max(0, min(1, progress))
        return percent(Double(clamped), locale: locale)
    }
}
