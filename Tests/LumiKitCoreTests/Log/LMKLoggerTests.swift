//
//  LMKLoggerTests.swift
//  LumiKit
//
//  LMKLogger follows the logging contract the Luminoid packages share: the same six levels and
//  unified-logging mapping, a threshold clamped at error, public messages with a private detail,
//  and the same `describe` format for errors. These tests pin it so LMKLogger cannot drift.
//

import Foundation
import os
import Synchronization
import Testing
@testable import LumiKitCore

private enum SampleError: Error {
    case timeout
    case failed(String)
    case wrapped(any Error)
    case labeled(underlying: any Error)
    case pair(String, underlying: any Error)
}

// MARK: - LMKLogger (stateless)

/// Nothing here writes a log line: the configuration suite below captures by handler while
/// these run in parallel.
struct LMKLoggerTests {
    @Test
    func `Built-in categories carry distinct Console names`() {
        let categories = [LMKLogger.LogCategory.general, .data, .ui, .network, .error, .localization, .lumiKit]
        #expect(categories.map(\.name) == ["General", "Data", "UI", "Network", "Error", "Localization", "LumiKit"])
        #expect(Set(categories.map(\.name)).count == categories.count)
        #expect(LMKLogger.LogCategory.general === LMKLogger.LogCategory.general, "built-in categories are shared instances")
    }

    @Test
    func `Privacy and log levels are hashable`() {
        #expect(Set([LMKLogger.Privacy.public, .private, .public]).count == 2)
        #expect(Set(LMKLogLevel.allCases).count == 6)
    }

    @Test
    func `Custom category creation`() {
        let category = LMKLogger.LogCategory(name: "CustomTest")
        #expect(category.name == "CustomTest")
    }

    @Test
    func `Levels are ordered and map to unified-logging types like os.Logger's methods`() {
        #expect(LMKLogLevel.allCases == [.debug, .info, .notice, .warning, .error, .fault])
        #expect(LMKLogLevel.allCases.sorted() == LMKLogLevel.allCases)
        #expect(LMKLogLevel.debug.osLogType == .debug)
        #expect(LMKLogLevel.info.osLogType == .info)
        #expect(LMKLogLevel.notice.osLogType == .default)
        #expect(LMKLogLevel.warning.osLogType == .error)
        #expect(LMKLogLevel.error.osLogType == .error)
        #expect(LMKLogLevel.fault.osLogType == .fault)
    }

    @Test
    func `describe summarizes an NSError by domain and code, with the underlying error's`() {
        let underlying = NSError(domain: NSPOSIXErrorDomain, code: 60)
        let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorTimedOut, userInfo: [NSUnderlyingErrorKey: underlying])
        let described = LMKLogger.describe(error)
        #expect(described.summary == "NSURLErrorDomain -1001 <- NSPOSIXErrorDomain 60")
        #expect(described.detail?.contains("NSURLErrorDomain") == true)
    }

    @Test
    func `describe summarizes Swift enum errors as type and case, keeping payloads private`() {
        let failed = LMKLogger.describe(SampleError.failed("user text"))
        #expect(failed.summary.hasSuffix("SampleError.failed"))
        #expect(!failed.summary.contains("user text"))
        #expect(failed.detail?.contains("user text") == true)

        let timeout = LMKLogger.describe(SampleError.timeout)
        #expect(timeout.summary.hasSuffix("SampleError.timeout"))
        #expect(timeout.detail == nil)

        let wrapped = LMKLogger.describe(SampleError.wrapped(URLError(.timedOut)))
        #expect(wrapped.summary.hasSuffix("SampleError.wrapped <- NSURLErrorDomain -1001"))

        let labeled = LMKLogger.describe(SampleError.labeled(underlying: URLError(.timedOut)))
        #expect(labeled.summary.hasSuffix("SampleError.labeled <- NSURLErrorDomain -1001"))

        let pair = LMKLogger.describe(SampleError.pair("stage", underlying: URLError(.timedOut)))
        #expect(pair.summary.hasSuffix("SampleError.pair <- NSURLErrorDomain -1001"))
        #expect(!pair.summary.contains("stage"))
    }

    @Test
    func `Entries round-trip through Codable and compare by value`() throws {
        let entry = LMKLogEntry(
            timestamp: Date(timeIntervalSince1970: 1000),
            level: .notice,
            category: "Network",
            message: "timeout",
            privateDetail: "https://example.com/?token=secret",
            file: "A.swift",
            function: "load()",
            line: 12
        )
        let data = try JSONEncoder().encode(entry)
        let decoded = try JSONDecoder().decode(LMKLogEntry.self, from: data)
        #expect(decoded == entry)
        #expect(entry.formattedMessage == "[A.swift:12] load() - timeout", "the private detail stays out of the formatted message")
    }

    @Test
    func `Entries encoded before privateDetail existed still decode`() throws {
        let legacy = Data(#"{"timestamp":0,"level":"warning","category":"UI","message":"m","file":"","function":"","line":0}"#.utf8)
        let decoded = try JSONDecoder().decode(LMKLogEntry.self, from: legacy)
        #expect(decoded.level == .warning)
        #expect(decoded.privateDetail == nil)
    }

    @Test
    func `Entries without a call site format as the bare message`() {
        let entry = LMKLogEntry(level: .info, category: "General", message: "plain")
        #expect(entry.formattedMessage == "plain")
    }

    @Test
    func `Forwarded entries without a function format without the dash`() {
        let entry = LMKLogEntry(level: .notice, category: "Sophon/Core", message: "Request succeeded", file: "LLMRetryLoop.swift", line: 66)
        #expect(entry.formattedMessage == "[LLMRetryLoop.swift:66] Request succeeded")
    }
}

