//
//  LMKOverscrollFooterHelperTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

// MARK: - LMKOverscrollFooterHelper

@MainActor
struct LMKOverscrollFooterHelperTests {
    @Test
    func `Initial overscrollAmount is 0`() {
        let scrollView = UIScrollView(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        let footer = UIView()
        let helper = LMKOverscrollFooterHelper(footerView: footer, scrollView: scrollView, footerHeight: 160)
        #expect(helper.overscrollAmount == 0)
    }

    @Test
    func `Initial overscrollProgress is 0`() {
        let scrollView = UIScrollView(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        let footer = UIView()
        let helper = LMKOverscrollFooterHelper(footerView: footer, scrollView: scrollView, footerHeight: 160)
        #expect(helper.overscrollProgress == 0)
    }

    @Test
    func `Footer view is added to scroll view`() {
        let scrollView = UIScrollView(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        let footer = UIView()
        _ = LMKOverscrollFooterHelper(footerView: footer, scrollView: scrollView, footerHeight: 160)
        #expect(footer.superview === scrollView)
    }

    @Test
    func `updatePosition sets footer frame when content exists`() {
        let scrollView = UIScrollView(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        scrollView.contentSize = CGSize(width: 320, height: 1000)
        let footer = UIView()
        let helper = LMKOverscrollFooterHelper(footerView: footer, scrollView: scrollView, footerHeight: 160)

        helper.updatePosition()

        #expect(footer.frame.origin.y == 1000)
        #expect(footer.frame.width == 320)
        #expect(footer.frame.height == 160)
    }

    @Test
    func `updatePosition uses bounds height when content is shorter`() {
        let scrollView = UIScrollView(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        scrollView.contentSize = CGSize(width: 320, height: 200)
        let footer = UIView()
        let helper = LMKOverscrollFooterHelper(footerView: footer, scrollView: scrollView, footerHeight: 160)

        helper.updatePosition()

        // max(200, 480) = 480
        #expect(footer.frame.origin.y == 480)
    }

    @Test
    func `overscrollAmount calculated on overscroll`() {
        let scrollView = UIScrollView(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        scrollView.contentSize = CGSize(width: 320, height: 1000)
        let footer = UIView()
        let helper = LMKOverscrollFooterHelper(footerView: footer, scrollView: scrollView, footerHeight: 160)

        // Simulate scrolling past the end: contentOffset.y + bounds.height > contentSize.height
        scrollView.contentOffset = CGPoint(x: 0, y: 600)
        helper.updatePosition()

        // rawOverscroll = 600 + 480 - 1000 = 80
        #expect(helper.overscrollAmount == 80)
    }

    @Test
    func `overscrollAmount is 0 when not overscrolling`() {
        let scrollView = UIScrollView(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        scrollView.contentSize = CGSize(width: 320, height: 1000)
        let footer = UIView()
        let helper = LMKOverscrollFooterHelper(footerView: footer, scrollView: scrollView, footerHeight: 160)

        scrollView.contentOffset = CGPoint(x: 0, y: 100)
        helper.updatePosition()

        // rawOverscroll = 100 + 480 - 1000 = -420, clamped to 0
        #expect(helper.overscrollAmount == 0)
    }

    @Test
    func `overscrollProgress is normalized 0-1`() {
        let scrollView = UIScrollView(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        scrollView.contentSize = CGSize(width: 320, height: 1000)
        let footer = UIView()
        let helper = LMKOverscrollFooterHelper(footerView: footer, scrollView: scrollView, footerHeight: 160)

        // Half overscroll: 80 / 160 = 0.5
        scrollView.contentOffset = CGPoint(x: 0, y: 600)
        helper.updatePosition()
        #expect(helper.overscrollProgress == 0.5)
    }

    @Test
    func `overscrollProgress capped at 1.0`() {
        let scrollView = UIScrollView(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        scrollView.contentSize = CGSize(width: 320, height: 1000)
        let footer = UIView()
        let helper = LMKOverscrollFooterHelper(footerView: footer, scrollView: scrollView, footerHeight: 160)

        // Way past: rawOverscroll = 800 + 480 - 1000 = 280, 280/160 = 1.75 -> capped at 1.0
        scrollView.contentOffset = CGPoint(x: 0, y: 800)
        helper.updatePosition()
        #expect(helper.overscrollProgress == 1.0)
    }

    @Test
    func `overscrollProgress returns 0 when footerHeight is 0`() {
        let scrollView = UIScrollView(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        scrollView.contentSize = CGSize(width: 320, height: 1000)
        let footer = UIView()
        let helper = LMKOverscrollFooterHelper(footerView: footer, scrollView: scrollView, footerHeight: 0)
        #expect(helper.overscrollProgress == 0)
    }

    @Test
    func `updatePosition no-op when contentSize is zero`() {
        let scrollView = UIScrollView(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        scrollView.contentSize = .zero
        let footer = UIView()
        let helper = LMKOverscrollFooterHelper(footerView: footer, scrollView: scrollView, footerHeight: 160)

        helper.updatePosition()

        // Footer frame should not be set (still zero)
        #expect(helper.overscrollAmount == 0)
    }
}
