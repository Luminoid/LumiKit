//
//  LMKHapticsTests.swift
//  LumiKit
//

import Testing
@testable import LumiKitUI

// MARK: - LMKHaptics

@MainActor
struct LMKHapticsTests {
    @Test
    func `isEnabled defaults on, round-trips, and keeps feedback calls safe when off`() {
        #expect(LMKHaptics.isEnabled)
        LMKHaptics.isEnabled = false
        defer { LMKHaptics.isEnabled = true }
        #expect(!LMKHaptics.isEnabled)
        LMKHaptics.success()
        LMKHaptics.light()
        LMKHaptics.selection()
    }

    @Test
    func `Feedback methods are callable in the test host (smoke)`() {
        LMKHaptics.success()
        LMKHaptics.warning()
        LMKHaptics.error()
        LMKHaptics.selection()
        LMKHaptics.light()
        LMKHaptics.medium()
        LMKHaptics.heavy()
    }

    @Test
    func `Prepare methods are callable in the test host (smoke)`() {
        LMKHaptics.prepareNotification()
        LMKHaptics.prepareSelection()
        LMKHaptics.prepareImpact(.light)
        LMKHaptics.prepareImpact(.medium)
        LMKHaptics.prepareImpact(.heavy)
        LMKHaptics.prepareImpact(.rigid)
        LMKHaptics.prepare()
    }
}
