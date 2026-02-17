//
//  LMKActionSheetTests.swift
//  LumiKit
//
//  Tests for LMKActionSheet: Action struct, initialization,
//  view hierarchy, static presentation, and dynamic colors.
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
        // 3 action rows + 1 cancel button = 4 controls
        #expect(controls.count == 4)
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
}
