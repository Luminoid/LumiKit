//
//  LMKConcurrencyHelpersTests.swift
//  LumiKit
//

import Foundation
import Testing

@testable import LumiKitCore

// MARK: - LMKConcurrencyHelpers

@Suite("LMKConcurrencyHelpers")
struct ConcurrencyHelpersTests {
    struct TestModel: Codable, Equatable {
        let name: String
        let count: Int
    }

    @Test("Encode produces valid data")
    func encodeProducesData() {
        let model = TestModel(name: "test", count: 42)
        let data = LMKConcurrencyHelpers.encode(model)
        #expect(data != nil)
    }

    @Test("Decode recovers original model")
    func decodeRecoversModel() {
        let model = TestModel(name: "lumikit", count: 7)
        let data = LMKConcurrencyHelpers.encode(model)!
        let decoded = LMKConcurrencyHelpers.decode(TestModel.self, from: data)
        #expect(decoded == model)
    }

    @Test("Decode returns nil for invalid data")
    func decodeInvalidData() {
        let badData = Data("not json".utf8)
        let result = LMKConcurrencyHelpers.decode(TestModel.self, from: badData)
        #expect(result == nil)
    }

    @Test("Encode/decode round-trip for arrays")
    func encodeDecodeArray() {
        let models = [TestModel(name: "a", count: 1), TestModel(name: "b", count: 2)]
        let data = LMKConcurrencyHelpers.encode(models)!
        let decoded = LMKConcurrencyHelpers.decode([TestModel].self, from: data)
        #expect(decoded == models)
    }
}
