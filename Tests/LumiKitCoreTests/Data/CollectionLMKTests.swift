//
//  CollectionLMKTests.swift
//  LumiKit
//

import Foundation
import Testing

@testable import LumiKitCore

// MARK: - Collection+LMK

@Suite("Collection+LMK")
struct CollectionLMKTests {
    @Test("Safe subscript returns element for valid index")
    func safeSubscriptValid() {
        let items = ["a", "b", "c"]
        #expect(items[safe: 1] == "b")
    }

    @Test("Safe subscript returns nil for out-of-bounds index")
    func safeSubscriptOutOfBounds() {
        let items = ["a", "b", "c"]
        #expect(items[safe: 5] == nil)
        #expect(items[safe: -1] == nil)
    }

    @Test("Safe subscript returns nil for empty collection")
    func safeSubscriptEmpty() {
        let items: [String] = []
        #expect(items[safe: 0] == nil)
    }

    @Test("lmk_uniqued preserves order and removes duplicates")
    func uniquedPreservesOrder() {
        let items = [1, 2, 2, 3, 1, 4]
        #expect(items.lmk_uniqued() == [1, 2, 3, 4])
    }

    @Test("lmk_uniqued on empty returns empty")
    func uniquedEmpty() {
        let items: [Int] = []
        #expect(items.lmk_uniqued().isEmpty)
    }

    @Test("lmk_chunked splits correctly")
    func chunkedSplits() {
        let items = [1, 2, 3, 4, 5]
        let chunks = items.lmk_chunked(size: 2)
        #expect(chunks.count == 3)
        #expect(chunks[0] == [1, 2])
        #expect(chunks[1] == [3, 4])
        #expect(chunks[2] == [5])
    }

    @Test("lmk_chunked with size larger than count returns single chunk")
    func chunkedLargerSize() {
        let items = [1, 2]
        let chunks = items.lmk_chunked(size: 10)
        #expect(chunks.count == 1)
        #expect(chunks[0] == [1, 2])
    }

    @Test("lmk_chunked with size 0 returns empty")
    func chunkedZeroSize() {
        let items = [1, 2, 3]
        #expect(items.lmk_chunked(size: 0).isEmpty)
    }
}
