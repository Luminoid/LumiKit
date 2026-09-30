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
}
