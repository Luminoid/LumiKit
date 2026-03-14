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

@Suite("LMKScrollStackViewController (defaults)")
@MainActor
struct LMKScrollStackViewControllerDefaultTests {
    @Test("default stackSpacing is LMKSpacing.large")
    func defaultStackSpacing() {
        let vc = TestScrollVC()
        #expect(vc.stackSpacing == LMKSpacing.large)
    }

    @Test("default keyboardDismissMode is .onDrag")
    func defaultKeyboardDismissMode() {
        let vc = TestScrollVC()
        #expect(vc.keyboardDismissMode == .onDrag)
    }

    @Test("default alwaysBounceVertical is false")
    func defaultAlwaysBounceVertical() {
        let vc = TestScrollVC()
        #expect(!vc.alwaysBounceVertical)
    }

    @Test("default scrollViewUseSafeArea is true")
    func defaultScrollViewUseSafeArea() {
        let vc = TestScrollVC()
        #expect(vc.scrollViewUseSafeArea)
    }

    @Test("default contentInsets uses cardPadding on all sides")
    func defaultContentInsets() {
        let vc = TestScrollVC()
        let padding = LMKSpacing.cardPadding
        let expected = UIEdgeInsets(top: padding, left: padding, bottom: padding, right: padding)
        #expect(vc.contentInsets == expected)
    }
}

// MARK: - LMKScrollStackViewController (view hierarchy)

@Suite("LMKScrollStackViewController (view hierarchy)")
@MainActor
struct LMKScrollStackViewControllerHierarchyTests {
    @Test("scrollView is added to view after loadViewIfNeeded")
    func scrollViewInHierarchy() {
        let vc = TestScrollVC()
        vc.loadViewIfNeeded()
        #expect(vc.scrollView.superview === vc.view)
    }

    @Test("contentView is added to scrollView")
    func contentViewInScrollView() {
        let vc = TestScrollVC()
        vc.loadViewIfNeeded()
        #expect(vc.contentView.superview === vc.scrollView)
    }

    @Test("stackView is added to contentView")
    func stackViewInContentView() {
        let vc = TestScrollVC()
        vc.loadViewIfNeeded()
        #expect(vc.stackView.superview === vc.contentView)
    }

    @Test("view background is backgroundPrimary")
    func viewBackgroundColor() {
        let vc = TestScrollVC()
        vc.loadViewIfNeeded()
        #expect(vc.view.backgroundColor == LMKColor.backgroundPrimary)
    }

    @Test("stackView axis is vertical")
    func stackViewAxis() {
        let vc = TestScrollVC()
        vc.loadViewIfNeeded()
        #expect(vc.stackView.axis == .vertical)
    }

    @Test("stackView alignment is fill")
    func stackViewAlignment() {
        let vc = TestScrollVC()
        vc.loadViewIfNeeded()
        #expect(vc.stackView.alignment == .fill)
    }
}

// MARK: - LMKScrollStackViewController (template methods)

@Suite("LMKScrollStackViewController (template methods)")
@MainActor
struct LMKScrollStackViewControllerTemplateTests {
    @Test("setupStackContent is called during viewDidLoad")
    func setupStackContentCalled() {
        let vc = TestScrollVC()
        vc.loadViewIfNeeded()
        #expect(vc.setupStackContentCalled)
    }
}

// MARK: - LMKScrollStackViewController (custom configuration)

@Suite("LMKScrollStackViewController (custom configuration)")
@MainActor
struct LMKScrollStackViewControllerCustomTests {
    @Test("custom stackSpacing is applied to stackView")
    func customStackSpacing() {
        let vc = CustomScrollVC()
        vc.loadViewIfNeeded()
        #expect(vc.stackView.spacing == LMKSpacing.xl)
    }

    @Test("custom keyboardDismissMode is applied to scrollView")
    func customKeyboardDismissMode() {
        let vc = CustomScrollVC()
        vc.loadViewIfNeeded()
        #expect(vc.scrollView.keyboardDismissMode == .interactive)
    }

    @Test("custom alwaysBounceVertical is applied to scrollView")
    func customAlwaysBounceVertical() {
        let vc = CustomScrollVC()
        vc.loadViewIfNeeded()
        #expect(vc.scrollView.alwaysBounceVertical)
    }
}

// MARK: - LMKScrollStackViewController (helpers)

@Suite("LMKScrollStackViewController (helpers)")
@MainActor
struct LMKScrollStackViewControllerHelperTests {
    @Test("addSectionHeader adds a UILabel to the stack view")
    func sectionHeaderAddsLabel() {
        let vc = TestScrollVC()
        vc.loadViewIfNeeded()
        vc.addSectionHeader("Test Header")
        #expect(vc.stackView.arrangedSubviews.count == 1)
        #expect(vc.stackView.arrangedSubviews.first is UILabel)
    }

    @Test("addDivider adds a LMKDividerView to the stack view")
    func dividerAddsDividerView() {
        let vc = TestScrollVC()
        vc.loadViewIfNeeded()
        vc.addDivider()
        #expect(vc.stackView.arrangedSubviews.count == 1)
        #expect(vc.stackView.arrangedSubviews.first is LMKDividerView)
    }
}
