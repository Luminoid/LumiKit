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
    func `Is a UIControl subclass`() {
        let control = LMKSegmentedControl(items: ["A"])
        #expect(control as Any is UIControl)
    }

    @Test
    func `selectedSegmentIndex = -1 does not crash`() {
        let control = LMKSegmentedControl(items: ["★", "★★", "★★★"])
        control.selectedSegmentIndex = -1
        #expect(control.selectedSegmentIndex == -1)
    }

    @Test
    func `selectedSegmentIndex out of upper bound does not crash`() {
        let control = LMKSegmentedControl(items: ["A", "B"])
        control.selectedSegmentIndex = 99
        #expect(control.selectedSegmentIndex == 99)
    }

    @Test
    func `Recovering from -1 to a valid index selects that segment`() {
        let control = LMKSegmentedControl(items: ["A", "B", "C"])
        control.selectedSegmentIndex = -1
        control.selectedSegmentIndex = 2
        #expect(control.selectedSegmentIndex == 2)
    }

    @Test
    func `fitsSegmentsToContent intrinsic width stays stable across selection changes`() {
        let control = LMKSegmentedControl(
            items: (1 ... 5).map { String(repeating: "\u{2605}", count: $0) }
        )
        control.fitsSegmentsToContent = true

        control.selectedSegmentIndex = -1
        let unselected = control.intrinsicContentSize.width

        control.selectedSegmentIndex = 0
        let firstSelected = control.intrinsicContentSize.width

        control.selectedSegmentIndex = 4
        let lastSelected = control.intrinsicContentSize.width

        #expect(unselected == firstSelected)
        #expect(firstSelected == lastSelected)
    }

    @Test
    func `fitsSegmentsToContent hugs content horizontally`() {
        let control = LMKSegmentedControl(items: ["A", "B"])
        #expect(control.contentHuggingPriority(for: .horizontal) == .defaultHigh)

        control.fitsSegmentsToContent = true
        #expect(control.contentHuggingPriority(for: .horizontal) == .required)

        control.fitsSegmentsToContent = false
        #expect(control.contentHuggingPriority(for: .horizontal) == .defaultHigh)
    }

    @Test
    func `itemPadding widens intrinsic width in fit-content mode`() {
        let control = LMKSegmentedControl(items: ["A", "B", "C"])
        control.fitsSegmentsToContent = true
        let basePadding = control.itemPadding
        let baseWidth = control.intrinsicContentSize.width

        control.itemPadding = basePadding + 10
        let widerWidth = control.intrinsicContentSize.width

        // Three segments: +10 padding on each side of each segment => +60 total.
        #expect(widerWidth == baseWidth + 60)
    }
}
