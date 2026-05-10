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
    func `Selecting last in-range index does not crash`() {
        let control = LMKSegmentedControl(items: ["A", "B", "C"])
        control.selectedSegmentIndex = 2
        #expect(control.selectedSegmentIndex == 2)
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

    @Test
    func `fitsSegmentsToContent + scrollable lays out without constraint conflict`() {
        // Labels of wildly different widths inside a scroll view. If fit mode
        // and the scrollable min-width floor both installed constraints on the
        // same label, short labels ("A") would break the "== refWidth + pad"
        // constraint (unsatisfiable vs ">= 44 + scrollablePad*2"). This test
        // triggers a layout pass and asserts no ambiguity/unsatisfiability.
        let control = LMKSegmentedControl(items: ["A", "BB", "CCC", "Long Label Here"])
        control.fitsSegmentsToContent = true
        let scroll = control.makeScrollableContainer()

        scroll.frame = CGRect(x: 0, y: 0, width: 200, height: 40)
        scroll.layoutIfNeeded()

        #expect(!control.hasAmbiguousLayout)
        #expect(control.isScrollable == true)
        // Content must exceed the scroll view viewport so scrolling makes sense.
        #expect(scroll.contentSize.width >= control.intrinsicContentSize.width)
    }

    @Test
    func `fitsSegmentsToContent + scrollable uses itemPadding not scrollableItemPadding`() {
        // In combined mode each label is pinned exactly to refWidth + itemPadding*2.
        // Changing `scrollableItemPadding` must not alter the intrinsic width.
        let control = LMKSegmentedControl(items: ["A", "BB", "CCC"])
        control.fitsSegmentsToContent = true
        _ = control.makeScrollableContainer()

        let baseline = control.intrinsicContentSize.width
        control.scrollableItemPadding += 100
        #expect(control.intrinsicContentSize.width == baseline)

        // But changing itemPadding should still widen it.
        control.itemPadding += 10
        #expect(control.intrinsicContentSize.width == baseline + 60)
    }

    @Test
    func `toggling fitsSegmentsToContent after scrollable does not conflict`() {
        // Reversed order vs the test above: scrollable first, then fit=true,
        // then fit=false. The min-width floor must reappear when fit is
        // turned off, and disappear when turned on.
        let control = LMKSegmentedControl(items: ["A", "BB"])
        _ = control.makeScrollableContainer()
        control.fitsSegmentsToContent = true
        control.fitsSegmentsToContent = false
        control.fitsSegmentsToContent = true

        control.frame = CGRect(x: 0, y: 0, width: 300, height: 40)
        control.layoutIfNeeded()

        #expect(!control.hasAmbiguousLayout)
    }

    @Test
    func `itemSpacing widens intrinsic width only when scrollable`() {
        // Non-scrollable mode always uses 0 stack spacing, so itemSpacing
        // changes must not affect intrinsic width there.
        let control = LMKSegmentedControl(items: ["A", "B", "C"])
        let nonScrollBase = control.intrinsicContentSize.width
        control.itemSpacing += 10
        #expect(control.intrinsicContentSize.width == nonScrollBase)

        // After entering scrollable mode, the gap between adjacent segments
        // is added (items.count - 1) times to the intrinsic width.
        _ = control.makeScrollableContainer()
        let scrollableBase = control.intrinsicContentSize.width
        control.itemSpacing += 5
        #expect(control.intrinsicContentSize.width == scrollableBase + 5 * 2)
    }

    @Test
    func `itemSpacing default matches previous hardcoded value`() {
        // Callers that relied on the old hardcoded LMKSpacing.medium gap in
        // scrollable mode should see the same intrinsic width out of the box.
        let control = LMKSegmentedControl(items: ["A", "B"])
        #expect(control.itemSpacing == LMKSpacing.medium)
    }

    @Test
    func `scrollable non-fit intrinsic width stays stable across selection changes`() {
        // Previously non-fit scrollable sized each segment from its live label
        // intrinsicContentSize, which differs between the selected (bodyMedium)
        // and unselected (subbodyMedium) fonts — the selected segment rendered
        // visibly wider. Per-label widths are now pinned at the wider
        // selected-state refWidth (+ scrollableItemPadding), so changing
        // selection must not shift intrinsic width.
        let control = LMKSegmentedControl(items: ["Month 1", "Month 2", "Month 12"])
        _ = control.makeScrollableContainer()

        control.selectedSegmentIndex = 0
        let firstSelected = control.intrinsicContentSize.width
        control.selectedSegmentIndex = 1
        let middleSelected = control.intrinsicContentSize.width
        control.selectedSegmentIndex = 2
        let lastSelected = control.intrinsicContentSize.width

        #expect(firstSelected == middleSelected)
        #expect(middleSelected == lastSelected)
    }
}
