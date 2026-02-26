//
//  LMKNetworkLogger.swift
//  LumiKit
//
//  Network debugging system for the Lumi ecosystem.
//  DEBUG builds only — zero footprint in release.
//

#if DEBUG

    @preconcurrency import Foundation

    /// Network debugging system for the Lumi ecosystem.
    ///
    /// Configure once at app launch:
    /// ```swift
    /// LMKNetworkLogger.configure(maxRecords: 100)
    /// LMKNetworkLogger.enable()
    ///
    /// // In services:
    /// let config = URLSessionConfiguration.default.withNetworkLogging()
    /// ```
    public enum LMKNetworkLogger {
        // MARK: - Configuration

        /// Internal request store. Set via `configure()`.
        ///
        /// - Important: Must only be written from the main thread during app launch.
        ///   Read access is thread-safe via `LMKNetworkRequestStore`'s internal lock.
        private nonisolated(unsafe) static var store: LMKNetworkRequestStore?

        /// Whether the logger has been configured.
        private nonisolated(unsafe) static var isConfigured = false

        /// Configure the network logger. Call once at app launch.
        /// - Parameter maxRecords: Maximum number of requests to retain (default 100).
        public static func configure(maxRecords: Int = 100) {
            Self.store = LMKNetworkRequestStore(maxRecords: maxRecords)
            Self.isConfigured = true
        }

        /// Enable network request logging by registering the URLProtocol.
        ///
        /// - Important: Enabled in DEBUG builds via LMK_ENABLE_NETWORK_LOGGING flag.
        ///   If network logging is not working, ensure the flag is defined in Package.swift.
        public static func enable() {
            guard isConfigured else {
                print("[LMKNetworkLogger] Warning: Call configure() before enable()")
                return
            }
            #if LMK_ENABLE_NETWORK_LOGGING
            URLProtocol.registerClass(LMKNetworkRequestLoggerProtocol.self)
            #else
            print("[LMKNetworkLogger] Warning: Network logging disabled (LMK_ENABLE_NETWORK_LOGGING not defined)")
            #endif
        }

        /// Disable network request logging by unregistering the URLProtocol.
        public static func disable() {
            #if LMK_ENABLE_NETWORK_LOGGING
            URLProtocol.unregisterClass(LMKNetworkRequestLoggerProtocol.self)
            #endif
        }

        // MARK: - Record Access

        /// All captured network requests (newest first).
        public static var records: [LMKNetworkRequestRecord] {
            store?.records ?? []
        }

        /// Number of captured requests.
        public static var count: Int {
            store?.count ?? 0
        }

        /// Whether network logging is configured.
        public static var isEnabled: Bool {
            isConfigured
        }

        /// Clear all captured requests.
        public static func clearRecords() {
            store?.clear()
        }

        // MARK: - Internal Access

        /// Internal access for URLProtocol. Not part of public API.
        fileprivate static var internalStore: LMKNetworkRequestStore? {
            store
        }
    }

    // MARK: - URLProtocol Implementation

    /// Internal URLProtocol that intercepts all URLSession requests.
    /// Not exposed publicly — use `LMKNetworkLogger` API instead.
    ///
    /// - Important: Enabled in DEBUG builds via LMK_ENABLE_NETWORK_LOGGING flag.
    ///   The @preconcurrency attribute suppresses Swift 6 strict concurrency warnings
    ///   for URLProtocol subclass usage.
    ///
    /// - Note: URLProtocol instances are used in a single-threaded context by
    ///   URLSession's internal queue, so these properties don't need concurrency
    ///   annotations. Regular instance variables are safe here.
    #if LMK_ENABLE_NETWORK_LOGGING
    @preconcurrency @objc
    final class LMKNetworkRequestLoggerProtocol: URLProtocol, URLSessionDataDelegate, @unchecked Sendable {
        private var session: URLSession?
        private var dataTask: URLSessionDataTask?
        private var startTime: Date?
        private var requestID: UUID?
        private var responseData = Data()

        /// Serial queue for URLSession delegate callbacks to avoid Swift 6 strict concurrency deadlocks.
        /// Using delegateQueue: nil causes URLSession to create a private queue that can deadlock.
        private static let delegateQueue: OperationQueue = {
            let queue = OperationQueue()
            queue.maxConcurrentOperationCount = 1 // Serial queue
            queue.name = "com.lumikit.network.logger.delegate"
            return queue
        }()

        override required init(request: URLRequest, cachedResponse: CachedURLResponse?, client: (any URLProtocolClient)?) {
            super.init(request: request, cachedResponse: cachedResponse, client: client)
        }

        // MARK: - URLProtocol Overrides

        override class func canInit(with request: URLRequest) -> Bool {
            // Avoid infinite loops — only intercept once
            guard property(forKey: "LMKNetworkRequestLogger", in: request) == nil else {
                return false
            }
            return true
        }

        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            request
        }

        override func startLoading() {
            startTime = Date()

            // Mark request to avoid re-intercepting
            guard let mutableRequest = (request as NSURLRequest).mutableCopy() as? NSMutableURLRequest else {
                client?.urlProtocol(self, didFailWithError: NSError(domain: "LMKNetworkRequestLogger", code: -1))
                return
            }
            LMKNetworkRequestLoggerProtocol.setProperty(true, forKey: "LMKNetworkRequestLogger", in: mutableRequest)

            // Capture request details (thread-safe, no @MainActor needed)
            if let store = LMKNetworkLogger.internalStore {
                requestID = store.addRequest(
                    request.url ?? URL(string: "about:blank")!,
                    method: request.httpMethod ?? "GET",
                    headers: request.allHTTPHeaderFields ?? [:],
                    body: request.httpBody
                )
            }

            // Perform the actual request with a clean configuration (no URLProtocol interception)
            let config = URLSessionConfiguration.ephemeral
            config.protocolClasses = [] // Critical: prevent re-interception by URLProtocol
            session = URLSession(configuration: config, delegate: self, delegateQueue: Self.delegateQueue)
            dataTask = session?.dataTask(with: mutableRequest as URLRequest)
            dataTask?.resume()
        }

        override func stopLoading() {
            dataTask?.cancel()
            session?.invalidateAndCancel()
        }

        // MARK: - URLSessionDataDelegate
        func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
            responseData.append(data)
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
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                client?.urlProtocolDidFinishLoading(self)
                if let id = requestID, let store = LMKNetworkLogger.internalStore {
                    store.updateResponse(
                        id: id,
                        statusCode: response.statusCode,
                        headers: response.allHeaderFields as? [String: String] ?? [:],
                        body: responseData,
                        duration: duration
                    )
                }
            } else {
                client?.urlProtocolDidFinishLoading(self)
            }
        }

        func urlSession(
            _ session: URLSession,
            dataTask: URLSessionDataTask,
            didReceive response: URLResponse,
            completionHandler: @escaping (URLSession.ResponseDisposition) -> Void
        ) {
            completionHandler(.allow)
        }
    }
    #endif // LMK_ENABLE_NETWORK_LOGGING

#endif // DEBUG
