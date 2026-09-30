//
//  LMKNetworkHistoryViewControllerTests.swift
//  LumiKit
//
//  Tests for the network history screen: the diffable list follows the store,
//  the empty state toggles, and rows describe their record.
//

#if DEBUG && canImport(UIKit)

    import LumiKitUI
    import Testing
    import UIKit
    @testable import LumiKitDebug

    extension LMKNetworkLoggerSerializedSuite {
        @MainActor
        struct LMKNetworkHistoryViewControllerTests {
            @Test
            func `Lists the captured records newest first and reloads on demand`() throws {
                LMKNetworkLogger.configure(maxRecords: 10)
                let store = try #require(LMKNetworkLogger.internalStore)
                let history = LMKNetworkHistoryViewController()
                history.loadViewIfNeeded()
                #expect(history.records.isEmpty)
                #expect(history.tableView.numberOfRows(inSection: 0) == 0)

                let first = try store.addRequest(#require(URL(string: "https://example.com/1")), method: "GET", headers: [:], body: nil)
                _ = try store.addRequest(#require(URL(string: "https://example.com/2")), method: "POST", headers: [:], body: nil)
                history.reload()

                #expect(history.records.count == 2)
                #expect(history.records.first?.displayMethod == "POST")
                #expect(history.tableView.numberOfRows(inSection: 0) == 2)

                store.updateResponse(id: first, statusCode: 404, headers: [:], body: nil, duration: 0.5)
                history.reload()
                #expect(history.records.last?.statusCode == 404, "an updated record is reconfigured in place")

                LMKNetworkLogger.clearRecords()
                history.reload()
                #expect(history.records.isEmpty)
            }

            @Test
            func `Rows carry the URL and a method, status, duration, time line`() throws {
                let record = try LMKNetworkRequestRecord(
                    id: UUID(),
                    timestamp: Date(timeIntervalSince1970: 0),
                    request: .init(url: #require(URL(string: "https://example.com/path")), method: "PUT", headers: [:], body: nil),
                    response: .init(statusCode: 201, headers: [:], body: nil),
                    errorDescription: nil,
                    duration: 0.25
                )

                let row = LMKNetworkHistoryViewController.rowConfiguration(for: record)

                #expect(row.title == "https://example.com/path")
                #expect(row.subtitle?.hasPrefix("PUT · 201 · 250ms · ") == true)
            }

            @Test
            func `Strings default to localized text and the clear item is labeled`() {
                let strings = LMKNetworkHistoryViewController.HistoryStrings()
                #expect(strings.title != "networkHistory.title")
                #expect(!strings.clearAccessibilityLabel.isEmpty)

                let history = LMKNetworkHistoryViewController()
                #expect(history.trailingItem?.accessibilityLabel == strings.clearAccessibilityLabel)
            }

            @Test
            func `The detail screen formats every section of a record`() throws {
                let record = try LMKNetworkRequestRecord(
                    id: UUID(),
                    timestamp: Date(timeIntervalSince1970: 0),
                    request: .init(url: #require(URL(string: "https://example.com")), method: "GET", headers: ["Accept": "application/json"], body: Data("{}".utf8)),
                    response: .init(statusCode: 500, headers: ["Server": "test"], body: Data("oops".utf8)),
                    errorDescription: "boom",
                    duration: 1
                )

                let text = LMKNetworkDetailViewController.formatRecord(record)

                for section in ["REQUEST SUMMARY", "REQUEST URL", "REQUEST HEADERS", "REQUEST BODY", "RESPONSE HEADERS", "RESPONSE BODY", "ERROR"] {
                    #expect(text.contains(section), "\(section)")
                }
                #expect(text.contains("Accept: application/json"))
                #expect(text.contains("boom"))
            }
        }
    }

#endif