// MARK: - LMKLogger (process-wide configuration)

/// Every test here mutates the shared logger, so the suite runs serialized and restores the
/// configuration it changed. Captures keep only lines written from this file, since other
/// suites log concurrently.
@Suite(.serialized)
struct LMKLoggerConfigurationTests {
    private final class Capture: Sendable {
        private let entries = Mutex<[LMKLogEntry]>([])

        func record(_ entry: LMKLogEntry) {
            entries.withLock { $0.append(entry) }
        }

        var all: [LMKLogEntry] {
            entries.withLock { $0 }
        }

        /// The lines this file wrote.
        var local: [LMKLogEntry] {
            all.filter { $0.file == "LMKLoggerTests.swift" }
        }
    }

    private final class Spy: LMKLogging {
        let calls = Mutex<[(LMKLogLevel, String, String?)]>([])

        func log(_ level: LMKLogLevel, _ message: String, privateDetail: String?, error _: (any Error)?, category _: LMKLogger.LogCategory, file _: String, function _: String, line _: Int) {
            calls.withLock { $0.append((level, message, privateDetail)) }
        }
    }

    private static let category = LMKLogger.LogCategory(name: "LoggerContractTests")

    /// Runs `body` with a capturing handler (and `level` as the threshold when given), then
    /// restores the threshold, handler, and message privacy.
    private func withCapture(at level: LMKLogLevel? = nil, _ body: (Capture) -> Void) {
        let capture = Capture()
        let savedLevel = LMKLogger.minimumLevel
        let savedHandler = LMKLogger.entryHandler
        let savedPrivacy = LMKLogger.messagePrivacy
        if let level {
            LMKLogger.minimumLevel = level
        }
        LMKLogger.entryHandler = { capture.record($0) }
        defer {
            LMKLogger.entryHandler = savedHandler
            LMKLogger.minimumLevel = savedLevel
            LMKLogger.messagePrivacy = savedPrivacy
        }
        body(capture)
    }

    // MARK: - Threshold

    @Test
    func `The default threshold is debug in DEBUG builds, and debug lines are written without setup`() {
        #if DEBUG
            #expect(LMKLogger.defaultMinimumLevel == .debug)
        #else
            #expect(LMKLogger.defaultMinimumLevel == .info)
        #endif
        #expect(LMKLogger.minimumLevel == LMKLogger.defaultMinimumLevel)
        withCapture { capture in
            LMKLogger.debug("trace", category: Self.category)
            #expect(capture.local.map(\.level) == (LMKLogger.defaultMinimumLevel == .debug ? [.debug] : []))
        }
    }

    @Test
    func `The threshold clamps at error, so errors and faults always come through`() {
        withCapture(at: .fault) { capture in
            #expect(LMKLogger.minimumLevel == .error)
            LMKLogger.warning("dropped", category: Self.category)
            LMKLogger.error("kept", category: Self.category)
            LMKLogger.fault("kept too", category: Self.category)
            #expect(capture.local.map(\.level) == [.error, .fault])
            #expect(capture.local.last?.category == "LoggerContractTests")
        }
    }

