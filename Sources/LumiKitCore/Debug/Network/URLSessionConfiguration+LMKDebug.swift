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
        /// - Important: Currently disabled in SPM builds due to Swift 6 concurrency limitations.
        ///   Returns `self` unchanged. Apps should copy network debugging files locally or use
        ///   Xcode with `SWIFT_APPROACHABLE_CONCURRENCY = YES` build setting.
        @discardableResult
        public func withNetworkLogging() -> URLSessionConfiguration {
            #if !SWIFT_PACKAGE
            if let existingClasses = protocolClasses {
                protocolClasses = [LMKNetworkRequestLoggerProtocol.self] + existingClasses
            } else {
                protocolClasses = [LMKNetworkRequestLoggerProtocol.self]
            }
            #endif
            return self
        }
    }

#endif
