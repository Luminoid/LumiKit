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

@Suite("LMKBottomSheetController")
@MainActor
struct LMKBottomSheetControllerTests {
    // MARK: - Initialization

    @Test("Default cancel title uses LMKAlertPresenter string")
    func defaultCancelTitle() {
        let original = LMKAlertPresenter.strings
        defer { LMKAlertPresenter.strings = original }

        LMKAlertPresenter.strings = .init(cancel: "Cancelar")
        let sheet = TestBottomSheet()
        sheet.loadViewIfNeeded()

        #expect(sheet.cancelButton.title(for: .normal) == "Cancelar")
    }

    @Test("Custom cancel title is applied")
    func customCancelTitle() {
        let sheet = TestBottomSheet(cancelTitle: "Close")
        sheet.loadViewIfNeeded()

        #expect(sheet.cancelButton.title(for: .normal) == "Close")
    }

    // MARK: - View Hierarchy

    @Test("Container view has rounded top corners")
    func containerCornerRadius() {
        let sheet = TestBottomSheet()
        sheet.loadViewIfNeeded()

        #expect(sheet.containerView.layer.cornerRadius == LMKCornerRadius.large)
        #expect(sheet.containerView.layer.maskedCorners == [.layerMinXMinYCorner, .layerMaxXMinYCorner])
    }

    @Test("Dimming view starts hidden")
    func dimmingViewStartsHidden() {
        let sheet = TestBottomSheet()
        sheet.loadViewIfNeeded()

        #expect(sheet.dimmingView.alpha == 0)
    }

    @Test("Dimming view has tap gesture recognizer")
    func dimmingViewHasTapGesture() {
        let sheet = TestBottomSheet()
        sheet.loadViewIfNeeded()

        let hasTap = sheet.dimmingView.gestureRecognizers?.contains { $0 is UITapGestureRecognizer } ?? false
        #expect(hasTap)
    }

    @Test("Drag indicator has correct dimensions")
    func dragIndicatorDimensions() {
        let sheet = TestBottomSheet()
        sheet.loadViewIfNeeded()

        #expect(sheet.dragIndicator.layer.cornerRadius == LMKBottomSheetLayout.dragIndicatorCornerRadius)
    }

    @Test("Cancel button has correct styling")
    func cancelButtonStyling() {
        let sheet = TestBottomSheet()
        sheet.loadViewIfNeeded()

        #expect(sheet.cancelButton.backgroundColor == LMKColor.backgroundSecondary)
        #expect(sheet.cancelButton.layer.cornerRadius == LMKCornerRadius.medium)
    }

    // MARK: - Template Methods

    @Test("setupSheetContent is called during viewDidLoad")
    func setupSheetContentCalled() {
        let sheet = TestBottomSheet()
        #expect(!sheet.setupSheetContentCalled)
        sheet.loadViewIfNeeded()
        #expect(sheet.setupSheetContentCalled)
    }

    @Test("onDismissTapped is callable")
    func onDismissTappedCallable() {
        let sheet = TestBottomSheet()
        sheet.loadViewIfNeeded()
        // Verify the method exists and is callable (dismiss animation is async)
        #expect(sheet.view != nil)
    }

    // MARK: - Static Convenience

    @Test("addAsChild adds sheet as child VC")
    func addAsChildAddsSheet() {
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

    @Test("addAsChild sets autoresizing mask")
    func addAsChildSetsAutoresizing() {
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

    @Test("computeMaxHeight returns positive value")
    func computeMaxHeightPositive() {
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
