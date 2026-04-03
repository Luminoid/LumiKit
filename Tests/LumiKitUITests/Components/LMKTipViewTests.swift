//
//  LMKTipViewTests.swift
//  LumiKitUITests
//
//  Tests for tip component.
//

import Testing
import UIKit
@testable import LumiKitUI

@MainActor
struct LMKTipViewTests {
    // MARK: - Initialization

    @Test
    func `Init with message only uses defaults`() {
        let tip = LMKTipView(message: "Hello")

        #expect(tip.superview == nil)
        #expect(tip.onDismiss == nil)
    }

    @Test
    func `Init with title, message, and icon`() {
        let icon = UIImage(systemName: "star")
        let tip = LMKTipView(title: "Tip", message: "Message", icon: icon)

        #expect(tip.superview == nil)
    }

    // MARK: - Layout Constants

    @Test
    func `Layout constants have expected values`() {
        #expect(LMKTipLayout.arrowWidth == 16)
        #expect(LMKTipLayout.arrowHeight == 8)
        #expect(LMKTipLayout.arrowTipRadius == 2)
        #expect(LMKTipLayout.maxWidth == 300)
        #expect(LMKTipLayout.minMargin == 16)
        #expect(LMKTipLayout.sourceSpacing == 4)
        #expect(LMKTipLayout.iconBackgroundSize == 36)
    }

    // MARK: - Configurable Strings

    @Test
    func `Default strings have expected values`() {
        let strings = LMKTipView.Strings()

        #expect(strings.dismissAccessibilityHint == "Tap anywhere to dismiss")
        #expect(strings.dismissButtonTitle == "Got it")
    }

    // MARK: - Bubble Styling

    @Test
    func `Bubble view has correct corner radius`() {
        let tip = LMKTipView(message: "Test")

        // The bubble view is the second subview (after dimming)
        let bubble = tip.subviews.first { $0 !== tip.subviews.first }
        #expect(bubble?.layer.cornerRadius == LMKCornerRadius.medium)
    }

    @Test
    func `Bubble view has correct background color`() {
        let tip = LMKTipView(message: "Test")

        let bubble = tip.subviews.first { $0 !== tip.subviews.first }
        #expect(bubble?.backgroundColor == LMKColor.backgroundSecondary)
    }

    // MARK: - Dismiss Button

    @Test
    func `Dismiss button is hidden by default before show`() {
        let tip = LMKTipView(message: "Test")

        let bubble = tip.subviews.first { $0 !== tip.subviews.first }
        let buttons = findAllSubviews(in: bubble, ofType: UIButton.self)
        let dismissBtn = buttons.first { $0.title(for: .normal) == LMKTipView.strings.dismissButtonTitle }
        #expect(dismissBtn?.isHidden == true)
    }

    private func findAllSubviews<T: UIView>(in view: UIView?, ofType: T.Type) -> [T] {
        guard let view else { return [] }
        var result: [T] = []
        if let typed = view as? T { result.append(typed) }
        for sub in view.subviews {
            result.append(contentsOf: findAllSubviews(in: sub, ofType: ofType))
        }
        return result
    }

    // MARK: - Dimming

    @Test
    func `Dimming view is first subview`() {
        let tip = LMKTipView(message: "Test")

        let dimming = tip.subviews.first
        #expect(dimming != nil)
        #expect(dimming?.gestureRecognizers?.isEmpty == false)
    }

    @Test
    func `Dimming view has tap gesture recognizer`() {
        let tip = LMKTipView(message: "Test")

        let dimming = tip.subviews.first
        let tapGestures = dimming?.gestureRecognizers?.filter { $0 is UITapGestureRecognizer }
        #expect(tapGestures?.count == 1)
    }

    // MARK: - Accessibility

    @Test
    func `Bubble accessibility label contains message`() {
        let tip = LMKTipView(title: "Title", message: "Message")

        let bubble = tip.subviews.first { $0 !== tip.subviews.first }
        #expect(bubble?.accessibilityLabel == "Title. Message")
    }

    @Test
    func `Bubble accessibility label is message when no title`() {
        let tip = LMKTipView(message: "Just a message")

        let bubble = tip.subviews.first { $0 !== tip.subviews.first }
        #expect(bubble?.accessibilityLabel == "Just a message")
    }

    @Test
    func `Dimming view is accessible as button`() {
        let tip = LMKTipView(message: "Test")

        let dimming = tip.subviews.first
        #expect(dimming?.isAccessibilityElement == true)
        #expect(dimming?.accessibilityTraits == .button)
    }

    // MARK: - Dismiss Callback

    @Test
    func `Dismiss callback can be set`() {
        var dismissed = false
        let tip = LMKTipView(message: "Test")
        tip.onDismiss = { dismissed = true }

        // Verify callback is set by invoking it directly
        tip.onDismiss?()
        #expect(dismissed)
    }

    // MARK: - Icon

    @Test
    func `Icon with background circle is created when icon provided`() {
        let tip = LMKTipView(title: "Tip", message: "Msg", icon: UIImage(systemName: "star"))

        // Find the circular icon background (36pt round view)
        let bubble = tip.subviews.first { $0 !== tip.subviews.first }
        let iconBg = findSubview(in: bubble) { view in
            view.layer.cornerRadius == LMKTipLayout.iconBackgroundSize / 2
        }
        #expect(iconBg != nil)
    }

    private func findSubview(in view: UIView?, where predicate: (UIView) -> Bool) -> UIView? {
        guard let view else { return nil }
        if predicate(view) { return view }
        for sub in view.subviews {
            if let found = findSubview(in: sub, where: predicate) { return found }
        }
        return nil
    }
}
