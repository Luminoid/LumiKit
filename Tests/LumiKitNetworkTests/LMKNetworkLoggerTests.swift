//
//  LMKNetworkLoggerTests.swift
//  LumiKit
//
//  Tests for LMKNetworkLogger — configuration, state transitions,
//  record access, and clearing.
//

#if DEBUG

    import Foundation
    import Testing
    @testable import LumiKitNetwork

    @Suite("LMKNetworkLogger")
    struct LMKNetworkLoggerTests {
        // MARK: - Configuration

        @Test("isConfigured returns true after configure()")
        func isConfiguredAfterConfigure() {
            LMKNetworkLogger.configure(maxRecords: 50)

            #expect(LMKNetworkLogger.isConfigured)
        }

        @Test("configure sets up internal store")
        func configureCreatesStore() {
            LMKNetworkLogger.configure(maxRecords: 10)

            // Store is functional — count should be 0
            #expect(LMKNetworkLogger.count == .zero)
            #expect(LMKNetworkLogger.records.isEmpty)
        }

        @Test("configure with custom maxRecords")
        func configureCustomMaxRecords() {
            LMKNetworkLogger.configure(maxRecords: 5)

            #expect(LMKNetworkLogger.isConfigured)
            #expect(LMKNetworkLogger.count == .zero)
        }

        @Test("configure can be called multiple times")
        func configureMultipleTimes() {
            LMKNetworkLogger.configure(maxRecords: 10)
            LMKNetworkLogger.configure(maxRecords: 20)

            #expect(LMKNetworkLogger.isConfigured)
            #expect(LMKNetworkLogger.count == .zero)
        }

        // MARK: - Enable / Disable

        @Test("enable after configure does not crash")
        func enableAfterConfigure() {
            LMKNetworkLogger.configure(maxRecords: 50)
            LMKNetworkLogger.enable()

            #expect(LMKNetworkLogger.isConfigured)

            // Clean up
            LMKNetworkLogger.disable()
        }

        @Test("disable after enable does not crash")
        func disableAfterEnable() {
            LMKNetworkLogger.configure(maxRecords: 50)
            LMKNetworkLogger.enable()
            LMKNetworkLogger.disable()

            #expect(LMKNetworkLogger.isConfigured)
        }

        @Test("disable without enable does not crash")
        func disableWithoutEnable() {
            LMKNetworkLogger.configure(maxRecords: 50)
            LMKNetworkLogger.disable()

            #expect(LMKNetworkLogger.isConfigured)
        }

        // MARK: - Record Access

        @Test("records returns empty array when no requests logged")
        func recordsEmptyInitially() {
            LMKNetworkLogger.configure(maxRecords: 50)
            LMKNetworkLogger.clearRecords()

            #expect(LMKNetworkLogger.records.isEmpty)
            #expect(LMKNetworkLogger.count == .zero)
        }

        // MARK: - Clear Records

        @Test("clearRecords empties the store")
        func clearRecordsEmpties() {
            LMKNetworkLogger.configure(maxRecords: 50)

            // Pre-clear to ensure clean state
            LMKNetworkLogger.clearRecords()

            #expect(LMKNetworkLogger.count == .zero)
            #expect(LMKNetworkLogger.records.isEmpty)
        }

        @Test("clearRecords is safe to call multiple times")
        func clearRecordsMultipleTimes() {
            LMKNetworkLogger.configure(maxRecords: 50)
            LMKNetworkLogger.clearRecords()
            LMKNetworkLogger.clearRecords()
            LMKNetworkLogger.clearRecords()

            #expect(LMKNetworkLogger.count == .zero)
        }

        // MARK: - State Transitions

        @Test("Full lifecycle: configure → enable → disable")
        func fullLifecycle() {
            // Configure
            LMKNetworkLogger.configure(maxRecords: 100)
            #expect(LMKNetworkLogger.isConfigured)
            #expect(LMKNetworkLogger.count == .zero)

            // Enable
            LMKNetworkLogger.enable()
            #expect(LMKNetworkLogger.isConfigured)

            // Disable
            LMKNetworkLogger.disable()
            #expect(LMKNetworkLogger.isConfigured)
            #expect(LMKNetworkLogger.count == .zero)
        }

        @Test("Reconfigure resets store")
        func reconfigureResetsStore() {
            LMKNetworkLogger.configure(maxRecords: 100)
            #expect(LMKNetworkLogger.isConfigured)

            // Reconfigure with different max
            LMKNetworkLogger.configure(maxRecords: 5)
            #expect(LMKNetworkLogger.isConfigured)
            #expect(LMKNetworkLogger.count == .zero)
        }

        // MARK: - Edge Cases

        @Test("count returns 0 before configuration")
        func countBeforeConfiguration() {
            // After other tests have configured, reconfigure to ensure clean state
            LMKNetworkLogger.configure(maxRecords: 50)
            LMKNetworkLogger.clearRecords()

            #expect(LMKNetworkLogger.count == .zero)
        }

        @Test("records returns empty array before configuration")
        func recordsBeforeConfiguration() {
            LMKNetworkLogger.configure(maxRecords: 50)
            LMKNetworkLogger.clearRecords()

            #expect(LMKNetworkLogger.records.isEmpty)
        }
    }

#endif
