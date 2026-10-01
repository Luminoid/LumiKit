//
//  LMKLogger.swift
//  LumiKit
//
//  Configurable logging on os.log.
//  - Four levels (debug, info, warning, error); debug is compiled out of release builds
//  - Runtime threshold (`minimumLevel`) and kill switch (`isEnabled`)
//  - Configurable subsystem, message privacy, in-memory log store, and an entry handler
//  - `LMKLogging` gives the same API as an injectable instance
//

import Foundation
import os.log
import Synchronization

// MARK: - LMKLogging

/// The logger API as an instance, for hosts that inject a logger rather than call `LMKLogger` statics.
///
/// `LMKLogger.default` forwards to the static logger; a test double can capture calls instead.
public protocol LMKLogging: Sendable {
    func log(
        _ level: LMKLogLevel,
        _ message: String,
        error: (any Error)?,
        category: LMKLogger.LogCategory,
        file: String,
        function: String,
        line: Int
    )
}

public extension LMKLogging {
    func debug(_ message: String, category: LMKLogger.LogCategory = .general, file: String = #file, function: String = #function, line: Int = #line) {
        log(.debug, message, error: nil, category: category, file: file, function: function, line: line)
    }

    func info(_ message: String, category: LMKLogger.LogCategory = .general, file: String = #file, function: String = #function, line: Int = #line) {
        log(.info, message, error: nil, category: category, file: file, function: function, line: line)
    }

    func warning(_ message: String, category: LMKLogger.LogCategory = .general, file: String = #file, function: String = #function, line: Int = #line) {
        log(.warning, message, error: nil, category: category, file: file, function: function, line: line)
    }

    func error(_ message: String, error: (any Error)? = nil, category: LMKLogger.LogCategory = .error, file: String = #file, function: String = #function, line: Int = #line) {
        log(.error, message, error: error, category: category, file: file, function: function, line: line)
    }
}

// MARK: - LMKLogger

/// Configurable logging system for the Lumi ecosystem.
///
/// Configure once at app launch:
/// ```swift
/// LMKLogger.configure(subsystem: Bundle.main.bundleIdentifier ?? "com.example")
/// LMKLogger.minimumLevel = .info        // optional: drop debug output at runtime
/// LMKLogger.enableLogStore()            // optional: capture logs in memory
/// LMKLogger.entryHandler = { entry in } // optional: forward entries (crash breadcrumbs, analytics)
/// ```
/// Every setting is safe to read and write from any thread.
public enum LMKLogger {
    // MARK: - Types

    /// How message text is marked for the unified logging system.
    public enum Privacy: Sendable, Hashable {
        /// Messages are readable in Console and `log show` (the default).
        case `public`
        /// Messages are redacted in Console unless the device is configured to show private data.
        case `private`
    }

    private struct Configuration {
        var subsystem: String
        var minimumLevel: LMKLogLevel = .debug
        var isEnabled = true
        var messagePrivacy: Privacy = .public
        var entryHandler: (@Sendable (LMKLogEntry) -> Void)?
        var logStore: LMKLogStore?
        var logs: [String: OSLog] = [:]
    }

    private struct Emission {
        let log: OSLog
        let privacy: Privacy
        let store: LMKLogStore?
        let handler: (@Sendable (LMKLogEntry) -> Void)?
    }

    private struct StaticLogging: LMKLogging {
        func log(_ level: LMKLogLevel, _ message: String, error: (any Error)?, category: LogCategory, file: String, function: String, line: Int) {
            LMKLogger.log(level, message, error: error, category: category, file: file, function: function, line: line)
        }
    }

    private static let configuration = Mutex(Configuration(subsystem: Bundle.main.bundleIdentifier ?? "com.lumikit"))

    // MARK: - Configuration

    /// The logging subsystem identifier. Defaults to the main bundle identifier.
    public static var subsystem: String {
        configuration.withLock { $0.subsystem }
    }

    /// Configure the logger subsystem. Call once at app launch.
    /// - Parameter subsystem: The subsystem identifier (typically `Bundle.main.bundleIdentifier`).
    public static func configure(subsystem: String) {
        configuration.withLock {
            $0.subsystem = subsystem
            $0.logs.removeAll()
        }
    }

    /// Entries below this level are dropped before they reach os.log, the store, or the handler. Default `.debug`.
    public static var minimumLevel: LMKLogLevel {
        get { configuration.withLock { $0.minimumLevel } }
        set { configuration.withLock { $0.minimumLevel = newValue } }
    }

    /// `false` silences every level. Default `true`.
    public static var isEnabled: Bool {
        get { configuration.withLock { $0.isEnabled } }
        set { configuration.withLock { $0.isEnabled = newValue } }
    }

    /// Privacy marker for message text in the unified logging system. Default `.public`.
    public static var messagePrivacy: Privacy {
        get { configuration.withLock { $0.messagePrivacy } }
        set { configuration.withLock { $0.messagePrivacy = newValue } }
    }

