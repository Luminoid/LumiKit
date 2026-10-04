//
//  LMKNetworkRequestRecord.swift
//  LumiKit
//
//  Captures HTTP request/response details for debugging.
//  Debug builds only (`LMK_ENABLE_NETWORK_LOGGING`) — zero footprint in release.
//

#if LMK_ENABLE_NETWORK_LOGGING

    import Foundation

    /// Single network request/response captured for debugging.
    public struct LMKNetworkRequestRecord: Identifiable, Sendable, Equatable {
        public let id: UUID
        public let timestamp: Date
        public let request: Request
        public let response: Response?
        public let errorDescription: String?
        public let duration: TimeInterval?

        public struct Request: Sendable, Equatable {
            public let url: URL
            public let method: String
            public let headers: [String: String]
            /// The body as captured, cut at `maxBodyCaptureSize`; `nil` when there was none or capture is off.
            public let body: Data?
            /// Whether `body` is the start of a longer body.
            public let isBodyTruncated: Bool

            init(url: URL, method: String, headers: [String: String], body: Data?, isBodyTruncated: Bool = false) {
                self.url = url
                self.method = method
                self.headers = headers
                self.body = body
                self.isBodyTruncated = isBodyTruncated
            }
        }

        public struct Response: Sendable, Equatable {
            public let statusCode: Int
            public let headers: [String: String]
            /// The body as captured, cut at `maxBodyCaptureSize`; `nil` when there was none or capture is off.
            public let body: Data?
            /// Whether `body` is the start of a longer body.
            public let isBodyTruncated: Bool

            init(statusCode: Int, headers: [String: String], body: Data?, isBodyTruncated: Bool = false) {
                self.statusCode = statusCode
                self.headers = headers
                self.body = body
                self.isBodyTruncated = isBodyTruncated
            }
        }

        /// Where a request stands, as the history marks it.
        public enum Outcome: Sendable, Hashable {
            /// Neither a response nor an error has landed yet.
            case pending
            /// A 2xx response, or 304 Not Modified (the cached copy is still good).
            case success
            /// Any other 3xx response: a redirect the session followed, whose next hop is a record
            /// of its own, or one it refused.
            case redirect
            /// The request failed, or the response status is outside 2xx and 3xx.
            case error
        }

        // MARK: - Computed Properties

        public var statusCode: Int? { response?.statusCode }

        /// The request's outcome. A transport error outranks a status that arrived before it.
        public var outcome: Outcome {
            if errorDescription != nil { return .error }
            guard let code = statusCode else { return .pending }
            switch code {
            case 200 ... 299, 304: return .success
            case 300 ... 399: return .redirect
            default: return .error
            }
        }

        /// A 2xx response, or 304 Not Modified, with no error.
        public var isSuccess: Bool { outcome == .success }

        /// A 3xx response other than 304, with no error.
        public var isRedirect: Bool { outcome == .redirect }

        /// A transport error, or a response status outside 2xx and 3xx.
        public var isError: Bool { outcome == .error }

        /// The request URL, with redacted query values shown as `LMKNetworkLogger.redactedValue`.
        public var displayURL: String {
            request.url.absoluteString.replacingOccurrences(of: LMKNetworkLogger.redactedValueQueryEncoded, with: LMKNetworkLogger.redactedValue)
        }

        public var displayMethod: String {
            request.method
        }

        public var displayStatus: String {
            if let code = statusCode {
                "\(code)"
            } else if errorDescription != nil {
                LMKLocalized("networkRecord.errorStatus")
            } else {
                LMKLocalized("networkRecord.pendingStatus")
            }
        }

        /// The duration in whole milliseconds, in the user's locale ("250ms", "2,500ms"); "-" while pending.
        public var displayDuration: String {
            guard let duration else { return "-" }
            let milliseconds = Duration.milliseconds(Int64((duration * 1000).rounded()))
            return milliseconds.formatted(.units(allowed: [.milliseconds], width: .narrow))
        }

        public var requestBodyText: String? {
            guard let data = request.body else { return nil }
            return formatBodyData(data, contentType: headerValue(for: "Content-Type", in: request.headers), isTruncated: request.isBodyTruncated)
        }

        public var responseBodyText: String? {
            guard let response, let data = response.body else { return nil }
            return formatBodyData(data, contentType: headerValue(for: "Content-Type", in: response.headers), isTruncated: response.isBodyTruncated)
        }

        // MARK: - Helpers

        /// Whether both records carry the same result (a record only changes when its response or
        /// error lands): status, error, and duration, without comparing bodies.
        func hasSameResult(as other: Self) -> Bool {
            statusCode == other.statusCode && errorDescription == other.errorDescription && duration == other.duration
        }

        private func headerValue(for key: String, in headers: [String: String]) -> String? {
            headers.first(where: { $0.key.caseInsensitiveCompare(key) == .orderedSame })?.value
        }

        private func formatBodyData(_ data: Data, contentType: String?, isTruncated: Bool) -> String {
            // Try to pretty-print JSON
            if let contentType, contentType.contains("json"),
               let json = try? JSONSerialization.jsonObject(with: data),
               let prettyData = try? JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys]),
               let prettyString = String(data: prettyData, encoding: .utf8) {
                return prettyString
            }

            // Fall back to UTF-8 text. A truncated body may end inside a multi-byte character, so
            // up to three trailing bytes are dropped before the data counts as binary.
            let trailingBytesToTry = isTruncated ? min(3, data.count) : 0
            for dropped in 0 ... trailingBytesToTry {
                if let text = String(data: data.dropLast(dropped), encoding: .utf8) {
                    return text
                }
            }

            // Binary data
            return String(format: LMKLocalized("networkRecord.binaryBody"), Int64(data.count))
        }

        public func formattedRequestHeaders() -> String {
            request.headers.sorted { $0.key < $1.key }
                .map { "\($0.key): \($0.value)" }
                .joined(separator: "\n")
        }

        public func formattedResponseHeaders() -> String? {
            response?.headers.sorted { $0.key < $1.key }
                .map { "\($0.key): \($0.value)" }
                .joined(separator: "\n")
        }
    }

#endif
