//
//  LMKConcurrencyTests.swift
//  LumiKit
//

import Foundation
import Testing
@testable import LumiKitCore

// MARK: - LMKConcurrency

struct LMKConcurrencyTests {
    struct TestModel: Codable, Equatable {
        let name: String
        let count: Int
    }

    @Test
    func `Encode produces valid data`() throws {
        let model = TestModel(name: "test", count: 42)
        let data = try LMKConcurrency.encode(model)
        #expect(!data.isEmpty)
    }

    @Test
    func `Decode recovers original model`() throws {
        let model = TestModel(name: "lumikit", count: 7)
        let data = try LMKConcurrency.encode(model)
        let decoded = try LMKConcurrency.decode(TestModel.self, from: data)
        #expect(decoded == model)
    }

    @Test
    func `Decode throws for invalid data`() {
        let badData = Data("not json".utf8)
        #expect(throws: DecodingError.self) {
            try LMKConcurrency.decode(TestModel.self, from: badData)
        }
        #expect((try? LMKConcurrency.decode(TestModel.self, from: badData)) == nil)
    }

    @Test
    func `Encode/decode round-trip for arrays`() throws {
        let models = [TestModel(name: "a", count: 1), TestModel(name: "b", count: 2)]
        let data = try LMKConcurrency.encode(models)
        let decoded = try LMKConcurrency.decode([TestModel].self, from: data)
        #expect(decoded == models)
    }

    @Test
    func `Custom coders are honored`() throws {
        struct Dated: Codable, Equatable { let when: Date }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let value = Dated(when: Date(timeIntervalSince1970: 86400))

        let data = try LMKConcurrency.encode(value, encoder: encoder)
        #expect(String(bytes: data, encoding: .utf8)?.contains("1970-01-02T00:00:00Z") == true)
        #expect(try LMKConcurrency.decode(Dated.self, from: data, decoder: decoder) == value)
    }

    @Test
    func `onMainActorAfter can be cancelled before it fires`() async throws {
        final class Flag: @unchecked Sendable { var fired = false }
        let flag = Flag()
        let task = LMKConcurrency.onMainActorAfter(delay: 0.05) { flag.fired = true }
        task.cancel()
        try await Task.sleep(for: .milliseconds(120))
        #expect(!flag.fired)
    }

    @Test
    func `onMainActorAfter runs the work on the main actor`() async {
        final class Flag: @unchecked Sendable { var onMain = false }
        let flag = Flag()
        let task = LMKConcurrency.onMainActorAfter(delay: 0.01) { flag.onMain = Thread.isMainThread }
        await task.value
        #expect(flag.onMain)
    }

    @Test
    func `onMainActorAfter clamps delays it cannot sleep for`() async {
        final class Flag: @unchecked Sendable { var fired = false }
        let flag = Flag()
        for delay in [TimeInterval.infinity, .nan, -5] {
            let task = LMKConcurrency.onMainActorAfter(delay: delay) { flag.fired = true }
            if delay < 0 || delay.isNaN {
                await task.value
                #expect(flag.fired, "a negative or NaN delay runs the work at once")
                flag.fired = false
            } else {
                task.cancel()
                await task.value
                #expect(!flag.fired, "an infinite delay waits (a year) instead of trapping, and cancels")
            }
        }
        #expect(LMKConcurrency.maximumDelay == 365 * 24 * 60 * 60)
    }

    @Test
    @MainActor
    func `onMainActor runs with a live object and skips a released one`() async {
        final class Owner: Sendable {}
        final class Flag: @unchecked Sendable { var runs = 0 }
        let flag = Flag()
        let owner = Owner()
        await LMKConcurrency.onMainActor(weak: owner) { _ in flag.runs += 1 }.value
        #expect(flag.runs == 1)

        var released: Owner? = Owner()
        let task = LMKConcurrency.onMainActor(weak: released ?? owner) { _ in flag.runs += 1 }
        released = nil
        await task.value
        #expect(flag.runs == 1, "the work is skipped once the object is gone")
    }

    @Test
    @MainActor
    func `executeTask runs the operation and swallows its errors`() async {
        struct Boom: Error {}
        final class Owner: Sendable {}
        final class Flag: @unchecked Sendable { var runs = 0 }
        let flag = Flag()
        let owner = Owner()
        await LMKConcurrency.executeTask(weak: owner) { _ in flag.runs += 1 }.value
        #expect(flag.runs == 1)
        await LMKConcurrency.executeTask(weak: owner) { _ in
            flag.runs += 1
            throw Boom()
        }.value
        #expect(flag.runs == 2, "a thrown error is logged, not propagated")

        let cancelled = LMKConcurrency.executeTask(weak: owner) { _ in flag.runs += 1 }
        cancelled.cancel()
        await cancelled.value
        #expect(flag.runs == 2, "a task cancelled before it starts skips the operation")
    }

    @Test
    @MainActor
    func `assertMainActor passes on the main actor`() {
        LMKConcurrency.assertMainActor(operation: "test")
        #expect(Thread.isMainThread)
    }
}
