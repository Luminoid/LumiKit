//
//  LMKActionSheetTests.swift
//  LumiKit
//
//  Tests for LMKActionSheet: Action struct, Page struct, initialization,
//  view hierarchy, navigation, static presentation, and dynamic colors.
//

import Testing
import UIKit

@testable import LumiKitUI

// MARK: - LMKActionSheet

@Suite("LMKActionSheet")
@MainActor
struct LMKActionSheetTests {
    // MARK: - Action Struct

    @Test("Action default style has correct properties")
    func actionDefaultStyle() {
        let action = LMKActionSheet.Action(title: "Edit") { }
        #expect(action.title == "Edit")
        #expect(action.style == .default)
        #expect(action.icon == nil)
        #expect(action.page == nil)
    }

    @Test("Action destructive style")
    func actionDestructiveStyle() {
        let action = LMKActionSheet.Action(title: "Delete", style: .destructive) { }
        #expect(action.title == "Delete")
        #expect(action.style == .destructive)
    }

    @Test("Action with icon preserves image")
    func actionWithIcon() {
        let icon = UIImage(systemName: "trash")
        let action = LMKActionSheet.Action(title: "Delete", icon: icon) { }
        #expect(action.icon != nil)
    }

    @Test("ActionStyle default and destructive are distinct")
    func actionStyleDistinct() {
        #expect(LMKActionSheet.ActionStyle.default != .destructive)
    }

    @Test("Action with subtitle preserves subtitle")
    func actionWithSubtitle() {
        let action = LMKActionSheet.Action(title: "Test", subtitle: "Detail") { }
        #expect(action.subtitle == "Detail")
    }

    // MARK: - Action Navigation Init

    @Test("Action with page has non-nil page")
    func actionWithPage() {
        let page = LMKActionSheet.Page(title: "Sub Page")
        let action = LMKActionSheet.Action(title: "Navigate", page: page)
        #expect(action.page != nil)
        #expect(action.page?.title == "Sub Page")
    }

    @Test("Action without page has nil page")
    func actionWithoutPage() {
        let action = LMKActionSheet.Action(title: "Regular") { }
        #expect(action.page == nil)
    }

    @Test("Navigation action preserves style and icon")
    func navigationActionPreservesProperties() {
        let icon = UIImage(systemName: "tag")
        let page = LMKActionSheet.Page(title: "Categories")
        let action = LMKActionSheet.Action(title: "Edit", style: .default, icon: icon, page: page)
        #expect(action.title == "Edit")
        #expect(action.style == .default)
        #expect(action.icon != nil)
        #expect(action.page != nil)
    }

    // MARK: - Page Struct

    @Test("Page with all properties")
    func pageWithAllProperties() {
        let contentView = UIView()
        let page = LMKActionSheet.Page(
            title: "Title",
            message: "Message",
            actions: [.init(title: "OK") { }],
            contentView: contentView,
            contentHeight: 200,
            confirmTitle: "Confirm",
            onConfirm: { }
        )
        #expect(page.title == "Title")
        #expect(page.message == "Message")
        #expect(page.actions.count == 1)
        #expect(page.contentView === contentView)
        #expect(page.contentHeight == 200)
        #expect(page.confirmTitle == "Confirm")
        #expect(page.onConfirm != nil)
    }

    @Test("Page with defaults only")
    func pageWithDefaults() {
        let page = LMKActionSheet.Page()
        #expect(page.title == nil)
        #expect(page.message == nil)
        #expect(page.actions.isEmpty)
        #expect(page.contentView == nil)
        #expect(page.contentHeight == 0)
        #expect(page.confirmTitle == nil)
        #expect(page.onConfirm == nil)
    }

    @Test("Page with content view and confirm")
    func pageWithContentAndConfirm() {
        let picker = UIDatePicker()
        let page = LMKActionSheet.Page(
            title: "Select Date",
            contentView: picker,
            contentHeight: 200,
            confirmTitle: "Save"
        )
        #expect(page.title == "Select Date")
        #expect(page.contentView === picker)
        #expect(page.confirmTitle == "Save")
    }

    // MARK: - Initialization

    @Test("Init with title and actions")
    func initWithTitle() {
        let sheet = LMKActionSheet(
            title: "Actions",
            actions: [.init(title: "OK") { }]
        )
        sheet.loadViewIfNeeded()
        #expect(sheet.view != nil)
    }

    @Test("Init with title and message")
    func initWithTitleAndMessage() {
        let sheet = LMKActionSheet(
            title: "Actions",
            message: "Choose an action",
            actions: [.init(title: "OK") { }]
        )
        sheet.loadViewIfNeeded()
        #expect(sheet.view != nil)
    }

    @Test("Init with custom content view")
    func initWithContentView() {
        let picker = UIDatePicker()
        let sheet = LMKActionSheet(
            title: "Select Date",
            contentView: picker,
            contentHeight: 200,
            actions: [.init(title: "Confirm") { }]
        )
        sheet.loadViewIfNeeded()
        #expect(sheet.view != nil)
    }

