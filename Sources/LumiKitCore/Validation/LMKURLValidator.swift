//
//  LMKURLValidator.swift
//  LumiKit
//
//  URL validation for user-entered endpoints: scheme, length, and a host blocklist
//  (loopback, private, link-local, CGNAT, multicast, and unspecified addresses).
//

import Foundation

/// URL validation for user-entered endpoints and external resources.
///
/// The host check is a literal blocklist: names are not resolved, so a DNS record that
/// points at a private address is not caught here. Resolve and re-check at request time
/// when that matters.
public enum LMKURLValidator {
    // MARK: - Types

    /// Why a URL was rejected.
    public enum ValidationError: Error, Hashable, Sendable {
        /// Empty after trimming.
        case empty
        /// Longer than the allowed maximum.
        case tooLong(maximum: Int)
        /// Not parseable as a URL.
        case malformed
        /// The scheme is not the required one.
        case unexpectedScheme(expected: String)
        /// No host component.
        case missingHost
        /// The host is on the blocklist.
        case blockedHost(String)
    }

    // MARK: - Validation

    /// Validates a URL string: trimmed, non-empty, within `maxLength`, the required scheme, a host, and not blocked.
    /// - Parameters:
    ///   - input: Raw URL string (whitespace is trimmed).
    ///   - maxLength: Maximum URL length (default: 500).
    ///   - requiredScheme: Required URL scheme, compared case-insensitively (default: "https").
    public static func validate(
        _ input: String?,
        maxLength: Int = 500,
        requiredScheme: String = "https"
    ) -> Result<URL, ValidationError> {
        let trimmed = (input ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return .failure(.empty) }
        guard trimmed.count <= maxLength else { return .failure(.tooLong(maximum: maxLength)) }
        guard let url = URL(string: trimmed) else { return .failure(.malformed) }
        guard url.scheme?.lowercased() == requiredScheme.lowercased() else { return .failure(.unexpectedScheme(expected: requiredScheme)) }
        guard let host = url.host, !host.isEmpty else { return .failure(.missingHost) }
        guard !isBlockedHost(host) else { return .failure(.blockedHost(host)) }
        return .success(url)
    }

