//
//  LMKLogStoreTests.swift
//  LumiKit
//

import Foundation
import Testing
@testable import LumiKitCore

// MARK: - LMKLogStore

struct LMKLogStoreTests {
    // MARK: - Basic Operations

    @Test
    func `Append and retrieve entries`() {
        let store = LMKLogStore(maxEntries: 10)
        store.append(makeEntry(level: .info, message: "Hello"))
        store.append(makeEntry(level: .error, message: "Oops"))

        #expect(store.count == 2)
        #expect(store.entries.count == 2)
        #expect(store.entries[0].message == "Hello")
        #expect(store.entries[1].message == "Oops")
    }

    @Test
    func `Count reflects stored entries`() {
        let store = LMKLogStore(maxEntries: 10)
        #expect(store.isEmpty)

        store.append(makeEntry())
        #expect(store.count == 1)

        store.append(makeEntry())
        store.append(makeEntry())
        #expect(store.count == 3)
    }

    @Test
    func `Clear removes all entries`() {
        let store = LMKLogStore(maxEntries: 10)
        store.append(makeEntry())
        store.append(makeEntry())
        store.append(makeEntry())

        store.clear()
        #expect(store.isEmpty)
        #expect(store.entries.isEmpty)
    }

    // MARK: - Ring Buffer

    @Test
    func `FIFO eviction at max capacity`() {
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

    @Test
    func `Max entries of 1 keeps only the latest`() {
        let store = LMKLogStore(maxEntries: 1)
        store.append(makeEntry(message: "a"))
        store.append(makeEntry(message: "b"))
        store.append(makeEntry(message: "c"))

        #expect(store.count == 1)
        #expect(store.entries[0].message == "c")
    }

    // MARK: - Entries Snapshot

    @Test
    func `Entries returns a copy, not a reference`() {
        let store = LMKLogStore(maxEntries: 10)
        store.append(makeEntry(message: "before"))

        let snapshot = store.entries
        store.append(makeEntry(message: "after"))

        #expect(snapshot.count == 1)
        #expect(store.entries.count == 2)
    }

    // MARK: - Formatting

    @Test
    func `Formatted output contains level and category`() {
        let store = LMKLogStore(maxEntries: 10)
        store.append(makeEntry(level: .warning, category: "Network", message: "timeout"))

        let output = store.formatted()
        #expect(output.contains("[WARNING]"))
        #expect(output.contains("[Network]"))
        #expect(output.contains("timeout"))
    }

    @Test
    func `Formatted empty store returns placeholder`() {
        let store = LMKLogStore(maxEntries: 10)
        #expect(store.formatted() == "(no logs captured)")
    }

    // MARK: - Thread Safety

    @Test
    func `Concurrent appends do not crash`() async {
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

    @Test
    func `All log levels have expected raw values`() {
        #expect(LMKLogLevel.debug.rawValue == "debug")
        #expect(LMKLogLevel.info.rawValue == "info")
        #expect(LMKLogLevel.warning.rawValue == "warning")
        #expect(LMKLogLevel.error.rawValue == "error")
    }

    @Test
    func `Log level CaseIterable has 4 cases`() {
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

@Suite(.serialized)
struct LMKLoggerLogStoreIntegrationTests {
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