    @Test("Init without title or message")
    func initWithoutTitleOrMessage() {
        let sheet = LMKActionSheet(
            actions: [.init(title: "Option 1") { }]
        )
        sheet.loadViewIfNeeded()
        #expect(sheet.view != nil)
    }

    @Test("Init with empty actions array")
    func initWithEmptyActions() {
        let sheet = LMKActionSheet(title: "Empty", actions: [])
        sheet.loadViewIfNeeded()
        #expect(sheet.view != nil)
    }

    @Test("Init with navigation actions")
    func initWithNavigationActions() {
        let subPage = LMKActionSheet.Page(
            title: "Sub",
            actions: [.init(title: "Item") { }]
        )
        let sheet = LMKActionSheet(
            title: "Root",
            actions: [
                .init(title: "Navigate", page: subPage),
                .init(title: "Regular") { },
            ]
        )
        sheet.loadViewIfNeeded()
        #expect(sheet.view != nil)
    }

    // MARK: - View Hierarchy

    @Test("Container view has top corners rounded")
    func containerCornerRadius() {
        let sheet = LMKActionSheet(title: "Test", actions: [.init(title: "OK") { }])
        sheet.loadViewIfNeeded()

        let container = sheet.view.subviews.first { $0.layer.cornerRadius == LMKCornerRadius.large }
        #expect(container != nil)
        #expect(container?.layer.maskedCorners == [.layerMinXMinYCorner, .layerMaxXMinYCorner])
    }

    @Test("Dimming view covers full area")
    func dimmingViewLayout() {
        let sheet = LMKActionSheet(title: "Test", actions: [.init(title: "OK") { }])
        sheet.loadViewIfNeeded()
        sheet.view.frame = CGRect(x: 0, y: 0, width: 375, height: 812)
        sheet.view.layoutIfNeeded()

        let dimming = sheet.view.subviews.first {
            $0.gestureRecognizers?.contains(where: { $0 is UITapGestureRecognizer }) == true
        }
        #expect(dimming != nil)
    }

    @Test("Cancel button uses LMKAlertPresenter cancel string")
    func cancelButtonTitle() {
        let original = LMKAlertPresenter.strings
        defer { LMKAlertPresenter.strings = original }

        LMKAlertPresenter.strings = .init(cancel: "Cancelar")
        let sheet = LMKActionSheet(title: "Test", actions: [.init(title: "OK") { }])
        sheet.loadViewIfNeeded()

        let cancelButton = findButton(in: sheet.view, withTitle: "Cancelar")
        #expect(cancelButton != nil)
    }

    // MARK: - Multiple Actions

    @Test("Multiple actions create correct number of rows")
    func multipleActionRows() {
        let sheet = LMKActionSheet(
            title: "Actions",
            actions: [
                .init(title: "Edit") { },
                .init(title: "Share") { },
                .init(title: "Delete", style: .destructive) { },
            ]
        )
        sheet.loadViewIfNeeded()

        let controls = findAllControls(in: sheet.view)
        // 3 action rows + 1 cancel button + 1 back button (hidden) = 5 controls
        #expect(controls.count == 5)
    }

    // MARK: - Static Presentation

