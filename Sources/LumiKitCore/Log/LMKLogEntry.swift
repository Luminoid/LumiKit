//
//  LMKLogEntry.swift
//  LumiKit
//
//  Log levels and the entries `LMKLogStore` captures.
//

import Foundation

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
