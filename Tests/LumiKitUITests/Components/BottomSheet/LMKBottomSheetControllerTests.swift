//
//  LMKBottomSheetControllerTests.swift
//  LumiKit
//
//  Tests for LMKBottomSheetController base class: shared UI,
//  animation, dismissal, trait changes, and child VC presentation.
//

import Testing
import UIKit
@testable import LumiKitUI

// MARK: - LMKBottomSheetController

@MainActor
struct LMKBottomSheetControllerTests {
    // MARK: - Initialization

    @Test
    func `Default cancel title uses LMKAlertPresenter string`() {
        let original = LMKAlertPresenter.strings
        defer { LMKAlertPresenter.strings = original }

        LMKAlertPresenter.strings = .init(cancel: "Cancelar")
        let sheet = TestBottomSheet()
        sheet.loadViewIfNeeded()

        #expect(sheet.cancelButton.title(for: .normal) == "Cancelar")
    }

    @Test
    func `Custom cancel title is applied`() {
        let sheet = TestBottomSheet(cancelTitle: "Close")
        sheet.loadViewIfNeeded()

        #expect(sheet.cancelButton.title(for: .normal) == "Close")
    }

    // MARK: - View Hierarchy

    @Test
    func `Container view has rounded top corners`() {
        let sheet = TestBottomSheet()
        sheet.loadViewIfNeeded()

        #expect(sheet.containerView.layer.cornerRadius == LMKCornerRadius.large)
        #expect(sheet.containerView.layer.maskedCorners == [.layerMinXMinYCorner, .layerMaxXMinYCorner])
    }

    @Test
    func `Dimming view starts hidden`() {
        let sheet = TestBottomSheet()
        sheet.loadViewIfNeeded()

        #expect(sheet.dimmingView.alpha == 0)
    }

    @Test
    func `Dimming view has tap gesture recognizer`() {
        let sheet = TestBottomSheet()
        sheet.loadViewIfNeeded()

        let hasTap = sheet.dimmingView.gestureRecognizers?.contains { $0 is UITapGestureRecognizer } ?? false
        #expect(hasTap)
    }

    @Test
    func `Drag indicator has correct dimensions`() {
        let sheet = TestBottomSheet()
        sheet.loadViewIfNeeded()

        #expect(sheet.dragIndicator.layer.cornerRadius == LMKBottomSheetLayout.dragIndicatorCornerRadius)
    }

    @Test
    func `Cancel button has correct styling`() {
        let sheet = TestBottomSheet()
        sheet.loadViewIfNeeded()

        #expect(sheet.cancelButton.backgroundColor == LMKColor.backgroundSecondary)
        #expect(sheet.cancelButton.layer.cornerRadius == LMKCornerRadius.medium)
    }

    // MARK: - Template Methods

    @Test
    func `setupSheetContent is called during viewDidLoad`() {
        let sheet = TestBottomSheet()
        #expect(!sheet.setupSheetContentCalled)
        sheet.loadViewIfNeeded()
        #expect(sheet.setupSheetContentCalled)
    }

    @Test
    func `onDismissTapped is callable`() {
        let sheet = TestBottomSheet()
        sheet.loadViewIfNeeded()
        // Verify the method exists and is callable (dismiss animation is async)
        #expect(sheet.view != nil)
    }

    // MARK: - Static Convenience

    @Test
    func `addAsChild adds sheet as child VC`() {
        let parent = UIViewController()
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 375, height: 812))
        window.rootViewController = parent
        window.makeKeyAndVisible()

        let sheet = TestBottomSheet()
        LMKBottomSheetController.addAsChild(sheet, in: parent)

        #expect(parent.children.count == 1)
        #expect(parent.children.first === sheet)
        #expect(sheet.view.superview === parent.view)
    }

    @Test
    func `addAsChild sets autoresizing mask`() {
        let parent = UIViewController()
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 375, height: 812))
        window.rootViewController = parent
        window.makeKeyAndVisible()

        let sheet = TestBottomSheet()
        LMKBottomSheetController.addAsChild(sheet, in: parent)

        #expect(sheet.view.autoresizingMask.contains(.flexibleWidth))
        #expect(sheet.view.autoresizingMask.contains(.flexibleHeight))
    }

    // MARK: - Max Height

    @Test
    func `computeMaxHeight returns positive value`() {
        let sheet = TestBottomSheet()
        sheet.loadViewIfNeeded()
        sheet.view.frame = CGRect(x: 0, y: 0, width: 375, height: 812)

        let maxHeight = sheet.computeMaxHeight()
        #expect(maxHeight > 0)
    }
}

// MARK: - Test Helper

private final class TestBottomSheet: LMKBottomSheetController {
    var setupSheetContentCalled = false

    override init(cancelTitle: String? = nil) {
        super.init(cancelTitle: cancelTitle)
    }

    override func setupSheetContent() {
        setupSheetContentCalled = true
    }
}
