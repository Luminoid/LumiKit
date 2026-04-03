//
//  LMKDividerViewTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

// MARK: - LMKDividerView

@MainActor
struct LMKDividerViewTests {
    @Test
    func `Horizontal divider intrinsic size`() {
        let divider = LMKDividerView(orientation: .horizontal)
        let size = divider.intrinsicContentSize
        #expect(size.height > 0)
        #expect(size.width == UIView.noIntrinsicMetric)
    }

    @Test
    func `Vertical divider intrinsic size`() {
        let divider = LMKDividerView(orientation: .vertical)
        let size = divider.intrinsicContentSize
        #expect(size.width > 0)
        #expect(size.height == UIView.noIntrinsicMetric)
    }

    @Test
    func `Default color is LMKColor.divider`() {
        let divider = LMKDividerView()
        #expect(divider.backgroundColor == LMKColor.divider)
    }

    @Test
    func `Custom color is applied`() {
        let divider = LMKDividerView(color: .red)
        #expect(divider.backgroundColor == .red)
    }
}
