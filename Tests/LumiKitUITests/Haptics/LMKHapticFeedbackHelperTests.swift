//
//  LMKHapticFeedbackHelperTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

// MARK: - LMKHapticFeedbackHelper

@MainActor
struct LMKHapticFeedbackHelperTests {
    @Test
    func `Feedback methods don't crash`() {
        LMKHapticFeedbackHelper.success()
        LMKHapticFeedbackHelper.warning()
        LMKHapticFeedbackHelper.error()
        LMKHapticFeedbackHelper.selection()
        LMKHapticFeedbackHelper.light()
        LMKHapticFeedbackHelper.medium()
        LMKHapticFeedbackHelper.heavy()
    }

    @Test
    func `Prepare methods don't crash`() {
        LMKHapticFeedbackHelper.prepareNotification()
        LMKHapticFeedbackHelper.prepareSelection()
        LMKHapticFeedbackHelper.prepareImpact(.light)
        LMKHapticFeedbackHelper.prepareImpact(.medium)
        LMKHapticFeedbackHelper.prepareImpact(.heavy)
        LMKHapticFeedbackHelper.prepareImpact(.rigid)
        LMKHapticFeedbackHelper.prepare()
    }
}
