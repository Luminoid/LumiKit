//
//  LMKCardPageControllerTests.swift
//  LumiKit
//
//  Tests for LMKCardPageController: header layout, button configuration,
//  template methods, navigation, configurable strings, button visibility,
//  header separator, and multi-page navigation.
//

import SnapKit
import Testing
import UIKit
@testable import LumiKitUI

// MARK: - LMKCardPageController

@MainActor
struct LMKCardPageControllerTests {
    // MARK: - Initialization

    @Test
    func `Title is set from init`() {
        let page = TestCardPage(title: "Settings")
        page.loadViewIfNeeded()

        #expect(page.headerTitleLabel.text == "Settings")
        #expect(page.title == "Settings")
    }

    // MARK: - Header Layout

    @Test
    func `Header view has correct height`() {
        let page = TestCardPage(title: "Test")
        page.loadViewIfNeeded()
        page.view.frame = CGRect(x: 0, y: 0, width: 375, height: 600)
        page.view.layoutIfNeeded()

        #expect(page.headerView.frame.height == LMKCardPageLayout.headerHeight)
    }

    @Test
    func `Header view background is backgroundPrimary`() {
        let page = TestCardPage(title: "Test")
        page.loadViewIfNeeded()

        #expect(page.headerView.backgroundColor == LMKColor.backgroundPrimary)
    }

    @Test
    func `View background is backgroundPrimary`() {
        let page = TestCardPage(title: "Test")
        page.loadViewIfNeeded()

        #expect(page.view.backgroundColor == LMKColor.backgroundPrimary)
    }

    // MARK: - Leading Button

    @Test
    func `Leading button has chevron.left image`() {
        let page = TestCardPage(title: "Test")
        page.loadViewIfNeeded()

        let expectedImage = UIImage(
            systemName: "chevron.left",
            withConfiguration: UIImage.SymbolConfiguration(
                pointSize: LMKCardPageLayout.symbolPointSize,
                weight: LMKCardPageLayout.symbolWeight
            )
        )
        #expect(page.leadingButton.image(for: .normal) == expectedImage)
    }

    @Test
    func `Leading button tint is secondary`() {
        let page = TestCardPage(title: "Test")
        page.loadViewIfNeeded()

        #expect(page.leadingButton.tintColor == LMKColor.secondary)
    }

    @Test
    func `Leading button visual size is 32pt`() {
        let page = TestCardPage(title: "Test")
        page.loadViewIfNeeded()
        page.view.frame = CGRect(x: 0, y: 0, width: 375, height: 600)
        page.view.layoutIfNeeded()

        #expect(page.leadingButton.frame.width == 32)
        #expect(page.leadingButton.frame.height == 32)
    }

    // MARK: - Trailing Button

    @Test
    func `Trailing button uses default doc.on.doc symbol`() {
        let page = TestCardPage(title: "Test")
        page.loadViewIfNeeded()

        let expectedImage = UIImage(
            systemName: "doc.on.doc",
            withConfiguration: UIImage.SymbolConfiguration(
                pointSize: LMKCardPageLayout.symbolPointSize,
                weight: LMKCardPageLayout.symbolWeight
            )
        )
        #expect(page.trailingButton.image(for: .normal) == expectedImage)
    }

    @Test
    func `Trailing button uses custom symbol from override`() {
        let page = CustomSymbolCardPage(title: "Test")
        page.loadViewIfNeeded()

        let expectedImage = UIImage(
            systemName: "square.and.arrow.up",
            withConfiguration: UIImage.SymbolConfiguration(
                pointSize: LMKCardPageLayout.symbolPointSize,
                weight: LMKCardPageLayout.symbolWeight
            )
        )
        #expect(page.trailingButton.image(for: .normal) == expectedImage)
    }

    @Test
    func `Trailing button tint is secondary`() {
        let page = TestCardPage(title: "Test")
        page.loadViewIfNeeded()

        #expect(page.trailingButton.tintColor == LMKColor.secondary)
    }

    @Test
    func `Trailing button visual size is 32pt`() {
        let page = TestCardPage(title: "Test")
        page.loadViewIfNeeded()
        page.view.frame = CGRect(x: 0, y: 0, width: 375, height: 600)
        page.view.layoutIfNeeded()

        #expect(page.trailingButton.frame.width == 32)
        #expect(page.trailingButton.frame.height == 32)
    }

    // MARK: - Template Methods

