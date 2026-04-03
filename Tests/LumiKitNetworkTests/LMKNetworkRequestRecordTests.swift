//
//  LMKNetworkRequestRecordTests.swift
//  LumiKit
//
//  Tests for LMKNetworkRequestRecord — computed properties, display formatting,
//  body text rendering, and header formatting.
//

#if DEBUG

    import Foundation
    import Testing
    @testable import LumiKitNetwork

    struct LMKNetworkRequestRecordTests {
        // MARK: - Helpers

        private func makeRecord(
            url: String = "https://api.example.com/plants",
            method: String = "GET",
            requestHeaders: [String: String] = [:],
            requestBody: Data? = nil,
            statusCode: Int? = nil,
            responseHeaders: [String: String] = [:],
            responseBody: Data? = nil,
            errorDescription: String? = nil,
            duration: TimeInterval? = nil
        ) throws -> LMKNetworkRequestRecord {
            let parsedURL = try #require(URL(string: url))
            let response: LMKNetworkRequestRecord.LMKResponseData? = if let statusCode {
                .init(statusCode: statusCode, headers: responseHeaders, body: responseBody)
            } else {
                nil
            }
            return LMKNetworkRequestRecord(
                id: UUID(),
                timestamp: Date(),
                request: .init(url: parsedURL, method: method, headers: requestHeaders, body: requestBody),
                response: response,
                errorDescription: errorDescription,
                duration: duration
            )
        }

        // MARK: - isSuccess

        @Test
        func `isSuccess returns true for HTTP 200`() throws {
            let record = try makeRecord(statusCode: 200)
            #expect(record.isSuccess)
        }

        @Test
        func `isSuccess returns true for HTTP 201`() throws {
            let record = try makeRecord(statusCode: 201)
            #expect(record.isSuccess)
        }

        @Test
        func `isSuccess returns true for HTTP 299`() throws {
            let record = try makeRecord(statusCode: 299)
            #expect(record.isSuccess)
        }

        @Test
        func `isSuccess returns false for HTTP 404`() throws {
            let record = try makeRecord(statusCode: 404)
            #expect(!record.isSuccess)
        }

        @Test
        func `isSuccess returns false for HTTP 500`() throws {
            let record = try makeRecord(statusCode: 500)
            #expect(!record.isSuccess)
        }

        @Test
        func `isSuccess returns false when no response`() throws {
            let record = try makeRecord()
            #expect(!record.isSuccess)
        }

        // MARK: - isError

        @Test
        func `isError returns true when errorDescription is set`() throws {
            let record = try makeRecord(errorDescription: "Connection timed out")
            #expect(record.isError)
        }

        @Test
        func `isError returns true for non-2xx status code`() throws {
            let record = try makeRecord(statusCode: 500)
            #expect(record.isError)
        }

        @Test
        func `isError returns false for 2xx with no error`() throws {
            let record = try makeRecord(statusCode: 200)
            #expect(!record.isError)
        }

        @Test
        func `isError returns false when no response and no error`() throws {
            let record = try makeRecord()
            #expect(!record.isError)
        }

        @Test
        func `isError returns true when both error and non-2xx status`() throws {
            let record = try makeRecord(statusCode: 502, errorDescription: "Bad gateway")
            #expect(record.isError)
        }

        // MARK: - displayURL

        @Test
        func `displayURL returns full URL string`() throws {
            let record = try makeRecord(url: "https://api.example.com/v2/plants?page=1")
            #expect(record.displayURL == "https://api.example.com/v2/plants?page=1")
        }

        // MARK: - displayMethod

        @Test
        func `displayMethod returns request method`() throws {
            let record = try makeRecord(method: "POST")
            #expect(record.displayMethod == "POST")
        }

        @Test
        func `displayMethod preserves case`() throws {
            let record = try makeRecord(method: "delete")
            #expect(record.displayMethod == "delete")
        }

        // MARK: - displayStatus

        @Test
        func `displayStatus returns status code as string`() throws {
            let record = try makeRecord(statusCode: 201)
            #expect(record.displayStatus == "201")
        }

        @Test
        func `displayStatus returns Error when errorDescription is set and no response`() throws {
            let record = try makeRecord(errorDescription: "timeout")
            #expect(record.displayStatus == "Error")
        }

        @Test
        func `displayStatus returns Pending when no response and no error`() throws {
            let record = try makeRecord()
            #expect(record.displayStatus == "Pending")
        }

        @Test
        func `displayStatus returns code even when error also set`() throws {
            let record = try makeRecord(statusCode: 503, errorDescription: "Service unavailable")
            #expect(record.displayStatus == "503")
        }

        // MARK: - displayDuration

        @Test
        func `displayDuration formats milliseconds`() throws {
            let record = try makeRecord(duration: 0.123)
            #expect(record.displayDuration == "123ms")
        }

        @Test
        func `displayDuration formats sub-millisecond as 0ms`() throws {
            let record = try makeRecord(duration: 0.0004)
            #expect(record.displayDuration == "0ms")
        }

        @Test
        func `displayDuration formats seconds as milliseconds`() throws {
            let record = try makeRecord(duration: 2.5)
            #expect(record.displayDuration == "2500ms")
        }

        @Test
        func `displayDuration returns dash when nil`() throws {
            let record = try makeRecord()
            #expect(record.displayDuration == "-")
        }

        // MARK: - requestBodyText

        @Test
        func `requestBodyText returns nil when no body`() throws {
            let record = try makeRecord()
            #expect(record.requestBodyText == nil)
        }

        @Test
        func `requestBodyText returns plain text for non-JSON`() throws {
            let body = Data("hello world".utf8)
            let record = try makeRecord(requestBody: body)
            #expect(record.requestBodyText == "hello world")
        }

        @Test
        func `requestBodyText pretty-prints JSON when Content-Type is application/json`() throws {
            let json = Data(#"{"name":"Fern","type":"indoor"}"#.utf8)
            let record = try makeRecord(
                requestHeaders: ["Content-Type": "application/json"],
                requestBody: json
            )
            let text = try #require(record.requestBodyText)
            #expect(text.contains("\"name\""))
            #expect(text.contains("\"Fern\""))
            // Pretty-printed means multiline
            #expect(text.contains("\n"))
        }

        @Test
        func `requestBodyText handles case-insensitive Content-Type header`() throws {
            let json = Data(#"{"a":1}"#.utf8)
            let record = try makeRecord(
                requestHeaders: ["content-type": "application/json"],
                requestBody: json
            )
            let text = try #require(record.requestBodyText)
            #expect(text.contains("\n"))
        }

        @Test
        func `requestBodyText returns binary placeholder for non-UTF8 data`() throws {
            let body = Data([0xFF, 0xFE, 0x00, 0x01])
            let record = try makeRecord(requestBody: body)
            let text = try #require(record.requestBodyText)
            #expect(text.contains("binary data"))
            #expect(text.contains("4 bytes"))
        }

        // MARK: - responseBodyText

        @Test
        func `responseBodyText returns nil when no response`() throws {
            let record = try makeRecord()
            #expect(record.responseBodyText == nil)
        }

        @Test
        func `responseBodyText returns nil when response has no body`() throws {
            let record = try makeRecord(statusCode: 204)
            #expect(record.responseBodyText == nil)
        }

        @Test
        func `responseBodyText returns plain text`() throws {
            let body = Data("OK".utf8)
            let record = try makeRecord(statusCode: 200, responseBody: body)
            #expect(record.responseBodyText == "OK")
        }

        @Test
        func `responseBodyText pretty-prints JSON response`() throws {
            let json = Data(#"{"id":42}"#.utf8)
            let record = try makeRecord(
                statusCode: 200,
                responseHeaders: ["Content-Type": "application/json; charset=utf-8"],
                responseBody: json
            )
            let text = try #require(record.responseBodyText)
            #expect(text.contains("\"id\""))
            #expect(text.contains("42"))
            #expect(text.contains("\n"))
        }

        // MARK: - formattedRequestHeaders()

        @Test
        func `formattedRequestHeaders returns sorted key-value pairs`() throws {
            let record = try makeRecord(
                requestHeaders: [
                    "Content-Type": "application/json",
                    "Authorization": "Bearer token123",
                    "Accept": "application/json",
                ]
            )
            let formatted = record.formattedRequestHeaders()
            let lines = formatted.split(separator: "\n")
            #expect(lines.count == 3)
            #expect(lines[0] == "Accept: application/json")
            #expect(lines[1] == "Authorization: Bearer token123")
            #expect(lines[2] == "Content-Type: application/json")
        }

        @Test
        func `formattedRequestHeaders returns empty string when no headers`() throws {
            let record = try makeRecord()
            #expect(record.formattedRequestHeaders() == "")
        }

        // MARK: - formattedResponseHeaders()

        @Test
        func `formattedResponseHeaders returns sorted key-value pairs`() throws {
            let record = try makeRecord(
                statusCode: 200,
                responseHeaders: [
                    "X-Request-Id": "abc-123",
                    "Content-Length": "42",
                ]
            )
            let formatted = try #require(record.formattedResponseHeaders())
            let lines = formatted.split(separator: "\n")
            #expect(lines.count == 2)
            #expect(lines[0] == "Content-Length: 42")
            #expect(lines[1] == "X-Request-Id: abc-123")
        }

        @Test
        func `formattedResponseHeaders returns nil when no response`() throws {
            let record = try makeRecord()
            #expect(record.formattedResponseHeaders() == nil)
        }

        @Test
        func `formattedResponseHeaders returns empty string when response has no headers`() throws {
            let record = try makeRecord(statusCode: 200)
            let formatted = try #require(record.formattedResponseHeaders())
            #expect(formatted == "")
        }

        // MARK: - statusCode

        @Test
        func `statusCode returns response status code`() throws {
            let record = try makeRecord(statusCode: 404)
            #expect(record.statusCode == 404)
        }

        @Test
        func `statusCode returns nil when no response`() throws {
            let record = try makeRecord()
            #expect(record.statusCode == nil)
        }

        // MARK: - Identifiable

        @Test
        func `Records have unique IDs`() throws {
            let record1 = try makeRecord()
            let record2 = try makeRecord()
            #expect(record1.id != record2.id)
        }
    }

#endif
