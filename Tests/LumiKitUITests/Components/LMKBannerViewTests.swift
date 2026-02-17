//
//  LMKBannerViewTests.swift
//  LumiKit
//

import Testing
import UIKit

@testable import LumiKitUI

// MARK: - LMKBannerView

@Suite("LMKBannerView")
@MainActor
struct LMKBannerViewTests {
    @Test("Banner creates with correct background")
    func creation() {
        let banner = LMKBannerView(type: .warning, message: "Test")
        #expect(banner.backgroundColor != nil)
    }

    @Test("Action title shows/hides button")
    func actionTitleToggle() {
        let banner = LMKBannerView(type: .info, message: "Test")
        banner.actionTitle = "Retry"
        #expect(banner.actionTitle == "Retry")
        banner.actionTitle = nil
        #expect(banner.actionTitle == nil)
    }

    @Test("Default strings are English")
    func defaultStrings() {
        let strings = LMKBannerView.Strings()
        #expect(strings.dismissAccessibilityLabel == "Dismiss")
    }

    @Test("Banner background uses type color with alpha")
    func bannerBackground() {
        let banner = LMKBannerView(type: .warning, message: "Test")
        #expect(banner.backgroundColor != nil)
        #expect(banner.backgroundColor != .clear)
    }

    @Test("Banner manages accessibility elements")
    func bannerAccessibilityElements() {
        let banner = LMKBannerView(type: .info, message: "Test")
        #expect(banner.accessibilityElements != nil)
        #expect(!banner.isAccessibilityElement)
    }
}
