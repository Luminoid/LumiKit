//
//  LMKLogStore.swift
//  LumiKit
//
//  The thread-safe in-memory ring buffer of captured log entries.
//  Opt-in via `LMKLogger.enableLogStore()`.
//

import Foundation
import Synchronization

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
    /// - Parameter maxEntries: Maximum number of entries to retain (values below 1 keep one). Oldest are evicted first.
    public init(maxEntries: Int) {
        let capacity = max(1, maxEntries)
        self.maxEntries = capacity
        ring = Mutex(Ring(slots: Array(repeating: nil, count: capacity)))
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
    /// Each line: `[HH:mm:ss.SSS] [LEVEL] [Category] [File.swift:12] function - message | private detail`.
    /// The store is on-device debug output, so the private detail is included when the entry has one.
    public func formatted() -> String {
        let entries = entries
        guard !entries.isEmpty else { return "(no logs captured)" }

        // Local formatter each call — DateFormatter is not thread-safe
        // and LMKLogStore is Sendable (shared across threads). The POSIX locale keeps the
        // fixed pattern's digits and 24-hour clock whatever the device's own settings are.
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "HH:mm:ss.SSS"

        return entries.map { entry in
            let time = formatter.string(from: entry.timestamp)
            let level = entry.level.rawValue.uppercased()
            let detail = entry.privateDetail.map { " | \($0)" } ?? ""
            return "[\(time)] [\(level)] [\(entry.category)] \(entry.formattedMessage)\(detail)"
        }.joined(separator: "\n")
    }
}