    @Test
    func `Minimum level drops lower levels`() {
        withCapture(at: .notice) { capture in
            LMKLogger.debug("dropped")
            LMKLogger.info("dropped too")
            LMKLogger.notice("kept")
            LMKLogger.warning("kept as well")
            LMKLogger.error("and this")
            #expect(capture.local.map(\.message) == ["kept", "kept as well", "and this"])
        }
    }

    @Test
    func `Filtered messages and details are never built`() {
        final class Counter: Sendable {
            let builds = Mutex(0)
            func text() -> String {
                builds.withLock { $0 += 1 }
                return "built"
            }
        }
        let counter = Counter()
        withCapture(at: .warning) { capture in
            LMKLogger.info(counter.text(), private: counter.text())
            LMKLogger.debug(counter.text())
            LMKLogger.log(.notice, counter.text(), private: counter.text())
            #expect(counter.builds.withLock { $0 } == 0, "an interpolation below the threshold costs nothing")

            LMKLogger.warning(counter.text(), private: counter.text())
            #expect(counter.builds.withLock { $0 } == 2)
            #expect(capture.local.map(\.message) == ["built"])
        }
    }

    // MARK: - Entries

    @Test
    func `Configure subsystem is reflected and keeps logging`() {
        let previous = LMKLogger.subsystem
        defer { LMKLogger.configure(subsystem: previous) }
        LMKLogger.configure(subsystem: "com.test.lumikit")
        #expect(LMKLogger.subsystem == "com.test.lumikit")
        #expect(LMKLogger.LogCategory.general.osLog === LMKLogger.LogCategory.general.osLog)
        // The log call and its check stay outside the `#expect`s above: inside one closure, an
        // `#expect` on a string comparison followed by one on `===` made the next autoclosure
        // return the earlier string literal (Xcode 27 toolchain, test code only).
        var messages: [String] = []
        withCapture { capture in
            LMKLogger.error("after configure", category: Self.category)
            messages = capture.local.map(\.message)
        }
        #expect(messages == ["after configure"])
    }

    @Test
    func `Entry handler receives the call site and category`() {
        withCapture { capture in
            LMKLogger.warning("careful", category: .network)
            let entry = capture.local.last
            #expect(entry?.level == .warning)
            #expect(entry?.category == "Network")
            #expect(entry?.message == "careful")
            #expect(entry?.privateDetail == nil)
            #expect(entry?.file == "LMKLoggerTests.swift")
            #expect(entry?.function.contains("Entry handler receives") == true)
            #expect(entry?.line ?? 0 > 0)
        }
    }

    @Test
    func `A private detail stays out of the public message`() {
        withCapture { capture in
            LMKLogger.notice("Fetched page", private: "https://example.com/?token=secret", category: Self.category)
            let entry = capture.local.last
            #expect(entry?.message == "Fetched page")
            #expect(entry?.privateDetail == "https://example.com/?token=secret")
            #expect(entry?.formattedMessage.contains("token") == false)
        }
    }

