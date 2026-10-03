//
//  LMKLogger.swift
//  LumiKit
//
//  Configurable logging on os.Logger.
//  - Six levels (debug, info, notice, warning, error, fault) written at the unified-logging
//    types os.Logger's own methods use
//  - Runtime threshold (`minimumLevel`): debug in DEBUG builds, info otherwise, clamped at
//    error so errors and faults always come through
//  - Public message text, a private detail for user data, and errors split by `describe(_:)`
//  - Configurable subsystem, message privacy, in-memory log store, and an entry handler;
//    `record(_:)` forwards entries another package already wrote
//  - `LMKLogging` gives the same API as an injectable instance
//

import Foundation
import os
import Synchronization

// MARK: - LMKLogging

/// The logger API as an instance, for hosts that inject a logger rather than call `LMKLogger` statics.
///
/// `LMKLogger.default` forwards to the static logger; a test double can capture calls instead.
public protocol LMKLogging: Sendable {
    /// Writes one line. `message` is public text; `privateDetail` carries user data and is
    /// written as private; an attached `error` adds its summary to the message.
    func log(
        _ level: LMKLogLevel,
        _ message: String,
        privateDetail: String?,
        error: (any Error)?,
        category: LMKLogger.LogCategory,
        file: String,
        function: String,
        line: Int
    )
}

public extension LMKLogging {
    func debug(
        _ message: String,
        private detail: String? = nil,
        error: (any Error)? = nil,
        category: LMKLogger.LogCategory = .general,
        file: String = #fileID,
        function: String = #function,
        line: Int = #line
    ) {
        log(.debug, message, privateDetail: detail, error: error, category: category, file: file, function: function, line: line)
    }

    func info(
        _ message: String,
        private detail: String? = nil,
        error: (any Error)? = nil,
        category: LMKLogger.LogCategory = .general,
        file: String = #fileID,
        function: String = #function,
        line: Int = #line
    ) {
        log(.info, message, privateDetail: detail, error: error, category: category, file: file, function: function, line: line)
    }

    func notice(
        _ message: String,
        private detail: String? = nil,
        error: (any Error)? = nil,
        category: LMKLogger.LogCategory = .general,
        file: String = #fileID,
        function: String = #function,
        line: Int = #line
    ) {
        log(.notice, message, privateDetail: detail, error: error, category: category, file: file, function: function, line: line)
    }

    func warning(
        _ message: String,
        private detail: String? = nil,
        error: (any Error)? = nil,
        category: LMKLogger.LogCategory = .general,
        file: String = #fileID,
        function: String = #function,
        line: Int = #line
    ) {
        log(.warning, message, privateDetail: detail, error: error, category: category, file: file, function: function, line: line)
    }

    func error(
        _ message: String,
        private detail: String? = nil,
        error: (any Error)? = nil,
        category: LMKLogger.LogCategory = .error,
        file: String = #fileID,
        function: String = #function,
        line: Int = #line
    ) {
        log(.error, message, privateDetail: detail, error: error, category: category, file: file, function: function, line: line)
    }

    func fault(
        _ message: String,
        private detail: String? = nil,
        error: (any Error)? = nil,
        category: LMKLogger.LogCategory = .error,
        file: String = #fileID,
        function: String = #function,
        line: Int = #line
    ) {
        log(.fault, message, privateDetail: detail, error: error, category: category, file: file, function: function, line: line)
    }
}

// MARK: - LMKLogger

