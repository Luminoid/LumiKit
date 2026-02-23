//
//  LMKLogStoreTests.swift
//  LumiKit
//

import Foundation
import Testing

@testable import LumiKitCore

// MARK: - LMKLogStore

@Suite("LMKLogStore")
struct LMKLogStoreTests {
    // MARK: - Basic Operations

    @Test("Append and retrieve entries")
    func appendAndRetrieve() {
        let store = LMKLogStore(maxEntries: 10)
        store.append(makeEntry(level: .info, message: "Hello"))
        store.append(makeEntry(level: .error, message: "Oops"))

        #expect(store.count == 2)
        #expect(store.entries.count == 2)
        #expect(store.entries[0].message == "Hello")
        #expect(store.entries[1].message == "Oops")
    }

    @Test("Count reflects stored entries")
    func count() {
        let store = LMKLogStore(maxEntries: 10)
        #expect(store.count == 0)

        store.append(makeEntry())
        #expect(store.count == 1)

        store.append(makeEntry())
        store.append(makeEntry())
        #expect(store.count == 3)
    }

    @Test("Clear removes all entries")
    func clear() {
        let store = LMKLogStore(maxEntries: 10)
        store.append(makeEntry())
        store.append(makeEntry())
        store.append(makeEntry())

        store.clear()
        #expect(store.count == 0)
        #expect(store.entries.isEmpty)
    }

    // MARK: - Ring Buffer

    @Test("FIFO eviction at max capacity")
    func fifoEviction() {
        let store = LMKLogStore(maxEntries: 3)
        store.append(makeEntry(message: "first"))
        store.append(makeEntry(message: "second"))
        store.append(makeEntry(message: "third"))
        store.append(makeEntry(message: "fourth"))

        #expect(store.count == 3)
        #expect(store.entries[0].message == "second")
        #expect(store.entries[1].message == "third")
        #expect(store.entries[2].message == "fourth")
    }

    @Test("Max entries of 1 keeps only the latest")
    func maxEntriesOne() {
        let store = LMKLogStore(maxEntries: 1)
        store.append(makeEntry(message: "a"))
        store.append(makeEntry(message: "b"))
        store.append(makeEntry(message: "c"))

        #expect(store.count == 1)
        #expect(store.entries[0].message == "c")
    }

    // MARK: - Entries Snapshot

    @Test("Entries returns a copy, not a reference")
    func entriesReturnsCopy() {
        let store = LMKLogStore(maxEntries: 10)
        store.append(makeEntry(message: "before"))

        let snapshot = store.entries
        store.append(makeEntry(message: "after"))

        #expect(snapshot.count == 1)
        #expect(store.entries.count == 2)
    }

    // MARK: - Formatting

    @Test("Formatted output contains level and category")
    func formattedOutput() {
        let store = LMKLogStore(maxEntries: 10)
        store.append(makeEntry(level: .warning, category: "Network", message: "timeout"))

        let output = store.formatted()
        #expect(output.contains("[WARNING]"))
        #expect(output.contains("[Network]"))
        #expect(output.contains("timeout"))
    }

    @Test("Formatted empty store returns placeholder")
    func formattedEmpty() {
        let store = LMKLogStore(maxEntries: 10)
        #expect(store.formatted() == "(no logs captured)")
    }

    // MARK: - Thread Safety

    @Test("Concurrent appends do not crash")
    func concurrentAppends() async {
        let store = LMKLogStore(maxEntries: 100)

        await withTaskGroup(of: Void.self) { group in
            for i in 0 ..< 200 {
                group.addTask {
                    store.append(makeEntry(message: "msg-\(i)"))
                }
            }
        }

        // 200 appended, max 100 retained
        #expect(store.count == 100)
    }

    // MARK: - Log Level

    @Test("All log levels have expected raw values")
    func logLevelRawValues() {
        #expect(LMKLogLevel.debug.rawValue == "debug")
        #expect(LMKLogLevel.info.rawValue == "info")
        #expect(LMKLogLevel.warning.rawValue == "warning")
        #expect(LMKLogLevel.error.rawValue == "error")
    }

    @Test("Log level CaseIterable has 4 cases")
    func logLevelCaseIterable() {
        #expect(LMKLogLevel.allCases.count == 4)
    }

    // MARK: - Helpers

    private func makeEntry(
        level: LMKLogLevel = .info,
        category: String = "General",
        message: String = "test"
    ) -> LMKLogEntry {
        LMKLogEntry(timestamp: Date(), level: level, category: category, message: message)
    }
}

// MARK: - LMKLogger Log Store Integration

@Suite("LMKLogger Log Store Integration", .serialized)
struct LMKLoggerLogStoreIntegrationTests {
    @Test("enableLogStore creates a store")
    func enableCreatesStore() {
        LMKLogger.enableLogStore(maxEntries: 10)
        #expect(LMKLogger.logStore != nil)
        LMKLogger.disableLogStore()
    }

    @Test("disableLogStore removes the store")
    func disableRemovesStore() {
        LMKLogger.enableLogStore()
        LMKLogger.disableLogStore()
        #expect(LMKLogger.logStore == nil)
    }

    @Test("Log calls populate the store when enabled")
    func logCallsPopulateStore() {
        LMKLogger.enableLogStore(maxEntries: 100)

        LMKLogger.info("info msg", category: .data)
        LMKLogger.warning("warn msg", category: .network)
        LMKLogger.error("err msg")

        let store = LMKLogger.logStore
        #expect(store != nil)

        // At least 3 entries (debug may also be captured in DEBUG builds)
        let entries = store?.entries ?? []
        #expect(entries.count >= 3)

        // Verify levels are captured
        let levels = Set(entries.map(\.level))
        #expect(levels.contains(.info))
        #expect(levels.contains(.warning))
        #expect(levels.contains(.error))

        LMKLogger.disableLogStore()
    }

    @Test("Log calls do nothing when store is disabled")
    func logCallsWithoutStore() {
        LMKLogger.disableLogStore()
        LMKLogger.info("should not crash")
        #expect(LMKLogger.logStore == nil)
    }

    @Test("LogCategory exposes name property")
    func logCategoryName() {
        #expect(LMKLogger.LogCategory.general.name == "General")
        #expect(LMKLogger.LogCategory.data.name == "Data")
        #expect(LMKLogger.LogCategory.network.name == "Network")

        let custom = LMKLogger.LogCategory(name: "Custom")
        #expect(custom.name == "Custom")
    }
}
