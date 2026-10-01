//
//  LMKNetworkLogger.swift
//  LumiKit
//
//  Network debugging system for the Lumi ecosystem.
//  Debug builds only (`LMK_ENABLE_NETWORK_LOGGING`) — zero footprint in release.
//

#if LMK_ENABLE_NETWORK_LOGGING

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
    /// Credentials never reach the store: the header fields in `redactedHeaderFields` and the query
    /// items in `redactedQueryItems` (a URL's password too) are replaced with `redactedValue` at
    /// capture time.
    ///
    /// The logger is a `URLProtocol`, so a logged request runs on the logger's own session (a
    /// `.default` configuration: the shared cookie jar, cache, and credential storage). The request
    /// arrives with the app session's `httpAdditionalHeaders` already applied; redirects are
    /// reported back to the app session, which decides whether to follow them. What does not carry
    /// over: a session's own cookie storage, cache, credential storage, and timeouts, and its
    /// delegate's authentication handling (certificate pinning, client certificates), which the
    /// system's default handling answers instead.
    public enum LMKNetworkLogger {
        // MARK: - Configuration

        /// What the logger captures and keeps. Every field normalizes on assignment: header fields,
        /// query items, and hosts are lowercased, and the counts are clamped.
        public struct Configuration: Sendable, Equatable {
            /// Requests retained (oldest evicted first). Default 100; values below 1 keep one.
            public var maxRecords: Int {
                didSet { maxRecords = max(1, maxRecords) }
            }

            /// Header fields whose values are replaced with `redactedValue`, compared case-insensitively.
            public var redactedHeaderFields: Set<String> {
                didSet { redactedHeaderFields = Self.lowercased(redactedHeaderFields) }
            }

            /// Query item names whose values are replaced with `redactedValue` in the stored URL,
            /// compared case-insensitively.
            public var redactedQueryItems: Set<String> {
                didSet { redactedQueryItems = Self.lowercased(redactedQueryItems) }
            }

            /// Hosts to capture (exact host or a parent domain, so `example.com` covers
            /// `api.example.com`); `nil` captures every host.
            public var hostFilter: Set<String>? {
                didSet { hostFilter = hostFilter.map(Self.lowercased) }
            }

            /// Bytes of each body kept. Default 512 KB; a body past the cap is stored cut, flagged as truncated.
            public var maxBodyCaptureSize: Int {
                didSet { maxBodyCaptureSize = max(0, maxBodyCaptureSize) }
            }

            /// Whether request and response bodies are captured at all. Default `true`.
            public var capturesBodies: Bool

            /// `Authorization`, `Proxy-Authorization`, `Cookie`, `Set-Cookie`, and the API-key headers of
            /// the common providers (`X-API-Key`, `Api-Key`, `X-Goog-Api-Key`, `X-Auth-Token`,
            /// `X-Access-Token`, `X-Amz-Security-Token`, `X-CSRF-Token`, `X-XSRF-Token`,
            /// `Ocp-Apim-Subscription-Key`, `X-Functions-Key`).
            public static let defaultRedactedHeaderFields: Set<String> = [
                "authorization", "proxy-authorization", "cookie", "set-cookie",
                "x-api-key", "api-key", "x-goog-api-key", "x-auth-token", "x-access-token",
                "x-amz-security-token", "x-csrf-token", "x-xsrf-token", "ocp-apim-subscription-key", "x-functions-key",
            ]

            /// The query items that carry keys, tokens, and signatures: `key`, `api_key`, `apikey`,
            /// `api-key`, `access_token`, `refresh_token`, `id_token`, `token`, `auth`, `signature`,
            /// `sig`, `client_secret`, `secret`, `password`, and the signed-URL items of S3 and GCS.
            public static let defaultRedactedQueryItems: Set<String> = [
                "key", "api_key", "apikey", "api-key", "access_token", "refresh_token", "id_token", "token", "auth",
                "signature", "sig", "client_secret", "secret", "password",
                "x-amz-signature", "x-amz-security-token", "x-amz-credential", "x-goog-signature", "x-goog-credential",
            ]

            public init(
                maxRecords: Int = 100,
                redactedHeaderFields: Set<String> = Self.defaultRedactedHeaderFields,
                redactedQueryItems: Set<String> = Self.defaultRedactedQueryItems,
                hostFilter: Set<String>? = nil,
                maxBodyCaptureSize: Int = 512 * 1024,
                capturesBodies: Bool = true
            ) {
                self.maxRecords = max(1, maxRecords)
                self.redactedHeaderFields = Self.lowercased(redactedHeaderFields)
                self.redactedQueryItems = Self.lowercased(redactedQueryItems)
                self.hostFilter = hostFilter.map(Self.lowercased)
                self.maxBodyCaptureSize = max(0, maxBodyCaptureSize)
                self.capturesBodies = capturesBodies
            }

            private static func lowercased(_ names: Set<String>) -> Set<String> {
                Set(names.map { $0.lowercased() })
            }
        }

        /// The value a redacted header or query item carries in the store.
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

        /// Enable network request logging by registering the URLProtocol. Sessions built with
        /// `lmk_enableNetworkLogging()` capture only while the logger is enabled.
        ///
        /// - Important: The whole module compiles only under `LMK_ENABLE_NETWORK_LOGGING`, which
        ///   the package defines for debug configurations.
        public static func enable() {
            guard isConfigured else {
                LMKLogger.warning("Call configure() before enable()", category: .network)
                return
            }
            URLProtocol.registerClass(LMKNetworkRequestLoggerProtocol.self)
            state.withLock { $0.isEnabled = true }
        }

        /// Disable network request logging by unregistering the URLProtocol.
        public static func disable() {
            URLProtocol.unregisterClass(LMKNetworkRequestLoggerProtocol.self)
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

        /// The captured request with `id`, if it is still retained.
        public static func record(id: UUID) -> LMKNetworkRequestRecord? {
            internalStore?.record(id: id)
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
        /// A `Location` header's query items are redacted like a URL's.
        public static func redact(_ headers: [String: String], configuration: Configuration) -> [String: String] {
            var redacted = headers
            for (key, value) in headers {
                let field = key.lowercased()
                if configuration.redactedHeaderFields.contains(field) {
                    redacted[key] = redactedValue
                } else if field == "location", let url = URL(string: value) {
                    redacted[key] = redact(url, configuration: configuration).absoluteString
                }
            }
            return redacted
        }

        /// `url` with the value of every query item named in `configuration.redactedQueryItems`, and
        /// any password, replaced by `redactedValue` (percent-encoded in the stored URL); every other
        /// part of the URL is kept byte for byte.
        public static func redact(_ url: URL, configuration: Configuration) -> URL {
            guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return url }
            var changed = false
            if components.percentEncodedPassword != nil {
                components.percentEncodedPassword = redactedValueQueryEncoded
                changed = true
            }
            if !configuration.redactedQueryItems.isEmpty, let items = components.percentEncodedQueryItems {
                var queryChanged = false
                let redactedItems = items.map { item -> URLQueryItem in
                    let name = (item.name.removingPercentEncoding ?? item.name).lowercased()
                    guard item.value != nil, configuration.redactedQueryItems.contains(name) else { return item }
                    queryChanged = true
                    return URLQueryItem(name: item.name, value: redactedValueQueryEncoded)
                }
                if queryChanged {
                    components.percentEncodedQueryItems = redactedItems
                    changed = true
                }
            }
            guard changed, let redacted = components.url else { return url }
            return redacted
        }

        /// `redactedValue` as it appears inside a URL.
        static let redactedValueQueryEncoded = redactedValue.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? redactedValue

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

        /// The configuration while the logger is enabled; `nil` otherwise, so a disabled logger
        /// intercepts nothing even on sessions that list the protocol.
        static var activeConfiguration: Configuration? {
            state.withLock { $0.isEnabled ? $0.configuration : nil }
        }

        // MARK: - Change observation

        /// Delivers `recordsDidChangeNotification` to the main actor, one call per burst: a
        /// notification that arrives while a delivery is pending is folded into it. The observer
        /// unregisters itself and drops the pending delivery when it is released.
        final class ChangeObserver: NSObject, Sendable {
            private let onChange: @MainActor @Sendable () -> Void
            private let pendingDelivery = OSAllocatedUnfairLock<Task<Void, Never>?>(initialState: nil)

            init(onChange: @escaping @MainActor @Sendable () -> Void) {
                self.onChange = onChange
                super.init()
                NotificationCenter.default.addObserver(self, selector: #selector(recordsDidChange), name: LMKNetworkLogger.recordsDidChangeNotification, object: nil)
            }

            deinit {
                pendingDelivery.withLock { $0?.cancel() }
            }

            /// Whether a delivery is scheduled and has not run yet.
            var hasPendingDelivery: Bool {
                pendingDelivery.withLock { $0 != nil }
            }

            @objc private func recordsDidChange() {
                pendingDelivery.withLock { task in
                    guard task == nil else { return }
                    task = Task { @MainActor [weak self] in
                        guard let self else { return }
                        pendingDelivery.withLock { $0 = nil }
                        guard !Task.isCancelled else { return }
                        onChange()
                    }
                }
            }
        }
    }

    // MARK: - URLProtocol Implementation

    /// Internal URLProtocol that intercepts URLSession requests. Not exposed publicly: use
    /// `LMKNetworkLogger` instead.
    ///
    /// Every intercepted request runs on one shared inner session, so connections are reused
    /// across them; the session's delegate routes each task's callbacks back to the protocol
    /// instance that started it. Instance state is written in `startLoading` before the task
    /// resumes and afterwards only touched on the inner session's serial delegate queue.
    @preconcurrency @objc
    final class LMKNetworkRequestLoggerProtocol: URLProtocol, @unchecked Sendable {
        private static let blankURL = URL(string: "about:blank") ?? URL(fileURLWithPath: "/")
        private static let markerKey = "LMKNetworkRequestLogger"

        /// Streamed request bodies up to this size (with a `Content-Length`) are read into memory so
        /// they can be captured and replayed; larger or unsized streams are forwarded as they are.
        static let maxBodyDrainSize = 10 * 1024 * 1024

        private static let innerDelegate = LMKNetworkLoggerSessionDelegate()

        /// The session every intercepted request runs on. `.default` keeps the shared cookie jar,
        /// cache, and credential storage the app's own default sessions use, so a logged request still
        /// carries its cookies; `protocolClasses = []` and the marker property keep the logger out of it.
        private static let innerSession: URLSession = {
            let configuration = URLSessionConfiguration.default
            configuration.protocolClasses = []
            // Serial queue for the delegate callbacks (a private queue can deadlock under strict concurrency).
            let queue = OperationQueue()
            queue.maxConcurrentOperationCount = 1
            queue.name = "com.lumikit.network.logger.delegate"
            return URLSession(configuration: configuration, delegate: innerDelegate, delegateQueue: queue)
        }()

        private var dataTask: URLSessionDataTask?
        private var startTime = Date()
        private var requestID: UUID?
        private var configuration = LMKNetworkLogger.Configuration()
        private var responseData = Data()
        private var responseByteCount = 0
        private var didRedirect = false
        private let isStopped = OSAllocatedUnfairLock(initialState: false)

        override required init(request: URLRequest, cachedResponse: CachedURLResponse?, client: (any URLProtocolClient)?) {
            super.init(request: request, cachedResponse: cachedResponse, client: client)
        }

        // MARK: - URLProtocol Overrides

        override static func canInit(with request: URLRequest) -> Bool {
            // Intercept once only, HTTP only, and only while the logger is enabled.
            guard property(forKey: markerKey, in: request) == nil,
                  let scheme = request.url?.scheme?.lowercased(), scheme == "http" || scheme == "https",
                  let configuration = LMKNetworkLogger.activeConfiguration else { return false }
            return LMKNetworkLogger.shouldCapture(url: request.url, configuration: configuration)
        }

        override static func canonicalRequest(for request: URLRequest) -> URLRequest {
            request
        }

        override func startLoading() {
            startTime = Date()
            configuration = LMKNetworkLogger.activeConfiguration ?? LMKNetworkLogger.Configuration()

            guard let forwarded = (request as NSURLRequest).mutableCopy() as? NSMutableURLRequest else {
                client?.urlProtocol(self, didFailWithError: URLError(.unknown))
                return
            }
            Self.setProperty(true, forKey: Self.markerKey, in: forwarded)

            let body: Data?
            do {
                body = try Self.drainBody(of: request, into: forwarded)
            } catch {
                client?.urlProtocol(self, didFailWithError: error)
                return
            }

            if let store = LMKNetworkLogger.internalStore {
                let captured = configuration.capturesBodies ? body?.prefix(configuration.maxBodyCaptureSize) : nil
                requestID = store.addRequest(
                    LMKNetworkLogger.redact(request.url ?? Self.blankURL, configuration: configuration),
                    method: request.httpMethod ?? "GET",
                    headers: LMKNetworkLogger.redact(request.allHTTPHeaderFields ?? [:], configuration: configuration),
                    body: captured,
                    isBodyTruncated: captured.map { $0.count < (body?.count ?? 0) } ?? false
                )
            }

            let dataTask = Self.innerSession.dataTask(with: forwarded as URLRequest)
            self.dataTask = dataTask
            Self.innerDelegate.register(self, for: dataTask)
            dataTask.resume()
        }

        override func stopLoading() {
            isStopped.withLock { $0 = true }
            dataTask?.cancel()
        }

        /// Reads a streamed body into `forwarded.httpBody` so it can be captured and, on a redirect,
        /// replayed. A stream without a `Content-Length`, or one above `maxBodyDrainSize`, stays a
        /// stream on the forwarded request and is not captured.
        private static func drainBody(of request: URLRequest, into forwarded: NSMutableURLRequest) throws -> Data? {
            if let body = request.httpBody { return body }
            guard let stream = request.httpBodyStream else { return nil }
            guard let declared = request.value(forHTTPHeaderField: "Content-Length").flatMap(Int.init), (0 ... maxBodyDrainSize).contains(declared) else {
                return nil
            }
            var data = Data(capacity: declared)
            let bufferSize = 64 * 1024
            var buffer = [UInt8](repeating: 0, count: bufferSize)
            stream.open()
            defer { stream.close() }
            while data.count < declared {
                let read = stream.read(&buffer, maxLength: min(bufferSize, declared - data.count))
                if read < 0 { throw stream.streamError ?? URLError(.cannotDecodeRawData) }
                if read == 0 { break }
                data.append(buffer, count: read)
            }
            forwarded.httpBodyStream = nil
            forwarded.httpBody = data
            return data
        }

        // MARK: - Inner session callbacks (serial delegate queue)

        /// The inner session never follows a redirect itself. The 3xx is handed to the client's
        /// session, which decides: a followed redirect comes back as a fresh request (the marker is
        /// off the copy it receives) and this load is stopped; a refused one keeps this load going,
        /// so the 3xx response and body reach the client as the task's result, as they would
        /// without the logger.
        func innerWillRedirect(to newRequest: URLRequest, response: HTTPURLResponse) {
            didRedirect = true
            guard let redirected = (newRequest as NSURLRequest).mutableCopy() as? NSMutableURLRequest else { return }
            Self.removeProperty(forKey: Self.markerKey, in: redirected)
            guard !isStopped.withLock({ $0 }) else { return }
            client?.urlProtocol(self, wasRedirectedTo: redirected as URLRequest, redirectResponse: response)
        }

        func innerDidReceive(_ response: URLResponse, completionHandler: (URLSession.ResponseDisposition) -> Void) {
            if !isStopped.withLock({ $0 }) {
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }
            completionHandler(.allow)
        }

        func innerDidReceive(_ data: Data) {
            responseByteCount += data.count
            if configuration.capturesBodies, responseData.count < configuration.maxBodyCaptureSize {
                responseData.append(data.prefix(configuration.maxBodyCaptureSize - responseData.count))
            }
            if !isStopped.withLock({ $0 }) {
                client?.urlProtocol(self, didLoad: data)
            }
        }

        func innerDidComplete(_ task: URLSessionTask, error: (any Error)?) {
            let stopped = isStopped.withLock { $0 }
            if let error {
                if !stopped { client?.urlProtocol(self, didFailWithError: error) }
                // A load stopped because its redirect was followed still records the 3xx it got.
                if didRedirect, let response = task.response as? HTTPURLResponse {
                    recordResponse(response, body: configuration.capturesBodies ? responseData : nil)
                } else if let id = requestID, let store = LMKNetworkLogger.internalStore {
                    store.updateError(id: id, error: error, duration: Date().timeIntervalSince(startTime))
                }
                return
            }
            if !stopped { client?.urlProtocolDidFinishLoading(self) }
            if let response = task.response as? HTTPURLResponse {
                recordResponse(response, body: configuration.capturesBodies ? responseData : nil)
            }
        }

        private func recordResponse(_ response: HTTPURLResponse, body: Data?) {
            guard let id = requestID, let store = LMKNetworkLogger.internalStore else { return }
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
                body: body,
                isBodyTruncated: body != nil && responseByteCount > responseData.count,
                duration: Date().timeIntervalSince(startTime)
            )
        }
    }

    /// The inner session's delegate: hands each task's callbacks to the protocol instance that
    /// started it and drops the mapping when the task completes.
    private final class LMKNetworkLoggerSessionDelegate: NSObject, URLSessionDataDelegate, @unchecked Sendable {
        private let handlers = OSAllocatedUnfairLock(initialState: [Int: LMKNetworkRequestLoggerProtocol]())

        func register(_ handler: LMKNetworkRequestLoggerProtocol, for task: URLSessionTask) {
            handlers.withLock { $0[task.taskIdentifier] = handler }
        }

        private func handler(for task: URLSessionTask) -> LMKNetworkRequestLoggerProtocol? {
            handlers.withLock { $0[task.taskIdentifier] }
        }

        func urlSession(
            _ session: URLSession,
            task: URLSessionTask,
            willPerformHTTPRedirection response: HTTPURLResponse,
            newRequest: URLRequest,
            completionHandler: @escaping (URLRequest?) -> Void
        ) {
            handler(for: task)?.innerWillRedirect(to: newRequest, response: response)
            completionHandler(nil)
        }

        func urlSession(
            _ session: URLSession,
            dataTask: URLSessionDataTask,
            didReceive response: URLResponse,
            completionHandler: @escaping (URLSession.ResponseDisposition) -> Void
        ) {
            guard let handler = handler(for: dataTask) else {
                completionHandler(.cancel)
                return
            }
            handler.innerDidReceive(response, completionHandler: completionHandler)
        }

        func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
            handler(for: dataTask)?.innerDidReceive(data)
        }

        func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: (any Error)?) {
            let handler = handlers.withLock { $0.removeValue(forKey: task.taskIdentifier) }
            handler?.innerDidComplete(task, error: error)
        }
    }

#endif // LMK_ENABLE_NETWORK_LOGGING
