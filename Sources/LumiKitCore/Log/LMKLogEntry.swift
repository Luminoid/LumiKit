//
//  LMKLogEntry.swift
//  LumiKit
//
//  Log levels and the entries `LMKLogStore` captures.
//

import Foundation
import os

// MARK: - Log Level

/// Log severity, ordered from `debug` (lowest) to `fault` (highest). The names follow `os.Logger`'s methods.
public enum LMKLogLevel: String, Sendable, CaseIterable, Comparable, Codable {
    /// Development detail. Never saved on device.
    case debug
    /// Helpful context. Kept in memory only, so usually missing from a sysdiagnose.
    case info
    /// A normal but significant event (configuration, lifecycle, an operation's outcome). Saved on device.
    case notice
    /// Something went wrong, but the operation recovered or degraded.
    case warning
    /// An operation failed.
    case error
    /// A bug: an invariant the code relies on is broken.
    case fault

    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.rank < rhs.rank
    }

    /// The unified-logging type this level is written at (`warning` matches `Logger.warning`).
    public var osLogType: OSLogType {
        switch self {
        case .debug: .debug
        case .info: .info
        case .notice: .default
        case .warning, .error: .error
        case .fault: .fault
        }
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

    /// The public text: the message as passed to the logger, plus an attached error's summary in brackets.
    public let message: String

    /// User data and an attached error's full description, written to the unified log as private
    /// (redacted in field logs); `nil` when the line carries none.
    public let privateDetail: String?

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
        privateDetail: String? = nil,
        file: String = "",
        function: String = "",
        line: Int = 0
    ) {
        self.timestamp = timestamp
        self.level = level
        self.category = category
        self.message = message
        self.privateDetail = privateDetail
        self.file = file
        self.function = function
        self.line = line
    }

    /// `[File.swift:12] function - message` (`[File.swift:12] message` when the function is
    /// unknown), or the message alone when the call site is unknown. The private detail is not included.
    public var formattedMessage: String {
        guard !file.isEmpty else { return message }
        guard !function.isEmpty else { return "[\(file):\(line)] \(message)" }
        return "[\(file):\(line)] \(function) - \(message)"
    }
}
