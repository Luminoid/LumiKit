//
//  LMKHapticFeedbackHelperTests.swift
//  LumiKit
//

import Testing
import UIKit

@testable import LumiKitUI

// MARK: - LMKHapticFeedbackHelper

@Suite("LMKHapticFeedbackHelper")
@MainActor
struct LMKHapticFeedbackHelperTests {
    @Test("Feedback methods don't crash")
    func feedbackMethods() {
        LMKHapticFeedbackHelper.success()
        LMKHapticFeedbackHelper.warning()
        LMKHapticFeedbackHelper.error()
        LMKHapticFeedbackHelper.selection()
        LMKHapticFeedbackHelper.light()
        LMKHapticFeedbackHelper.medium()
        LMKHapticFeedbackHelper.heavy()
    }

    @Test("Prepare methods don't crash")
    func prepareMethods() {
        LMKHapticFeedbackHelper.prepareNotification()
        LMKHapticFeedbackHelper.prepareSelection()
        LMKHapticFeedbackHelper.prepareImpact(.light)
        LMKHapticFeedbackHelper.prepareImpact(.medium)
        LMKHapticFeedbackHelper.prepareImpact(.heavy)
        LMKHapticFeedbackHelper.prepareImpact(.rigid)
        LMKHapticFeedbackHelper.prepare()
    }
}
