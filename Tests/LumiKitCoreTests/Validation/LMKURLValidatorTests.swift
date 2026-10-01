//
//  LMKURLValidatorTests.swift
//  LumiKit
//

import Foundation
import Testing
@testable import LumiKitCore

// MARK: - LMKURLValidator

struct LMKURLValidatorTests {
    // MARK: - validate

    @Test
    func `Valid HTTPS URL succeeds with the parsed URL`() throws {
        let url = try LMKURLValidator.validate("https://example.com/api").get()
        #expect(url.absoluteString == "https://example.com/api")
    }

    @Test
    func `Each rejection carries its reason`() {
        #expect(LMKURLValidator.validate("") == .failure(.empty))
        #expect(LMKURLValidator.validate(nil) == .failure(.empty))
        #expect(LMKURLValidator.validate("   ") == .failure(.empty))
        #expect(LMKURLValidator.validate("https://example.com/" + String(repeating: "a", count: 500)) == .failure(.tooLong(maximum: 500)))
        #expect(LMKURLValidator.validate("http://example.com") == .failure(.unexpectedScheme(expected: "https")))
        #expect(LMKURLValidator.validate("https:///path") == .failure(.missingHost))
        #expect(LMKURLValidator.validate("https://localhost/api") == .failure(.blockedHost("localhost")))
        #expect(LMKURLValidator.validate("not a url at all") == .failure(.malformed) || LMKURLValidator.validate("not a url at all") == .failure(.unexpectedScheme(expected: "https")))
    }

    @Test
    func `Scheme is compared case-insensitively and can be changed`() {
        #expect(LMKURLValidator.validate("HTTPS://example.com").map(\.host) == .success("example.com"))
        #expect(LMKURLValidator.validate("ws://example.com", requiredScheme: "ws").map(\.host) == .success("example.com"))
    }

    // MARK: - validateHTTPSURL

    @Test
    func `Valid HTTPS URL passes`() {
        let result = LMKURLValidator.validateHTTPSURL("https://example.com/api")
        #expect(result == "https://example.com/api")
    }

    @Test
    func `HTTP URL is rejected`() {
        #expect(LMKURLValidator.validateHTTPSURL("http://example.com") == nil)
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
    func `Whitespace is trimmed`() {
        let result = LMKURLValidator.validateHTTPSURL("  https://example.com  ")
        #expect(result == "https://example.com")
    }

    // MARK: - Host blocklist

    @Test
    func `Localhost is blocked`() {
        #expect(LMKURLValidator.validateHTTPSURL("https://localhost/api") == nil)
        #expect(LMKURLValidator.validateHTTPSURL("https://localhost.localdomain/api") == nil)
        #expect(LMKURLValidator.validateHTTPSURL("https://app.localhost/") == nil, "*.localhost resolves to loopback")
        #expect(LMKURLValidator.validateHTTPSURL("https://LOCALHOST./") == nil, "a trailing dot is the same name")
    }

    @Test
    func `Shorthand IPv4 forms the resolver accepts are blocked`() {
        for host in ["127.1", "2130706433", "0x7f.0.0.1", "0177.0.0.1", "10.1", "192.168.1", "127.0.0.1."] {
            #expect(LMKURLValidator.isBlockedHost(host), "\(host) should be blocked")
            #expect(LMKURLValidator.validate("https://\(host)/") == .failure(.blockedHost(host)), "\(host) through validate")
        }
        #expect(!LMKURLValidator.isBlockedHost("8.8.8.8."))
    }

    @Test
    func `Bracketed IPv6 literals are read without the brackets`() {
        #expect(LMKURLValidator.isBlockedHost("[::1]"))
        #expect(LMKURLValidator.isBlockedHost("[fe80::1]"))
        #expect(!LMKURLValidator.isBlockedHost("[2606:4700::1111]"))
        #expect(LMKURLValidator.validate("https://[::1]/") == .failure(.blockedHost("::1")))
    }

    @Test
    func `Validation errors are hashable`() {
        let errors: Set<LMKURLValidator.ValidationError> = [.empty, .malformed, .tooLong(maximum: 500), .tooLong(maximum: 500), .blockedHost("a")]
        #expect(errors.count == 4)
    }

    @Test
    func `Private, loopback, link-local, CGNAT, and unspecified IPv4 ranges are blocked`() {
        for host in ["10.0.0.1", "192.168.1.1", "172.16.0.1", "172.31.255.254", "127.0.0.1", "169.254.1.1", "100.64.0.1", "100.127.255.254", "0.0.0.0", "0.1.2.3"] {
            #expect(LMKURLValidator.isBlockedHost(host), "\(host) should be blocked")
        }
    }

    @Test
    func `Multicast and reserved IPv4 ranges are blocked`() {
        for host in ["224.0.0.1", "239.255.255.250", "240.0.0.1", "255.255.255.255"] {
            #expect(LMKURLValidator.isBlockedHost(host), "\(host) should be blocked")
        }
    }

    @Test
    func `Public IPv4 addresses and host names pass`() {
        for host in ["8.8.8.8", "100.63.255.255", "100.128.0.1", "172.32.0.1", "203.0.113.9", "example.com"] {
            #expect(!LMKURLValidator.isBlockedHost(host), "\(host) should pass")
        }
    }

    @Test
    func `IPv6 loopback, unspecified, local, and multicast ranges are blocked`() {
        for host in ["::1", "::", "fc00::1", "fd12:3456::1", "fe80::1", "ff02::1"] {
            #expect(LMKURLValidator.isBlockedHost(host), "\(host) should be blocked")
        }
    }

    @Test
    func `IPv4-mapped IPv6 addresses follow the IPv4 rules`() {
        #expect(LMKURLValidator.isBlockedHost("::ffff:127.0.0.1"))
        #expect(LMKURLValidator.isBlockedHost("::ffff:10.1.2.3"))
        #expect(!LMKURLValidator.isBlockedHost("::ffff:8.8.8.8"))
        #expect(!LMKURLValidator.isBlockedHost("2606:4700::1111"))
    }

    // MARK: - normalizeBaseURL

    @Test
    func `normalizeBaseURL adds trailing slash`() {
        #expect(LMKURLValidator.normalizeBaseURL("https://example.com/path") == "https://example.com/path/")
        #expect(LMKURLValidator.normalizeBaseURL("https://example.com") == "https://example.com/")
    }

    @Test
    func `normalizeBaseURL preserves existing slash`() {
        #expect(LMKURLValidator.normalizeBaseURL("https://example.com/path/") == "https://example.com/path/")
    }

    @Test
    func `normalizeBaseURL preserves file URLs unless asked not to`() {
        #expect(LMKURLValidator.normalizeBaseURL("https://example.com/data.json") == "https://example.com/data.json")
        #expect(LMKURLValidator.normalizeBaseURL("https://example.com/feed.xml") == "https://example.com/feed.xml")
        #expect(LMKURLValidator.normalizeBaseURL("https://example.com/data.json", preservingPathExtension: false) == "https://example.com/data.json/")
    }
}
