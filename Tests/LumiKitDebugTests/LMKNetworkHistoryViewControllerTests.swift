//
//  LMKNetworkHistoryViewControllerTests.swift
//  LumiKit
//
//  Tests for the network history screen: the diffable list follows the store,
//  the empty state toggles, and rows describe their record.
//

#if LMK_ENABLE_NETWORK_LOGGING && canImport(UIKit)

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
                #expect(history.title == LMKNetworkHistoryViewController.historyStrings.title)
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

                let strings = LMKNetworkDetailViewController.DetailStrings()
                let sections = [
                    strings.summarySection, strings.urlSection, strings.requestHeadersSection, strings.requestBodySection,
                    strings.responseHeadersSection, strings.responseBodySection, strings.errorSection,
                ]
                for section in sections {
                    #expect(text.contains(section), "\(section)")
                    #expect(!section.hasPrefix("networkDetail."), "\(section) resolves from the table")
                }
                #expect(text.contains(String(format: strings.methodFormat, "GET")))
                #expect(text.contains(String(format: strings.statusFormat, "500")))
                #expect(text.contains("Accept: application/json"))
                #expect(text.contains("boom"))
            }

            @Test
            func `The detail screen notes a body cut at capture and one cut for display`() throws {
                let strings = LMKNetworkDetailViewController.DetailStrings()
                let long = String(repeating: "a", count: 50010)
                let record = try LMKNetworkRequestRecord(
                    id: UUID(),
                    timestamp: Date(),
                    request: .init(url: #require(URL(string: "https://example.com")), method: "POST", headers: [:], body: Data("cut".utf8), isBodyTruncated: true),
                    response: .init(statusCode: 200, headers: [:], body: Data(long.utf8)),
                    errorDescription: nil,
                    duration: 1
                )

                let text = LMKNetworkDetailViewController.formatRecord(record, strings: strings)

                #expect(text.contains(String(format: strings.captureLimitFormat, ByteCountFormatter.string(fromByteCount: 3, countStyle: .binary))))
                #expect(text.contains(String(format: strings.truncatedFormat, "10")))
                #expect(!text.contains(long), "the display cut applies")
            }

            @Test
            func `The detail screen re-reads its record when the response lands`() throws {
                LMKNetworkLogger.configure(maxRecords: 10)
                let store = try #require(LMKNetworkLogger.internalStore)
                let id = try store.addRequest(#require(URL(string: "https://example.com/pending")), method: "GET", headers: [:], body: nil)
                let pending = try #require(store.record(id: id))
                let detail = LMKNetworkDetailViewController(record: pending)
                detail.loadViewIfNeeded()
                let strings = LMKNetworkDetailViewController.DetailStrings()
                #expect(detail.textView.text.contains(String(format: strings.statusFormat, pending.displayStatus)))

                store.updateResponse(id: id, statusCode: 404, headers: [:], body: nil, duration: 0.5)
                detail.refreshRecord()

                #expect(detail.record.statusCode == 404)
                #expect(detail.textView.text.contains(String(format: strings.statusFormat, "404")))

                LMKNetworkLogger.clearRecords()
                detail.refreshRecord()
                #expect(detail.record.statusCode == 404, "a record evicted from the store keeps its last copy")
            }

            @Test
            func `The history list applies theme layout values and survives reloading off screen`() throws {
                LMKNetworkLogger.configure(maxRecords: 10)
                let store = try #require(LMKNetworkLogger.internalStore)
                var theme = LMKTheme.default
                theme.layout = LMKLayoutTheme(rowHeightEstimated: 99)
                let history = LMKNetworkHistoryViewController()
                history.loadViewIfNeeded()
                history.applyTheme(theme)
                #expect(history.tableView.estimatedRowHeight == 99)

                _ = try store.addRequest(#require(URL(string: "https://example.com/1")), method: "GET", headers: [:], body: nil)
                history.reload()
                #expect(history.tableView.window == nil)
                #expect(history.tableView.numberOfRows(inSection: 0) == 1, "a snapshot applied off screen still lands")
            }
        }
    }

#endif
