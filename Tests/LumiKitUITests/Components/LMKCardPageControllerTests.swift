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

@Suite("LMKCardPageController")
@MainActor
struct LMKCardPageControllerTests {
    // MARK: - Initialization

    @Test("Title is set from init")
    func titleFromInit() {
        let page = TestCardPage(title: "Settings")
        page.loadViewIfNeeded()

        #expect(page.headerTitleLabel.text == "Settings")
        #expect(page.title == "Settings")
    }

    // MARK: - Header Layout

    @Test("Header view has correct height")
    func headerHeight() {
        let page = TestCardPage(title: "Test")
        page.loadViewIfNeeded()
        page.view.frame = CGRect(x: 0, y: 0, width: 375, height: 600)
        page.view.layoutIfNeeded()

        #expect(page.headerView.frame.height == LMKCardPageLayout.headerHeight)
    }

    @Test("Header view background is backgroundPrimary")
    func headerBackground() {
        let page = TestCardPage(title: "Test")
        page.loadViewIfNeeded()

        #expect(page.headerView.backgroundColor == LMKColor.backgroundPrimary)
    }

    @Test("View background is backgroundPrimary")
    func viewBackground() {
        let page = TestCardPage(title: "Test")
        page.loadViewIfNeeded()

        #expect(page.view.backgroundColor == LMKColor.backgroundPrimary)
    }

    // MARK: - Leading Button

