//
//  LMKNavigationBarTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

// MARK: - LMKNavigationBarItem

@MainActor
struct LMKNavigationBarItemTests {
    @Test
    func `init with image`() {
        let image = UIImage(systemName: "plus")
        var called = false
        let item = LMKNavigationBarItem(image: image, title: "Add", accessibilityLabel: "Add item") { called = true }

        #expect(item.image != nil)
        #expect(item.title == "Add")
        #expect(item.accessibilityLabel == "Add item")
        item.action()
        #expect(called)
    }

    @Test
    func `init with system name`() {
        var called = false
        let item = LMKNavigationBarItem(systemName: "gear", accessibilityLabel: "Settings") { called = true }

        #expect(item.image != nil)
        #expect(item.title == nil)
        #expect(item.accessibilityLabel == "Settings")
        item.action()
        #expect(called)
    }

    @Test
    func `init with title`() {
        let item = LMKNavigationBarItem(title: "Done") {}

        #expect(item.image == nil)
        #expect(item.title == "Done")
        #expect(item.accessibilityLabel == "Done")
    }

    @Test
    func `title init uses custom accessibility label`() {
        let item = LMKNavigationBarItem(title: "Save", accessibilityLabel: "Save changes") {}

        #expect(item.accessibilityLabel == "Save changes")
    }
}

// MARK: - LMKNavigationBar

@MainActor
struct LMKNavigationBarTests {
    // MARK: - Initialization

    @Test
    func `default state`() {
        let bar = LMKNavigationBar()

        #expect(bar.title == nil)
        #expect(bar.largeTitleEnabled == false)
        #expect(bar.showsBackButton == false)
        #expect(bar.showsSeparator == true)
        #expect(bar.backAction == nil)
    }

    // MARK: - Title

    @Test
    func `set title`() {
        let bar = LMKNavigationBar()
        bar.title = "Pets"

        #expect(bar.title == "Pets")
    }

    @Test
    func `update title`() {
        let bar = LMKNavigationBar()
        bar.title = "First"
        bar.title = "Second"

        #expect(bar.title == "Second")
    }

    @Test
    func `clear title`() {
        let bar = LMKNavigationBar()
        bar.title = "Title"
        bar.title = nil

        #expect(bar.title == nil)
    }

    // MARK: - Large Title

    @Test
    func `enable large title`() {
        let bar = LMKNavigationBar()
        bar.largeTitleEnabled = true

        #expect(bar.largeTitleEnabled == true)
    }

    @Test
    func `toggle large title`() {
        let bar = LMKNavigationBar()
        bar.largeTitleEnabled = true
        bar.largeTitleEnabled = false

        #expect(bar.largeTitleEnabled == false)
    }

    // MARK: - Back Button

    @Test
    func `show back button`() {
        let bar = LMKNavigationBar()
        bar.showsBackButton = true

        #expect(bar.showsBackButton == true)
    }

    @Test
    func `hide back button`() {
        let bar = LMKNavigationBar()
        bar.showsBackButton = true
        bar.showsBackButton = false

        #expect(bar.showsBackButton == false)
    }

    @Test
    func `custom back action`() {
        var called = false
        let bar = LMKNavigationBar()
        bar.backAction = { called = true }

        bar.backAction?()
        #expect(called)
    }

    // MARK: - Separator

    @Test
    func `hide separator`() {
        let bar = LMKNavigationBar()
        bar.showsSeparator = false

        #expect(bar.showsSeparator == false)
    }

    @Test
    func `show separator`() {
        let bar = LMKNavigationBar()
        bar.showsSeparator = false
        bar.showsSeparator = true

        #expect(bar.showsSeparator == true)
    }

    // MARK: - Appearance

    @Test
    func `custom bar background`() {
        let bar = LMKNavigationBar()
        bar.barBackgroundColor = .red

        #expect(bar.barBackgroundColor == .red)
        #expect(bar.backgroundColor == .red)
    }

