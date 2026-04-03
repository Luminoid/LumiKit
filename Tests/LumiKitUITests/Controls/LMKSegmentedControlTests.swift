//
//  LMKSegmentedControlTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

@MainActor
struct LMKSegmentedControlTests {
    @Test
    func `Creates with correct number of segments`() {
        let control = LMKSegmentedControl(items: ["A", "B", "C"])
        #expect(control.numberOfSegments == 3)
    }

    @Test
    func `Default selected index is 0`() {
        let control = LMKSegmentedControl(items: ["X", "Y"])
        #expect(control.selectedSegmentIndex == 0)
    }

    @Test
    func `Handler can be set`() {
        let control = LMKSegmentedControl(items: ["A", "B"])
        control.valueChangedHandler = { _ in }
        #expect(control.valueChangedHandler != nil)
    }

    @Test
    func `setSelectedSegmentIndex updates index`() {
        let control = LMKSegmentedControl(items: ["A", "B", "C"])
        control.setSelectedSegmentIndex(2, animated: false)
        #expect(control.selectedSegmentIndex == 2)
    }

    @Test
    func `setSelectedSegmentIndex ignores out of bounds`() {
        let control = LMKSegmentedControl(items: ["A", "B"])
        control.setSelectedSegmentIndex(5, animated: false)
        #expect(control.selectedSegmentIndex == 0)
    }

    @Test
    func `isScrollable defaults to false`() {
        let control = LMKSegmentedControl(items: ["A", "B"])
        #expect(control.isScrollable == false)
    }

    @Test
    func `makeScrollableContainer sets isScrollable`() {
        let control = LMKSegmentedControl(items: ["A", "B", "C"])
        let scrollView = control.makeScrollableContainer()
        #expect(control.isScrollable == true)
        #expect(scrollView.subviews.contains(control))
        #expect(scrollView.showsHorizontalScrollIndicator == false)
    }

    @Test
    func `gestureRecognizerShouldBegin returns true when scrollable`() {
        let control = LMKSegmentedControl(items: ["A", "B"])
        control.isScrollable = true
        let gesture = UIPanGestureRecognizer()
        #expect(control.gestureRecognizerShouldBegin(gesture) == true)
    }

    @Test
    func `Init with [Any]? converts strings`() {
        let control = LMKSegmentedControl(items: ["Hello", "World"] as [Any]?)
        #expect(control.numberOfSegments == 2)
    }

    @Test
    func `Is a UIControl subclass`() {
        let control = LMKSegmentedControl(items: ["A"])
        #expect(control is UIControl)
    }
}