    @Test("Leading button has chevron.left image")
    func leadingButtonImage() {
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

    @Test("Leading button tint is secondary")
    func leadingButtonTint() {
        let page = TestCardPage(title: "Test")
        page.loadViewIfNeeded()

        #expect(page.leadingButton.tintColor == LMKColor.secondary)
    }

    @Test("Leading button visual size is 32pt")
    func leadingButtonSize() {
        let page = TestCardPage(title: "Test")
        page.loadViewIfNeeded()
        page.view.frame = CGRect(x: 0, y: 0, width: 375, height: 600)
        page.view.layoutIfNeeded()

        #expect(page.leadingButton.frame.width == 32)
        #expect(page.leadingButton.frame.height == 32)
    }

    // MARK: - Trailing Button

    @Test("Trailing button uses default doc.on.doc symbol")
    func trailingButtonDefaultSymbol() {
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

    @Test("Trailing button uses custom symbol from override")
    func trailingButtonCustomSymbol() {
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

    @Test("Trailing button tint is secondary")
    func trailingButtonTint() {
        let page = TestCardPage(title: "Test")
        page.loadViewIfNeeded()

        #expect(page.trailingButton.tintColor == LMKColor.secondary)
    }

    @Test("Trailing button visual size is 32pt")
    func trailingButtonSize() {
        let page = TestCardPage(title: "Test")
        page.loadViewIfNeeded()
        page.view.frame = CGRect(x: 0, y: 0, width: 375, height: 600)
        page.view.layoutIfNeeded()

        #expect(page.trailingButton.frame.width == 32)
        #expect(page.trailingButton.frame.height == 32)
    }

    // MARK: - Template Methods

    @Test("setupContent is called during viewDidLoad")
    func setupContentCalled() {
        let page = TestCardPage(title: "Test")
        #expect(!page.setupContentCalled)
        page.loadViewIfNeeded()
        #expect(page.setupContentCalled)
    }

    @Test("leadingButtonTapped pops navigation controller")
    func leadingButtonPopsNav() {
        let root = UIViewController()
        let nav = UINavigationController(rootViewController: root)
        let page = TestCardPage(title: "Test")
        nav.pushViewController(page, animated: false)

        #expect(nav.viewControllers.count == 2)
        page.leadingButtonTapped()
        #expect(nav.viewControllers.count == 1)
    }

    @Test("trailingButtonTapped is callable and records call")
    func trailingButtonTappedCallable() {
        let page = TestCardPage(title: "Test")
        page.loadViewIfNeeded()
        page.trailingButtonTapped()

        #expect(page.trailingButtonTappedCalled)
    }

    // MARK: - Custom Header Height

    @Test("Custom header height override is applied")
    func customHeaderHeight() {
        let page = CustomHeightCardPage(title: "Test")
        page.loadViewIfNeeded()
        page.view.frame = CGRect(x: 0, y: 0, width: 375, height: 600)
        page.view.layoutIfNeeded()

        #expect(page.headerView.frame.height == 64)
    }

    // MARK: - Title Label

    @Test("Title label has center alignment")
    func titleLabelAlignment() {
        let page = TestCardPage(title: "Test")
        page.loadViewIfNeeded()

        #expect(page.headerTitleLabel.textAlignment == .center)
    }

    @Test("Title label text color is textPrimary")
    func titleLabelColor() {
        let page = TestCardPage(title: "Test")
        page.loadViewIfNeeded()

        #expect(page.headerTitleLabel.textColor == LMKColor.textPrimary)
    }

    @Test("Title label uses LMKTypography.bodyBold")
    func titleLabelFont() {
        let page = TestCardPage(title: "Test")
        page.loadViewIfNeeded()

        #expect(page.headerTitleLabel.font == LMKTypography.bodyBold)
    }

    // MARK: - Configurable Strings

    @Test("Default leading button accessibility label is Back")
    func defaultLeadingAccessibilityLabel() {
        #expect(LMKCardPageController.strings.leadingButtonAccessibilityLabel == "Back")
    }

    @Test("Default trailing button accessibility label is Action")
    func defaultTrailingAccessibilityLabel() {
        #expect(LMKCardPageController.strings.trailingButtonAccessibilityLabel == "Action")
    }

    @Test("Custom strings are applied")
    func customStringsApplied() {
        let original = LMKCardPageController.strings
        defer { LMKCardPageController.strings = original }

        LMKCardPageController.strings = .init(
            leadingButtonAccessibilityLabel: "Atrás",
            trailingButtonAccessibilityLabel: "Acción"
        )
        #expect(LMKCardPageController.strings.leadingButtonAccessibilityLabel == "Atrás")
        #expect(LMKCardPageController.strings.trailingButtonAccessibilityLabel == "Acción")
    }

    @Test("Leading button has accessibility label from strings")
    func leadingButtonAccessibilityLabel() {
        let page = TestCardPage(title: "Test")
        page.loadViewIfNeeded()

        #expect(page.leadingButton.accessibilityLabel == LMKCardPageController.strings.leadingButtonAccessibilityLabel)
    }

    @Test("Trailing button has accessibility label from strings")
    func trailingButtonAccessibilityLabel() {
        let page = TestCardPage(title: "Test")
        page.loadViewIfNeeded()

        #expect(page.trailingButton.accessibilityLabel == LMKCardPageController.strings.trailingButtonAccessibilityLabel)
    }

    // MARK: - Button Visibility

    @Test("Leading button is hidden when showsLeadingButton is false")
    func leadingButtonHidden() {
        let page = NoButtonsCardPage(title: "Test")
        page.loadViewIfNeeded()

        #expect(page.leadingButton.isHidden)
    }

    @Test("Trailing button is hidden when showsTrailingButton is false")
    func trailingButtonHidden() {
        let page = NoButtonsCardPage(title: "Test")
        page.loadViewIfNeeded()

        #expect(page.trailingButton.isHidden)
    }

    @Test("Both buttons visible by default")
    func buttonsVisibleByDefault() {
        let page = TestCardPage(title: "Test")
        page.loadViewIfNeeded()

        #expect(!page.leadingButton.isHidden)
        #expect(!page.trailingButton.isHidden)
    }

    @Test("No back button page hides leading only")
    func noBackButtonHidesLeadingOnly() {
        let page = NoBackButtonCardPage(title: "Test")
        page.loadViewIfNeeded()

        #expect(page.leadingButton.isHidden)
        #expect(!page.trailingButton.isHidden)
    }

    // MARK: - Leading Button Symbol

    @Test("Leading button uses custom symbol from override")
    func leadingButtonCustomSymbol() {
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

    @Test("Separator is hidden by default")
    func separatorHiddenByDefault() {
        let page = TestCardPage(title: "Test")
        page.loadViewIfNeeded()

        #expect(page.headerSeparator.isHidden)
    }

    @Test("Separator is visible when showsHeaderSeparator is true")
    func separatorVisibleWhenEnabled() {
        let page = CustomLeadingCardPage(title: "Test")
        page.loadViewIfNeeded()

        #expect(!page.headerSeparator.isHidden)
    }

    @Test("Separator color is divider")
    func separatorColor() {
        let page = CustomLeadingCardPage(title: "Test")
        page.loadViewIfNeeded()

        #expect(page.headerSeparator.backgroundColor == LMKColor.divider)
    }

    // MARK: - Multi-Page Navigation

    @Test("canPopContent is false initially")
    func canPopContentInitiallyFalse() {
        let page = TestCardPage(title: "Test")
        page.loadViewIfNeeded()

        #expect(!page.canPopContent)
    }

    @Test("Push adds to navigation stack")
    func pushAddsToStack() {
        let page = TestCardPage(title: "Root")
        page.loadViewIfNeeded()
        page.view.frame = CGRect(x: 0, y: 0, width: 375, height: 600)
        page.view.layoutIfNeeded()

        let detailView = UIView()
        page.pushContentView(detailView, title: "Detail", animated: false)

        #expect(page.canPopContent)
    }

    @Test("Push updates title")
    func pushUpdatesTitle() {
        let page = TestCardPage(title: "Root")
        page.loadViewIfNeeded()
        page.view.frame = CGRect(x: 0, y: 0, width: 375, height: 600)
        page.view.layoutIfNeeded()

        page.pushContentView(UIView(), title: "Detail", animated: false)

        #expect(page.headerTitleLabel.text == "Detail")
        #expect(page.title == "Detail")
    }

    @Test("Push shows leading button even when showsLeadingButton is false")
    func pushShowsLeadingButton() {
        let page = NoBackButtonCardPage(title: "Root")
        page.loadViewIfNeeded()
        page.view.frame = CGRect(x: 0, y: 0, width: 375, height: 600)
        page.view.layoutIfNeeded()

        #expect(page.leadingButton.isHidden)

        page.pushContentView(UIView(), title: "Detail", animated: false)

        #expect(!page.leadingButton.isHidden)
    }

    @Test("Pop restores previous title")
    func popRestoresTitle() {
        let page = TestCardPage(title: "Root")
        page.loadViewIfNeeded()
        page.view.frame = CGRect(x: 0, y: 0, width: 375, height: 600)
        page.view.layoutIfNeeded()

        page.pushContentView(UIView(), title: "Detail", animated: false)
        page.popContentView(animated: false)

        #expect(page.headerTitleLabel.text == "Root")
        #expect(page.title == "Root")
    }

    @Test("Pop hides leading button when back at root with showsLeadingButton false")
    func popHidesLeadingButton() {
        let page = NoBackButtonCardPage(title: "Root")
        page.loadViewIfNeeded()
        page.view.frame = CGRect(x: 0, y: 0, width: 375, height: 600)
        page.view.layoutIfNeeded()

        page.pushContentView(UIView(), title: "Detail", animated: false)
        #expect(!page.leadingButton.isHidden)

        page.popContentView(animated: false)
        #expect(page.leadingButton.isHidden)
    }

    @Test("Pop does not hide leading button at root when showsLeadingButton is true")
    func popKeepsLeadingButtonVisible() {
        let page = TestCardPage(title: "Root")
        page.loadViewIfNeeded()
        page.view.frame = CGRect(x: 0, y: 0, width: 375, height: 600)
        page.view.layoutIfNeeded()

        page.pushContentView(UIView(), title: "Detail", animated: false)
        page.popContentView(animated: false)

        #expect(!page.leadingButton.isHidden)
    }

    @Test("canPopContent is false after popping last page")
    func canPopContentFalseAfterLastPop() {
        let page = TestCardPage(title: "Root")
        page.loadViewIfNeeded()
        page.view.frame = CGRect(x: 0, y: 0, width: 375, height: 600)
        page.view.layoutIfNeeded()

        page.pushContentView(UIView(), title: "Detail", animated: false)
        page.popContentView(animated: false)

        #expect(!page.canPopContent)
    }

    @Test("Pop content is invoked before popping nav controller when stack is non-empty")
    func popContentBeforeNav() {
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

    @Test("Push preserves title when nil is passed")
    func pushPreservesTitleWhenNil() {
        let page = TestCardPage(title: "Root")
        page.loadViewIfNeeded()
        page.view.frame = CGRect(x: 0, y: 0, width: 375, height: 600)
        page.view.layoutIfNeeded()

        page.pushContentView(UIView(), animated: false)

        #expect(page.headerTitleLabel.text == "Root")
    }

    // MARK: - Full Featured Example

    @Test("Full-featured page configures all options correctly")
    func fullFeaturedPage() {
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
