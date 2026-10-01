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
    func `Counts and the current page are clamped instead of trapping`() {
        let indicator = LMKPageIndicator()
        indicator.numberOfPages = -1
        #expect(indicator.numberOfPages == 0)
        #expect(indicator.dotViews.isEmpty)
        #expect(!indicator.isAccessibilityElement, "nothing to read with no pages")
        indicator.maxVisibleDots = 0
        #expect(indicator.maxVisibleDots == 1)
        indicator.maxVisibleDots = 7
        indicator.numberOfPages = 5
        #expect(indicator.isAccessibilityElement)
        indicator.currentPage = 9
        #expect(indicator.currentPage == 4)
        #expect(indicator.dotViews[4].backgroundColor === LMKColor.primary)
        indicator.currentPage = -3
        #expect(indicator.currentPage == 0)
        indicator.currentPage = 4
        indicator.numberOfPages = 2
        #expect(indicator.currentPage == 1, "the page follows a shrinking count")
        #expect(indicator.accessibilityValue == "2 of 2")
        indicator.numberOfPages = 0
        #expect(indicator.currentPage == 0)
        #expect(indicator.accessibilityValue == "0 of 0")
    }

    @Test
    func `A window always holds maxVisibleDots pages, even and at the ends`() {
        let indicator = LMKPageIndicator()
        indicator.maxVisibleDots = 6
        indicator.numberOfPages = 10
        indicator.onPageChange = { _ in }
        indicator.frame = CGRect(x: 0, y: 0, width: 200, height: 8)
        indicator.layoutIfNeeded()
        #expect(indicator.dotViews.count == 6)
        indicator.currentPage = 9
        indicator.layoutIfNeeded()
        #expect(indicator.dotViews.last?.backgroundColor === LMKColor.primary, "the last page has its active dot")
        #expect(indicator.page(at: indicator.dotViews[5].center) == 9)
        #expect(indicator.page(at: indicator.dotViews[0].center) == 4)
        indicator.currentPage = 0
        indicator.layoutIfNeeded()
        #expect(indicator.dotViews.first?.backgroundColor === LMKColor.primary)
        #expect(indicator.page(at: indicator.dotViews[5].center) == 5)
        indicator.currentPage = 5
        indicator.layoutIfNeeded()
        #expect(indicator.page(at: indicator.dotViews[0].center) == 2, "centered as far as the ends allow")
        #expect(indicator.page(at: indicator.dotViews[5].center) == 7)
    }

    @Test
    func `A windowed row is centered on the dots as drawn`() {
        let indicator = LMKPageIndicator()
        indicator.maxVisibleDots = 5
        indicator.numberOfPages = 10
        indicator.frame = CGRect(x: 0, y: 0, width: 200, height: 8)
        indicator.layoutIfNeeded()
        func rowCenter() -> CGFloat {
            let minX = indicator.dotViews.map(\.frame.minX).min() ?? 0
            let maxX = indicator.dotViews.map(\.frame.maxX).max() ?? 0
            return (minX + maxX) / 2
        }
        #expect(abs(rowCenter() - 100) < 0.001)
        indicator.currentPage = 9
        indicator.layoutIfNeeded()
        #expect(abs(rowCenter() - 100) < 0.001, "the row does not shift as the active dot reaches an end")
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
        let sized = LMKPageIndicator(style: LMKPageIndicator.Style(smallDotSize: 3, activePillWidth: 30, expandsActiveDot: true, haptics: false))
        sized.maxVisibleDots = 3
        sized.numberOfPages = 5
        sized.frame = CGRect(x: 0, y: 0, width: 200, height: 8)
        sized.layoutIfNeeded()
        #expect(sized.dotViews[0].frame.width == 30, "the active dot is the pill")
        #expect(sized.dotViews[2].frame.size == CGSize(width: 3, height: 3), "the edge dot of a window is small")
        #expect(LMKPageIndicator.Style().merging(LMKPageIndicator.Style(haptics: false)).haptics == false)

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
