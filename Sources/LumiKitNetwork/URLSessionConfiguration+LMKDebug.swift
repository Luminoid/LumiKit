//
//  URLSessionConfiguration+LMKDebug.swift
//  LumiKit
//
//  Helper to inject LMKNetworkLogger into custom URLSession configurations.
//  DEBUG builds only — zero footprint in release.
//

#if DEBUG

    import Foundation

    extension URLSessionConfiguration {
        /// Add LMKNetworkLogger to protocolClasses for request interception.
        /// Call this on any custom URLSessionConfiguration to enable network history capture.
        ///
        /// The URLProtocol uses URLSessionDataDelegate with a serial OperationQueue and
        /// ephemeral configuration to avoid Swift 6 strict concurrency issues.
        @discardableResult
        public func withNetworkLogging() -> URLSessionConfiguration {
            if let existingClasses = protocolClasses {
                protocolClasses = [LMKNetworkRequestLoggerProtocol.self] + existingClasses
            } else {
                protocolClasses = [LMKNetworkRequestLoggerProtocol.self]
            }
            return self
        }
    }

#endif
