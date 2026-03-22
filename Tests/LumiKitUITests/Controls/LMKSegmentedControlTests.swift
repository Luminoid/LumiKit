//
//  LMKSegmentedControlTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

// MARK: - LMKSegmentedControl

@Suite("LMKSegmentedControl")
@MainActor
struct LMKSegmentedControlTests {
    @Test("Creates with correct number of segments")
    func creation() {
        let control = LMKSegmentedControl(items: ["A", "B", "C"])
        #expect(control.numberOfSegments == 3)
    }

    @Test("Handlers can be set")
    func handlersSet() {
        let control = LMKSegmentedControl(items: ["X", "Y"])
        control.valueChangedHandler = { _ in }
        control.didValueChangeHandler = { _ in }
        #expect(control.valueChangedHandler != nil)
        #expect(control.didValueChangeHandler != nil)
    }

    // MARK: - Scrollable

    @Test("isScrollable defaults to false")
    func scrollableDefault() {
        let control = LMKSegmentedControl(items: ["A", "B"])
        #expect(control.isScrollable == false)
    }

    @Test("gestureRecognizerShouldBegin returns true when scrollable")
    func gestureYieldsWhenScrollable() {
        let control = LMKSegmentedControl(items: ["A", "B"])
        control.isScrollable = true
        let gesture = UIPanGestureRecognizer()
        #expect(control.gestureRecognizerShouldBegin(gesture) == true)
    }

    @Test("makeScrollableContainer sets isScrollable and returns configured scroll view")
    func scrollableContainer() {
        let control = LMKSegmentedControl(items: ["A", "B", "C", "D", "E"])
        let scrollView = control.makeScrollableContainer()

        #expect(control.isScrollable == true)
        #expect(scrollView is LMKControlScrollView)
        #expect(scrollView.subviews.contains(control))
        #expect(scrollView.showsHorizontalScrollIndicator == false)
        #expect(scrollView.delaysContentTouches == false)
        #expect(scrollView.canCancelContentTouches == true)
    }
}

// MARK: - LMKControlScrollView

@Suite("LMKControlScrollView")
@MainActor
struct LMKControlScrollViewTests {
    @Test("touchesShouldCancel returns true for any view")
    func cancelsTouches() {
        let scrollView = LMKControlScrollView()
        let button = UIButton()
        let label = UILabel()
        #expect(scrollView.touchesShouldCancel(in: button) == true)
        #expect(scrollView.touchesShouldCancel(in: label) == true)
    }

    @Test("Configures scroll properties on init")
    func defaultProperties() {
        let scrollView = LMKControlScrollView()
        #expect(scrollView.showsHorizontalScrollIndicator == false)
        #expect(scrollView.delaysContentTouches == false)
        #expect(scrollView.canCancelContentTouches == true)
    }
}
