//
//  LMKLoggerTests.swift
//  LumiKit
//

import Foundation
import Synchronization
import Testing
@testable import LumiKitCore

// MARK: - LMKLogger (stateless)

struct LMKLoggerTests {
    @Test
    func `Built-in categories exist`() {
        _ = LMKLogger.LogCategory.general
        _ = LMKLogger.LogCategory.data
        _ = LMKLogger.LogCategory.ui
        _ = LMKLogger.LogCategory.network
        _ = LMKLogger.LogCategory.error
        _ = LMKLogger.LogCategory.localization
    }

    @Test
    func `Custom category creation`() {
        let category = LMKLogger.LogCategory(name: "CustomTest")
        #expect(category.name == "CustomTest")
        LMKLogger.debug("Custom category test", category: category)
    }

    @Test
    func `Log levels compare in severity order`() {
        #expect(LMKLogLevel.debug < .info)
        #expect(LMKLogLevel.info < .warning)
        #expect(LMKLogLevel.warning < .error)
        #expect(LMKLogLevel.allCases == LMKLogLevel.allCases.sorted())
    }

    @Test
    func `Entries round-trip through Codable and compare by value`() throws {
        let entry = LMKLogEntry(timestamp: Date(timeIntervalSince1970: 1000), level: .warning, category: "Network", message: "timeout", file: "A.swift", function: "load()", line: 12)
        let data = try JSONEncoder().encode(entry)
        let decoded = try JSONDecoder().decode(LMKLogEntry.self, from: data)
        #expect(decoded == entry)
        #expect(entry.formattedMessage == "[A.swift:12] load() - timeout")
    }

    @Test
    func `Entries without a call site format as the bare message`() {
        let entry = LMKLogEntry(level: .info, category: "General", message: "plain")
        #expect(entry.formattedMessage == "plain")
    }
}

// MARK: - LMKLogger (process-wide configuration)

/// Every test here mutates the shared logger, so the suite runs serialized and restores the defaults.
@Suite(.serialized)
struct LMKLoggerConfigurationTests {
    private final class Capture: Sendable {
        let entries = Mutex<[LMKLogEntry]>([])
        var all: [LMKLogEntry] { entries.withLock { $0 } }
        func record(_ entry: LMKLogEntry) {
            entries.withLock { $0.append(entry) }
        }
    }

    private func withCapture(_ body: (Capture) -> Void) {
        let capture = Capture()
        LMKLogger.entryHandler = { capture.record($0) }
        defer {
            LMKLogger.entryHandler = nil
            LMKLogger.minimumLevel = .debug
            LMKLogger.isEnabled = true
            LMKLogger.messagePrivacy = .public
        }
        body(capture)
    }

    @Test
    func `Configure subsystem is reflected and keeps logging`() {
        let previous = LMKLogger.subsystem
        defer { LMKLogger.configure(subsystem: previous) }
        LMKLogger.configure(subsystem: "com.test.lumikit")
        #expect(LMKLogger.subsystem == "com.test.lumikit")
        #expect(LMKLogger.LogCategory.general.osLog === LMKLogger.LogCategory.general.osLog)
        LMKLogger.info("Test message after configure", category: .general)
    }

    @Test
    func `Entry handler receives the call site and category`() {
        withCapture { capture in
            LMKLogger.warning("careful", category: .network)
            let entry = capture.all.last
            #expect(entry?.level == .warning)
            #expect(entry?.category == "Network")
            #expect(entry?.message == "careful")
            #expect(entry?.file == "LMKLoggerTests.swift")
            #expect(entry?.line ?? 0 > 0)
        }
    }

    @Test
    func `Attached errors are appended to the message`() {
        struct Boom: LocalizedError { var errorDescription: String? { "boom" } }
        withCapture { capture in
            LMKLogger.error("failed", error: Boom())
            #expect(capture.all.last?.message == "failed | Error: boom")
            #expect(capture.all.last?.category == "Error")
        }
    }

    @Test
    func `Minimum level drops lower levels`() {
        withCapture { capture in
            LMKLogger.minimumLevel = .warning
            LMKLogger.info("dropped")
            LMKLogger.debug("dropped too")
            LMKLogger.warning("kept")
            LMKLogger.error("kept as well")
            #expect(capture.all.map(\.message) == ["kept", "kept as well"])
        }
    }

    @Test
    func `Disabled logger emits nothing`() {
        withCapture { capture in
            LMKLogger.isEnabled = false
            LMKLogger.error("silent")
            #expect(capture.all.isEmpty)
            LMKLogger.isEnabled = true
            LMKLogger.error("audible")
            #expect(capture.all.map(\.message) == ["audible"])
        }
    }

    @Test
    func `Message privacy is stored and logging continues`() {
        withCapture { capture in
            LMKLogger.messagePrivacy = .private
            #expect(LMKLogger.messagePrivacy == .private)
            LMKLogger.info("private text")
            #expect(capture.all.last?.message == "private text")
        }
    }

    @Test
    func `The default LMKLogging instance forwards to the static logger`() {
        withCapture { capture in
            let logger: any LMKLogging = LMKLogger.default
            logger.info("via instance", category: .data)
            logger.error("via instance error")
            #expect(capture.all.map(\.message) == ["via instance", "via instance error"])
            #expect(capture.all.first?.category == "Data")
            #expect(capture.all.first?.file == "LMKLoggerTests.swift")
        }
    }

    // MARK: - Log store

    @Test
    func `enableLogStore creates a store`() {
        LMKLogger.enableLogStore(maxEntries: 10)
        #expect(LMKLogger.logStore != nil)
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

        LMKLogger.info("info msg", category: .data)
        LMKLogger.warning("warn msg", category: .network)
        LMKLogger.error("err msg")

        let entries = LMKLogger.logStore?.entries ?? []
        #expect(entries.count >= 3)
        let levels = Set(entries.map(\.level))
        #expect(levels.contains(.info))
        #expect(levels.contains(.warning))
        #expect(levels.contains(.error))
        #expect(entries.contains { $0.message == "info msg" && $0.category == "Data" })
    }

    @Test
    func `Log calls do nothing when store is disabled`() {
        LMKLogger.disableLogStore()
        LMKLogger.info("should not crash")
        #expect(LMKLogger.logStore == nil)
    }

    @Test
    func `LogCategory exposes name property`() {
        #expect(LMKLogger.LogCategory.general.name == "General")
        #expect(LMKLogger.LogCategory.data.name == "Data")
        #expect(LMKLogger.LogCategory.network.name == "Network")

        let custom = LMKLogger.LogCategory(name: "Custom")
        #expect(custom.name == "Custom")
    }
}
