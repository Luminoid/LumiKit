//
//  LMKDividerViewTests.swift
//  LumiKit
//

import Testing
import UIKit

@testable import LumiKitUI

// MARK: - LMKDividerView

@Suite("LMKDividerView")
@MainActor
struct LMKDividerViewTests {
    @Test("Horizontal divider intrinsic size")
    func horizontalIntrinsicSize() {
        let divider = LMKDividerView(orientation: .horizontal)
        let size = divider.intrinsicContentSize
        #expect(size.height > 0)
        #expect(size.width == UIView.noIntrinsicMetric)
    }

    @Test("Vertical divider intrinsic size")
    func verticalIntrinsicSize() {
        let divider = LMKDividerView(orientation: .vertical)
        let size = divider.intrinsicContentSize
        #expect(size.width > 0)
        #expect(size.height == UIView.noIntrinsicMetric)
    }

    @Test("Default color is LMKColor.divider")
    func defaultColor() {
        let divider = LMKDividerView()
        #expect(divider.backgroundColor == LMKColor.divider)
    }

    @Test("Custom color is applied")
    func customColor() {
        let divider = LMKDividerView(color: .red)
        #expect(divider.backgroundColor == .red)
    }
}
