//
//  LMKHitExpandingControlsTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

@MainActor
struct LMKHitExpandingControlsTests {
    @Test
    func `The slider control and its track answer a 44pt touch around a 34pt row`() {
        let slider = LMKSlider()
        slider.frame = CGRect(x: 0, y: 0, width: 300, height: 34)
        slider.layoutIfNeeded()
        #expect(slider.point(inside: CGPoint(x: 150, y: -4), with: nil), "above the row")
        #expect(slider.point(inside: CGPoint(x: 150, y: 38), with: nil), "below the row")
        #expect(!slider.point(inside: CGPoint(x: 150, y: -6), with: nil))

        #expect(slider.slider is LMKHitExpandingSlider)
        slider.slider.frame = CGRect(x: 0, y: 0, width: 300, height: 34)
        #expect(slider.slider.point(inside: CGPoint(x: 150, y: -4), with: nil))
        #expect(!slider.slider.point(inside: CGPoint(x: 150, y: -6), with: nil))

        slider.isEnabled = false
        #expect(!slider.point(inside: CGPoint(x: 150, y: -4), with: nil), "a disabled control keeps its bounds")
        #expect(!slider.slider.point(inside: CGPoint(x: 150, y: 10), with: nil), "a disabled track takes no touch")
    }

    @Test
    func `The search field answers a 44pt touch around its 36pt row`() {
        let searchBar = LMKSearchBar()
        #expect(searchBar.textField is LMKHitExpandingTextField)
        searchBar.textField.frame = CGRect(x: 0, y: 0, width: 300, height: 36)
        #expect(searchBar.textField.point(inside: CGPoint(x: 100, y: -3), with: nil))
        #expect(searchBar.textField.point(inside: CGPoint(x: 100, y: 39), with: nil))
        #expect(!searchBar.textField.point(inside: CGPoint(x: 100, y: -5), with: nil))
    }
}