    @Test
    func `setupContent is called during viewDidLoad`() {
        let page = TestCardPage(title: "Test")
        #expect(!page.setupContentCalled)
        page.loadViewIfNeeded()
        #expect(page.setupContentCalled)
    }

    @Test
    func `leadingButtonTapped pops navigation controller`() {
        let root = UIViewController()
        let nav = UINavigationController(rootViewController: root)
        let page = TestCardPage(title: "Test")
        nav.pushViewController(page, animated: false)

        #expect(nav.viewControllers.count == 2)
        page.leadingButtonTapped()
        #expect(nav.viewControllers.count == 1)
    }

    @Test
    func `trailingButtonTapped is callable and records call`() {
        let page = TestCardPage(title: "Test")
        page.loadViewIfNeeded()
        page.trailingButtonTapped()

        #expect(page.trailingButtonTappedCalled)
    }

    // MARK: - Custom Header Height

    @Test
    func `Custom header height override is applied`() {
        let page = CustomHeightCardPage(title: "Test")
        page.loadViewIfNeeded()
        page.view.frame = CGRect(x: 0, y: 0, width: 375, height: 600)
        page.view.layoutIfNeeded()

        #expect(page.headerView.frame.height == 64)
    }

    // MARK: - Title Label

    @Test
    func `Title label has center alignment`() {
        let page = TestCardPage(title: "Test")
        page.loadViewIfNeeded()

        #expect(page.headerTitleLabel.textAlignment == .center)
    }

    @Test
    func `Title label text color is textPrimary`() {
        let page = TestCardPage(title: "Test")
        page.loadViewIfNeeded()

        #expect(page.headerTitleLabel.textColor == LMKColor.textPrimary)
    }

    @Test
    func `Title label uses LMKTypography.bodyBold`() {
        let page = TestCardPage(title: "Test")
        page.loadViewIfNeeded()

        #expect(page.headerTitleLabel.font == LMKTypography.bodyBold)
    }

    // MARK: - Configurable Strings

    @Test
    func `Default leading button accessibility label is Back`() {
        #expect(LMKCardPageController.strings.leadingButtonAccessibilityLabel == "Back")
    }

    @Test
    func `Default trailing button accessibility label is Action`() {
        #expect(LMKCardPageController.strings.trailingButtonAccessibilityLabel == "Action")
    }

    @Test
    func `Custom strings are applied`() {
        let original = LMKCardPageController.strings
        defer { LMKCardPageController.strings = original }

        LMKCardPageController.strings = .init(
            leadingButtonAccessibilityLabel: "Atrás",
            trailingButtonAccessibilityLabel: "Acción"
        )
        #expect(LMKCardPageController.strings.leadingButtonAccessibilityLabel == "Atrás")
        #expect(LMKCardPageController.strings.trailingButtonAccessibilityLabel == "Acción")
    }

    @Test
    func `Leading button has accessibility label from strings`() {
        let page = TestCardPage(title: "Test")
        page.loadViewIfNeeded()

        #expect(page.leadingButton.accessibilityLabel == LMKCardPageController.strings.leadingButtonAccessibilityLabel)
    }

    @Test
    func `Trailing button has accessibility label from strings`() {
        let page = TestCardPage(title: "Test")
        page.loadViewIfNeeded()

        #expect(page.trailingButton.accessibilityLabel == LMKCardPageController.strings.trailingButtonAccessibilityLabel)
    }

    // MARK: - Button Visibility

    @Test
    func `Leading button is hidden when showsLeadingButton is false`() {
        let page = NoButtonsCardPage(title: "Test")
        page.loadViewIfNeeded()

        #expect(page.leadingButton.isHidden)
    }

    @Test
    func `Trailing button is hidden when showsTrailingButton is false`() {
        let page = NoButtonsCardPage(title: "Test")
        page.loadViewIfNeeded()

        #expect(page.trailingButton.isHidden)
    }

    @Test
    func `Both buttons visible by default`() {
        let page = TestCardPage(title: "Test")
        page.loadViewIfNeeded()

        #expect(!page.leadingButton.isHidden)
        #expect(!page.trailingButton.isHidden)
    }

    @Test
    func `No back button page hides leading only`() {
        let page = NoBackButtonCardPage(title: "Test")
        page.loadViewIfNeeded()

        #expect(page.leadingButton.isHidden)
        #expect(!page.trailingButton.isHidden)
    }

