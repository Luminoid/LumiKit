//
//  URLSessionConfigurationLMKDebugTests.swift
//  LumiKit
//

import Testing
@testable import LumiKitNetwork

// MARK: - URLSessionConfiguration+LMKDebug

#if DEBUG && LMK_ENABLE_NETWORK_LOGGING

    import Foundation

    @MainActor
    struct URLSessionConfigurationLMKDebugTests {
        @Test
        func `enableNetworkLogging adds protocol class`() {
            let config = URLSessionConfiguration.default
            let initialCount = config.protocolClasses?.count ?? 0

            config.enableNetworkLogging()

            let newCount = config.protocolClasses?.count ?? 0
            #expect(newCount == initialCount + 1)
        }

        @Test
        func `enableNetworkLogging is idempotent`() {
            let config = URLSessionConfiguration.default
            config.enableNetworkLogging()
            let countAfterFirst = config.protocolClasses?.count ?? 0

            config.enableNetworkLogging()
            let countAfterSecond = config.protocolClasses?.count ?? 0

            #expect(countAfterFirst == countAfterSecond)
        }

        @Test
        func `enableNetworkLogging returns self for chaining`() {
            let config = URLSessionConfiguration.default
            let returned = config.enableNetworkLogging()

            #expect(returned === config)
        }

        @Test
        func `enableNetworkLogging preserves existing protocol classes`() {
            let config = URLSessionConfiguration.default
            let existingClasses = config.protocolClasses ?? []

            config.enableNetworkLogging()

            // All original classes should still be present
            let newClasses = config.protocolClasses ?? []
            for existingClass in existingClasses {
                let found = newClasses.contains { $0 == existingClass }
                #expect(found)
            }
        }
    }

#endif