    /// `validate(_:maxLength:requiredScheme:)` as a string: the trimmed input when valid, `nil` otherwise.
    public static func validateHTTPSURL(
        _ input: String?,
        maxLength: Int = 500,
        requiredScheme: String = "https"
    ) -> String? {
        switch validate(input, maxLength: maxLength, requiredScheme: requiredScheme) {
        case .success: (input ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        case .failure: nil
        }
    }

    /// Normalizes a base URL by appending a trailing slash.
    /// - Parameters:
    ///   - input: A validated URL string.
    ///   - preservingPathExtension: When `true` (the default), a URL whose last path component has an
    ///     extension (`data.json`) is a file, not a base, and is returned unchanged.
    public static func normalizeBaseURL(_ input: String, preservingPathExtension: Bool = true) -> String {
        if input.hasSuffix("/") { return input }
        if preservingPathExtension, let url = URL(string: input), !url.pathExtension.isEmpty { return input }
        return input + "/"
    }

    // MARK: - Host blocklist

    /// Whether `host` is localhost (or a `.localhost` name), or an unspecified, loopback, private,
    /// link-local, CGNAT, or multicast address, in dotted, shorthand (`127.1`, `2130706433`,
    /// `0x7f.0.0.1`), or IPv6 form. A trailing dot and IPv6 brackets are ignored.
    public static func isBlockedHost(_ host: String) -> Bool {
        var host = host
        if host.hasSuffix(".") { host.removeLast() }
        if host.hasPrefix("["), host.hasSuffix("]") {
            host = String(host.dropFirst().dropLast())
        }
        let lower = host.lowercased()
        if lower == "localhost" || lower.hasPrefix("localhost.") || lower.hasSuffix(".localhost") {
            return true
        }
        var addr6 = in6_addr()
        if inet_pton(AF_INET6, host, &addr6) == 1 {
            return isBlockedIPv6(&addr6)
        }
        // A dotted quad is checked as `inet_pton` reads it and as `inet_aton` and the resolvers
        // read it (`0177.0.0.1` is 177.0.0.1 to one and 127.0.0.1 to the other); either
        // reading being blocked blocks the host.
        var addr4 = in_addr()
        if inet_pton(AF_INET, host, &addr4) == 1, isBlockedIPv4(addr4) {
            return true
        }
        if let octets = shorthandIPv4Octets(host), isBlockedIPv4(octets: octets) {
            return true
        }
        return false
    }

    /// The four octets of an IPv4 address as `inet_aton` and the resolvers read it: one to four
    /// parts (`127.1`, `10.1`, `2130706433`), each decimal, octal with a leading zero
    /// (`0177.0.0.1`), or hexadecimal (`0x7f.0.0.1`), the last part filling the remaining bytes.
    /// `nil` for anything else.
    private static func shorthandIPv4Octets(_ host: String) -> [UInt8]? {
        let parts = host.split(separator: ".", omittingEmptySubsequences: false)
        guard (1 ... 4).contains(parts.count) else { return nil }
        var values: [UInt64] = []
        for part in parts {
            guard let value = numericPart(part) else { return nil }
            values.append(value)
        }
        // The last part fills every remaining byte, as in `inet_aton`.
        let leading = values.dropLast()
        guard leading.allSatisfy({ $0 <= 0xFF }), let last = values.last else { return nil }
        let lastByteCount = 4 - leading.count
        guard last < (1 << (8 * UInt64(lastByteCount))) else { return nil }
        var octets = leading.map { UInt8($0) }
        for shift in stride(from: (lastByteCount - 1) * 8, through: 0, by: -8) {
            octets.append(UInt8((last >> UInt64(shift)) & 0xFF))
        }
        return octets
    }

    private static func numericPart(_ part: Substring) -> UInt64? {
        let lower = part.lowercased()
        if lower.hasPrefix("0x") {
            let digits = lower.dropFirst(2)
            return digits.isEmpty ? nil : UInt64(digits, radix: 16)
        }
        if lower.count > 1, lower.hasPrefix("0") {
            return UInt64(lower.dropFirst(), radix: 8)
        }
        return UInt64(lower, radix: 10)
    }

    private static func isBlockedIPv4(_ addr: in_addr) -> Bool {
        let octets = withUnsafeBytes(of: addr.s_addr) { Array($0) }
        return isBlockedIPv4(octets: octets)
    }

    private static func isBlockedIPv4(octets: [UInt8]) -> Bool {
        let b0 = octets[0]
        let b1 = octets[1]
        if b0 == 0 { return true } // 0.0.0.0/8 (unspecified, "this network")
        if b0 == 127 { return true } // 127.0.0.0/8
        if b0 == 10 { return true } // 10.0.0.0/8
        if b0 == 100, (b1 & 0xC0) == 0x40 { return true } // 100.64.0.0/10 (carrier-grade NAT)
        if b0 == 172, (b1 & 0xF0) == 0x10 { return true } // 172.16.0.0/12
        if b0 == 192, b1 == 168 { return true } // 192.168.0.0/16
        if b0 == 169, b1 == 254 { return true } // 169.254.0.0/16
        if b0 >= 224 { return true } // 224.0.0.0/4 multicast and 240.0.0.0/4 reserved (incl. broadcast)
        return false
    }

    private static func isBlockedIPv6(_ addr: UnsafePointer<in6_addr>) -> Bool {
        let p = addr.withMemoryRebound(to: UInt8.self, capacity: 16) { $0 }
        let leadingZero = (0 ..< 10).allSatisfy { p[$0] == 0 }
        if leadingZero, p[10] == 0, p[11] == 0, p[12] == 0, p[13] == 0, p[14] == 0 {
            return true // :: (unspecified) and ::1 (loopback)
        }
        if leadingZero, p[10] == 0xFF, p[11] == 0xFF {
            return isBlockedIPv4(octets: [p[12], p[13], p[14], p[15]]) // ::ffff:a.b.c.d (IPv4-mapped)
        }
        if (p[0] & 0xFE) == 0xFC { return true } // fc00::/7 (unique local)
        if p[0] == 0xFE, (p[1] & 0xC0) == 0x80 { return true } // fe80::/10 (link-local)
        if p[0] == 0xFF { return true } // ff00::/8 (multicast)
        return false
    }
}