    // MARK: - Leading Button Symbol

    @Test
    func `Leading button uses custom symbol from override`() {
        let page = CustomLeadingCardPage(title: "Test")
        page.loadViewIfNeeded()

        let expectedImage = UIImage(
            systemName: "xmark",
            withConfiguration: UIImage.SymbolConfiguration(
                pointSize: LMKCardPageLayout.symbolPointSize,
                weight: LMKCardPageLayout.symbolWeight
            )
        )
        #expect(page.leadingButton.image(for: .normal) == expectedImage)
    }

    // MARK: - Header Separator

    @Test
    func `Separator is hidden by default`() {
        let page = TestCardPage(title: "Test")
        page.loadViewIfNeeded()

        #expect(page.headerSeparator.isHidden)
    }

    @Test
    func `Separator is visible when showsHeaderSeparator is true`() {
        let page = CustomLeadingCardPage(title: "Test")
        page.loadViewIfNeeded()

        #expect(!page.headerSeparator.isHidden)
    }

    @Test
    func `Separator color is divider`() {
        let page = CustomLeadingCardPage(title: "Test")
        page.loadViewIfNeeded()

        #expect(page.headerSeparator.backgroundColor == LMKColor.divider)
    }

    // MARK: - Multi-Page Navigation

    @Test
    func `canPopContent is false initially`() {
        let page = TestCardPage(title: "Test")
        page.loadViewIfNeeded()

        #expect(!page.canPopContent)
    }

    @Test
    func `Push adds to navigation stack`() {
        let page = TestCardPage(title: "Root")
        page.loadViewIfNeeded()
        page.view.frame = CGRect(x: 0, y: 0, width: 375, height: 600)
        page.view.layoutIfNeeded()

        let detailView = UIView()
        page.pushContentView(detailView, title: "Detail", animated: false)

        #expect(page.canPopContent)
    }

    @Test
    func `Push updates title`() {
        let page = TestCardPage(title: "Root")
        page.loadViewIfNeeded()
        page.view.frame = CGRect(x: 0, y: 0, width: 375, height: 600)
        page.view.layoutIfNeeded()

        page.pushContentView(UIView(), title: "Detail", animated: false)

        #expect(page.headerTitleLabel.text == "Detail")
        #expect(page.title == "Detail")
    }

    @Test
    func `Push shows leading button even when showsLeadingButton is false`() {
        let page = NoBackButtonCardPage(title: "Root")
        page.loadViewIfNeeded()
        page.view.frame = CGRect(x: 0, y: 0, width: 375, height: 600)
        page.view.layoutIfNeeded()

        #expect(page.leadingButton.isHidden)

        page.pushContentView(UIView(), title: "Detail", animated: false)

        #expect(!page.leadingButton.isHidden)
    }

    @Test
    func `Pop restores previous title`() {
        let page = TestCardPage(title: "Root")
        page.loadViewIfNeeded()
        page.view.frame = CGRect(x: 0, y: 0, width: 375, height: 600)
        page.view.layoutIfNeeded()

        page.pushContentView(UIView(), title: "Detail", animated: false)
        page.popContentView(animated: false)

        #expect(page.headerTitleLabel.text == "Root")
        #expect(page.title == "Root")
    }

    @Test
    func `Pop hides leading button when back at root with showsLeadingButton false`() {
        let page = NoBackButtonCardPage(title: "Root")
        page.loadViewIfNeeded()
        page.view.frame = CGRect(x: 0, y: 0, width: 375, height: 600)
        page.view.layoutIfNeeded()

        page.pushContentView(UIView(), title: "Detail", animated: false)
        #expect(!page.leadingButton.isHidden)

        page.popContentView(animated: false)
        #expect(page.leadingButton.isHidden)
    }

    @Test
    func `Pop does not hide leading button at root when showsLeadingButton is true`() {
        let page = TestCardPage(title: "Root")
        page.loadViewIfNeeded()
        page.view.frame = CGRect(x: 0, y: 0, width: 375, height: 600)
        page.view.layoutIfNeeded()

        page.pushContentView(UIView(), title: "Detail", animated: false)
        page.popContentView(animated: false)

        #expect(!page.leadingButton.isHidden)
    }

    @Test
    func `canPopContent is false after popping last page`() {
        let page = TestCardPage(title: "Root")
        page.loadViewIfNeeded()
        page.view.frame = CGRect(x: 0, y: 0, width: 375, height: 600)
        page.view.layoutIfNeeded()

        page.pushContentView(UIView(), title: "Detail", animated: false)
        page.popContentView(animated: false)

        #expect(!page.canPopContent)
    }

