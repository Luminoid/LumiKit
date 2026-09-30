//
//  LMKNetworkLoggerTests.swift
//  LumiKit
//
//  Tests for LMKNetworkLogger — configuration, capture rules, state transitions,
//  record access, and clearing.
//

#if DEBUG

    import Foundation
    import Testing
    @testable import LumiKitDebug

    /// Parent suite: every test that touches the process-wide `LMKNetworkLogger` runs serially,
    /// across the child suites, since sibling suites otherwise run in parallel and reconfigure
    /// the shared store under each other.
    @Suite(.serialized)
    enum LMKNetworkLoggerSerializedSuite {}

    extension LMKNetworkLoggerSerializedSuite {
        struct LMKNetworkLoggerTests {
            // MARK: - Configuration

            @Test
            func `isConfigured returns true after configure()`() {
                LMKNetworkLogger.configure(maxRecords: 50)

                #expect(LMKNetworkLogger.isConfigured)
                #expect(LMKNetworkLogger.configuration?.maxRecords == 50)
            }

            @Test
            func `configure sets up an empty store`() {
                LMKNetworkLogger.configure(maxRecords: 10)

                #expect(LMKNetworkLogger.count == .zero)
                #expect(LMKNetworkLogger.records.isEmpty)
            }

            @Test
            func `configure can be called multiple times and keeps the last configuration`() {
                LMKNetworkLogger.configure(maxRecords: 10)
                LMKNetworkLogger.configure(LMKNetworkLogger.Configuration(maxRecords: 20, hostFilter: ["Example.com"]))

                #expect(LMKNetworkLogger.isConfigured)
                #expect(LMKNetworkLogger.count == .zero)
                #expect(LMKNetworkLogger.configuration?.maxRecords == 20)
                #expect(LMKNetworkLogger.configuration?.hostFilter == ["example.com"], "hosts are lowercased")
            }

            @Test
            func `Configuration normalizes its fields`() {
                let configuration = LMKNetworkLogger.Configuration(maxRecords: 0, redactedHeaderFields: ["Authorization", "X-Secret"], maxBodyCaptureSize: -5)
                #expect(configuration.maxRecords == 1)
                #expect(configuration.redactedHeaderFields == ["authorization", "x-secret"])
                #expect(configuration.maxBodyCaptureSize == 0)
                #expect(configuration.capturesBodies)
                #expect(LMKNetworkLogger.Configuration.defaultRedactedHeaderFields.contains("authorization"))
                #expect(LMKNetworkLogger.Configuration.defaultRedactedHeaderFields.contains("set-cookie"))
            }

            // MARK: - Capture rules

            @Test
            func `redact replaces credential headers case-insensitively and keeps the rest`() {
                let configuration = LMKNetworkLogger.Configuration()
                let headers = ["Authorization": "Bearer secret", "cookie": "session=abc", "X-API-Key": "k", "Content-Type": "application/json"]

                let redacted = LMKNetworkLogger.redact(headers, configuration: configuration)

                #expect(redacted["Authorization"] == LMKNetworkLogger.redactedValue)
                #expect(redacted["cookie"] == LMKNetworkLogger.redactedValue)
                #expect(redacted["X-API-Key"] == LMKNetworkLogger.redactedValue)
                #expect(redacted["Content-Type"] == "application/json")
                #expect(redacted.count == headers.count)
            }

            @Test
            func `redact honors a custom field set, including none`() {
                let custom = LMKNetworkLogger.Configuration(redactedHeaderFields: ["x-token"])
                let redacted = LMKNetworkLogger.redact(["Authorization": "a", "X-Token": "t"], configuration: custom)
                #expect(redacted["Authorization"] == "a")
                #expect(redacted["X-Token"] == LMKNetworkLogger.redactedValue)

                let none = LMKNetworkLogger.Configuration(redactedHeaderFields: [])
                #expect(LMKNetworkLogger.redact(["Authorization": "a"], configuration: none)["Authorization"] == "a")
            }

            @Test
            func `shouldCapture allows every host without a filter`() {
                let configuration = LMKNetworkLogger.Configuration()
                #expect(LMKNetworkLogger.shouldCapture(url: URL(string: "https://anything.test/path"), configuration: configuration))
                #expect(LMKNetworkLogger.shouldCapture(url: nil, configuration: configuration))
            }

            @Test
            func `shouldCapture matches the host or a parent domain`() {
                let configuration = LMKNetworkLogger.Configuration(hostFilter: ["example.com", "api.other.test"])
                #expect(LMKNetworkLogger.shouldCapture(url: URL(string: "https://example.com/a"), configuration: configuration))
                #expect(LMKNetworkLogger.shouldCapture(url: URL(string: "https://API.example.com/a"), configuration: configuration))
                #expect(LMKNetworkLogger.shouldCapture(url: URL(string: "https://api.other.test"), configuration: configuration))
                #expect(!LMKNetworkLogger.shouldCapture(url: URL(string: "https://other.test"), configuration: configuration), "a subdomain filter does not cover its parent")
                #expect(!LMKNetworkLogger.shouldCapture(url: URL(string: "https://notexample.com"), configuration: configuration), "suffix matches need a dot boundary")
                #expect(!LMKNetworkLogger.shouldCapture(url: nil, configuration: configuration))
            }

            // MARK: - Enable / Disable

            @Test
            func `enable and disable toggle isEnabled and never crash`() {
                LMKNetworkLogger.configure(maxRecords: 50)
                LMKNetworkLogger.disable()
                #expect(!LMKNetworkLogger.isEnabled)

                LMKNetworkLogger.enable()
                #if LMK_ENABLE_NETWORK_LOGGING
                    #expect(LMKNetworkLogger.isEnabled)
                #endif

                LMKNetworkLogger.disable()
                #expect(!LMKNetworkLogger.isEnabled)
                #expect(LMKNetworkLogger.isConfigured)
            }

            // MARK: - Records

            @Test
            func `records flow through the store and clear`() throws {
                LMKNetworkLogger.configure(maxRecords: 50)
                let store = try #require(LMKNetworkLogger.internalStore)
                _ = try store.addRequest(#require(URL(string: "https://example.com")), method: "GET", headers: [:], body: nil)

                #expect(LMKNetworkLogger.count == 1)
                #expect(LMKNetworkLogger.records.first?.displayMethod == "GET")

                LMKNetworkLogger.clearRecords()
                LMKNetworkLogger.clearRecords()

                #expect(LMKNetworkLogger.count == .zero)
                #expect(LMKNetworkLogger.records.isEmpty)
            }

            @Test
            func `store changes post the change notification`() async throws {
                LMKNetworkLogger.configure(maxRecords: 50)
                let store = try #require(LMKNetworkLogger.internalStore)

                await confirmation("recordsDidChange", expectedCount: 2) { confirm in
                    let token = NotificationCenter.default.addObserver(forName: LMKNetworkLogger.recordsDidChangeNotification, object: nil, queue: nil) { _ in
                        confirm()
                    }
                    _ = try? store.addRequest(#require(URL(string: "https://example.com")), method: "GET", headers: [:], body: nil)
                    LMKNetworkLogger.clearRecords()
                    NotificationCenter.default.removeObserver(token)
                }
            }

            @Test
            func `Full lifecycle: configure → enable → disable`() {
                LMKNetworkLogger.configure(maxRecords: 100)
                #expect(LMKNetworkLogger.isConfigured)
                #expect(LMKNetworkLogger.count == .zero)

                LMKNetworkLogger.enable()
                #expect(LMKNetworkLogger.isConfigured)

                LMKNetworkLogger.disable()
                #expect(LMKNetworkLogger.isConfigured)
                #expect(LMKNetworkLogger.count == .zero)
            }
        }
    }

#endif