/// Configurable logging system for the Lumi ecosystem, on `os.Logger`.
///
/// Configure once at app launch:
/// ```swift
/// LMKLogger.configure(subsystem: Bundle.main.bundleIdentifier ?? "com.example")
/// LMKLogger.minimumLevel = .notice      // optional: write less at runtime
/// LMKLogger.enableLogStore()            // optional: capture logs in memory
/// LMKLogger.entryHandler = { entry in } // optional: forward entries (crash breadcrumbs, analytics)
/// ```
///
/// Message text is public: keep it to static text, codes, ids, counts, dimensions, and type
/// names. Pass user data (URLs, file paths, user content, text shown to the user) as `private:`,
/// and attach errors with `error:` rather than interpolating their description:
/// ```swift
/// LMKLogger.error("Upload failed", private: fileURL.path, error: error, category: .network)
/// ```
///
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

    #if DEBUG
        /// The threshold before an app sets one: everything in DEBUG builds.
        static let defaultMinimumLevel = LMKLogLevel.debug
    #else
        /// The threshold before an app sets one: info and above outside DEBUG builds.
        static let defaultMinimumLevel = LMKLogLevel.info
    #endif

    private struct Configuration {
        var subsystem: String
        var minimumLevel = LMKLogger.defaultMinimumLevel
        var messagePrivacy: Privacy = .public
        var entryHandler: (@Sendable (LMKLogEntry) -> Void)?
        var logStore: LMKLogStore?
        var loggers: [String: Logger] = [:]
        var osLogs: [String: OSLog] = [:]
        var onceKeys: Set<String> = []

        mutating func logger(for category: String) -> Logger {
            if let cached = loggers[category] { return cached }
            let logger = Logger(subsystem: subsystem, category: category)
            loggers[category] = logger
            return logger
        }
    }

    private struct Emission {
        let logger: Logger
        let privacy: Privacy
        let store: LMKLogStore?
        let handler: (@Sendable (LMKLogEntry) -> Void)?
    }

    private struct StaticLogging: LMKLogging {
        func log(_ level: LMKLogLevel, _ message: String, privateDetail: String?, error: (any Error)?, category: LogCategory, file: String, function: String, line: Int) {
            LMKLogger.log(level, message, private: privateDetail, error: error, category: category, file: file, function: function, line: line)
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
            $0.loggers.removeAll()
            $0.osLogs.removeAll()
        }
    }

    /// Entries below this level are dropped before they reach the unified log, the store, or the
    /// handler. Default `.debug` in DEBUG builds and `.info` otherwise. A value above `.error`
    /// clamps to `.error`, so errors and faults are always written.
    public static var minimumLevel: LMKLogLevel {
        get { configuration.withLock { $0.minimumLevel } }
        set { configuration.withLock { $0.minimumLevel = min(newValue, .error) } }
    }

    /// Privacy marker for the message text in the unified logging system. Default `.public`.
    /// The `[File.swift:12] function` prefix is always public and a private detail always private.
    public static var messagePrivacy: Privacy {
        get { configuration.withLock { $0.messagePrivacy } }
        set { configuration.withLock { $0.messagePrivacy = newValue } }
    }

    /// Receives every written entry after level filtering, and every entry passed to
    /// `record(_:)`, on the logging thread.
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
    /// Built-in categories: `.general`, `.data`, `.ui`, `.network`, `.error`, `.localization`, and
    /// `.lumiKit` (LumiKit's own lines). Create custom categories via `LogCategory(name:)`.
    public final class LogCategory: Sendable {
        /// The category name (e.g. "General", "Data", "Network").
        public let name: String

        /// The `OSLog` for this category under the current subsystem, for APIs that take one
        /// (signposts). `LMKLogger` itself writes through `os.Logger`.
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
        /// Lines LumiKit writes itself (alerts, sharing, photos, image encoding), under the app's
        /// subsystem: filter on it in Console, or find them in the log store and handler.
        public static let lumiKit = LogCategory(name: "LumiKit")
    }

    private static func osLog(for name: String) -> OSLog {
        configuration.withLock { configuration in
            if let log = configuration.osLogs[name] { return log }
            let log = OSLog(subsystem: configuration.subsystem, category: name)
            configuration.osLogs[name] = log
            return log
        }
    }

    // MARK: - Log Levels

    /// Development detail. Written only at a `.debug` threshold (the DEBUG-build default). The
    /// message and detail are built only when the entry is written, so an interpolation costs
    /// nothing when the level is filtered out.
    public static func debug(
        _ message: @autoclosure () -> String,
        private detail: @autoclosure () -> String? = nil,
        error: (any Error)? = nil,
        category: LogCategory = .general,
        file: String = #fileID,
        function: String = #function,
        line: Int = #line
    ) {
        log(.debug, message(), private: detail(), error: error, category: category, file: file, function: function, line: line)
    }

    /// Helpful context; kept in memory only by the unified logging system.
    public static func info(
        _ message: @autoclosure () -> String,
        private detail: @autoclosure () -> String? = nil,
        error: (any Error)? = nil,
        category: LogCategory = .general,
        file: String = #fileID,
        function: String = #function,
        line: Int = #line
    ) {
        log(.info, message(), private: detail(), error: error, category: category, file: file, function: function, line: line)
    }

    /// A normal but significant event (configuration, lifecycle, an operation's outcome); saved on device.
    public static func notice(
        _ message: @autoclosure () -> String,
        private detail: @autoclosure () -> String? = nil,
        error: (any Error)? = nil,
        category: LogCategory = .general,
        file: String = #fileID,
        function: String = #function,
        line: Int = #line
    ) {
        log(.notice, message(), private: detail(), error: error, category: category, file: file, function: function, line: line)
    }

    /// Something went wrong, but the operation recovered or degraded.
    public static func warning(
        _ message: @autoclosure () -> String,
        private detail: @autoclosure () -> String? = nil,
        error: (any Error)? = nil,
        category: LogCategory = .general,
        file: String = #fileID,
        function: String = #function,
        line: Int = #line
    ) {
        log(.warning, message(), private: detail(), error: error, category: category, file: file, function: function, line: line)
    }

    /// An operation failed. Always written.
    public static func error(
        _ message: @autoclosure () -> String,
        private detail: @autoclosure () -> String? = nil,
        error: (any Error)? = nil,
        category: LogCategory = .error,
        file: String = #fileID,
        function: String = #function,
        line: Int = #line
    ) {
        log(.error, message(), private: detail(), error: error, category: category, file: file, function: function, line: line)
    }

    /// A bug: an invariant the code relies on is broken. Always written.
    public static func fault(
        _ message: @autoclosure () -> String,
        private detail: @autoclosure () -> String? = nil,
        error: (any Error)? = nil,
        category: LogCategory = .error,
        file: String = #fileID,
        function: String = #function,
        line: Int = #line
    ) {
        log(.fault, message(), private: detail(), error: error, category: category, file: file, function: function, line: line)
    }

    /// The general entry point behind the level-specific functions. `message` and `detail` are
    /// evaluated only after the level check passes.
    ///
    /// The unified log receives `[File.swift:12] function - message | detail`: the prefix is
    /// public, the message follows `messagePrivacy`, and the detail is private. An attached
    /// error adds `[summary]` (see `describe(_:)`) to the message and its full description to
    /// the detail.
    public static func log(
        _ level: LMKLogLevel,
        _ message: @autoclosure () -> String,
        private detail: @autoclosure () -> String? = nil,
        error: (any Error)? = nil,
        category: LogCategory = .general,
        file: String = #fileID,
        function: String = #function,
        line: Int = #line
    ) {
        let emission: Emission? = configuration.withLock { configuration in
            guard level >= configuration.minimumLevel else { return nil }
            return Emission(
                logger: configuration.logger(for: category.name),
                privacy: configuration.messagePrivacy,
                store: configuration.logStore,
                handler: configuration.entryHandler
            )
        }
        guard let emission else { return }

        var publicText = message()
        var privateParts: [String] = []
        if let detail = detail() {
            privateParts.append(detail)
        }
        if let error {
            let described = describe(error)
            publicText += " [\(described.summary)]"
            if let errorDetail = described.detail {
                privateParts.append(errorDetail)
            }
        }
        let entry = LMKLogEntry(
            level: level,
            category: category.name,
            message: publicText,
            privateDetail: privateParts.isEmpty ? nil : privateParts.joined(separator: " | "),
            file: (file as NSString).lastPathComponent,
            function: function,
            line: line
        )
        write(entry, to: emission.logger, privacy: emission.privacy)
        emission.store?.append(entry)
        emission.handler?(entry)
    }

    /// Writes a line once per `key` until `resetOnce(_:)`, for failures on per-frame, polling,
    /// or per-call paths. A line below the threshold does not use up its key. Keys should come
    /// from a small fixed set; each is remembered until reset.
    public static func once(
        _ key: String,
        _ level: LMKLogLevel,
        _ message: @autoclosure () -> String,
        private detail: @autoclosure () -> String? = nil,
        error: (any Error)? = nil,
        category: LogCategory = .general,
        file: String = #fileID,
        function: String = #function,
        line: Int = #line
    ) {
        let isFirst = configuration.withLock { configuration in
            guard level >= configuration.minimumLevel else { return false }
            return configuration.onceKeys.insert(key).inserted
        }
        guard isFirst else { return }
        log(level, message(), private: detail(), error: error, category: category, file: file, function: function, line: line)
    }

    /// Re-arms a `once` key, typically when the failing state clears.
    public static func resetOnce(_ key: String) {
        configuration.withLock { _ = $0.onceKeys.remove(key) }
    }

    /// Adds an entry another logger already wrote to the unified log (a package's own logging
    /// core, forwarded from its handler) to the log store and the entry handler. Nothing is
    /// written to the unified log again and the threshold is not applied: the source filtered it.
    public static func record(_ entry: LMKLogEntry) {
        let (store, handler) = configuration.withLock { ($0.logStore, $0.entryHandler) }
        store?.append(entry)
        handler?(entry)
    }

    // MARK: - Errors

    /// Splits an error into a public summary and a private detail.
    ///
    /// - Swift enum errors summarize as `Module.Type.case`, plus the summary of an error payload.
    /// - Other errors summarize as NSError domain and code, plus the underlying error's domain and code.
    /// - The detail is the full `String(describing:)`, which may carry user data; `nil` when the summary already says it all.
    public static func describe(_ error: any Error) -> (summary: String, detail: String?) {
        let full = String(describing: error)
        let summary: String
        let mirror = Mirror(reflecting: error)
        if mirror.displayStyle == .enum {
            let payload = mirror.children.first
            var text = "\(String(reflecting: type(of: error))).\(payload?.label ?? full)"
            if let inner = payload.flatMap({ firstError(in: $0.value) }) {
                text += " <- \(describe(inner).summary)"
            }
            summary = text
        } else {
            let nsError = error as NSError
            var text = "\(nsError.domain) \(nsError.code)"
            if let underlying = nsError.userInfo[NSUnderlyingErrorKey] as? NSError {
                text += " <- \(underlying.domain) \(underlying.code)"
            }
            summary = text
        }
        return (summary, summary.hasSuffix(full) ? nil : full)
    }

    /// An enum payload's error: the payload itself, or the first error among its (possibly labeled) tuple elements.
    private static func firstError(in payload: Any) -> (any Error)? {
        if let error = payload as? any Error {
            return error
        }
        return Mirror(reflecting: payload).children.lazy.compactMap { $0.value as? any Error }.first
    }

    // MARK: - Writing

    private static func write(_ entry: LMKLogEntry, to logger: Logger, privacy: Privacy) {
        let prefix = entry.file.isEmpty ? "" : "[\(entry.file):\(entry.line)] \(entry.function) - "
        let type = entry.level.osLogType
        switch (privacy, entry.privateDetail) {
        case (.public, nil):
            logger.log(level: type, "\(prefix, privacy: .public)\(entry.message, privacy: .public)")
        case let (.public, detail?):
            logger.log(level: type, "\(prefix, privacy: .public)\(entry.message, privacy: .public) | \(detail, privacy: .private)")
        case (.private, nil):
            logger.log(level: type, "\(prefix, privacy: .public)\(entry.message, privacy: .private)")
        case let (.private, detail?):
            logger.log(level: type, "\(prefix, privacy: .public)\(entry.message, privacy: .private) | \(detail, privacy: .private)")
        }
    }
}
