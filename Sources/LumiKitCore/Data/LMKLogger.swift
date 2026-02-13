//
//  LMKLogger.swift
//  LumiKit
//
//  Configurable logging system using os.log.
//  - Supports different log levels (debug, info, warning, error)
//  - Debug logs are automatically disabled in release builds
//  - Uses unified logging subsystem for better performance
//  - Subsystem is configurable via `configure(subsystem:)`
//

import Foundation
import os.log

/// Configurable logging system for the Lumi ecosystem.
///
/// Configure once at app launch:
/// ```swift
/// LMKLogger.configure(subsystem: Bundle.main.bundleIdentifier ?? "com.example")
/// ```
public enum LMKLogger {
    // MARK: - Configuration

    /// The logging subsystem identifier. Defaults to the main bundle identifier.
    /// Call `configure(subsystem:)` to override.
    nonisolated(unsafe) private static var subsystem = Bundle.main.bundleIdentifier ?? "com.lumikit"

    /// Configure the logger subsystem. Call once at app launch.
    /// - Parameter subsystem: The subsystem identifier (typically `Bundle.main.bundleIdentifier`).
    public static func configure(subsystem: String) {
        Self.subsystem = subsystem
        // Rebuild category logs with the new subsystem
        LogCategory.rebuildLogs(subsystem: subsystem)
    }

    // MARK: - Log Categories

    /// Extensible log category backed by an `OSLog` instance.
    ///
    /// Built-in categories: `.general`, `.data`, `.ui`, `.network`, `.error`, `.localization`.
    /// Create custom categories via `LogCategory(name:)`.
    public final class LogCategory: Sendable {
        public let osLog: OSLog

        /// Create a custom log category.
        /// - Parameter name: The category name shown in Console.app.
        public init(name: String) {
            self.osLog = OSLog(subsystem: LMKLogger.subsystem, category: name)
        }

        // Built-in categories
        nonisolated(unsafe) public static var general = LogCategory(name: "General")
        nonisolated(unsafe) public static var data = LogCategory(name: "Data")
        nonisolated(unsafe) public static var ui = LogCategory(name: "UI")
        nonisolated(unsafe) public static var network = LogCategory(name: "Network")
        nonisolated(unsafe) public static var error = LogCategory(name: "Error")
        nonisolated(unsafe) public static var localization = LogCategory(name: "Localization")

        fileprivate static func rebuildLogs(subsystem: String) {
            general = LogCategory(name: "General")
            data = LogCategory(name: "Data")
            ui = LogCategory(name: "UI")
            network = LogCategory(name: "Network")
            error = LogCategory(name: "Error")
            localization = LogCategory(name: "Localization")
        }
    }

    // MARK: - Log Levels

    /// Debug logs — only emitted in DEBUG builds.
    public static func debug(
        _ message: String,
        category: LogCategory = .general,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        #if DEBUG
            let fileName = (file as NSString).lastPathComponent
            let logMessage = "[\(fileName):\(line)] \(function) - \(message)"
            os_log("%{public}@", log: category.osLog, type: .debug, logMessage)
        #endif
    }

    /// Info logs — emitted in all builds.
    public static func info(
        _ message: String,
        category: LogCategory = .general,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        let fileName = (file as NSString).lastPathComponent
        let logMessage = "[\(fileName):\(line)] \(function) - \(message)"
        os_log("%{public}@", log: category.osLog, type: .info, logMessage)
    }

    /// Error logs — always emitted, highest priority.
    public static func error(
        _ message: String,
        error: Error? = nil,
        category: LogCategory = .error,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        let fileName = (file as NSString).lastPathComponent
        var logMessage = "[\(fileName):\(line)] \(function) - \(message)"
        if let error {
            logMessage += " | Error: \(error.localizedDescription)"
        }
        os_log("%{public}@", log: category.osLog, type: .error, logMessage)
    }

    /// Warning logs — emitted in all builds.
    public static func warning(
        _ message: String,
        category: LogCategory = .general,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        let fileName = (file as NSString).lastPathComponent
        let logMessage = "[\(fileName):\(line)] \(function) - \(message)"
        os_log("%{public}@", log: category.osLog, type: .default, logMessage)
    }
}
