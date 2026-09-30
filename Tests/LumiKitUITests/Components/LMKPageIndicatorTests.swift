//
//  LMKPageIndicatorTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

@MainActor
struct LMKPageIndicatorTests {
    @Test
    func `Default state has zero pages and no size`() {
        let indicator = LMKPageIndicator()
        #expect(indicator.numberOfPages == 0)
        #expect(indicator.currentPage == 0)
        #expect(indicator.intrinsicContentSize == .zero)
        #expect(indicator.maxVisibleDots == 7)
        #expect(!indicator.expandsActiveDot)
    }

    @Test
    func `Setting numberOfPages rebuilds dots and windows them`() {
        let indicator = LMKPageIndicator()
        indicator.numberOfPages = 5
        #expect(indicator.dotViews.count == 5)
        indicator.maxVisibleDots = 5
        indicator.numberOfPages = 12
        #expect(indicator.dotViews.count == 5)
        indicator.numberOfPages = 4
        #expect(indicator.dotViews.count == 4)
    }

    @Test
    func `Intrinsic size follows the style and the pill`() {
        let indicator = LMKPageIndicator()
        indicator.numberOfPages = 3
        #expect(indicator.intrinsicContentSize == CGSize(width: 8 * 3 + 8 * 2, height: 8))
        indicator.expandsActiveDot = true
        #expect(abs(indicator.intrinsicContentSize.width - 56) < 0.001)
        indicator.style.dotSize = 10
        indicator.style.spacing = 4
        #expect(abs(indicator.intrinsicContentSize.width - 52) < 0.001)
        #expect(indicator.intrinsicContentSize.height == 10)
    }

    @Test
    func `Active and inactive dots take the style colors`() {
        let indicator = LMKPageIndicator()
        indicator.numberOfPages = 3
        indicator.currentPage = 1
        #expect(indicator.dotViews[1].backgroundColor === LMKColor.primary)
        #expect(indicator.dotViews[0].backgroundColor === LMKColor.fillStrong)
        indicator.style.activeColor = .red
        indicator.style.inactiveColor = .blue
        #expect(indicator.dotViews[1].backgroundColor == UIColor.red)
        #expect(indicator.dotViews[2].backgroundColor == UIColor.blue)
    }

    @Test
    func `Accessibility value reflects the page and honors per-instance strings`() {
        let indicator = LMKPageIndicator()
        indicator.numberOfPages = 3
        indicator.currentPage = 1
        #expect(indicator.accessibilityValue == "2 of 3")
        indicator.strings = LMKPageIndicator.Strings(pageFormat: "%lld / %lld")
        #expect(indicator.accessibilityValue == "2 / 3")
    }

    @Test
    func `Accessibility traits and adjustments require a handler`() {
        let indicator = LMKPageIndicator()
        indicator.numberOfPages = 3
        #expect(!indicator.accessibilityTraits.contains(.adjustable))
        indicator.accessibilityIncrement()
        #expect(indicator.currentPage == 0)

        var reported: Int?
        indicator.onPageChange = { reported = $0 }
        #expect(indicator.accessibilityTraits.contains(.adjustable))
        indicator.accessibilityIncrement()
        #expect(indicator.currentPage == 1)
        #expect(reported == 1)
        indicator.accessibilityDecrement()
        #expect(indicator.currentPage == 0)
        indicator.onPageChange = nil
        #expect(!indicator.accessibilityTraits.contains(.adjustable))
    }

    @Test
    func `Taps resolve the page under the point across a 44pt row`() {
        let indicator = LMKPageIndicator()
        indicator.numberOfPages = 3
        indicator.frame = CGRect(x: 0, y: 0, width: 200, height: 8)
        indicator.layoutIfNeeded()
        #expect(!indicator.point(inside: CGPoint(x: 100, y: -15), with: nil), "display-only indicators use their bounds")
        indicator.onPageChange = { _ in }
        #expect(indicator.point(inside: CGPoint(x: 100, y: -15), with: nil))
        let leftDot = indicator.dotViews[0].center
        let rightDot = indicator.dotViews[2].center
        #expect(indicator.page(at: CGPoint(x: leftDot.x, y: -15)) == 0)
        #expect(indicator.page(at: rightDot) == 2)
        #expect(indicator.page(at: CGPoint(x: 5, y: 4)) == nil)
    }

    @Test
    func `Right-to-left layouts mirror the dots`() {
        let indicator = LMKPageIndicator()
        indicator.numberOfPages = 3
        indicator.currentPage = 0
        indicator.frame = CGRect(x: 0, y: 0, width: 200, height: 8)
        indicator.layoutIfNeeded()
        let ltrFirst = indicator.dotViews[0].frame.minX
        indicator.semanticContentAttribute = .forceRightToLeft
        indicator.setNeedsLayout()
        indicator.layoutIfNeeded()
        let rtlFirst = indicator.dotViews[0].frame.minX
        #expect(rtlFirst > ltrFirst)
        #expect(indicator.dotViews[0].frame.maxX == 200 - ltrFirst)
    }

    @Test
    func `theme.pageIndicator supplies app-wide defaults`() {
        var theme = LMKTheme()
        theme.pageIndicator = LMKPageIndicator.Style(dotSize: 6, expandsActiveDot: true)
        let indicator = LMKPageIndicator()
        indicator.numberOfPages = 2
        let window = LMKThemeTesting.host(indicator, theme: theme)
        defer { window.isHidden = true }
        #expect(indicator.expandsActiveDot)
        #expect(indicator.intrinsicContentSize.height == 6)
    }
}
