//
//  LMKLocalHTTPServer.swift
//  LumiKit
//
//  A loopback HTTP/1.1 server for end-to-end logger tests: real sockets, so the
//  URLProtocol, the inner session, cookies, and redirects behave as they do in an app.
//

import Foundation
import Network
import os

/// Serves one canned response per request on 127.0.0.1 and remembers what it received.
final class LMKLocalHTTPServer: @unchecked Sendable {
    struct Request {
        let method: String
        let path: String
        let headers: [String: String]
        let body: Data

        func header(_ name: String) -> String? {
            headers.first { $0.key.caseInsensitiveCompare(name) == .orderedSame }?.value
        }
    }

    struct Response {
        var status = 200
        var reason = "OK"
        var headers: [String: String] = [:]
        var body = Data()

        static func text(_ text: String, status: Int = 200, headers: [String: String] = [:]) -> Self {
            var response = Self(status: status, reason: status == 200 ? "OK" : "Status", headers: headers, body: Data(text.utf8))
            response.headers["Content-Type"] = "text/plain; charset=utf-8"
            return response
        }

        static func redirect(to location: String, status: Int = 302, body: String = "") -> Self {
            Self(status: status, reason: "Found", headers: ["Location": location, "Content-Type": "text/plain"], body: Data(body.utf8))
        }
    }

    private let listener: NWListener
    private let queue = DispatchQueue(label: "com.lumikit.tests.localhttp")
    private let received = OSAllocatedUnfairLock(initialState: [Request]())
    private let handler: @Sendable (Request) -> Response
    private(set) var port: UInt16 = 0

    /// Every request received so far, in arrival order.
    var requests: [Request] { received.withLock { $0 } }

    private init(handler: @escaping @Sendable (Request) -> Response) throws {
        self.handler = handler
        let parameters = NWParameters.tcp
        parameters.requiredLocalEndpoint = NWEndpoint.hostPort(host: "127.0.0.1", port: .any)
        listener = try NWListener(using: parameters)
    }

    /// Starts a server on a free loopback port and returns it once it is listening.
    static func start(handler: @escaping @Sendable (Request) -> Response) async throws -> LMKLocalHTTPServer {
        let server = try LMKLocalHTTPServer(handler: handler)
        try await server.listen()
        return server
    }

    func stop() {
        listener.cancel()
    }

    /// The base URL of the server ("http://127.0.0.1:<port>").
    var baseURL: URL {
        URL(string: "http://127.0.0.1:\(port)") ?? URL(fileURLWithPath: "/")
    }

    func url(_ path: String) -> URL {
        URL(string: path, relativeTo: baseURL)?.absoluteURL ?? baseURL
    }

    private func listen() async throws {
        let ready = OSAllocatedUnfairLock(initialState: false)
        listener.newConnectionHandler = { [weak self] connection in
            self?.serve(connection)
        }
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, any Error>) in
            listener.stateUpdateHandler = { [weak self] state in
                guard let self, !ready.withLock({ $0 }) else { return }
                switch state {
                case .ready:
                    ready.withLock { $0 = true }
                    port = listener.port?.rawValue ?? 0
                    continuation.resume()
                case let .failed(error):
                    ready.withLock { $0 = true }
                    continuation.resume(throwing: error)
                default:
                    break
                }
            }
            listener.start(queue: queue)
        }
    }

    private func serve(_ connection: NWConnection) {
        connection.start(queue: queue)
        receive(on: connection, buffered: Data())
    }

    private func receive(on connection: NWConnection, buffered: Data) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 64 * 1024) { [weak self] data, _, isComplete, error in
            guard let self, error == nil else {
                connection.cancel()
                return
            }
            var buffered = buffered
            if let data { buffered.append(data) }
            if let request = Self.parse(buffered) {
                received.withLock { $0.append(request) }
                let response = handler(request)
                connection.send(content: Self.serialize(response), completion: .contentProcessed { _ in
                    connection.cancel()
                })
            } else if isComplete {
                connection.cancel()
            } else {
                receive(on: connection, buffered: buffered)
            }
        }
    }

    /// A complete request from the bytes so far, or `nil` while more is needed.
    private static func parse(_ data: Data) -> Request? {
        guard let headerEnd = data.range(of: Data("\r\n\r\n".utf8)) else { return nil }
        guard let headerText = String(data: data[data.startIndex ..< headerEnd.lowerBound], encoding: .utf8) else { return nil }
        var lines = headerText.components(separatedBy: "\r\n")
        let requestLine = lines.removeFirst().split(separator: " ")
        guard requestLine.count >= 2 else { return nil }
        var headers: [String: String] = [:]
        for line in lines {
            guard let colon = line.firstIndex(of: ":") else { continue }
            headers[String(line[..<colon])] = line[line.index(after: colon)...].trimmingCharacters(in: .whitespaces)
        }
        let contentLength = headers.first { $0.key.caseInsensitiveCompare("Content-Length") == .orderedSame }.flatMap { Int($0.value) } ?? 0
        let bodyStart = headerEnd.upperBound
        guard data.count - bodyStart >= contentLength else { return nil }
        let body = data[bodyStart ..< bodyStart + contentLength]
        return Request(method: String(requestLine[0]), path: String(requestLine[1]), headers: headers, body: Data(body))
    }

    private static func serialize(_ response: Response) -> Data {
        var headers = response.headers
        headers["Content-Length"] = "\(response.body.count)"
        headers["Connection"] = "close"
        var text = "HTTP/1.1 \(response.status) \(response.reason)\r\n"
        for (name, value) in headers.sorted(by: { $0.key < $1.key }) {
            text += "\(name): \(value)\r\n"
        }
        text += "\r\n"
        return Data(text.utf8) + response.body
    }
}

/// Polling wait for asynchronous work, as in the UI test target.
enum LMKWait {
    /// Polls `condition` every 20 ms until it holds or `timeout` passes.
    static func until(timeout: Duration = .seconds(10), _ condition: @Sendable () -> Bool) async {
        let deadline = ContinuousClock.now + timeout
        while !condition(), ContinuousClock.now < deadline {
            try? await Task.sleep(for: .milliseconds(20))
        }
    }
}
