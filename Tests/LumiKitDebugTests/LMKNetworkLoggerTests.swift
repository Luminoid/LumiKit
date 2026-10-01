//
//  LMKNetworkLoggerTests.swift
//  LumiKit
//
//  Tests for LMKNetworkLogger — configuration, capture rules, state transitions,
//  record access, and clearing.
//

#if LMK_ENABLE_NETWORK_LOGGING

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
                let configuration = LMKNetworkLogger.Configuration(maxRecords: 0, redactedHeaderFields: ["Authorization", "X-Secret"], redactedQueryItems: ["Key"], maxBodyCaptureSize: -5)
                #expect(configuration.maxRecords == 1)
                #expect(configuration.redactedHeaderFields == ["authorization", "x-secret"])
                #expect(configuration.redactedQueryItems == ["key"])
                #expect(configuration.maxBodyCaptureSize == 0)
                #expect(configuration.capturesBodies)
                for field in ["authorization", "set-cookie", "x-api-key", "x-goog-api-key", "api-key", "x-amz-security-token", "x-csrf-token"] {
                    #expect(LMKNetworkLogger.Configuration.defaultRedactedHeaderFields.contains(field), "\(field)")
                }
                for item in ["key", "api_key", "access_token", "token", "signature", "client_secret", "password"] {
                    #expect(LMKNetworkLogger.Configuration.defaultRedactedQueryItems.contains(item), "\(item)")
                }
            }

            @Test
            func `Configuration normalizes fields mutated after init`() throws {
                var configuration = LMKNetworkLogger.Configuration()
                configuration.redactedHeaderFields.insert("X-Goog-Api-Key")
                configuration.redactedQueryItems = ["Access_Token"]
                configuration.hostFilter = ["Example.com"]
                configuration.maxRecords = 0
                configuration.maxBodyCaptureSize = -1
                #expect(configuration.redactedHeaderFields.contains("x-goog-api-key"))
                #expect(!configuration.redactedHeaderFields.contains("X-Goog-Api-Key"))
                #expect(configuration.redactedQueryItems == ["access_token"])
                #expect(configuration.hostFilter == ["example.com"])
                #expect(configuration.maxRecords == 1)
                #expect(configuration.maxBodyCaptureSize == 0)
                #expect(LMKNetworkLogger.redact(["X-GOOG-API-KEY": "k"], configuration: configuration)["X-GOOG-API-KEY"] == LMKNetworkLogger.redactedValue)

                LMKNetworkLogger.configure(configuration)
                #expect(LMKNetworkLogger.configuration?.maxRecords == 1)
                let store = try #require(LMKNetworkLogger.internalStore)
                _ = store.addRequest(URL(fileURLWithPath: "/a"), method: "GET", headers: [:], body: nil)
                _ = store.addRequest(URL(fileURLWithPath: "/b"), method: "GET", headers: [:], body: nil)
                #expect(LMKNetworkLogger.count == 1, "a clamped capacity of one keeps the newest record")
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
            func `redact covers the Gemini key header and query credentials in a Location header`() {
                let configuration = LMKNetworkLogger.Configuration()
                let redacted = LMKNetworkLogger.redact(
                    ["x-goog-api-key": "AIza", "Location": "https://example.com/cb?code=1&access_token=t#frag", "Server": "nginx"],
                    configuration: configuration
                )
                #expect(redacted["x-goog-api-key"] == LMKNetworkLogger.redactedValue)
                #expect(redacted["Location"] == "https://example.com/cb?code=1&access_token=\(LMKNetworkLogger.redactedValueQueryEncoded)#frag")
                #expect(redacted["Server"] == "nginx")
            }

            @Test
            func `redact replaces query credentials and a password in a URL, and nothing else`() throws {
                let configuration = LMKNetworkLogger.Configuration()
                let url = try #require(URL(string: "https://user:pa%40ss@api.example.com/v1/items?KEY=abc123&q=a%20b&api_key=&token=t&x=%2B#top"))

                let redacted = LMKNetworkLogger.redact(url, configuration: configuration)

                let components = try #require(URLComponents(url: redacted, resolvingAgainstBaseURL: false))
                #expect(components.host == "api.example.com")
                #expect(components.user == "user")
                #expect(components.password == LMKNetworkLogger.redactedValue)
                #expect(components.path == "/v1/items")
                #expect(components.fragment == "top")
                let items = try #require(components.queryItems)
                #expect(items.map(\.name) == ["KEY", "q", "api_key", "token", "x"], "order and spelling are kept")
                #expect(items[0].value == LMKNetworkLogger.redactedValue, "names match case-insensitively")
                #expect(items[1].value == "a b")
                #expect(items[2].value == LMKNetworkLogger.redactedValue)
                #expect(items[3].value == LMKNetworkLogger.redactedValue)
                #expect(items[4].value == "+")
                #expect(redacted.absoluteString.contains("q=a%20b"), "untouched items keep their bytes")
                #expect(redacted.absoluteString.contains("x=%2B"))

                let plain = try #require(URL(string: "https://example.com/path?q=1"))
                #expect(LMKNetworkLogger.redact(plain, configuration: configuration) == plain)
                #expect(LMKNetworkLogger.redact(url, configuration: LMKNetworkLogger.Configuration(redactedQueryItems: [])).query == url.query, "an empty set redacts no query item")
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
                #expect(LMKNetworkLogger.isEnabled)

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
            func `The active configuration is nil while disabled`() {
                LMKNetworkLogger.configure(maxRecords: 5)
                LMKNetworkLogger.disable()
                #expect(LMKNetworkLogger.activeConfiguration == nil)
                LMKNetworkLogger.enable()
                #expect(LMKNetworkLogger.activeConfiguration?.maxRecords == 5)
                LMKNetworkLogger.disable()
                #expect(LMKNetworkLogger.activeConfiguration == nil)
                #expect(LMKNetworkLogger.configuration?.maxRecords == 5, "the configuration itself is kept")
            }

            @Test
            func `The protocol intercepts HTTP requests only, once, and only while enabled`() throws {
                LMKNetworkLogger.configure(LMKNetworkLogger.Configuration(hostFilter: ["example.com"]))
                LMKNetworkLogger.enable()
                defer { LMKNetworkLogger.disable() }
                let http = try URLRequest(url: #require(URL(string: "https://api.example.com/v1")))
                #expect(LMKNetworkRequestLoggerProtocol.canInit(with: http))
                #expect(!LMKNetworkRequestLoggerProtocol.canInit(with: URLRequest(url: URL(fileURLWithPath: "/tmp/example.com"))), "file URLs never produce an HTTP response")
                let dataURL = try URLRequest(url: #require(URL(string: "data:text/plain,example.com")))
                #expect(!LMKNetworkRequestLoggerProtocol.canInit(with: dataURL))
                let otherHost = try URLRequest(url: #require(URL(string: "https://other.test/")))
                #expect(!LMKNetworkRequestLoggerProtocol.canInit(with: otherHost), "the host filter applies")

                LMKNetworkLogger.disable()
                #expect(!LMKNetworkRequestLoggerProtocol.canInit(with: http), "a disabled logger intercepts nothing")
            }

            @Test
            func `A change observer delivers a burst of notifications once, on the main actor`() async throws {
                LMKNetworkLogger.configure(maxRecords: 50)
                let store = try #require(LMKNetworkLogger.internalStore)
                final class Deliveries: @unchecked Sendable {
                    var count = 0
                    var onMain = true
                }
                let deliveries = Deliveries()
                let observer = LMKNetworkLogger.ChangeObserver {
                    deliveries.count += 1
                    deliveries.onMain = deliveries.onMain && Thread.isMainThread
                }

                for index in 0 ..< 20 {
                    _ = store.addRequest(URL(fileURLWithPath: "/\(index)"), method: "GET", headers: [:], body: nil)
                }
                await LMKWait.until { !observer.hasPendingDelivery }
                await Task.yield()

                #expect(deliveries.count >= 1)
                #expect(deliveries.count < 20, "a burst is folded into far fewer deliveries")
                #expect(deliveries.onMain)

                let delivered = deliveries.count
                store.clear()
                await LMKWait.until { deliveries.count > delivered }
                #expect(deliveries.count == delivered + 1, "a later change schedules a fresh delivery")
                withExtendedLifetime(observer) {}
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
