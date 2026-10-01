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
    func `Horizontal and vertical intrinsic sizes use the resolved thickness`() {
        let horizontal = LMKDividerView(orientation: .horizontal)
        #expect(horizontal.intrinsicContentSize.height == horizontal.resolvedThickness)
        #expect(horizontal.intrinsicContentSize.width == UIView.noIntrinsicMetric)
        #expect(horizontal.resolvedThickness > 0)
        #expect(horizontal.resolvedThickness <= 1)

        let vertical = LMKDividerView(orientation: .vertical)
        #expect(vertical.intrinsicContentSize.width == vertical.resolvedThickness)
        #expect(vertical.intrinsicContentSize.height == UIView.noIntrinsicMetric)
        vertical.orientation = .horizontal
        #expect(vertical.intrinsicContentSize.width == UIView.noIntrinsicMetric)
    }

    @Test
    func `Default color is the divider token and custom colors apply`() {
        #expect(LMKDividerView().backgroundColor === LMKColor.divider)
        #expect(LMKDividerView(color: .red).backgroundColor == UIColor.red)
        let styled = LMKDividerView(style: LMKDividerView.Style(color: .blue, thickness: 2))
        #expect(styled.backgroundColor == UIColor.blue)
        #expect(styled.intrinsicContentSize.height == 2)
        styled.style.thickness = 3
        #expect(styled.intrinsicContentSize.height == 3)
    }

    @Test
    func `A dashed divider draws a shape layer instead of a background`() {
        let divider = LMKDividerView(style: LMKDividerView.Style(color: .red, thickness: 1, dash: [4, 2]))
        divider.frame = CGRect(x: 0, y: 0, width: 100, height: 1)
        divider.layoutIfNeeded()
        #expect(divider.backgroundColor == UIColor.clear)
        let shape = divider.layer.sublayers?.compactMap { $0 as? CAShapeLayer }.first
        #expect(shape?.isHidden == false)
        #expect(shape?.lineDashPattern == [4, 2])
        #expect(shape?.path != nil)
        #expect(shape?.lineWidth == 1)

        let hairline = LMKDividerView(style: LMKDividerView.Style(color: .red, thickness: 0.4, dash: [2, 2]))
        hairline.frame = CGRect(x: 0, y: 0, width: 100, height: 1)
        hairline.layoutIfNeeded()
        let hairlineShape = hairline.layer.sublayers?.compactMap { $0 as? CAShapeLayer }.first
        #expect(hairlineShape?.lineWidth == LMKLayout.pixelAligned(0.4, for: hairline), "the dash is drawn in whole pixels")
        #expect((hairlineShape?.lineWidth ?? 0) >= 1 / LMKScene.screenScale)
    }

    @Test
    func `theme.divider supplies app-wide defaults`() {
        var theme = LMKTheme()
        theme.divider = LMKDividerView.Style(color: .magenta, thickness: 4)
        let divider = LMKDividerView()
        let window = LMKThemeTesting.host(divider, theme: theme)
        defer { window.isHidden = true }
        #expect(divider.backgroundColor == UIColor.magenta)
        #expect(divider.intrinsicContentSize.height == 4)
    }
}
