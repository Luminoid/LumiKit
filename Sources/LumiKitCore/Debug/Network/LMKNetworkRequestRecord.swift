//
//  LMKNetworkRequestRecord.swift
//  LumiKit
//
//  Captures HTTP request/response details for debugging.
//  DEBUG builds only — zero footprint in release.
//

#if DEBUG

    import Foundation

    /// Single network request/response captured for debugging.
    public struct LMKNetworkRequestRecord: Identifiable, Sendable {
        public let id: UUID
        public let timestamp: Date
        public let request: LMKRequestData
        public let response: LMKResponseData?
        public let error: Error?
        public let duration: TimeInterval?

        public struct LMKRequestData: Sendable {
            public let url: URL
            public let method: String
            public let headers: [String: String]
            public let body: Data?
        }

        public struct LMKResponseData: Sendable {
            public let statusCode: Int
            public let headers: [String: String]
            public let body: Data?
        }

        // MARK: - Computed Properties

        public var statusCode: Int? { response?.statusCode }

        public var isSuccess: Bool {
            guard let code = statusCode else { return false }
            return (200 ... 299).contains(code)
        }

        public var isError: Bool {
            error != nil || (statusCode != nil && !isSuccess)
        }

        public var displayURL: String {
            request.url.absoluteString
        }

        public var displayMethod: String {
            request.method
        }

        public var displayStatus: String {
            if let code = statusCode {
                "\(code)"
            } else if error != nil {
                "Error"
            } else {
                "Pending"
            }
        }

        public var displayDuration: String {
            guard let duration else { return "-" }
            return String(format: "%.0fms", duration * 1000)
        }

        public var requestBodyText: String? {
            guard let data = request.body else { return nil }
            return formatBodyData(data, contentType: request.headers["Content-Type"])
        }

        public var responseBodyText: String? {
            guard let data = response?.body else { return nil }
            return formatBodyData(data, contentType: response?.headers["Content-Type"])
        }

        // MARK: - Helpers

        private func formatBodyData(_ data: Data, contentType: String?) -> String {
            // Try to pretty-print JSON
            if let contentType, contentType.contains("json"),
               let json = try? JSONSerialization.jsonObject(with: data),
               let prettyData = try? JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys]),
               let prettyString = String(data: prettyData, encoding: .utf8) {
                return prettyString
            }

            // Fall back to UTF-8 string
            if let text = String(data: data, encoding: .utf8) {
                return text
            }

            // Binary data
            return "<binary data, \(data.count) bytes>"
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
