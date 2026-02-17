//
//  LMKURLValidatorTests.swift
//  LumiKit
//

import Foundation
import Testing

@testable import LumiKitCore

// MARK: - LMKURLValidator

@Suite("LMKURLValidator")
struct LMKURLValidatorTests {
    @Test("Valid HTTPS URL passes")
    func validHTTPS() {
        let result = LMKURLValidator.validateHTTPSURL("https://example.com/api")
        #expect(result == "https://example.com/api")
    }

    @Test("HTTP URL is rejected")
    func httpRejected() {
        let result = LMKURLValidator.validateHTTPSURL("http://example.com")
        #expect(result == nil)
    }

    @Test("Empty input is rejected")
    func emptyRejected() {
        #expect(LMKURLValidator.validateHTTPSURL("") == nil)
        #expect(LMKURLValidator.validateHTTPSURL(nil) == nil)
    }

    @Test("URL exceeding max length is rejected")
    func maxLengthRejected() {
        let longURL = "https://example.com/" + String(repeating: "a", count: 500)
        #expect(LMKURLValidator.validateHTTPSURL(longURL) == nil)
    }

    @Test("Localhost is blocked (SSRF)")
    func localhostBlocked() {
        #expect(LMKURLValidator.validateHTTPSURL("https://localhost/api") == nil)
        #expect(LMKURLValidator.validateHTTPSURL("https://localhost.localdomain/api") == nil)
    }

    @Test("Private IP ranges are blocked (SSRF)")
    func privateIPBlocked() {
        #expect(LMKURLValidator.validateHTTPSURL("https://10.0.0.1/api") == nil)
        #expect(LMKURLValidator.validateHTTPSURL("https://192.168.1.1/api") == nil)
        #expect(LMKURLValidator.validateHTTPSURL("https://172.16.0.1/api") == nil)
        #expect(LMKURLValidator.validateHTTPSURL("https://127.0.0.1/api") == nil)
    }

    @Test("Link-local is blocked (SSRF)")
    func linkLocalBlocked() {
        #expect(LMKURLValidator.validateHTTPSURL("https://169.254.1.1/api") == nil)
    }

    @Test("IPv6 loopback is blocked")
    func ipv6LoopbackBlocked() {
        #expect(LMKURLValidator.isBlockedHost("::1"))
    }

    @Test("normalizeBaseURL adds trailing slash")
    func normalizeBaseURLSlash() {
        #expect(LMKURLValidator.normalizeBaseURL("https://example.com/path") == "https://example.com/path/")
    }

    @Test("normalizeBaseURL preserves existing slash")
    func normalizeBaseURLExistingSlash() {
        #expect(LMKURLValidator.normalizeBaseURL("https://example.com/path/") == "https://example.com/path/")
    }

    @Test("normalizeBaseURL preserves .json suffix")
    func normalizeBaseURLJson() {
        #expect(LMKURLValidator.normalizeBaseURL("https://example.com/data.json") == "https://example.com/data.json")
    }

    @Test("Whitespace is trimmed")
    func whitespaceTrimmed() {
        let result = LMKURLValidator.validateHTTPSURL("  https://example.com  ")
        #expect(result == "https://example.com")
    }
}
