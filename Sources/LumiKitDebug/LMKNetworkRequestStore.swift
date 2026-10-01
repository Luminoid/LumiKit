//
//  LMKNetworkRequestStore.swift
//  LumiKit
//
//  Thread-safe in-memory store for captured network requests: a bounded ring
//  buffer with O(1) insertion, eviction, and lookup by id.
//  Debug builds only (`LMK_ENABLE_NETWORK_LOGGING`) — zero footprint in release.
//

#if LMK_ENABLE_NETWORK_LOGGING

    import Foundation
    import os

    /// Thread-safe, bounded in-memory store for network requests.
    ///
    /// A ring buffer: when `maxRecords` is reached the oldest entry is overwritten. All access
    /// is serialized via `OSAllocatedUnfairLock`; `onChange` runs after every mutation, on the
    /// mutating thread.
    final class LMKNetworkRequestStore: Sendable {
        // MARK: - Buffer

        private struct Buffer {
            var slots: [LMKNetworkRequestRecord?]
            /// Index of the oldest record.
            var head = 0
            var count = 0
            var slotByID: [UUID: Int] = [:]

            init(capacity: Int) {
                slots = Array(repeating: nil, count: capacity)
            }

            var capacity: Int { slots.count }
            var isEmpty: Bool { slotByID.isEmpty }

            /// Newest first.
            var records: [LMKNetworkRequestRecord] {
                (0 ..< count).compactMap { offset in
                    slots[(head + count - 1 - offset) % capacity]
                }
            }

            mutating func append(_ record: LMKNetworkRequestRecord) {
                if count == capacity {
                    if let evicted = slots[head] {
                        slotByID[evicted.id] = nil
                    }
                    head = (head + 1) % capacity
                    count -= 1
                }
                let slot = (head + count) % capacity
                slots[slot] = record
                slotByID[record.id] = slot
                count += 1
            }

            mutating func update(id: UUID, _ transform: (LMKNetworkRequestRecord) -> LMKNetworkRequestRecord) -> Bool {
                guard let slot = slotByID[id], let existing = slots[slot] else { return false }
                slots[slot] = transform(existing)
                return true
            }

            mutating func removeAll() {
                slots = Array(repeating: nil, count: capacity)
                head = 0
                count = 0
                slotByID.removeAll()
            }
        }

        // MARK: - Properties

        private let lock: OSAllocatedUnfairLock<Buffer>
        private let onChange: (@Sendable () -> Void)?

        // MARK: - Initialization

        /// - Parameters:
        ///   - maxRecords: Maximum number of requests to retain (values below 1 keep one). Oldest are evicted first.
        ///   - onChange: Called after every add, update, and clear.
        init(maxRecords: Int, onChange: (@Sendable () -> Void)? = nil) {
            lock = OSAllocatedUnfairLock(initialState: Buffer(capacity: max(1, maxRecords)))
            self.onChange = onChange
        }

        // MARK: - Access

        /// A snapshot of all stored requests (newest first).
        var records: [LMKNetworkRequestRecord] {
            lock.withLock { $0.records }
        }

        /// Number of requests currently stored.
        var count: Int {
            lock.withLock { $0.count }
        }

        /// Whether the store contains no requests.
        var isEmpty: Bool {
            lock.withLock { $0.isEmpty }
        }

        /// The record with `id`, if still stored.
        func record(id: UUID) -> LMKNetworkRequestRecord? {
            lock.withLock { buffer in
                buffer.slotByID[id].flatMap { buffer.slots[$0] }
            }
        }

        // MARK: - Mutation

        /// Add a new request. Evicts the oldest request if at capacity.
        func addRequest(_ url: URL, method: String, headers: [String: String], body: Data?, isBodyTruncated: Bool = false) -> UUID {
            let id = UUID()
            let record = LMKNetworkRequestRecord(
                id: id,
                timestamp: Date(),
                request: .init(url: url, method: method, headers: headers, body: body, isBodyTruncated: isBodyTruncated),
                response: nil,
                errorDescription: nil,
                duration: nil
            )
            lock.withLock { $0.append(record) }
            onChange?()
            return id
        }

        /// Update a request with response data.
        func updateResponse(id: UUID, statusCode: Int, headers: [String: String], body: Data?, isBodyTruncated: Bool = false, duration: TimeInterval) {
            let updated = lock.withLock { buffer in
                buffer.update(id: id) { existing in
                    LMKNetworkRequestRecord(
                        id: existing.id,
                        timestamp: existing.timestamp,
                        request: existing.request,
                        response: .init(statusCode: statusCode, headers: headers, body: body, isBodyTruncated: isBodyTruncated),
                        errorDescription: nil,
                        duration: duration
                    )
                }
            }
            if updated {
                onChange?()
            }
        }

        /// Update a request with error data.
        func updateError(id: UUID, error: any Error, duration: TimeInterval) {
            let description = error.localizedDescription
            let updated = lock.withLock { buffer in
                buffer.update(id: id) { existing in
                    LMKNetworkRequestRecord(
                        id: existing.id,
                        timestamp: existing.timestamp,
                        request: existing.request,
                        response: existing.response,
                        errorDescription: description,
                        duration: duration
                    )
                }
            }
            if updated {
                onChange?()
            }
        }

        /// Remove all stored requests.
        func clear() {
            lock.withLock { $0.removeAll() }
            onChange?()
        }
    }

#endif
