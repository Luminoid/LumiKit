//
//  URLSessionConfigurationLMKDebugTests.swift
//  LumiKit
//

import Testing
@testable import LumiKitDebug

// MARK: - URLSessionConfiguration+LMKDebug

#if LMK_ENABLE_NETWORK_LOGGING

    import Foundation

    @MainActor
    struct URLSessionConfigurationLMKDebugTests {
        @Test
        func `enableNetworkLogging adds protocol class`() {
            let config = URLSessionConfiguration.default
            let initialCount = config.protocolClasses?.count ?? 0

            config.lmk_enableNetworkLogging()

            let newCount = config.protocolClasses?.count ?? 0
            #expect(newCount == initialCount + 1)
        }

        @Test
        func `enableNetworkLogging is idempotent`() {
            let config = URLSessionConfiguration.default
            config.lmk_enableNetworkLogging()
            let countAfterFirst = config.protocolClasses?.count ?? 0

            config.lmk_enableNetworkLogging()
            let countAfterSecond = config.protocolClasses?.count ?? 0

            #expect(countAfterFirst == countAfterSecond)
        }

        @Test
        func `enableNetworkLogging returns self for chaining`() {
            let config = URLSessionConfiguration.default
            let returned = config.lmk_enableNetworkLogging()

            #expect(returned === config)
        }

        @Test
        func `enableNetworkLogging preserves existing protocol classes`() {
            let config = URLSessionConfiguration.default
            let existingClasses = config.protocolClasses ?? []

            config.lmk_enableNetworkLogging()

            // All original classes should still be present
            let newClasses = config.protocolClasses ?? []
            for existingClass in existingClasses {
                let found = newClasses.contains { $0 == existingClass }
                #expect(found)
            }
        }
    }

#endif