    /// Receives every emitted entry after level filtering, on the logging thread.
    public static var entryHandler: (@Sendable (LMKLogEntry) -> Void)? {
        get { configuration.withLock { $0.entryHandler } }
        set { configuration.withLock { $0.entryHandler = newValue } }
    }

    /// The logger as an `LMKLogging` instance, for injection.
    public static let `default`: any LMKLogging = StaticLogging()

    // MARK: - Log Store

    /// Optional in-memory log store. Populated when enabled via `enableLogStore()`.
    public static var logStore: LMKLogStore? {
        configuration.withLock { $0.logStore }
    }

    /// Enable in-memory log capture with a bounded ring buffer.
    /// - Parameter maxEntries: Maximum number of entries to retain (default 500; values below 1 keep one).
    public static func enableLogStore(maxEntries: Int = 500) {
        let store = LMKLogStore(maxEntries: maxEntries)
        configuration.withLock { $0.logStore = store }
    }

    /// Disable and discard the in-memory log store.
    public static func disableLogStore() {
        configuration.withLock { $0.logStore = nil }
    }

    // MARK: - Log Categories

    /// Extensible log category shown in Console.
    ///
    /// Built-in categories: `.general`, `.data`, `.ui`, `.network`, `.error`, `.localization`.
    /// Create custom categories via `LogCategory(name:)`.
    public final class LogCategory: Sendable {
        /// The category name (e.g. "General", "Data", "Network").
        public let name: String

        /// The `OSLog` for this category under the current subsystem.
        public var osLog: OSLog {
            LMKLogger.osLog(for: name)
        }

        /// Create a custom log category.
        /// - Parameter name: The category name shown in Console.app.
        public init(name: String) {
            self.name = name
        }

        // Built-in categories.
        public static let general = LogCategory(name: "General")
        public static let data = LogCategory(name: "Data")
        public static let ui = LogCategory(name: "UI")
        public static let network = LogCategory(name: "Network")
        public static let error = LogCategory(name: "Error")
        public static let localization = LogCategory(name: "Localization")
    }

    private static func osLog(for name: String) -> OSLog {
        configuration.withLock { configuration in
            if let log = configuration.logs[name] { return log }
            let log = OSLog(subsystem: configuration.subsystem, category: name)
            configuration.logs[name] = log
            return log
        }
    }

    // MARK: - Log Levels

    /// Debug logs — only emitted in DEBUG builds. The message is built only when the entry is
    /// emitted, so an interpolation costs nothing when the level is filtered out.
    public static func debug(
        _ message: @autoclosure () -> String,
        category: LogCategory = .general,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        #if DEBUG
            log(.debug, message(), error: nil, category: category, file: file, function: function, line: line)
        #endif
    }

    /// Info logs — emitted in all builds.
    public static func info(
        _ message: @autoclosure () -> String,
        category: LogCategory = .general,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(.info, message(), error: nil, category: category, file: file, function: function, line: line)
    }

    /// Warning logs — emitted in all builds.
    public static func warning(
        _ message: @autoclosure () -> String,
        category: LogCategory = .general,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(.warning, message(), error: nil, category: category, file: file, function: function, line: line)
    }

    /// Error logs — always emitted, highest priority.
    public static func error(
        _ message: @autoclosure () -> String,
        error: (any Error)? = nil,
        category: LogCategory = .error,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(.error, message(), error: error, category: category, file: file, function: function, line: line)
    }

    /// The general entry point behind the level-specific functions. `message` is evaluated only
    /// after the level and kill-switch checks pass.
    public static func log(
        _ level: LMKLogLevel,
        _ message: @autoclosure () -> String,
        error: (any Error)? = nil,
        category: LogCategory = .general,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        #if !DEBUG
            if level == .debug { return }
        #endif
        let emission: Emission? = configuration.withLock { configuration in
            guard configuration.isEnabled, level >= configuration.minimumLevel else { return nil }
            let log: OSLog
            if let cached = configuration.logs[category.name] {
                log = cached
            } else {
                log = OSLog(subsystem: configuration.subsystem, category: category.name)
                configuration.logs[category.name] = log
            }
            return Emission(log: log, privacy: configuration.messagePrivacy, store: configuration.logStore, handler: configuration.entryHandler)
        }
        guard let emission else { return }

        var text = message()
        if let error {
            text += " | Error: \(error.localizedDescription)"
        }
        let entry = LMKLogEntry(
            level: level,
            category: category.name,
            message: text,
            file: (file as NSString).lastPathComponent,
            function: function,
            line: line
        )
        switch emission.privacy {
        case .public: os_log("%{public}@", log: emission.log, type: level.osLogType, entry.formattedMessage)
        case .private: os_log("%{private}@", log: emission.log, type: level.osLogType, entry.formattedMessage)
        }
        emission.store?.append(entry)
        emission.handler?(entry)
    }
}

private extension LMKLogLevel {
    var osLogType: OSLogType {
        switch self {
        case .debug: .debug
        case .info: .info
        case .warning: .default
        case .error: .error
        }
    }
}
