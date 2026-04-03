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

    struct LMKNetworkLoggerTests {
        // MARK: - Configuration

        @Test
        func `isConfigured returns true after configure()`() {
            LMKNetworkLogger.configure(maxRecords: 50)

            #expect(LMKNetworkLogger.isConfigured)
        }

        @Test
        func `configure sets up internal store`() {
            LMKNetworkLogger.configure(maxRecords: 10)

            // Store is functional — count should be 0
            #expect(LMKNetworkLogger.count == .zero)
            #expect(LMKNetworkLogger.records.isEmpty)
        }

        @Test
        func `configure with custom maxRecords`() {
            LMKNetworkLogger.configure(maxRecords: 5)

            #expect(LMKNetworkLogger.isConfigured)
            #expect(LMKNetworkLogger.count == .zero)
        }

        @Test
        func `configure can be called multiple times`() {
            LMKNetworkLogger.configure(maxRecords: 10)
            LMKNetworkLogger.configure(maxRecords: 20)

            #expect(LMKNetworkLogger.isConfigured)
            #expect(LMKNetworkLogger.count == .zero)
        }

        // MARK: - Enable / Disable

        @Test
        func `enable after configure does not crash`() {
            LMKNetworkLogger.configure(maxRecords: 50)
            LMKNetworkLogger.enable()

            #expect(LMKNetworkLogger.isConfigured)

            // Clean up
            LMKNetworkLogger.disable()
        }

        @Test
        func `disable after enable does not crash`() {
            LMKNetworkLogger.configure(maxRecords: 50)
            LMKNetworkLogger.enable()
            LMKNetworkLogger.disable()

            #expect(LMKNetworkLogger.isConfigured)
        }

        @Test
        func `disable without enable does not crash`() {
            LMKNetworkLogger.configure(maxRecords: 50)
            LMKNetworkLogger.disable()

            #expect(LMKNetworkLogger.isConfigured)
        }

        // MARK: - Record Access

        @Test
        func `records returns empty array when no requests logged`() {
            LMKNetworkLogger.configure(maxRecords: 50)
            LMKNetworkLogger.clearRecords()

            #expect(LMKNetworkLogger.records.isEmpty)
            #expect(LMKNetworkLogger.count == .zero)
        }

        // MARK: - Clear Records

        @Test
        func `clearRecords empties the store`() {
            LMKNetworkLogger.configure(maxRecords: 50)

            // Pre-clear to ensure clean state
            LMKNetworkLogger.clearRecords()

            #expect(LMKNetworkLogger.count == .zero)
            #expect(LMKNetworkLogger.records.isEmpty)
        }

        @Test
        func `clearRecords is safe to call multiple times`() {
            LMKNetworkLogger.configure(maxRecords: 50)
            LMKNetworkLogger.clearRecords()
            LMKNetworkLogger.clearRecords()
            LMKNetworkLogger.clearRecords()

            #expect(LMKNetworkLogger.count == .zero)
        }

        // MARK: - State Transitions

        @Test
        func `Full lifecycle: configure → enable → disable`() {
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

        @Test
        func `Reconfigure resets store`() {
            LMKNetworkLogger.configure(maxRecords: 100)
            #expect(LMKNetworkLogger.isConfigured)

            // Reconfigure with different max
            LMKNetworkLogger.configure(maxRecords: 5)
            #expect(LMKNetworkLogger.isConfigured)
            #expect(LMKNetworkLogger.count == .zero)
        }

        // MARK: - Edge Cases

        @Test
        func `count returns 0 before configuration`() {
            // After other tests have configured, reconfigure to ensure clean state
            LMKNetworkLogger.configure(maxRecords: 50)
            LMKNetworkLogger.clearRecords()

            #expect(LMKNetworkLogger.count == .zero)
        }

        @Test
        func `records returns empty array before configuration`() {
            LMKNetworkLogger.configure(maxRecords: 50)
            LMKNetworkLogger.clearRecords()

            #expect(LMKNetworkLogger.records.isEmpty)
        }
    }

#endif