    @Test
    func `Pop content is invoked before popping nav controller when stack is non-empty`() {
        let page = TestCardPage(title: "Root")
        page.loadViewIfNeeded()
        page.view.frame = CGRect(x: 0, y: 0, width: 375, height: 600)
        page.view.layoutIfNeeded()

        page.pushContentView(UIView(), title: "Detail", animated: false)
        #expect(page.canPopContent)

        // popContentView is what the leading button action calls when stack is non-empty
        page.popContentView(animated: false)

        #expect(!page.canPopContent)
        #expect(page.headerTitleLabel.text == "Root")
    }

    @Test
    func `Push preserves title when nil is passed`() {
        let page = TestCardPage(title: "Root")
        page.loadViewIfNeeded()
        page.view.frame = CGRect(x: 0, y: 0, width: 375, height: 600)
        page.view.layoutIfNeeded()

        page.pushContentView(UIView(), animated: false)

        #expect(page.headerTitleLabel.text == "Root")
    }

    // MARK: - Full Featured Example

    @Test
    func `Full-featured page configures all options correctly`() {
        let page = FullFeaturedCardPage(title: "Full Featured")
        page.loadViewIfNeeded()
        page.view.frame = CGRect(x: 0, y: 0, width: 375, height: 600)
        page.view.layoutIfNeeded()

        // Header
        #expect(page.headerTitleLabel.text == "Full Featured")
        #expect(page.headerView.frame.height == 60)

        // Separator
        #expect(!page.headerSeparator.isHidden)

        // Both buttons visible
        #expect(!page.leadingButton.isHidden)
        #expect(!page.trailingButton.isHidden)

        // Content was set up
        #expect(page.setupContentCalled)

        // Template methods work
        page.leadingButtonTapped()
        #expect(page.leadingTapCalled)
        page.trailingButtonTapped()
        #expect(page.trailingTapCalled)
    }
}

// MARK: - Test Helpers

/// Basic test double with tracking.
private final class TestCardPage: LMKCardPageController {
    var setupContentCalled = false
    var trailingButtonTappedCalled = false

    override func setupContent() {
        setupContentCalled = true
    }

    override func trailingButtonTapped() {
        trailingButtonTappedCalled = true
    }
}

/// Example: Custom trailing button symbol.
private final class CustomSymbolCardPage: LMKCardPageController {
    override var trailingButtonSymbol: String { "square.and.arrow.up" }
}

/// Example: Custom header height.
private final class CustomHeightCardPage: LMKCardPageController {
    override var headerHeight: CGFloat { 64 }
}

/// Example: Card page with no buttons (standalone info page).
private final class NoButtonsCardPage: LMKCardPageController {
    override var showsLeadingButton: Bool { false }
    override var showsTrailingButton: Bool { false }
}

/// Example: Card page with custom leading symbol (xmark) and separator.
private final class CustomLeadingCardPage: LMKCardPageController {
    override var leadingButtonSymbol: String { "xmark" }
    override var showsHeaderSeparator: Bool { true }
    override var showsTrailingButton: Bool { false }
}

/// Example: Card page with no leading button (root page in a flow).
private final class NoBackButtonCardPage: LMKCardPageController {
    override var showsLeadingButton: Bool { false }
    override var trailingButtonSymbol: String { "ellipsis" }
}

/// Example: Full-featured card page demonstrating all configuration options.
private final class FullFeaturedCardPage: LMKCardPageController {
    var setupContentCalled = false
    var leadingTapCalled = false
    var trailingTapCalled = false

    override var leadingButtonSymbol: String { "arrow.left" }
    override var trailingButtonSymbol: String { "square.and.arrow.up" }
    override var headerHeight: CGFloat { 60 }
    override var showsHeaderSeparator: Bool { true }

    override func setupContent() {
        setupContentCalled = true

        let label = UILabel()
        label.text = "Example content"
        contentContainerView.addSubview(label)
        label.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(LMKSpacing.large)
            make.leading.trailing.equalToSuperview().inset(LMKSpacing.large)
        }
    }

    override func leadingButtonTapped() {
        leadingTapCalled = true
    }

    override func trailingButtonTapped() {
        trailingTapCalled = true
    }
}
