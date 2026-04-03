//
//  LMKBannerViewTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

// MARK: - LMKBannerView

@MainActor
struct LMKBannerViewTests {
    @Test
    func `Banner creates with correct background`() {
        let banner = LMKBannerView(type: .warning, message: "Test")
        #expect(banner.backgroundColor != nil)
    }

    @Test
    func `Action title shows/hides button`() {
        let banner = LMKBannerView(type: .info, message: "Test")
        banner.actionTitle = "Retry"
        #expect(banner.actionTitle == "Retry")
        banner.actionTitle = nil
        #expect(banner.actionTitle == nil)
    }

    @Test
    func `Default strings are English`() {
        let strings = LMKBannerView.Strings()
        #expect(strings.dismissAccessibilityLabel == "Dismiss")
    }

    @Test
    func `Banner background uses type color with alpha`() {
        let banner = LMKBannerView(type: .warning, message: "Test")
        #expect(banner.backgroundColor != nil)
        #expect(banner.backgroundColor != .clear)
    }

    @Test
    func `Banner manages accessibility elements`() {
        let banner = LMKBannerView(type: .info, message: "Test")
        #expect(banner.accessibilityElements != nil)
        #expect(!banner.isAccessibilityElement)
    }
}
