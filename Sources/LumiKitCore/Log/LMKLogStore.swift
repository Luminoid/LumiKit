//
//  LMKLogStore.swift
//  LumiKit
//
//  Thread-safe in-memory ring buffer for log entries.
//  Opt-in via `LMKLogger.enableLogStore()`.
//

import Foundation
import os

// MARK: - Log Level

/// Log severity level.
public enum LMKLogLevel: String, Sendable, CaseIterable {
    case debug
    case info
    case warning
    case error
}

// MARK: - Log Entry

/// A single captured log entry.
public struct LMKLogEntry: Sendable {
    /// When the log was recorded.
    public let timestamp: Date

    /// Severity level.
    public let level: LMKLogLevel

    /// Category name (e.g. "General", "Data", "Network").
    public let category: String

    /// The formatted log message (includes file, line, function).
    public let message: String
}

// MARK: - Log Store

/// Thread-safe, bounded in-memory log store.
///
/// Uses a FIFO ring buffer — when `maxEntries` is reached, the oldest
/// entry is evicted. All access is serialized via `OSAllocatedUnfairLock`.
///
/// ```swift
/// LMKLogger.enableLogStore(maxEntries: 500)
/// // ... app runs, logs accumulate ...
/// let entries = LMKLogger.logStore?.entries ?? []
/// ```
public final class LMKLogStore: Sendable {
    // MARK: - Properties

    private let maxEntries: Int
    private let lock: OSAllocatedUnfairLock<[LMKLogEntry]>

    // MARK: - Initialization

    /// Create a log store with a maximum capacity.
    /// - Parameter maxEntries: Maximum number of entries to retain. Oldest are evicted first.
    public init(maxEntries: Int) {
        self.maxEntries = maxEntries
        self.lock = OSAllocatedUnfairLock(initialState: [])
    }

    // MARK: - Access

    /// A snapshot of all stored entries (oldest first).
    public var entries: [LMKLogEntry] {
        lock.withLock { $0 }
    }

    /// Number of entries currently stored.
    public var count: Int {
        lock.withLock { $0.count }
    }

    // MARK: - Mutation

    /// Append a log entry. Evicts the oldest entry if at capacity.
    public func append(_ entry: LMKLogEntry) {
        lock.withLock { entries in
            if entries.count >= maxEntries {
                entries.removeFirst()
            }
            entries.append(entry)
        }
    }

    /// Remove all stored entries.
    public func clear() {
        lock.withLock { $0.removeAll() }
    }

    // MARK: - Formatting

    private static let displayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()

    /// Format all entries as a single string for display.
    ///
    /// Each line: `[HH:mm:ss.SSS] [LEVEL] [Category] message`
    public func formatted() -> String {
        let entries = self.entries
        guard !entries.isEmpty else { return "(no logs captured)" }

        let formatter = Self.displayFormatter

        return entries.map { entry in
            let time = formatter.string(from: entry.timestamp)
            let level = entry.level.rawValue.uppercased()
            return "[\(time)] [\(level)] [\(entry.category)] \(entry.message)"
        }.joined(separator: "\n")
    }
}
