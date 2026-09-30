//
//  LMKOverscrollFooterViewTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

@MainActor
struct LMKOverscrollFooterViewTests {
    private func makeScrollView(contentHeight: CGFloat = 1000) -> UIScrollView {
        let scrollView = UIScrollView(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        scrollView.contentSize = CGSize(width: 320, height: contentHeight)
        return scrollView
    }

    @Test
    func `attach parks the footer below the content and follows the scroll view`() {
        let scrollView = makeScrollView()
        let content = UIView()
        let footer = LMKOverscrollFooterView(contentView: content, height: 160)
        #expect(footer.overscrollAmount == 0)
        #expect(footer.revealProgress == 0)
        #expect(content.superview === footer)
        footer.attach(to: scrollView)
        #expect(footer.superview === scrollView)
        #expect(footer.scrollView === scrollView)
        #expect(footer.frame == CGRect(x: 0, y: 1000, width: 320, height: 160))
        #expect(footer.alpha == 0)

        scrollView.contentSize = CGSize(width: 320, height: 200)
        #expect(footer.frame.origin.y == 480, "shorter content parks at the bounds height")

        scrollView.contentSize = CGSize(width: 320, height: 1000)
        scrollView.contentOffset = CGPoint(x: 0, y: 600)
        #expect(footer.overscrollAmount == 80)
        #expect(footer.revealProgress == 0.5)
        #expect(footer.alpha == 0.5)

        scrollView.contentOffset = CGPoint(x: 0, y: 100)
        #expect(footer.overscrollAmount == 0)
        #expect(footer.alpha == 0)

        scrollView.contentOffset = CGPoint(x: 0, y: 800)
        #expect(footer.revealProgress == 1)
        footer.fadesWithProgress = false
        #expect(footer.alpha == 1)
    }

    @Test
    func `Reveal callbacks fire with progress and once per pull past the threshold`() {
        let scrollView = makeScrollView()
        let footer = LMKOverscrollFooterView(contentView: UIView(), height: 160)
        var progresses: [CGFloat] = []
        var reveals = 0
        footer.onRevealProgress = { progresses.append($0) }
        footer.onReveal = { reveals += 1 }
        footer.revealThreshold = 0.5
        footer.attach(to: scrollView)

        scrollView.contentOffset = CGPoint(x: 0, y: 560)
        #expect(progresses == [0.25])
        #expect(reveals == 0)
        scrollView.contentOffset = CGPoint(x: 0, y: 600)
        #expect(reveals == 1)
        scrollView.contentOffset = CGPoint(x: 0, y: 700)
        #expect(reveals == 1, "only once per pull")
        scrollView.contentOffset = CGPoint(x: 0, y: 100)
        #expect(footer.revealProgress == 0)
        scrollView.contentOffset = CGPoint(x: 0, y: 700)
        #expect(reveals == 2, "re-armed after settling back")
    }

    @Test
    func `detach stops following and removes the footer; a zero height never reveals`() {
        let scrollView = makeScrollView()
        let footer = LMKOverscrollFooterView(contentView: UIView(), height: 160)
        footer.attach(to: scrollView)
        footer.detach()
        #expect(footer.superview == nil)
        #expect(footer.scrollView == nil)
        scrollView.contentOffset = CGPoint(x: 0, y: 700)
        #expect(footer.overscrollAmount == 0)

        let flat = LMKOverscrollFooterView(contentView: UIView(), height: 0)
        flat.attach(to: scrollView)
        scrollView.contentOffset = CGPoint(x: 0, y: 800)
        #expect(flat.revealProgress == 0)

        let empty = UIScrollView(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        let idle = LMKOverscrollFooterView(contentView: UIView(), height: 160)
        idle.attach(to: empty)
        #expect(idle.overscrollAmount == 0, "no content, no position")
    }
}
