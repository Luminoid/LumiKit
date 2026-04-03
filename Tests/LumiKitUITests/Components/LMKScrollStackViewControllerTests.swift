//
//  LMKScrollStackViewControllerTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

// MARK: - Test Helpers

private final class TestScrollVC: LMKScrollStackViewController {
    var setupStackContentCalled = false

    override func setupStackContent() {
        setupStackContentCalled = true
    }
}

private final class CustomScrollVC: LMKScrollStackViewController {
    override var stackSpacing: CGFloat { LMKSpacing.xl }
    override var contentInsets: UIEdgeInsets {
        UIEdgeInsets(top: LMKSpacing.xl, left: LMKSpacing.large, bottom: LMKSpacing.xl, right: LMKSpacing.large)
    }

    override var keyboardDismissMode: UIScrollView.KeyboardDismissMode { .interactive }
    override var alwaysBounceVertical: Bool { true }
    override var scrollViewUseSafeArea: Bool { false }
}

// MARK: - LMKScrollStackViewController (defaults)

@MainActor
struct LMKScrollStackViewControllerDefaultTests {
    @Test
    func `default stackSpacing is LMKSpacing.large`() {
        let vc = TestScrollVC()
        #expect(vc.stackSpacing == LMKSpacing.large)
    }

    @Test
    func `default keyboardDismissMode is .onDrag`() {
        let vc = TestScrollVC()
        #expect(vc.keyboardDismissMode == .onDrag)
    }

    @Test
    func `default alwaysBounceVertical is false`() {
        let vc = TestScrollVC()
        #expect(!vc.alwaysBounceVertical)
    }

    @Test
    func `default scrollViewUseSafeArea is true`() {
        let vc = TestScrollVC()
        #expect(vc.scrollViewUseSafeArea)
    }

    @Test
    func `default contentInsets uses cardPadding on all sides`() {
        let vc = TestScrollVC()
        let padding = LMKSpacing.cardPadding
        let expected = UIEdgeInsets(top: padding, left: padding, bottom: padding, right: padding)
        #expect(vc.contentInsets == expected)
    }
}

// MARK: - LMKScrollStackViewController (view hierarchy)

@MainActor
struct LMKScrollStackViewControllerHierarchyTests {
    @Test
    func `scrollView is added to view after loadViewIfNeeded`() {
        let vc = TestScrollVC()
        vc.loadViewIfNeeded()
        #expect(vc.scrollView.superview === vc.view)
    }

    @Test
    func `contentView is added to scrollView`() {
        let vc = TestScrollVC()
        vc.loadViewIfNeeded()
        #expect(vc.contentView.superview === vc.scrollView)
    }

    @Test
    func `stackView is added to contentView`() {
        let vc = TestScrollVC()
        vc.loadViewIfNeeded()
        #expect(vc.stackView.superview === vc.contentView)
    }

    @Test
    func `view background is backgroundPrimary`() {
        let vc = TestScrollVC()
        vc.loadViewIfNeeded()
        #expect(vc.view.backgroundColor == LMKColor.backgroundPrimary)
    }

    @Test
    func `stackView axis is vertical`() {
        let vc = TestScrollVC()
        vc.loadViewIfNeeded()
        #expect(vc.stackView.axis == .vertical)
    }

    @Test
    func `stackView alignment is fill`() {
        let vc = TestScrollVC()
        vc.loadViewIfNeeded()
        #expect(vc.stackView.alignment == .fill)
    }
}

// MARK: - LMKScrollStackViewController (template methods)

@MainActor
struct LMKScrollStackViewControllerTemplateTests {
    @Test
    func `setupStackContent is called during viewDidLoad`() {
        let vc = TestScrollVC()
        vc.loadViewIfNeeded()
        #expect(vc.setupStackContentCalled)
    }
}

// MARK: - LMKScrollStackViewController (custom configuration)

@MainActor
struct LMKScrollStackViewControllerCustomTests {
    @Test
    func `custom stackSpacing is applied to stackView`() {
        let vc = CustomScrollVC()
        vc.loadViewIfNeeded()
        #expect(vc.stackView.spacing == LMKSpacing.xl)
    }

    @Test
    func `custom keyboardDismissMode is applied to scrollView`() {
        let vc = CustomScrollVC()
        vc.loadViewIfNeeded()
        #expect(vc.scrollView.keyboardDismissMode == .interactive)
    }

    @Test
    func `custom alwaysBounceVertical is applied to scrollView`() {
        let vc = CustomScrollVC()
        vc.loadViewIfNeeded()
        #expect(vc.scrollView.alwaysBounceVertical)
    }
}

// MARK: - LMKScrollStackViewController (helpers)

@MainActor
struct LMKScrollStackViewControllerHelperTests {
    @Test
    func `addSectionHeader adds a UILabel to the stack view`() {
        let vc = TestScrollVC()
        vc.loadViewIfNeeded()
        vc.addSectionHeader("Test Header")
        #expect(vc.stackView.arrangedSubviews.count == 1)
        #expect(vc.stackView.arrangedSubviews.first is UILabel)
    }

    @Test
    func `addDivider adds a LMKDividerView to the stack view`() {
        let vc = TestScrollVC()
        vc.loadViewIfNeeded()
        vc.addDivider()
        #expect(vc.stackView.arrangedSubviews.count == 1)
        #expect(vc.stackView.arrangedSubviews.first is LMKDividerView)
    }
}
