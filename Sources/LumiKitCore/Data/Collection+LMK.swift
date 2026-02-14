//
//  Collection+LMK.swift
//  LumiKit
//
//  Safe collection access and functional helpers.
//

import Foundation

public extension Collection {
    /// Safe subscript that returns `nil` for out-of-bounds indices.
    ///
    /// ```swift
    /// let items = ["a", "b", "c"]
    /// items[safe: 5]  // nil (no crash)
    /// items[safe: 1]  // "b"
    /// ```
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

public extension Sequence where Element: Hashable {
    /// Returns elements with duplicates removed, preserving order.
    ///
    /// ```swift
    /// [1, 2, 2, 3, 1].lmk_uniqued()  // [1, 2, 3]
    /// ```
    func lmk_uniqued() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}

public extension Array {
    /// Splits the array into chunks of the given size.
    ///
    /// ```swift
    /// [1, 2, 3, 4, 5].lmk_chunked(size: 2)  // [[1, 2], [3, 4], [5]]
    /// ```
    func lmk_chunked(size: Int) -> [[Element]] {
        guard size > 0 else { return [] }
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