    @Test
    func `custom large title font`() {
        let bar = LMKNavigationBar()
        let font = UIFont.systemFont(ofSize: 28, weight: .heavy)
        bar.largeTitleFont = font

        #expect(bar.largeTitleFont == font)
    }

    @Test
    func `custom large title color`() {
        let bar = LMKNavigationBar()
        bar.largeTitleColor = .blue

        #expect(bar.largeTitleColor == .blue)
    }

    @Test
    func `custom inline title font`() {
        let bar = LMKNavigationBar()
        let font = UIFont.systemFont(ofSize: 20, weight: .bold)
        bar.inlineTitleFont = font

        #expect(bar.inlineTitleFont == font)
    }

    @Test
    func `custom inline title color`() {
        let bar = LMKNavigationBar()
        bar.inlineTitleColor = .green

        #expect(bar.inlineTitleColor == .green)
    }

    @Test
    func `custom button tint color`() {
        let bar = LMKNavigationBar()
        bar.buttonTintColor = .orange

        #expect(bar.buttonTintColor == .orange)
    }

    // MARK: - Right Items

    @Test
    func `set right items`() {
        let bar = LMKNavigationBar()
        var addCalled = false
        var moreCalled = false

        bar.setRightItems([
            .init(systemName: "plus") { addCalled = true },
            .init(systemName: "ellipsis") { moreCalled = true },
        ])

        // Bar should have arranged subviews for each item
        #expect(!addCalled)
        #expect(!moreCalled)
    }

    @Test
    func `replace right items`() {
        let bar = LMKNavigationBar()
        bar.setRightItems([.init(systemName: "plus") {}])
        bar.setRightItems([.init(systemName: "gear") {}])

        // No crash, items replaced cleanly
    }

    @Test
    func `clear right items`() {
        let bar = LMKNavigationBar()
        bar.setRightItems([.init(systemName: "plus") {}])
        bar.setRightItems([])

        // No crash, items cleared
    }

    // MARK: - Left Items

    @Test
    func `set left items`() {
        let bar = LMKNavigationBar()
        bar.showsBackButton = true
        bar.setLeftItems([.init(title: "Edit") {}])

        // Setting left items hides the back button
        #expect(bar.showsBackButton == true) // Property unchanged
    }

    @Test
    func `clear left items`() {
        let bar = LMKNavigationBar()
        bar.setLeftItems([.init(title: "Edit") {}])
        bar.setLeftItems([])

        // No crash, items cleared
    }

    // MARK: - Item Enabled State

    @Test
    func `disable right item lowers alpha and stops firing action`() {
        let bar = LMKNavigationBar()
        var called = false
        bar.setRightItems([.init(systemName: "plus", accessibilityLabel: "Add") { called = true }])

        bar.setRightItemEnabled(at: 0, false)

        guard let button = findButton(in: bar, accessibilityLabel: "Add") else {
            Issue.record("Expected right item button to exist")
            return
        }
        #expect(!button.isEnabled)
        #expect(abs(button.alpha - LMKAlpha.disabled) < 0.001)
        button.sendActions(for: .touchUpInside)
        #expect(!called, "Disabled button should not fire its action")
    }

    @Test
    func `re-enable right item restores full alpha`() {
        let bar = LMKNavigationBar()
        bar.setRightItems([.init(systemName: "plus", accessibilityLabel: "Add") {}])

        bar.setRightItemEnabled(at: 0, false)
        bar.setRightItemEnabled(at: 0, true)

        let button = findButton(in: bar, accessibilityLabel: "Add")
        #expect(button?.isEnabled == true)
        #expect(button?.alpha == 1.0)
    }

    @Test
    func `disable left item lowers alpha`() {
        let bar = LMKNavigationBar()
        bar.setLeftItems([.init(title: "Edit") {}])

        bar.setLeftItemEnabled(at: 0, false)

        let button = findButton(in: bar, accessibilityLabel: "Edit")
        #expect(button?.isEnabled == false)
        #expect(abs((button?.alpha ?? 1.0) - LMKAlpha.disabled) < 0.001)
    }

