//
//  LMKURLValidatorTests.swift
//  LumiKit
//

import Foundation
import Testing
@testable import LumiKitCore

// MARK: - LMKURLValidator

struct LMKURLValidatorTests {
    @Test
    func `Valid HTTPS URL passes`() {
        let result = LMKURLValidator.validateHTTPSURL("https://example.com/api")
        #expect(result == "https://example.com/api")
    }

    @Test
    func `HTTP URL is rejected`() {
        let result = LMKURLValidator.validateHTTPSURL("http://example.com")
        #expect(result == nil)
    }

    @Test
    func `Empty input is rejected`() {
        #expect(LMKURLValidator.validateHTTPSURL("") == nil)
        #expect(LMKURLValidator.validateHTTPSURL(nil) == nil)
    }

    @Test
    func `URL exceeding max length is rejected`() {
        let longURL = "https://example.com/" + String(repeating: "a", count: 500)
        #expect(LMKURLValidator.validateHTTPSURL(longURL) == nil)
    }

    @Test
    func `Localhost is blocked (SSRF)`() {
        #expect(LMKURLValidator.validateHTTPSURL("https://localhost/api") == nil)
        #expect(LMKURLValidator.validateHTTPSURL("https://localhost.localdomain/api") == nil)
    }

    @Test
    func `Private IP ranges are blocked (SSRF)`() {
        #expect(LMKURLValidator.validateHTTPSURL("https://10.0.0.1/api") == nil)
        #expect(LMKURLValidator.validateHTTPSURL("https://192.168.1.1/api") == nil)
        #expect(LMKURLValidator.validateHTTPSURL("https://172.16.0.1/api") == nil)
        #expect(LMKURLValidator.validateHTTPSURL("https://127.0.0.1/api") == nil)
    }

    @Test
    func `Link-local is blocked (SSRF)`() {
        #expect(LMKURLValidator.validateHTTPSURL("https://169.254.1.1/api") == nil)
    }

    @Test
    func `IPv6 loopback is blocked`() {
        #expect(LMKURLValidator.isBlockedHost("::1"))
    }

    @Test
    func `normalizeBaseURL adds trailing slash`() {
        #expect(LMKURLValidator.normalizeBaseURL("https://example.com/path") == "https://example.com/path/")
    }

    @Test
    func `normalizeBaseURL preserves existing slash`() {
        #expect(LMKURLValidator.normalizeBaseURL("https://example.com/path/") == "https://example.com/path/")
    }

    @Test
    func `normalizeBaseURL preserves .json suffix`() {
        #expect(LMKURLValidator.normalizeBaseURL("https://example.com/data.json") == "https://example.com/data.json")
    }

    @Test
    func `Whitespace is trimmed`() {
        let result = LMKURLValidator.validateHTTPSURL("  https://example.com  ")
        #expect(result == "https://example.com")
    }
}
