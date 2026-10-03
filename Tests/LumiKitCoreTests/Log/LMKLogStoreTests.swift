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
        #expect(store.maxEntries == 10)
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
        #expect(store.entries.map(\.message) == ["second", "third", "fourth"])
    }

    @Test
    func `Order survives several wrap-arounds`() {
        let store = LMKLogStore(maxEntries: 4)
        for i in 1 ... 11 {
            store.append(makeEntry(message: "m\(i)"))
        }
        #expect(store.entries.map(\.message) == ["m8", "m9", "m10", "m11"])
    }

    @Test
    func `Appending after clear starts a fresh sequence`() {
        let store = LMKLogStore(maxEntries: 3)
        for i in 1 ... 5 {
            store.append(makeEntry(message: "m\(i)"))
        }
        store.clear()
        store.append(makeEntry(message: "n1"))
        store.append(makeEntry(message: "n2"))
        #expect(store.entries.map(\.message) == ["n1", "n2"])
    }

    @Test
    func `A capacity below one keeps one entry`() {
        let store = LMKLogStore(maxEntries: -3)
        #expect(store.maxEntries == 1)
        store.append(makeEntry(message: "a"))
        store.append(makeEntry(message: "b"))
        #expect(store.entries.map(\.message) == ["b"])
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
    func `Formatted output contains level, category, and call site`() {
        let store = LMKLogStore(maxEntries: 10)
        store.append(LMKLogEntry(level: .warning, category: "Network", message: "timeout", file: "Fetch.swift", function: "load()", line: 7))

        let output = store.formatted()
        #expect(output.contains("[WARNING]"))
        #expect(output.contains("[Network]"))
        #expect(output.contains("[Fetch.swift:7] load() - timeout"))
    }

    @Test
    func `Formatted output appends the private detail, which is on-device debug output`() {
        let store = LMKLogStore(maxEntries: 10)
        store.append(LMKLogEntry(level: .error, category: "Network", message: "upload failed", privateDetail: "/tmp/a.jpg", file: "Up.swift", function: "send()", line: 3))
        store.append(LMKLogEntry(level: .info, category: "Network", message: "plain"))

        let lines = store.formatted().split(separator: "\n")
        #expect(lines.first?.hasSuffix("[Up.swift:3] send() - upload failed | /tmp/a.jpg") == true)
        #expect(lines.last?.hasSuffix("] plain") == true)
    }

    @Test
    func `Formatted output stamps a fixed 24-hour ASCII time`() throws {
        let store = LMKLogStore(maxEntries: 10)
        store.append(LMKLogEntry(timestamp: Date(timeIntervalSince1970: 0), level: .info, category: "General", message: "m"))

        let line = try #require(store.formatted().split(separator: "\n").first)

        let stamp = try #require(line.split(separator: "]").first?.dropFirst())
        #expect(stamp.count == 12, "HH:mm:ss.SSS")
        #expect(stamp.utf8.count == stamp.count, "digits stay ASCII whatever the user locale")
        #expect(stamp.hasSuffix(".000"))
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
        #expect(store.entries.count == 100)
    }

    // MARK: - Log Level

    @Test
    func `All log levels have expected raw values`() {
        #expect(LMKLogLevel.allCases.map(\.rawValue) == ["debug", "info", "notice", "warning", "error", "fault"])
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