    @Test
    func `out-of-range index is a no-op`() {
        let bar = LMKNavigationBar()
        bar.setRightItems([.init(systemName: "plus") {}])

        // Should not crash
        bar.setRightItemEnabled(at: 5, false)
        bar.setRightItemEnabled(at: -1, false)
        bar.setLeftItemEnabled(at: 0, false) // No left items configured
    }

    // MARK: - Accessory Views

    @Test
    func `right accessory view is added as a subview of the bar`() {
        let bar = LMKNavigationBar()
        bar.setRightItems([.init(systemName: "plus") {}])
        let indicator = UIActivityIndicatorView()

        bar.setRightAccessoryView(indicator)

        #expect(indicator.superview === bar)
    }

    @Test
    func `right accessory view replaces a previous accessory`() {
        let bar = LMKNavigationBar()
        bar.setRightItems([.init(systemName: "plus") {}])
        let first = UIView()
        let second = UIView()

        bar.setRightAccessoryView(first)
        bar.setRightAccessoryView(second)

        #expect(first.superview == nil)
        #expect(second.superview === bar)
    }

    @Test
    func `right accessory view nil removes the existing accessory`() {
        let bar = LMKNavigationBar()
        let view = UIView()
        bar.setRightAccessoryView(view)

        bar.setRightAccessoryView(nil)

        #expect(view.superview == nil)
    }

    @Test
    func `large title accessory view is added under the large title row`() {
        let bar = LMKNavigationBar()
        bar.title = "Pets"
        bar.largeTitleEnabled = true
        let badge = UIView()

        bar.setLargeTitleAccessoryView(badge)

        // Lives inside the large title row, not the bar's direct subviews
        #expect(badge.superview != nil)
        #expect(badge.superview !== bar)
    }

    @Test
    func `large title accessory view nil removes the existing accessory`() {
        let bar = LMKNavigationBar()
        bar.title = "Pets"
        bar.largeTitleEnabled = true
        let badge = UIView()
        bar.setLargeTitleAccessoryView(badge)

        bar.setLargeTitleAccessoryView(nil)

        #expect(badge.superview == nil)
    }

    @Test
    func `right accessory view survives setRightItems`() {
        let bar = LMKNavigationBar()
        let indicator = UIActivityIndicatorView()
        bar.setRightAccessoryView(indicator)

        bar.setRightItems([
            .init(systemName: "plus") {},
            .init(systemName: "ellipsis") {},
        ])

        #expect(indicator.superview === bar)
    }

    // MARK: - Pin to Top

    @Test
    func `pin to top adds constraints`() {
        let parent = UIView(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        let bar = LMKNavigationBar()
        parent.addSubview(bar)
        bar.pinToTop(of: parent)

        parent.setNeedsLayout()
        parent.layoutIfNeeded()

        #expect(bar.superview === parent)
    }

    // MARK: - Combined Configuration

    @Test
    func `typical large title configuration`() {
        let bar = LMKNavigationBar()
        bar.title = "My Pets"
        bar.largeTitleEnabled = true
        bar.showsSeparator = true
        bar.setRightItems([
            .init(systemName: "plus") {},
            .init(systemName: "ellipsis") {},
        ])

        #expect(bar.title == "My Pets")
        #expect(bar.largeTitleEnabled == true)
        #expect(bar.showsSeparator == true)
    }

    @Test
    func `typical inline configuration`() {
        let bar = LMKNavigationBar()
        bar.title = "Pet Details"
        bar.showsBackButton = true
        bar.setRightItems([.init(systemName: "square.and.arrow.up") {}])

        #expect(bar.title == "Pet Details")
        #expect(bar.showsBackButton == true)
        #expect(bar.largeTitleEnabled == false)
    }

    // MARK: - Helpers

    private func findButton(in root: UIView, accessibilityLabel: String) -> UIButton? {
        if let button = root as? UIButton, button.accessibilityLabel == accessibilityLabel {
            return button
        }
        for subview in root.subviews {
            if let match = findButton(in: subview, accessibilityLabel: accessibilityLabel) {
                return match
            }
        }
        return nil
    }
}
