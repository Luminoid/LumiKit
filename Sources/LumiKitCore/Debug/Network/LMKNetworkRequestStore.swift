//
//  LMKNetworkRequestStore.swift
//  LumiKit
//
//  Thread-safe in-memory store for captured network requests.
//  Bounded ring buffer to prevent excessive memory usage.
//  DEBUG builds only — zero footprint in release.
//

#if DEBUG

    import Foundation
    import os

    /// Thread-safe, bounded in-memory store for network requests.
    ///
    /// Uses a FIFO ring buffer — when `maxRecords` is reached, the oldest
    /// entry is evicted. All access is serialized via `OSAllocatedUnfairLock`.
    public final class LMKNetworkRequestStore: Sendable {
        // MARK: - Properties

        private let maxRecords: Int
        private let lock: OSAllocatedUnfairLock<[LMKNetworkRequestRecord]>

        // MARK: - Initialization

        /// Create a request store with a maximum capacity.
        /// - Parameter maxRecords: Maximum number of requests to retain. Oldest are evicted first.
        public init(maxRecords: Int) {
            self.maxRecords = maxRecords
            self.lock = OSAllocatedUnfairLock(initialState: [])
        }

        // MARK: - Access

        /// A snapshot of all stored requests (newest first).
        public var records: [LMKNetworkRequestRecord] {
            lock.withLock { $0 }
        }

        /// Number of requests currently stored.
        public var count: Int {
            lock.withLock { $0.count }
        }

        // MARK: - Mutation

        /// Add a new request. Evicts the oldest request if at capacity.
        public func addRequest(_ url: URL, method: String, headers: [String: String], body: Data?) -> UUID {
            let id = UUID()
            let record = LMKNetworkRequestRecord(
                id: id,
                timestamp: Date(),
                request: .init(
                    url: url,
                    method: method,
                    headers: headers,
                    body: body
                ),
                response: nil,
                error: nil,
                duration: nil
            )

            lock.withLock { records in
                records.insert(record, at: 0)
                if records.count > maxRecords {
                    records = Array(records.prefix(maxRecords))
                }
            }

            return id
        }

        /// Update a request with response data.
        public func updateResponse(
            id: UUID,
            statusCode: Int,
            headers: [String: String],
            body: Data?,
            duration: TimeInterval
        ) {
            lock.withLock { records in
                guard let index = records.firstIndex(where: { $0.id == id }) else { return }
                let existing = records[index]
                records[index] = LMKNetworkRequestRecord(
                    id: existing.id,
                    timestamp: existing.timestamp,
                    request: existing.request,
                    response: .init(
                        statusCode: statusCode,
                        headers: headers,
                        body: body
                    ),
                    error: nil,
                    duration: duration
                )
            }
        }

        /// Update a request with error data.
        public func updateError(id: UUID, error: Error, duration: TimeInterval) {
            lock.withLock { records in
                guard let index = records.firstIndex(where: { $0.id == id }) else { return }
                let existing = records[index]
                records[index] = LMKNetworkRequestRecord(
                    id: existing.id,
                    timestamp: existing.timestamp,
                    request: existing.request,
                    response: existing.response,
                    error: error,
                    duration: duration
                )
            }
        }

        /// Remove all stored requests.
        public func clear() {
            lock.withLock { $0.removeAll() }
        }
    }

#endif