    @Test
    func `An attached error adds its summary to the message and its description to the private detail`() {
        let underlying = NSError(domain: NSPOSIXErrorDomain, code: 60)
        let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorTimedOut, userInfo: [NSUnderlyingErrorKey: underlying])
        withCapture { capture in
            LMKLogger.error("Request failed", error: error)
            let entry = capture.local.last
            #expect(entry?.message == "Request failed [NSURLErrorDomain -1001 <- NSPOSIXErrorDomain 60]")
            #expect(entry?.privateDetail?.contains("NSURLErrorDomain") == true)
            #expect(entry?.category == "Error")
        }
    }

    @Test
    func `A private detail and an error's description join in the private part`() {
        withCapture { capture in
            LMKLogger.warning("Upload failed", private: "/var/mobile/photo.jpg", error: SampleError.failed("user text"), category: Self.category)
            let entry = capture.local.last
            #expect(entry?.message.hasPrefix("Upload failed [") == true)
            #expect(entry?.message.hasSuffix("SampleError.failed]") == true)
            #expect(entry?.message.contains("user text") == false)
            #expect(entry?.privateDetail == "/var/mobile/photo.jpg | failed(\"user text\")")
        }
    }

    @Test
    func `Message privacy is stored and logging continues`() {
        withCapture { capture in
            LMKLogger.messagePrivacy = .private
            #expect(LMKLogger.messagePrivacy == .private)
            LMKLogger.info("private text", private: "detail")
            #expect(capture.local.last?.message == "private text")
        }
    }

    // MARK: - once

    @Test
    func `once writes a key a single time until it is reset`() {
        let key = "LMKLoggerTests.once.flood"
        defer { LMKLogger.resetOnce(key) }
        withCapture { capture in
            for _ in 0 ..< 3 {
                LMKLogger.once(key, .error, "Pool exhausted", category: Self.category)
            }
            LMKLogger.resetOnce(key)
            LMKLogger.once(key, .error, "Pool exhausted", category: Self.category)
            #expect(capture.local.count == 2)
        }
    }

    @Test
    func `once below the threshold does not use up its key`() {
        let key = "LMKLoggerTests.once.threshold"
        defer { LMKLogger.resetOnce(key) }
        withCapture(at: .error) { capture in
            LMKLogger.once(key, .warning, "filtered", category: Self.category)
            #expect(capture.local.isEmpty)
        }
        withCapture(at: .debug) { capture in
            LMKLogger.once(key, .warning, "written", category: Self.category)
            #expect(capture.local.map(\.message) == ["written"])
        }
    }

    // MARK: - record

    @Test
    func `record reaches the store and the handler without the threshold`() {
        LMKLogger.enableLogStore(maxEntries: 50)
        defer { LMKLogger.disableLogStore() }
        withCapture(at: .error) { capture in
            let forwarded = LMKLogEntry(level: .debug, category: "Session", message: "Configured 1920x1080", privateDetail: "detail", file: "PRMSession.swift", line: 7)
            LMKLogger.record(forwarded)
            #expect(capture.all.contains(forwarded), "a debug entry passes an error threshold: the source filtered it")
            #expect(LMKLogger.logStore?.entries.contains(forwarded) == true)
        }
    }

    // MARK: - LMKLogging

    @Test
    func `The default LMKLogging instance forwards to the static logger`() {
        withCapture { capture in
            let logger: any LMKLogging = LMKLogger.default
            logger.info("via instance", category: .data)
            logger.notice("via instance notice", private: "detail")
            logger.error("via instance error")
            logger.fault("via instance fault")
            #expect(capture.local.map(\.message) == ["via instance", "via instance notice", "via instance error", "via instance fault"])
            #expect(capture.local.map(\.level) == [.info, .notice, .error, .fault])
            #expect(capture.local.first?.category == "Data")
            #expect(capture.local.first?.file == "LMKLoggerTests.swift")
            #expect(capture.local.dropFirst().first?.privateDetail == "detail")
        }
    }

    @Test
    func `A custom LMKLogging receives the private detail`() {
        let spy = Spy()
        spy.warning("degraded", private: "user text")
        spy.debug("trace")
        let calls = spy.calls.withLock { $0 }
        #expect(calls.map(\.0) == [.warning, .debug])
        #expect(calls.map(\.1) == ["degraded", "trace"])
        #expect(calls.map(\.2) == ["user text", nil])
    }

    // MARK: - Log store

    @Test
    func `enableLogStore creates a store and clamps a capacity below one`() {
        LMKLogger.enableLogStore(maxEntries: 10)
        #expect(LMKLogger.logStore?.maxEntries == 10)
        LMKLogger.enableLogStore(maxEntries: 0)
        #expect(LMKLogger.logStore?.maxEntries == 1)
        LMKLogger.disableLogStore()
    }

    @Test
    func `disableLogStore removes the store`() {
        LMKLogger.enableLogStore()
        LMKLogger.disableLogStore()
        #expect(LMKLogger.logStore == nil)
    }

    @Test
    func `Log calls populate the store when enabled`() {
        LMKLogger.enableLogStore(maxEntries: 100)
        defer { LMKLogger.disableLogStore() }

        withCapture(at: .debug) { _ in
            LMKLogger.info("info msg", category: .data)
            LMKLogger.warning("warn msg", private: "kept on device", category: .network)
            LMKLogger.error("err msg")
        }

        let entries = (LMKLogger.logStore?.entries ?? []).filter { $0.file == "LMKLoggerTests.swift" }
        #expect(entries.map(\.level) == [.info, .warning, .error])
        #expect(entries.contains { $0.message == "info msg" && $0.category == "Data" })
        #expect(entries.contains { $0.privateDetail == "kept on device" })
    }

    @Test
    func `Log calls do nothing when store is disabled`() {
        LMKLogger.disableLogStore()
        LMKLogger.info("should not crash")
        #expect(LMKLogger.logStore == nil)
    }
}
