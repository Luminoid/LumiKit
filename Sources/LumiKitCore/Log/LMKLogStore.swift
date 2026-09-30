//
//  LMKLogStore.swift
//  LumiKit
//
//  Log levels, captured entries, and the thread-safe in-memory ring buffer.
//  Opt-in via `LMKLogger.enableLogStore()`.
//

import Foundation
import Synchronization

// MARK: - Log Level

/// Log severity, ordered from `debug` (lowest) to `error` (highest).
public enum LMKLogLevel: String, Sendable, CaseIterable, Comparable, Codable {
    case debug
    case info
    case warning
    case error

    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.rank < rhs.rank
    }

    private var rank: Int {
        Self.allCases.firstIndex(of: self) ?? 0
    }
}

// MARK: - Log Entry

/// A single captured log entry.
public struct LMKLogEntry: Sendable, Hashable, Codable {
    /// When the log was recorded.
    public let timestamp: Date

    /// Severity level.
    public let level: LMKLogLevel

    /// Category name (e.g. "General", "Data", "Network").
    public let category: String

    /// The message as passed to the logger (an attached error's description is appended).
    public let message: String

    /// The calling file's last path component; empty when unknown.
    public let file: String

    /// The calling function; empty when unknown.
    public let function: String

    /// The calling line; `0` when unknown.
    public let line: Int

    public init(
        timestamp: Date = Date(),
        level: LMKLogLevel,
        category: String,
        message: String,
        file: String = "",
        function: String = "",
        line: Int = 0
    ) {
        self.timestamp = timestamp
        self.level = level
        self.category = category
        self.message = message
        self.file = file
        self.function = function
        self.line = line
    }

    /// `[File.swift:12] function - message`, or the message alone when the call site is unknown.
    public var formattedMessage: String {
        guard !file.isEmpty else { return message }
        return "[\(file):\(line)] \(function) - \(message)"
    }
}

// MARK: - Log Store

/// Thread-safe, bounded in-memory log store.
///
/// A FIFO ring buffer: once `maxEntries` are stored, each new entry overwrites the oldest.
/// Appends are O(1); `entries` returns a snapshot in insertion order.
///
/// ```swift
/// LMKLogger.enableLogStore(maxEntries: 500)
/// // ... app runs, logs accumulate ...
/// let entries = LMKLogger.logStore?.entries ?? []
/// ```
public final class LMKLogStore: Sendable {
    private struct Ring {
        var slots: [LMKLogEntry?]
        var head = 0
        var count = 0
    }

    // MARK: - Properties

    /// The capacity the store was created with.
    public let maxEntries: Int

    private let ring: Mutex<Ring>

    // MARK: - Initialization

    /// Create a log store with a maximum capacity.
    /// - Parameter maxEntries: Maximum number of entries to retain (must be positive). Oldest are evicted first.
    public init(maxEntries: Int) {
        precondition(maxEntries > 0, "LMKLogStore needs a positive capacity")
        self.maxEntries = maxEntries
        ring = Mutex(Ring(slots: Array(repeating: nil, count: maxEntries)))
    }

    // MARK: - Access

    /// A snapshot of all stored entries (oldest first).
    public var entries: [LMKLogEntry] {
        ring.withLock { ring in
            (0 ..< ring.count).compactMap { ring.slots[(ring.head + $0) % maxEntries] }
        }
    }

    /// Number of entries currently stored.
    public var count: Int {
        ring.withLock { $0.count }
    }

    /// Whether the store contains no entries.
    public var isEmpty: Bool {
        ring.withLock { $0.count } == 0
    }

    // MARK: - Mutation

    /// Append a log entry. Overwrites the oldest entry when at capacity.
    public func append(_ entry: LMKLogEntry) {
        ring.withLock { ring in
            if ring.count < maxEntries {
                ring.slots[(ring.head + ring.count) % maxEntries] = entry
                ring.count += 1
            } else {
                ring.slots[ring.head] = entry
                ring.head = (ring.head + 1) % maxEntries
            }
        }
    }

    /// Remove all stored entries.
    public func clear() {
        ring.withLock { ring in
            ring.slots = Array(repeating: nil, count: maxEntries)
            ring.head = 0
            ring.count = 0
        }
    }

    // MARK: - Formatting

    /// Format all entries as a single string for display.
    ///
    /// Each line: `[HH:mm:ss.SSS] [LEVEL] [Category] [File.swift:12] function - message`
    public func formatted() -> String {
        let entries = entries
        guard !entries.isEmpty else { return "(no logs captured)" }

        // Local formatter each call — DateFormatter is not thread-safe
        // and LMKLogStore is Sendable (shared across threads).
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"

        return entries.map { entry in
            let time = formatter.string(from: entry.timestamp)
            let level = entry.level.rawValue.uppercased()
            return "[\(time)] [\(level)] [\(entry.category)] \(entry.formattedMessage)"
        }.joined(separator: "\n")
    }
}
