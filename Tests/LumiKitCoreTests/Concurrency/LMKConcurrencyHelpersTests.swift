//
//  LMKConcurrencyHelpersTests.swift
//  LumiKit
//

import Foundation
import Testing
@testable import LumiKitCore

// MARK: - LMKConcurrencyHelpers

struct ConcurrencyHelpersTests {
    struct TestModel: Codable, Equatable {
        let name: String
        let count: Int
    }

    @Test
    func `Encode produces valid data`() {
        let model = TestModel(name: "test", count: 42)
        let data = LMKConcurrencyHelpers.encode(model)
        #expect(data != nil)
    }

    @Test
    func `Decode recovers original model`() throws {
        let model = TestModel(name: "lumikit", count: 7)
        let data = try #require(LMKConcurrencyHelpers.encode(model))
        let decoded = LMKConcurrencyHelpers.decode(TestModel.self, from: data)
        #expect(decoded == model)
    }

    @Test
    func `Decode returns nil for invalid data`() {
        let badData = Data("not json".utf8)
        let result = LMKConcurrencyHelpers.decode(TestModel.self, from: badData)
        #expect(result == nil)
    }

    @Test
    func `Encode/decode round-trip for arrays`() throws {
        let models = [TestModel(name: "a", count: 1), TestModel(name: "b", count: 2)]
        let data = try #require(LMKConcurrencyHelpers.encode(models))
        let decoded = LMKConcurrencyHelpers.decode([TestModel].self, from: data)
        #expect(decoded == models)
    }
}
