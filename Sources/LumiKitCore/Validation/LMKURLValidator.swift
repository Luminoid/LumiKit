//
//  LMKURLValidator.swift
//  LumiKit
//
//  URL validation and SSRF mitigation utilities.
//  Blocks private IP ranges, localhost, and link-local addresses.
//

import Foundation

/// URL validation and SSRF mitigation utilities.
/// Reusable for custom URLs, API endpoints, and external resources.
public enum LMKURLValidator {
    /// Validates URL: HTTPS only, length limit, blocks private/localhost (SSRF mitigation).
    /// - Parameters:
    ///   - input: Raw URL string (may be trimmed).
    ///   - maxLength: Maximum URL length (default: 500).
    ///   - requiredScheme: Required URL scheme (default: "https").
    /// - Returns: Normalized URL string or `nil` if invalid.
    public static func validateHTTPSURL(
        _ input: String?,
        maxLength: Int = 500,
        requiredScheme: String = "https"
    ) -> String? {
        let trimmed = (input ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed.count <= maxLength else { return nil }
        guard let url = URL(string: trimmed) else { return nil }
        guard url.scheme?.lowercased() == requiredScheme.lowercased() else { return nil }
        guard let host = url.host, !host.isEmpty else { return nil }
        guard !isBlockedHost(host) else { return nil }
        return trimmed
    }

    /// Normalizes a base URL by ensuring trailing slash (unless it's a full file URL).
    /// - Parameter input: Validated URL string.
    /// - Returns: URL with trailing slash if it's a base path, or unchanged if it ends with `.json`.
    public static func normalizeBaseURL(_ input: String) -> String {
        if input.lowercased().hasSuffix(".json") { return input }
        if input.hasSuffix("/") { return input }
        return input + "/"
    }

    /// Blocks localhost and private IP ranges to mitigate SSRF.
    public static func isBlockedHost(_ host: String) -> Bool {
        let lower = host.lowercased()
        if lower == "localhost" || lower.hasPrefix("localhost.") {
            return true
        }
        var addr = in6_addr()
        if inet_pton(AF_INET6, host, &addr) == 1 {
            return isBlockedIPv6(&addr)
        }
        var addr4 = in_addr()
        if inet_pton(AF_INET, host, &addr4) == 1 {
            return isBlockedIPv4(addr4)
        }
        return false
    }

    private static func isBlockedIPv4(_ addr: in_addr) -> Bool {
        let octets = withUnsafeBytes(of: addr.s_addr) { Array($0) }
        let b0 = octets[0]
        let b1 = octets[1]
        if b0 == 127 { return true } // 127.0.0.0/8
        if b0 == 10 { return true } // 10.0.0.0/8
        if b0 == 172, (b1 & 0xF0) == 0x10 { return true } // 172.16.0.0/12
        if b0 == 192, b1 == 168 { return true } // 192.168.0.0/16
        if b0 == 169, b1 == 254 { return true } // 169.254.0.0/16
        return false
    }

    private static func isBlockedIPv6(_ addr: UnsafePointer<in6_addr>) -> Bool {
        let p = addr.withMemoryRebound(to: UInt8.self, capacity: 16) { $0 }
        if p[0] == 0, p[1] == 0, p[2] == 0, p[3] == 0, p[4] == 0, p[5] == 0, p[6] == 0, p[7] == 0,
           p[8] == 0, p[9] == 0, p[10] == 0, p[11] == 0, p[12] == 0, p[13] == 0, p[14] == 0, p[15] == 1 {
            return true // ::1
        }
        if (p[0] & 0xFE) == 0xFC { return true } // fc00::/7
        if p[0] == 0xFE, (p[1] & 0xC0) == 0x80 { return true } // fe80::/10
        return false
    }
}
