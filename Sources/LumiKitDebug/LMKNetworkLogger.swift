//
//  LMKNetworkLogger.swift
//  LumiKit
//
//  Network debugging system for the Lumi ecosystem.
//  DEBUG builds only — zero footprint in release.
//

#if DEBUG

    @preconcurrency import Foundation
    import LumiKitCore
    import os

    /// Network debugging system for the Lumi ecosystem.
    ///
    /// Configure once at app launch:
    /// ```swift
    /// LMKNetworkLogger.configure(LMKNetworkLogger.Configuration(maxRecords: 100, hostFilter: ["api.example.com"]))
    /// LMKNetworkLogger.enable()
    ///
    /// // In services:
    /// let config = URLSessionConfiguration.default.lmk_enableNetworkLogging()
    /// ```
    ///
    /// Credentials never reach the store: `Authorization`, `Cookie`, `Set-Cookie`, and API-key
    /// headers are replaced with `redactedValue` at capture time (`redactedHeaderFields`).
    public enum LMKNetworkLogger {
        // MARK: - Configuration

        /// What the logger captures and keeps.
        public struct Configuration: Sendable, Equatable {
            /// Requests retained (oldest evicted first). Default 100.
            public var maxRecords: Int
            /// Header fields whose values are replaced with `redactedValue`, compared case-insensitively.
            public var redactedHeaderFields: Set<String>
            /// Hosts to capture (exact host or a parent domain, so `example.com` covers
            /// `api.example.com`); `nil` captures every host.
            public var hostFilter: Set<String>?
            /// Bytes of each body kept. Default 512 KB.
            public var maxBodyCaptureSize: Int
            /// Whether request and response bodies are captured at all. Default `true`.
            public var capturesBodies: Bool

            /// `Authorization`, `Proxy-Authorization`, `Cookie`, `Set-Cookie`, `X-API-Key`, `X-Auth-Token`.
            public static let defaultRedactedHeaderFields: Set<String> = [
                "authorization", "proxy-authorization", "cookie", "set-cookie", "x-api-key", "x-auth-token",
            ]

            public init(
                maxRecords: Int = 100,
                redactedHeaderFields: Set<String> = Self.defaultRedactedHeaderFields,
                hostFilter: Set<String>? = nil,
                maxBodyCaptureSize: Int = 512 * 1024,
                capturesBodies: Bool = true
            ) {
                self.maxRecords = max(1, maxRecords)
                self.redactedHeaderFields = Set(redactedHeaderFields.map { $0.lowercased() })
                self.hostFilter = hostFilter.map { Set($0.map { $0.lowercased() }) }
                self.maxBodyCaptureSize = max(0, maxBodyCaptureSize)
                self.capturesBodies = capturesBodies
            }
        }

        /// The value a redacted header carries in the store.
        public static let redactedValue = "[REDACTED]"

        /// Posted (on the capturing queue) whenever a record is added, updated, or cleared.
        public static let recordsDidChangeNotification = Notification.Name("com.lumi.lumikit.networkLogger.recordsDidChange")

        private struct State {
            var configuration: Configuration?
            var store: LMKNetworkRequestStore?
            var isEnabled = false
        }

        private static let state = OSAllocatedUnfairLock(initialState: State())

        /// Configure the network logger. Call once at app launch (reconfiguring clears the store).
        public static func configure(_ configuration: Configuration) {
            let store = LMKNetworkRequestStore(maxRecords: configuration.maxRecords) {
                NotificationCenter.default.post(name: recordsDidChangeNotification, object: nil)
            }
            state.withLock { state in
                state.configuration = configuration
                state.store = store
            }
        }

        /// Configure with the default capture rules and `maxRecords` retained.
        public static func configure(maxRecords: Int = 100) {
            configure(Configuration(maxRecords: maxRecords))
        }

        /// The active configuration; `nil` before `configure`.
        public static var configuration: Configuration? {
            state.withLock { $0.configuration }
        }

        /// Enable network request logging by registering the URLProtocol.
        ///
        /// - Important: Enabled in DEBUG builds via the `LMK_ENABLE_NETWORK_LOGGING` flag.
        ///   If network logging is not working, ensure the flag is defined in Package.swift.
        public static func enable() {
            guard isConfigured else {
                LMKLogger.warning("Call configure() before enable()", category: .network)
                return
            }
            #if LMK_ENABLE_NETWORK_LOGGING
                URLProtocol.registerClass(LMKNetworkRequestLoggerProtocol.self)
                state.withLock { $0.isEnabled = true }
            #else
                LMKLogger.warning("Network logging disabled (LMK_ENABLE_NETWORK_LOGGING not defined)", category: .network)
            #endif
        }

        /// Disable network request logging by unregistering the URLProtocol.
        public static func disable() {
            #if LMK_ENABLE_NETWORK_LOGGING
                URLProtocol.unregisterClass(LMKNetworkRequestLoggerProtocol.self)
            #endif
            state.withLock { $0.isEnabled = false }
        }

        /// Whether the URLProtocol is registered.
        public static var isEnabled: Bool {
            state.withLock { $0.isEnabled }
        }

        // MARK: - Record Access

        /// All captured network requests (newest first).
        public static var records: [LMKNetworkRequestRecord] {
            internalStore?.records ?? []
        }

        /// Number of captured requests.
        public static var count: Int {
            internalStore?.count ?? 0
        }

        /// Whether network logging is configured.
        public static var isConfigured: Bool {
            state.withLock { $0.configuration != nil }
        }

        /// Clear all captured requests.
        public static func clearRecords() {
            internalStore?.clear()
        }

        // MARK: - Capture rules

        /// `headers` with every field in `configuration.redactedHeaderFields` replaced by `redactedValue`.
        public static func redact(_ headers: [String: String], configuration: Configuration) -> [String: String] {
            guard !configuration.redactedHeaderFields.isEmpty else { return headers }
            var redacted = headers
            for key in headers.keys where configuration.redactedHeaderFields.contains(key.lowercased()) {
                redacted[key] = redactedValue
            }
            return redacted
        }

        /// Whether a request to `url` is captured under `configuration.hostFilter`.
        public static func shouldCapture(url: URL?, configuration: Configuration) -> Bool {
            guard let filter = configuration.hostFilter else { return true }
            guard let host = url?.host?.lowercased(), !host.isEmpty else { return false }
            return filter.contains { allowed in
                host == allowed || host.hasSuffix("." + allowed)
            }
        }

        // MARK: - Internal Access

        /// Internal access for the URLProtocol. Not part of the public API.
        static var internalStore: LMKNetworkRequestStore? {
            state.withLock { $0.store }
        }
    }

    // MARK: - URLProtocol Implementation

    // Internal URLProtocol that intercepts URLSession requests.
    // Not exposed publicly — use `LMKNetworkLogger` instead.
    //
    // - Note: URLProtocol instances are used in a single-threaded context by URLSession's
    //   internal queue, so these properties need no concurrency annotations.
    #if LMK_ENABLE_NETWORK_LOGGING
        @preconcurrency @objc
        final class LMKNetworkRequestLoggerProtocol: URLProtocol, URLSessionDataDelegate, @unchecked Sendable {
            private static let blankURL = URL(string: "about:blank") ?? URL(fileURLWithPath: "/")
            private static let markerKey = "LMKNetworkRequestLogger"

            private var session: URLSession?
            private var dataTask: URLSessionDataTask?
            private var startTime: Date?
            private var requestID: UUID?
            private var responseData = Data()
            private var configuration = LMKNetworkLogger.Configuration()

            /// Serial queue for URLSession delegate callbacks (a private queue can deadlock under
            /// strict concurrency).
            private static let delegateQueue: OperationQueue = {
                let queue = OperationQueue()
                queue.maxConcurrentOperationCount = 1
                queue.name = "com.lumikit.network.logger.delegate"
                return queue
            }()

            override required init(request: URLRequest, cachedResponse: CachedURLResponse?, client: (any URLProtocolClient)?) {
                super.init(request: request, cachedResponse: cachedResponse, client: client)
            }

            // MARK: - URLProtocol Overrides

            override static func canInit(with request: URLRequest) -> Bool {
                // Intercept once only.
                guard property(forKey: markerKey, in: request) == nil else { return false }
                guard let configuration = LMKNetworkLogger.configuration else { return false }
                return LMKNetworkLogger.shouldCapture(url: request.url, configuration: configuration)
            }

            override static func canonicalRequest(for request: URLRequest) -> URLRequest {
                request
            }

            override func startLoading() {
                startTime = Date()
                configuration = LMKNetworkLogger.configuration ?? LMKNetworkLogger.Configuration()

                guard let mutableRequest = (request as NSURLRequest).mutableCopy() as? NSMutableURLRequest else {
                    client?.urlProtocol(self, didFailWithError: NSError(domain: Self.markerKey, code: -1))
                    return
                }
                Self.setProperty(true, forKey: Self.markerKey, in: mutableRequest)

                if let store = LMKNetworkLogger.internalStore {
                    let body = configuration.capturesBodies ? request.httpBody.map { $0.prefix(configuration.maxBodyCaptureSize) } : nil
                    requestID = store.addRequest(
                        request.url ?? Self.blankURL,
                        method: request.httpMethod ?? "GET",
                        headers: LMKNetworkLogger.redact(request.allHTTPHeaderFields ?? [:], configuration: configuration),
                        body: body
                    )
                }

                // The real request runs on a clean configuration so it is not intercepted again.
                let sessionConfiguration = URLSessionConfiguration.ephemeral
                sessionConfiguration.protocolClasses = []
                session = URLSession(configuration: sessionConfiguration, delegate: self, delegateQueue: Self.delegateQueue)
                dataTask = session?.dataTask(with: mutableRequest as URLRequest)
                dataTask?.resume()
            }

            override func stopLoading() {
                dataTask?.cancel()
                session?.invalidateAndCancel()
            }

            // MARK: - URLSessionDataDelegate

            func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
                if configuration.capturesBodies, responseData.count < configuration.maxBodyCaptureSize {
                    responseData.append(data.prefix(configuration.maxBodyCaptureSize - responseData.count))
                }
                client?.urlProtocol(self, didLoad: data)
            }

            func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
                let duration = startTime.map { Date().timeIntervalSince($0) } ?? 0

                if let error {
                    client?.urlProtocol(self, didFailWithError: error)
                    if let id = requestID, let store = LMKNetworkLogger.internalStore {
                        store.updateError(id: id, error: error, duration: duration)
                    }
                } else if let response = task.response as? HTTPURLResponse {
                    client?.urlProtocolDidFinishLoading(self)
                    if let id = requestID, let store = LMKNetworkLogger.internalStore {
                        let headers = Dictionary(
                            uniqueKeysWithValues: response.allHeaderFields.compactMap { key, value in
                                guard let key = key as? String else { return nil as (String, String)? }
                                return (key, "\(value)")
                            }
                        )
                        store.updateResponse(
                            id: id,
                            statusCode: response.statusCode,
                            headers: LMKNetworkLogger.redact(headers, configuration: configuration),
                            body: configuration.capturesBodies ? responseData : nil,
                            duration: duration
                        )
                    }
                } else {
                    client?.urlProtocolDidFinishLoading(self)
                }

                self.session?.finishTasksAndInvalidate()
            }

            func urlSession(
                _ session: URLSession,
                dataTask: URLSessionDataTask,
                didReceive response: URLResponse,
                completionHandler: @escaping (URLSession.ResponseDisposition) -> Void
            ) {
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                completionHandler(.allow)
            }
        }
    #endif // LMK_ENABLE_NETWORK_LOGGING

#endif // DEBUG
