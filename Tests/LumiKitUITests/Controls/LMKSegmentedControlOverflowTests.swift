//
//  LMKSegmentedControlOverflowTests.swift
//  LumiKit
//
//  A fit-content control wider than its host once had one segment's width
//  broken by Auto Layout (a 4pt label at accessibility sizes, found by the
//  Example sweep); it scrolls instead.
//

import Testing
import UIKit
@testable import LumiKitUI

@MainActor
struct LMKSegmentedControlOverflowTests {
    @Test
    func `Fit-content segments keep their widths and scroll when the host is too narrow`() throws {
        let control = LMKSegmentedControl(items: ["Needs Attention", "Recently Updated", "Under Care", "Overdue"], style: .fitContent)
        let host = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 60))
        let window = UIWindow(frame: host.bounds)
        window.addSubview(host)
        host.addSubview(control)
        control.snp.makeConstraints { make in
            make.leading.top.equalToSuperview()
            make.trailing.lessThanOrEqualToSuperview()
        }
        window.layoutIfNeeded()

        #expect(control.bounds.width <= 200)
        #expect(control.scrollView.isScrollEnabled)
        #expect(!control.scrollView.bounces, "no bounce, so the pill drag wins while the content fits")
        #expect(control.scrollView.contentSize.width > 200, "the titles keep their measured widths")
        let narrowest = try #require(control.segmentLabels.map(\.bounds.width).min())
        #expect(narrowest > 40, "no segment collapsed")
        for (label, reference) in zip(control.segmentLabels, control.segmentReferenceWidths) {
            #expect(label.bounds.width >= reference, "\(label.text ?? "") is not narrower than its text")
        }
    }

    @Test
    func `A fit-content control that fits hugs its content and does not scroll`() {
        let control = LMKSegmentedControl(items: ["A", "B"], style: .fitContent)
        let host = UIView(frame: CGRect(x: 0, y: 0, width: 400, height: 60))
        let window = UIWindow(frame: host.bounds)
        window.addSubview(host)
        host.addSubview(control)
        control.snp.makeConstraints { make in
            make.leading.top.equalToSuperview()
            make.trailing.lessThanOrEqualToSuperview()
        }
        window.layoutIfNeeded()
        #expect(control.bounds.width < 200, "hugs the two short titles")
        #expect(control.scrollView.contentSize.width <= control.bounds.width + 0.5)
    }
}
