//
//  LMKNetworkLoggerCaptureTests.swift
//  LumiKit
//
//  End-to-end tests of the URLProtocol against a loopback server: bodies, cookies,
//  redirects, redaction, the disabled state, and the inner session staying out of
//  its own logger.
//

#if LMK_ENABLE_NETWORK_LOGGING

    import Foundation
    import Testing
    @testable import LumiKitDebug

    extension LMKNetworkLoggerSerializedSuite {
        struct LMKNetworkLoggerCaptureTests {
            /// A logging session on the default configuration, as an app would build one.
            private func makeSession(delegate: (any URLSessionDelegate)? = nil) -> URLSession {
                let configuration = URLSessionConfiguration.default.lmk_enableNetworkLogging()
                return URLSession(configuration: configuration, delegate: delegate, delegateQueue: nil)
            }

            /// Configures the logger for the server's host, enables it, runs `body`, and disables it again.
            private func withLogger(
                _ configuration: LMKNetworkLogger.Configuration = LMKNetworkLogger.Configuration(),
                handler: @escaping @Sendable (LMKLocalHTTPServer.Request) -> LMKLocalHTTPServer.Response,
                body: (LMKLocalHTTPServer) async throws -> Void
            ) async throws {
                let server = try await LMKLocalHTTPServer.start(handler: handler)
                defer { server.stop() }
                var configuration = configuration
                configuration.hostFilter = ["127.0.0.1"]
                LMKNetworkLogger.configure(configuration)
                LMKNetworkLogger.enable()
                defer { LMKNetworkLogger.disable() }
                try await body(server)
            }

            /// The record for `path`, once the store has it with a response or an error.
            private func settledRecord(path: String) async -> LMKNetworkRequestRecord? {
                await LMKWait.until {
                    LMKNetworkLogger.records.contains { $0.request.url.path == path && ($0.response != nil || $0.errorDescription != nil) }
                }
                return LMKNetworkLogger.records.first { $0.request.url.path == path }
            }

            @Test
            func `A POST body is captured, forwarded, and the inner request is not logged again`() async throws {
                try await withLogger(handler: { _ in .text("created", status: 201) }, body: { server in
                    var request = URLRequest(url: server.url("/items"))
                    request.httpMethod = "POST"
                    request.httpBody = Data(#"{"name":"Fern"}"#.utf8)
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

                    let (data, response) = try await makeSession().data(for: request)

                    #expect((response as? HTTPURLResponse)?.statusCode == 201)
                    #expect(String(data: data, encoding: .utf8) == "created")
                    #expect(server.requests.count == 1, "the inner session's request is the only one the server sees")
                    #expect(server.requests.first?.body == request.httpBody, "the drained body reaches the server")
                    #expect(LMKNetworkLogger.count == 1, "the inner request is not intercepted a second time")
                    let record = try #require(await settledRecord(path: "/items"))
                    #expect(record.request.method == "POST")
                    #expect(record.request.body == request.httpBody)
                    #expect(!record.request.isBodyTruncated)
                    #expect(record.requestBodyText?.contains("\"name\" : \"Fern\"") == true)
                    #expect(record.statusCode == 201)
                    #expect(record.response?.body == Data("created".utf8))
                    #expect(record.duration ?? -1 >= 0)
                })
            }

            @Test
            func `Bodies past the capture size are cut and flagged, and still sent whole`() async throws {
                let payload = Data(repeating: UInt8(ascii: "x"), count: 5000) + Data("é".utf8)
                let configuration = LMKNetworkLogger.Configuration(maxBodyCaptureSize: 5001)
                try await withLogger(configuration, handler: { request in .text(String(data: request.body, encoding: .utf8) ?? "") }, body: { server in
                    var request = URLRequest(url: server.url("/upload"))
                    request.httpMethod = "PUT"
                    request.httpBody = payload

                    let (data, _) = try await makeSession().data(for: request)

                    #expect(data == payload, "the response echoes the whole body")
                    #expect(server.requests.first?.body == payload)
                    let record = try #require(await settledRecord(path: "/upload"))
                    #expect(record.request.isBodyTruncated)
                    #expect(record.request.body?.count == 5001)
                    #expect(record.requestBodyText == String(repeating: "x", count: 5000), "a cut inside a character is trimmed to text")
                    #expect(record.response?.isBodyTruncated == true)
                    #expect(record.response?.body?.count == 5001)
                })
            }

            @Test
            func `Cookies from the shared jar go out and Set-Cookie comes back into it`() async throws {
                let jar = HTTPCookieStorage.shared
                try await withLogger(handler: { _ in .text("ok", headers: ["Set-Cookie": "session=fresh; Path=/"]) }, body: { server in
                    let url = server.url("/cookies")
                    let cookie = try #require(HTTPCookie(properties: [.domain: "127.0.0.1", .path: "/", .name: "auth", .value: "stale", .port: "\(server.port)"]))
                    jar.setCookie(cookie)
                    defer { jar.cookies(for: url)?.forEach(jar.deleteCookie) }

                    _ = try await makeSession().data(from: url)

                    #expect(server.requests.first?.header("Cookie")?.contains("auth=stale") == true, "the app's cookie reaches the server through the logger")
                    #expect(jar.cookies(for: url)?.contains { $0.name == "session" && $0.value == "fresh" } == true, "the response cookie lands in the shared jar")
                    let record = try #require(await settledRecord(path: "/cookies"))
                    #expect(record.response?.headers["Set-Cookie"] == LMKNetworkLogger.redactedValue)
                })
            }

            @Test
            func `A redirect is reported to the session, which follows it, and both hops are recorded`() async throws {
                final class RedirectRecorder: NSObject, URLSessionTaskDelegate, @unchecked Sendable {
                    var seen: [(from: Int, to: String)] = []
                    func urlSession(
                        _ session: URLSession,
                        task: URLSessionTask,
                        willPerformHTTPRedirection response: HTTPURLResponse,
                        newRequest request: URLRequest,
                        completionHandler: @escaping (URLRequest?) -> Void
                    ) {
                        seen.append((response.statusCode, request.url?.path ?? ""))
                        completionHandler(request)
                    }
                }
                let recorder = RedirectRecorder()
                try await withLogger(handler: { request in
                    request.path == "/old" ? .redirect(to: "/new?token=abc") : .text("moved")
                }, body: { server in
                    let (data, response) = try await makeSession(delegate: recorder).data(from: server.url("/old"))

                    #expect(String(data: data, encoding: .utf8) == "moved")
                    #expect(response.url?.path == "/new")
                    #expect(recorder.seen.map(\.from) == [302])
                    #expect(recorder.seen.map(\.to) == ["/new"])
                    #expect(server.requests.map(\.path) == ["/old", "/new?token=abc"])
                    let first = try #require(await settledRecord(path: "/old"))
                    #expect(first.statusCode == 302)
                    #expect(first.response?.headers["Location"] == "/new?token=\(LMKNetworkLogger.redactedValueQueryEncoded)")
                    let second = try #require(await settledRecord(path: "/new"))
                    #expect(second.statusCode == 200)
                    #expect(second.request.url.query == "token=\(LMKNetworkLogger.redactedValueQueryEncoded)")
                    #expect(LMKNetworkLogger.count == 2)
                })
            }

            @Test
            func `A redirect the session refuses ends the task at the redirect response`() async throws {
                final class Refuser: NSObject, URLSessionTaskDelegate, @unchecked Sendable {
                    func urlSession(
                        _ session: URLSession,
                        task: URLSessionTask,
                        willPerformHTTPRedirection response: HTTPURLResponse,
                        newRequest request: URLRequest,
                        completionHandler: @escaping (URLRequest?) -> Void
                    ) {
                        completionHandler(nil)
                    }
                }
                try await withLogger(handler: { request in
                    request.path == "/old" ? .redirect(to: "/new", body: "redirecting") : .text("moved")
                }, body: { server in
                    let (data, response) = try await makeSession(delegate: Refuser()).data(from: server.url("/old"))

                    #expect((response as? HTTPURLResponse)?.statusCode == 302)
                    #expect(data == Data("redirecting".utf8), "the 3xx body is the task's result")
                    #expect(server.requests.map(\.path) == ["/old"], "the redirect target is never requested")
                    let record = try #require(await settledRecord(path: "/old"))
                    #expect(record.statusCode == 302)
                    #expect(record.response?.body == Data("redirecting".utf8))
                    #expect(LMKNetworkLogger.count == 1)
                })
            }

            @Test
            func `Query credentials are redacted in the record and sent to the server`() async throws {
                try await withLogger(handler: { _ in .text("ok") }, body: { server in
                    _ = try await makeSession().data(from: server.url("/search?key=SECRET&q=fern"))

                    #expect(server.requests.first?.path == "/search?key=SECRET&q=fern")
                    let record = try #require(await settledRecord(path: "/search"))
                    #expect(record.request.url.query == "key=\(LMKNetworkLogger.redactedValueQueryEncoded)&q=fern")
                    #expect(record.displayURL.hasSuffix("/search?key=\(LMKNetworkLogger.redactedValue)&q=fern"))
                    #expect(!LMKNetworkDetailViewController.formatRecord(record).contains("SECRET"))
                })
            }

            @Test
            func `A disabled logger intercepts nothing, even on a session that lists it`() async throws {
                try await withLogger(handler: { _ in .text("ok") }, body: { server in
                    let session = makeSession()
                    _ = try await session.data(from: server.url("/first"))
                    #expect(await settledRecord(path: "/first") != nil)

                    LMKNetworkLogger.disable()
                    _ = try await session.data(from: server.url("/second"))

                    #expect(server.requests.map(\.path) == ["/first", "/second"])
                    #expect(LMKNetworkLogger.records.map(\.request.url.path) == ["/first"])
                })
            }

            @Test
            func `A failed request records its error`() async throws {
                try await withLogger(handler: { _ in .text("ok") }, body: { server in
                    let url = server.url("/gone")
                    server.stop()
                    await Task.yield()

                    await #expect(throws: URLError.self) {
                        _ = try await makeSession().data(from: url)
                    }

                    let record = try #require(await settledRecord(path: "/gone"))
                    #expect(record.errorDescription != nil)
                    #expect(record.isError)
                    #expect(record.response == nil)
                })
            }
        }
    }

#endif
