//
//  LMKNetworkRequestStoreTests.swift
//  LumiKit
//
//  Tests for LMKNetworkRequestStore — thread safety and ring buffer behavior.
//

#if DEBUG

    import Foundation
    import LumiKitNetwork
    import Testing

    @Suite("LMKNetworkRequestStore")
    struct LMKNetworkRequestStoreTests {
        // MARK: - Basic Functionality

        @Test("Add request and retrieve")
        func addAndRetrieve() {
            let store = LMKNetworkRequestStore(maxRecords: 10)
            let url = URL(string: "https://example.com")!

            let id = store.addRequest(url, method: "GET", headers: [:], body: nil)

            #expect(store.count == 1)
            #expect(store.records.count == 1)
            #expect(store.records.first?.id == id)
            #expect(store.records.first?.request.url == url)
        }

        @Test("Multiple requests are newest-first")
        func multipleRequestsNewestFirst() {
            let store = LMKNetworkRequestStore(maxRecords: 10)
            let url1 = URL(string: "https://example.com/1")!
            let url2 = URL(string: "https://example.com/2")!
            let url3 = URL(string: "https://example.com/3")!

            let id1 = store.addRequest(url1, method: "GET", headers: [:], body: nil)
            let id2 = store.addRequest(url2, method: "POST", headers: [:], body: nil)
            let id3 = store.addRequest(url3, method: "PUT", headers: [:], body: nil)

            #expect(store.count == 3)
            #expect(store.records[0].id == id3) // newest first
            #expect(store.records[1].id == id2)
            #expect(store.records[2].id == id1)
        }

        @Test("Clear removes all records")
        func clearRecords() {
            let store = LMKNetworkRequestStore(maxRecords: 10)
            store.addRequest(URL(string: "https://example.com")!, method: "GET", headers: [:], body: nil)
            store.addRequest(URL(string: "https://example.com")!, method: "POST", headers: [:], body: nil)

            #expect(store.count == 2)

            store.clear()

            #expect(store.count == 0)
            #expect(store.records.isEmpty)
        }

        // MARK: - Ring Buffer (FIFO Eviction)

        @Test("Ring buffer evicts oldest when exceeding maxRecords")
        func ringBufferEviction() {
            let store = LMKNetworkRequestStore(maxRecords: 5)

            // Add 7 requests (exceeds maxRecords by 2)
            var ids: [UUID] = []
            for i in 1...7 {
                let url = URL(string: "https://example.com/\(i)")!
                let id = store.addRequest(url, method: "GET", headers: [:], body: nil)
                ids.append(id)
            }

            // Should retain only last 5 (newest)
            #expect(store.count == 5)

            // First two (oldest) should be evicted
            let recordIds = Set(store.records.map(\.id))
            #expect(!recordIds.contains(ids[0])) // evicted
            #expect(!recordIds.contains(ids[1])) // evicted
            #expect(recordIds.contains(ids[2]))
            #expect(recordIds.contains(ids[3]))
            #expect(recordIds.contains(ids[4]))
            #expect(recordIds.contains(ids[5]))
            #expect(recordIds.contains(ids[6]))

            // Newest should be first
            #expect(store.records[0].id == ids[6])
        }

        @Test("Ring buffer with large overage")
        func ringBufferLargeOverage() {
            let store = LMKNetworkRequestStore(maxRecords: 10)

            // Add 50 requests
            var ids: [UUID] = []
            for i in 1...50 {
                let url = URL(string: "https://example.com/\(i)")!
                let id = store.addRequest(url, method: "GET", headers: [:], body: nil)
                ids.append(id)
            }

            // Should retain only last 10
            #expect(store.count == 10)

            let recordIds = Set(store.records.map(\.id))
            // First 40 evicted
            for i in 0..<40 {
                #expect(!recordIds.contains(ids[i]))
            }
            // Last 10 retained
            for i in 40..<50 {
                #expect(recordIds.contains(ids[i]))
            }
        }

        // MARK: - Thread Safety

        @Test("Concurrent additions are thread-safe")
        func concurrentAdditions() async {
            let store = LMKNetworkRequestStore(maxRecords: 500)
            let url = URL(string: "https://example.com")!

            // 10 concurrent tasks each adding 20 requests
            await withTaskGroup(of: Void.self) { group in
                for threadId in 0..<10 {
                    group.addTask {
                        for i in 0..<20 {
                            _ = store.addRequest(
                                url.appendingPathComponent("\(threadId)/\(i)"),
                                method: "GET",
                                headers: [:],
                                body: nil
                            )
                        }
                    }
                }
            }

            // All 200 requests should be captured
            #expect(store.count == 200)
        }

        @Test("Concurrent read and write")
        func concurrentReadWrite() async {
            let store = LMKNetworkRequestStore(maxRecords: 100)
            let url = URL(string: "https://example.com")!

            await withTaskGroup(of: Void.self) { group in
                // Writer task
                group.addTask {
                    for i in 0..<50 {
                        _ = store.addRequest(
                            url.appendingPathComponent("\(i)"),
                            method: "GET",
                            headers: [:],
                            body: nil
                        )
                    }
                }

                // Reader tasks
                for _ in 0..<5 {
                    group.addTask {
                        for _ in 0..<20 {
                            _ = store.records // read concurrently
                            _ = store.count
                        }
                    }
                }
            }

            // Should complete without crashes
            #expect(store.count <= 50)
        }

        @Test("Concurrent updates are thread-safe")
        func concurrentUpdates() async {
            let store = LMKNetworkRequestStore(maxRecords: 100)
            let url = URL(string: "https://example.com")!

            // Pre-populate with 10 requests
            var ids: [UUID] = []
            for i in 0..<10 {
                let id = store.addRequest(
                    url.appendingPathComponent("\(i)"),
                    method: "GET",
                    headers: [:],
                    body: nil
                )
                ids.append(id)
            }

            // Concurrently update responses
            await withTaskGroup(of: Void.self) { group in
                for (index, id) in ids.enumerated() {
                    group.addTask {
                        store.updateResponse(
                            id: id,
                            statusCode: 200 + index,
                            headers: [:],
                            body: Data(),
                            duration: Double(index)
                        )
                    }
                }
            }

            // All updates should succeed
            let records = store.records
            #expect(records.count == 10)
            for record in records {
                #expect(record.response != nil)
            }
        }
    }

#endif
