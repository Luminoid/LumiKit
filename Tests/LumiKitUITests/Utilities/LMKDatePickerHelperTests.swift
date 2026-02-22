//
//  LMKDatePickerHelperTests.swift
//  LumiKit
//
//  Tests for LMKDatePickerHelper: date picker presentation,
//  date constraints, range picker, text field, configurable strings.
//

import LumiKitCore
import Testing
import UIKit

@testable import LumiKitUI

// MARK: - LMKDatePickerHelper

@Suite("LMKDatePickerHelper")
@MainActor
struct LMKDatePickerHelperTests {
    // MARK: - Setup

    private func makeHostVC() -> (UIViewController, UIWindow) {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 375, height: 812))
        let vc = UIViewController()
        window.rootViewController = vc
        window.makeKeyAndVisible()
        return (vc, window)
    }

    private func findDatePicker(in view: UIView) -> UIDatePicker? {
        if let picker = view as? UIDatePicker { return picker }
        for subview in view.subviews {
            if let found = findDatePicker(in: subview) { return found }
        }
        return nil
    }

    private func findAllDatePickers(in view: UIView) -> [UIDatePicker] {
        var pickers: [UIDatePicker] = []
        if let picker = view as? UIDatePicker { pickers.append(picker) }
        for subview in view.subviews {
            pickers.append(contentsOf: findAllDatePickers(in: subview))
        }
        return pickers
    }

    private func findTextField(in view: UIView) -> UITextField? {
        if let field = view as? UITextField { return field }
        for subview in view.subviews {
            if let found = findTextField(in: subview) { return found }
        }
        return nil
    }

    private func findActionSheet(in vc: UIViewController) -> LMKActionSheet? {
        vc.children.first { $0 is LMKActionSheet } as? LMKActionSheet
    }

    private func dayComponents(from date: Date) -> DateComponents {
        LMKDateHelper.calendar.dateComponents([.year, .month, .day], from: date)
    }

    // MARK: - presentDatePickerAlert

    @Test("presentDatePickerAlert adds action sheet as child")
    func presentDatePickerAlert_addsChild() {
        let (hostVC, _window) = makeHostVC()
        LMKDatePickerHelper.presentDatePickerAlert(
            on: hostVC,
            title: "Test",
            defaultDate: LMKDateHelper.today,
            onConfirm: { _ in }
        )
        #expect(findActionSheet(in: hostVC) != nil)
    }

    @Test("presentDatePickerAlert contains UIDatePicker")
    func presentDatePickerAlert_containsDatePicker() {
        let (hostVC, _window) = makeHostVC()
        LMKDatePickerHelper.presentDatePickerAlert(
            on: hostVC,
            title: "Test",
            defaultDate: LMKDateHelper.today,
            onConfirm: { _ in }
        )
        let sheet = findActionSheet(in: hostVC)
        #expect(sheet != nil)
        #expect(findDatePicker(in: sheet!.view) != nil)
    }

    @Test("presentDatePickerAlert applies default date")
    func presentDatePickerAlert_defaultDate() {
        let (hostVC, _window) = makeHostVC()
        let expectedDate = LMKDateHelper.calendar.date(byAdding: .day, value: -3, to: Date()) ?? Date()

        LMKDatePickerHelper.presentDatePickerAlert(
            on: hostVC,
            title: "Test",
            defaultDate: expectedDate,
            onConfirm: { _ in }
        )

        let sheet = findActionSheet(in: hostVC)
        let picker = findDatePicker(in: sheet!.view)
        #expect(picker != nil)
        #expect(dayComponents(from: picker!.date) == dayComponents(from: expectedDate))
    }

    @Test("presentDatePickerAlert sets maximum date to today by default")
    func presentDatePickerAlert_maximumDate() {
        let (hostVC, _window) = makeHostVC()
        LMKDatePickerHelper.presentDatePickerAlert(
            on: hostVC,
            title: "Test",
            defaultDate: LMKDateHelper.today,
            onConfirm: { _ in }
        )

        let sheet = findActionSheet(in: hostVC)
        let picker = findDatePicker(in: sheet!.view)
        #expect(picker != nil)
        #expect(picker!.maximumDate != nil)
        #expect(dayComponents(from: picker!.maximumDate!) == dayComponents(from: LMKDateHelper.today))
    }

    // MARK: - presentDatePicker

    @Test("presentDatePicker respects minimum and maximum date")
    func presentDatePicker_dateConstraints() {
        let (hostVC, _window) = makeHostVC()
        let minDate = LMKDateHelper.calendar.date(byAdding: .month, value: -1, to: LMKDateHelper.today)!
        let maxDate = LMKDateHelper.today

        LMKDatePickerHelper.presentDatePicker(
            on: hostVC,
            title: "Test",
            minimumDate: minDate,
            onConfirm: { _ in }
        )

        let sheet = findActionSheet(in: hostVC)
        let picker = findDatePicker(in: sheet!.view)
        #expect(picker != nil)
        #expect(dayComponents(from: picker!.minimumDate!) == dayComponents(from: minDate))
        #expect(dayComponents(from: picker!.maximumDate!) == dayComponents(from: maxDate))
    }

    // MARK: - presentFutureDatePicker

    @Test("presentFutureDatePicker sets minimum date to today")
    func presentFutureDatePicker_minimumDate() {
        let (hostVC, _window) = makeHostVC()
        LMKDatePickerHelper.presentFutureDatePicker(
            on: hostVC,
            title: "Test",
            onConfirm: { _ in }
        )

        let sheet = findActionSheet(in: hostVC)
        let picker = findDatePicker(in: sheet!.view)
        #expect(picker != nil)
        #expect(picker!.minimumDate != nil)
        #expect(dayComponents(from: picker!.minimumDate!) == dayComponents(from: LMKDateHelper.today))
        #expect(picker!.maximumDate == nil)
    }

    @Test("presentFutureDatePicker with excludeToday sets minimum to tomorrow")
    func presentFutureDatePicker_excludeToday() {
        let (hostVC, _window) = makeHostVC()
        let tomorrow = LMKDateHelper.calendar.date(byAdding: .day, value: 1, to: LMKDateHelper.today)!

        LMKDatePickerHelper.presentFutureDatePicker(
            on: hostVC,
            title: "Test",
            excludeToday: true,
            onConfirm: { _ in }
        )

        let sheet = findActionSheet(in: hostVC)
        let picker = findDatePicker(in: sheet!.view)
        #expect(picker != nil)
        #expect(dayComponents(from: picker!.minimumDate!) == dayComponents(from: tomorrow))
    }

    // MARK: - presentPastDatePicker

    @Test("presentPastDatePicker sets maximum date to today with no minimum")
    func presentPastDatePicker_dateConstraints() {
        let (hostVC, _window) = makeHostVC()
        LMKDatePickerHelper.presentPastDatePicker(
            on: hostVC,
            title: "Test",
            onConfirm: { _ in }
        )

        let sheet = findActionSheet(in: hostVC)
        let picker = findDatePicker(in: sheet!.view)
        #expect(picker != nil)
        #expect(dayComponents(from: picker!.maximumDate!) == dayComponents(from: LMKDateHelper.today))
        #expect(picker!.minimumDate == nil)
    }

    // MARK: - presentDateRangePicker

    @Test("presentDateRangePicker contains two date pickers")
    func presentDateRangePicker_twoPickers() {
        let (hostVC, _window) = makeHostVC()
        LMKDatePickerHelper.presentDateRangePicker(
            on: hostVC,
            title: "Test",
            onConfirm: { _, _ in }
        )

        let sheet = findActionSheet(in: hostVC)
        #expect(sheet != nil)
        let pickers = findAllDatePickers(in: sheet!.view)
        #expect(pickers.count == 2)
    }

    @Test("presentDateRangePicker uses compact style")
    func presentDateRangePicker_compactStyle() {
        let (hostVC, _window) = makeHostVC()
        LMKDatePickerHelper.presentDateRangePicker(
            on: hostVC,
            title: "Test",
            onConfirm: { _, _ in }
        )

        let sheet = findActionSheet(in: hostVC)
        let pickers = findAllDatePickers(in: sheet!.view)
        for picker in pickers {
            #expect(picker.preferredDatePickerStyle == .compact)
        }
    }

    // MARK: - presentDatePickerWithTextField

    @Test("presentDatePickerWithTextField contains text field and date picker")
    func presentDatePickerWithTextField_containsBoth() {
        let (hostVC, _window) = makeHostVC()
        LMKDatePickerHelper.presentDatePickerWithTextField(
            on: hostVC,
            title: "Test",
            onConfirm: { _, _ in }
        )

        let sheet = findActionSheet(in: hostVC)
        #expect(sheet != nil)
        #expect(findDatePicker(in: sheet!.view) != nil)
        #expect(findTextField(in: sheet!.view) != nil)
    }

    @Test("presentDatePickerWithTextField uses default placeholder from strings")
    func presentDatePickerWithTextField_defaultPlaceholder() {
        let original = LMKDatePickerHelper.strings
        defer { LMKDatePickerHelper.strings = original }
        LMKDatePickerHelper.strings = .init(textFieldPlaceholder: "Test placeholder")

        let (hostVC, _window) = makeHostVC()
        LMKDatePickerHelper.presentDatePickerWithTextField(
            on: hostVC,
            title: "Test",
            onConfirm: { _, _ in }
        )

        let sheet = findActionSheet(in: hostVC)
        let textField = findTextField(in: sheet!.view)
        #expect(textField?.placeholder == "Test placeholder")
    }

    @Test("presentDatePickerWithTextField respects custom placeholder override")
    func presentDatePickerWithTextField_customPlaceholder() {
        let (hostVC, _window) = makeHostVC()
        LMKDatePickerHelper.presentDatePickerWithTextField(
            on: hostVC,
            title: "Test",
            textFieldPlaceholder: "Custom override",
            onConfirm: { _, _ in }
        )

        let sheet = findActionSheet(in: hostVC)
        let textField = findTextField(in: sheet!.view)
        #expect(textField?.placeholder == "Custom override")
    }

    @Test("presentDatePickerWithTextField sets maximum date to today")
    func presentDatePickerWithTextField_maximumDate() {
        let (hostVC, _window) = makeHostVC()
        LMKDatePickerHelper.presentDatePickerWithTextField(
            on: hostVC,
            title: "Test",
            onConfirm: { _, _ in }
        )

        let sheet = findActionSheet(in: hostVC)
        let picker = findDatePicker(in: sheet!.view)
        #expect(picker != nil)
        #expect(dayComponents(from: picker!.maximumDate!) == dayComponents(from: LMKDateHelper.today))
    }

    // MARK: - Edge Cases

    @Test("presentDatePickerAlert clamps defaultDate after maximumDate")
    func presentDatePickerAlert_clampsOutOfBounds() {
        let (hostVC, _window) = makeHostVC()
        let futureDate = LMKDateHelper.calendar.date(byAdding: .year, value: 1, to: LMKDateHelper.today)!

        LMKDatePickerHelper.presentDatePickerAlert(
            on: hostVC,
            title: "Test",
            defaultDate: futureDate,
            maximumDate: LMKDateHelper.today,
            onConfirm: { _ in }
        )

        let sheet = findActionSheet(in: hostVC)
        let picker = findDatePicker(in: sheet!.view)
        #expect(picker != nil)
        // Should be clamped to today, not the future date
        #expect(dayComponents(from: picker!.date) == dayComponents(from: LMKDateHelper.today))
    }

    @Test("presentDatePicker swaps min > max and clamps defaultDate")
    func presentDatePicker_swapsMinMax() {
        let (hostVC, _window) = makeHostVC()
        let pastDate = LMKDateHelper.calendar.date(byAdding: .month, value: -2, to: LMKDateHelper.today)!
        let furtherPast = LMKDateHelper.calendar.date(byAdding: .month, value: -3, to: LMKDateHelper.today)!

        // Pass min > max (swapped)
        LMKDatePickerHelper.presentDatePicker(
            on: hostVC,
            title: "Test",
            defaultDate: LMKDateHelper.today,
            maximumDate: furtherPast,
            minimumDate: pastDate,
            onConfirm: { _ in }
        )

        let sheet = findActionSheet(in: hostVC)
        let picker = findDatePicker(in: sheet!.view)
        #expect(picker != nil)
        // min/max should be swapped so picker is usable
        #expect(dayComponents(from: picker!.minimumDate!) == dayComponents(from: furtherPast))
        #expect(dayComponents(from: picker!.maximumDate!) == dayComponents(from: pastDate))
        // defaultDate (today) should be clamped to the resolved max (pastDate)
        #expect(dayComponents(from: picker!.date) == dayComponents(from: pastDate))
    }

    @Test("presentFutureDatePicker clamps past defaultDate to minimum")
    func presentFutureDatePicker_clampsPastDate() {
        let (hostVC, _window) = makeHostVC()
        let pastDate = LMKDateHelper.calendar.date(byAdding: .month, value: -1, to: LMKDateHelper.today)!

        LMKDatePickerHelper.presentFutureDatePicker(
            on: hostVC,
            title: "Test",
            defaultDate: pastDate,
            onConfirm: { _ in }
        )

        let sheet = findActionSheet(in: hostVC)
        let picker = findDatePicker(in: sheet!.view)
        #expect(picker != nil)
        // Past date should be clamped to today (the minimum)
        #expect(dayComponents(from: picker!.date) == dayComponents(from: LMKDateHelper.today))
    }

    @Test("presentDatePickerWithTextField clamps future defaultDate to today")
    func presentDatePickerWithTextField_clampsFutureDate() {
        let (hostVC, _window) = makeHostVC()
        let futureDate = LMKDateHelper.calendar.date(byAdding: .month, value: 3, to: LMKDateHelper.today)!

        LMKDatePickerHelper.presentDatePickerWithTextField(
            on: hostVC,
            title: "Test",
            defaultDate: futureDate,
            onConfirm: { _, _ in }
        )

        let sheet = findActionSheet(in: hostVC)
        let picker = findDatePicker(in: sheet!.view)
        #expect(picker != nil)
        #expect(dayComponents(from: picker!.date) == dayComponents(from: LMKDateHelper.today))
    }

    // MARK: - Configurable Strings

    @Test("Strings has sensible defaults")
    func strings_defaults() {
        let s = LMKDatePickerHelper.Strings()
        #expect(s.confirm == "OK")
        #expect(s.fromLabel == "From")
        #expect(s.toLabel == "To")
        #expect(s.textFieldPlaceholder == "Add notes...")
    }

    @Test("Strings is Sendable")
    func strings_sendable() {
        let s = LMKDatePickerHelper.Strings(confirm: "Accept")
        let _: any Sendable = s
    }
}