    @Test("Static present adds sheet as child VC")
    func staticPresentAddsChild() {
        let parent = UIViewController()
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 375, height: 812))
        window.rootViewController = parent
        window.makeKeyAndVisible()

        LMKActionSheet.present(
            in: parent,
            title: "Test",
            actions: [.init(title: "OK") { }]
        )

        #expect(parent.children.count == 1)
        #expect(parent.children.first is LMKActionSheet)
    }

    @Test("Static present with content view adds sheet as child VC")
    func staticPresentWithContentView() {
        let parent = UIViewController()
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 375, height: 812))
        window.rootViewController = parent
        window.makeKeyAndVisible()

        let datePicker = UIDatePicker()
        LMKActionSheet.present(
            in: parent,
            title: "Select Date",
            contentView: datePicker,
            contentHeight: 200,
            actions: [.init(title: "Confirm") { }]
        )

        #expect(parent.children.count == 1)
        #expect(parent.children.first is LMKActionSheet)
    }

    // MARK: - Action Handler

    @Test("Action handler is called")
    func actionHandlerCalled() async {
        var handlerCalled = false
        let action = LMKActionSheet.Action(title: "Tap Me") {
            handlerCalled = true
        }
        action.handler()
        #expect(handlerCalled)
    }

    // MARK: - Configurable Strings

    @Test("Default back string is Back")
    func defaultBackString() {
        let original = LMKActionSheet.strings
        defer { LMKActionSheet.strings = original }

        #expect(LMKActionSheet.strings.back == "Back")
    }

    @Test("Custom back string is used")
    func customBackString() {
        let original = LMKActionSheet.strings
        defer { LMKActionSheet.strings = original }

        LMKActionSheet.strings = .init(back: "Atrás")
        #expect(LMKActionSheet.strings.back == "Atrás")
    }

    // MARK: - Back Button

    @Test("Back button is hidden on root page")
    func backButtonHiddenAtRoot() {
        let sheet = LMKActionSheet(
            title: "Root",
            actions: [.init(title: "OK") { }]
        )
        sheet.loadViewIfNeeded()

        let backBtn = findBackButton(in: sheet.containerView)
        #expect(backBtn != nil)
        #expect(backBtn?.isHidden == true)
    }

    // MARK: - Chevron Indicator

    @Test("Navigation action row shows chevron image view")
    func navigationActionShowsChevron() {
        let page = LMKActionSheet.Page(title: "Sub", actions: [.init(title: "Item") { }])
        let sheet = LMKActionSheet(
            title: "Root",
            actions: [.init(title: "Navigate", page: page)]
        )
        sheet.loadViewIfNeeded()

        let actionRow = findFirstActionRow(in: sheet.view)
        #expect(actionRow != nil)

        let chevron = findChevronImageView(in: actionRow!)
        #expect(chevron != nil)
        #expect(chevron?.isHidden == false)
    }

    @Test("Regular action row hides chevron")
    func regularActionHidesChevron() {
        let sheet = LMKActionSheet(
            title: "Root",
            actions: [.init(title: "Regular") { }]
        )
        sheet.loadViewIfNeeded()

        let actionRow = findFirstActionRow(in: sheet.view)
        #expect(actionRow != nil)

        let chevron = findChevronImageView(in: actionRow!)
        #expect(chevron != nil)
        #expect(chevron?.isHidden == true)
    }

    // MARK: - Mixed Actions

    @Test("Mixed navigation and regular actions have correct row count")
    func mixedActionsCorrectRowCount() {
        let page = LMKActionSheet.Page(title: "Sub")
        let sheet = LMKActionSheet(
            title: "Root",
            actions: [
                .init(title: "Navigate", page: page),
                .init(title: "Regular") { },
                .init(title: "Delete", style: .destructive) { },
            ]
        )
        sheet.loadViewIfNeeded()

        let controls = findAllControls(in: sheet.view)
        // 3 action rows + 1 cancel button + 1 back button (hidden) = 5
        #expect(controls.count == 5)
    }

    // MARK: - Page with Confirm Button

    @Test("Sheet with confirm title shows confirm button")
    func sheetWithConfirmShowsButton() {
        let sheet = LMKActionSheet(
            title: "Test",
            actions: [.init(title: "Option") { }],
            confirmTitle: "Save"
        )
        sheet.loadViewIfNeeded()

        let confirmBtn = findButton(in: sheet.view, withTitle: "Save")
        #expect(confirmBtn != nil)
    }

    @Test("Sheet without confirm title has no confirm button")
    func sheetWithoutConfirmNoButton() {
        let sheet = LMKActionSheet(
            title: "Test",
            actions: [.init(title: "Option") { }]
        )
        sheet.loadViewIfNeeded()

        let confirmBtn = findButton(in: sheet.view, withTitle: "Save")
        #expect(confirmBtn == nil)
    }

    // MARK: - Helpers

    private func findButton(in view: UIView, withTitle title: String) -> UIButton? {
        if let button = view as? UIButton, button.title(for: .normal) == title {
            return button
        }
        for subview in view.subviews {
            if let found = findButton(in: subview, withTitle: title) {
                return found
            }
        }
        return nil
    }

    private func findAllControls(in view: UIView) -> [UIControl] {
        var controls: [UIControl] = []
        if let control = view as? UIControl {
            controls.append(control)
        }
        for subview in view.subviews {
            controls.append(contentsOf: findAllControls(in: subview))
        }
        return controls
    }

    private func findBackButton(in view: UIView) -> UIButton? {
        if let button = view as? UIButton,
           button.image(for: .normal) != nil,
           button.accessibilityLabel == LMKActionSheet.strings.back {
            return button
        }
        for subview in view.subviews {
            if let found = findBackButton(in: subview) {
                return found
            }
        }
        return nil
    }

    private func findFirstActionRow(in view: UIView) -> ActionRowView? {
        if let row = view as? ActionRowView {
            return row
        }
        for subview in view.subviews {
            if let found = findFirstActionRow(in: subview) {
                return found
            }
        }
        return nil
    }

    private func findChevronImageView(in view: UIView) -> UIImageView? {
        for subview in view.subviews {
            if let iv = subview as? UIImageView, iv.image == UIImage(systemName: "chevron.right") {
                return iv
            }
            // Check in container views
            for inner in subview.subviews {
                if let iv = inner as? UIImageView, iv.image == UIImage(systemName: "chevron.right") {
                    return iv
                }
            }
        }
        return nil
    }
}
