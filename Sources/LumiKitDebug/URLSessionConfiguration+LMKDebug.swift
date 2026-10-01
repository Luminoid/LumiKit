//
//  URLSessionConfiguration+LMKDebug.swift
//  LumiKit
//
//  Helper to inject LMKNetworkLogger into custom URLSession configurations.
//  Debug builds only (`LMK_ENABLE_NETWORK_LOGGING`) — zero footprint in release.
//

#if LMK_ENABLE_NETWORK_LOGGING

    import Foundation

    public extension URLSessionConfiguration {
        /// Add LMKNetworkLogger to protocolClasses for request interception.
        /// Call this on any custom URLSessionConfiguration to enable network history capture;
        /// requests are captured only while `LMKNetworkLogger.isEnabled`.
        ///
        /// A logged request runs on the logger's own session with this configuration's
        /// `httpAdditionalHeaders` applied; its cookie storage, cache, credential storage, and
        /// timeouts are not, and authentication challenges are answered by the system's default
        /// handling rather than this session's delegate (see `LMKNetworkLogger`).
        @discardableResult
        func lmk_enableNetworkLogging() -> URLSessionConfiguration {
            guard !(protocolClasses ?? []).contains(where: { $0 == LMKNetworkRequestLoggerProtocol.self }) else {
                return self
            }
            if let existingClasses = protocolClasses {
                protocolClasses = [LMKNetworkRequestLoggerProtocol.self] + existingClasses
            } else {
                protocolClasses = [LMKNetworkRequestLoggerProtocol.self]
            }
            return self
        }
    }

#endif
