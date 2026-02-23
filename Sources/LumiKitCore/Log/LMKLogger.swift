//
//  LMKLogger.swift
//  LumiKit
//
//  Configurable logging system using os.log.
//  - Supports different log levels (debug, info, warning, error)
//  - Debug logs are automatically disabled in release builds
//  - Uses unified logging subsystem for better performance
//  - Subsystem is configurable via `configure(subsystem:)`
//  - Optional in-memory log store via `enableLogStore()`
//

import Foundation
import os.log

/// Configurable logging system for the Lumi ecosystem.
///
/// Configure once at app launch:
/// ```swift
/// LMKLogger.configure(subsystem: Bundle.main.bundleIdentifier ?? "com.example")
/// LMKLogger.enableLogStore() // optional: capture logs in memory
/// ```
public enum LMKLogger {
    // MARK: - Configuration

    /// The logging subsystem identifier. Defaults to the main bundle identifier.
    /// Call `configure(subsystem:)` to override.
    private nonisolated(unsafe) static var subsystem = Bundle.main.bundleIdentifier ?? "com.lumikit"

    /// Configure the logger subsystem. Call once at app launch.
    /// - Parameter subsystem: The subsystem identifier (typically `Bundle.main.bundleIdentifier`).
    public static func configure(subsystem: String) {
        Self.subsystem = subsystem
        LogCategory.rebuildLogs()
    }

    // MARK: - Log Store

    /// Optional in-memory log store. Populated when enabled via `enableLogStore()`.
    public private(set) nonisolated(unsafe) static var logStore: LMKLogStore?

    /// Enable in-memory log capture with a bounded ring buffer.
    /// - Parameter maxEntries: Maximum number of entries to retain (default 500).
    public static func enableLogStore(maxEntries: Int = 500) {
        logStore = LMKLogStore(maxEntries: maxEntries)
    }

    /// Disable and discard the in-memory log store.
    public static func disableLogStore() {
        logStore = nil
    }

    // MARK: - Log Categories

    /// Extensible log category backed by an `OSLog` instance.
    ///
    /// Built-in categories: `.general`, `.data`, `.ui`, `.network`, `.error`, `.localization`.
    /// Create custom categories via `LogCategory(name:)`.
    public final class LogCategory: Sendable {
        /// The category name (e.g. "General", "Data", "Network").
        public let name: String
        public let osLog: OSLog

        /// Create a custom log category.
        /// - Parameter name: The category name shown in Console.app.
        public init(name: String) {
            self.name = name
            self.osLog = OSLog(subsystem: LMKLogger.subsystem, category: name)
        }

        // Built-in categories.
        public nonisolated(unsafe) static var general = LogCategory(name: "General")
        public nonisolated(unsafe) static var data = LogCategory(name: "Data")
        public nonisolated(unsafe) static var ui = LogCategory(name: "UI")
        public nonisolated(unsafe) static var network = LogCategory(name: "Network")
        public nonisolated(unsafe) static var error = LogCategory(name: "Error")
        public nonisolated(unsafe) static var localization = LogCategory(name: "Localization")

        fileprivate static func rebuildLogs() {
            general = LogCategory(name: "General")
            data = LogCategory(name: "Data")
            ui = LogCategory(name: "UI")
            network = LogCategory(name: "Network")
            error = LogCategory(name: "Error")
            localization = LogCategory(name: "Localization")
        }
    }

    // MARK: - Formatting

    private static func formatLogMessage(_ message: String, file: String, function: String, line: Int) -> String {
        let fileName = (file as NSString).lastPathComponent
        return "[\(fileName):\(line)] \(function) - \(message)"
    }

    // MARK: - Log Levels

    /// Debug logs — only emitted in DEBUG builds.
    public static func debug(
        _ message: String,
        category: LogCategory = .general,
        file: String = #file,
        function: String = #function,
        line: Int = #line,
    ) {
        #if DEBUG
            let logMessage = formatLogMessage(message, file: file, function: function, line: line)
            os_log("%{public}@", log: category.osLog, type: .debug, logMessage)
            storeEntry(level: .debug, category: category.name, message: logMessage)
        #endif
    }

    /// Info logs — emitted in all builds.
    public static func info(
        _ message: String,
        category: LogCategory = .general,
        file: String = #file,
        function: String = #function,
        line: Int = #line,
    ) {
        let logMessage = formatLogMessage(message, file: file, function: function, line: line)
        os_log("%{public}@", log: category.osLog, type: .info, logMessage)
        storeEntry(level: .info, category: category.name, message: logMessage)
    }

    /// Error logs — always emitted, highest priority.
    public static func error(
        _ message: String,
        error: Error? = nil,
        category: LogCategory = .error,
        file: String = #file,
        function: String = #function,
        line: Int = #line,
    ) {
        var logMessage = formatLogMessage(message, file: file, function: function, line: line)
        if let error {
            logMessage += " | Error: \(error.localizedDescription)"
        }
        os_log("%{public}@", log: category.osLog, type: .error, logMessage)
        storeEntry(level: .error, category: category.name, message: logMessage)
    }

    /// Warning logs — emitted in all builds.
    public static func warning(
        _ message: String,
        category: LogCategory = .general,
        file: String = #file,
        function: String = #function,
        line: Int = #line,
    ) {
        let logMessage = formatLogMessage(message, file: file, function: function, line: line)
        os_log("%{public}@", log: category.osLog, type: .default, logMessage)
        storeEntry(level: .warning, category: category.name, message: logMessage)
    }

    // MARK: - Private Helpers

    private static func storeEntry(level: LMKLogLevel, category: String, message: String) {
        logStore?.append(LMKLogEntry(
            timestamp: Date(),
            level: level,
            category: category,
            message: message
        ))
    }
}
