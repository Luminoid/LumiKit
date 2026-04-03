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
    func `Default state has zero pages`() {
        let indicator = LMKPageIndicator()
        #expect(indicator.numberOfPages == 0)
        #expect(indicator.currentPage == 0)
    }

    @Test
    func `Setting numberOfPages rebuilds dots`() {
        let indicator = LMKPageIndicator()
        indicator.numberOfPages = 5
        #expect(indicator.numberOfPages == 5)
        #expect(indicator.subviews.count == 5)
    }

    @Test
    func `currentPage can be set`() {
        let indicator = LMKPageIndicator()
        indicator.numberOfPages = 3
        indicator.currentPage = 2
        #expect(indicator.currentPage == 2)
    }

    @Test
    func `Handler can be set`() {
        let indicator = LMKPageIndicator()
        indicator.pageChangedHandler = { _ in }
        #expect(indicator.pageChangedHandler != nil)
    }

    @Test
    func `Intrinsic content size is zero for zero pages`() {
        let indicator = LMKPageIndicator()
        #expect(indicator.intrinsicContentSize == .zero)
    }

    @Test
    func `Intrinsic content size is positive for pages`() {
        let indicator = LMKPageIndicator()
        indicator.numberOfPages = 3
        let size = indicator.intrinsicContentSize
        #expect(size.width > 0)
        #expect(size.height > 0)
    }

    @Test
    func `Accessibility value reflects page`() {
        let indicator = LMKPageIndicator()
        indicator.numberOfPages = 3
        indicator.currentPage = 1
        #expect(indicator.accessibilityValue == "2 of 3")
    }

    @Test
    func `Accessibility traits include adjustable`() {
        let indicator = LMKPageIndicator()
        #expect(indicator.accessibilityTraits.contains(.adjustable))
    }

    // MARK: - expandsActiveDot

    @Test
    func `expandsActiveDot defaults to false`() {
        let indicator = LMKPageIndicator()
        #expect(indicator.expandsActiveDot == false)
    }

    @Test
    func `Expanding pill increases intrinsic width`() {
        let indicator = LMKPageIndicator()
        indicator.numberOfPages = 3
        let normalWidth = indicator.intrinsicContentSize.width
        indicator.expandsActiveDot = true
        let expandedWidth = indicator.intrinsicContentSize.width
        #expect(expandedWidth > normalWidth)
    }

    // MARK: - maxVisibleDots

    @Test
    func `maxVisibleDots defaults to 7`() {
        let indicator = LMKPageIndicator()
        #expect(indicator.maxVisibleDots == 7)
    }

    @Test
    func `Windowed mode limits visible dots`() {
        let indicator = LMKPageIndicator()
        indicator.maxVisibleDots = 5
        indicator.numberOfPages = 12
        // Should only create 5 dot views, not 12
        #expect(indicator.subviews.count == 5)
    }

    @Test
    func `Non-windowed shows all dots`() {
        let indicator = LMKPageIndicator()
        indicator.maxVisibleDots = 7
        indicator.numberOfPages = 4
        #expect(indicator.subviews.count == 4)
    }
}
