//
//  LMKDatePickerTests.swift
//  LumiKit
//

import LumiKitCore
import Testing
import UIKit
@testable import LumiKitUI

// MARK: - Configuration

struct LMKDatePickerConfigurationTests {
    private func day(_ offset: Int) -> Date {
        LMKDate.calendar.date(byAdding: .day, value: offset, to: LMKDate.today) ?? LMKDate.today
    }

    @Test
    func `Inverted bounds swap and the initial date clamps into them`() {
        let inverted = LMKDatePicker.Configuration(title: "T", initial: day(0), minimum: day(-60), maximum: day(-90))
        #expect(inverted.resolvedBounds.minimum == day(-90))
        #expect(inverted.resolvedBounds.maximum == day(-60))
        #expect(inverted.resolvedInitial == day(-60))

        let open = LMKDatePicker.Configuration(title: "T")
        #expect(open.resolvedBounds.minimum == nil)
        #expect(open.resolvedBounds.maximum == nil)
        #expect(open.resolvedInitial == LMKDate.today)
        #expect(open.mode == .date)
        #expect(open.pickerStyle == .wheels)
    }

    @Test
    func `past and future presets set the bounds`() {
        let past = LMKDatePicker.Configuration.past(title: "Log", initial: day(365))
        #expect(past.maximum == LMKDate.today)
        #expect(past.minimum == nil)
        #expect(past.resolvedInitial == LMKDate.today)

        let future = LMKDatePicker.Configuration.future(title: "Plan", initial: day(-30))
        #expect(future.minimum == LMKDate.today)
        #expect(future.maximum == nil)
        #expect(future.resolvedInitial == LMKDate.today)
        #expect(LMKDatePicker.Configuration.future(title: "Plan", excludingToday: true).minimum == day(1))
    }
}

// MARK: - Presentation

@MainActor
struct LMKDatePickerTests {
    private func makeHost() -> (UIViewController, UIWindow) {
        let host = UIViewController()
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 375, height: 812))
        window.rootViewController = host
        window.makeKeyAndVisible()
        return (host, window)
    }

    private func find<T: UIView>(_ type: T.Type, in view: UIView) -> [T] {
        var found: [T] = []
        if let match = view as? T { found.append(match) }
        for subview in view.subviews {
            found.append(contentsOf: find(type, in: subview))
        }
        return found
    }

    private func dayComponents(_ date: Date?) -> DateComponents? {
        date.map { LMKDate.calendar.dateComponents([.year, .month, .day], from: $0) }
    }

    @Test
    func `present shows a configured picker in an action sheet and confirms with its date`() async {
        let (host, window) = makeHost()
        defer { window.isHidden = true }
        let past = LMKDate.calendar.date(byAdding: .month, value: -1, to: LMKDate.today)
        var confirmed: Date?
        let sheet = LMKDatePicker.present(LMKDatePicker.Configuration(title: "Test", minimum: past), from: host) { confirmed = $0 }
        #expect(host.children.first === sheet)
        let picker = find(UIDatePicker.self, in: sheet.view).first
        #expect(picker?.preferredDatePickerStyle == .wheels)
        #expect(dayComponents(picker?.minimumDate) == dayComponents(past))
        #expect(picker?.maximumDate == nil)
        #expect(dayComponents(picker?.date) == dayComponents(LMKDate.today))
        #expect(sheet.confirmButton?.title == "OK")
        sheet.confirmTapped()
        await LMKWait.until { confirmed != nil }
        #expect(dayComponents(confirmed) == dayComponents(LMKDate.today))
    }

    @Test
    func `The short form and the presets reach the picker`() {
        let (host, window) = makeHost()
        defer { window.isHidden = true }
        let sheet = LMKDatePicker.present(from: host, title: "Any", initial: LMKDate.today, maximum: nil) { _ in }
        let picker = find(UIDatePicker.self, in: sheet.view).first
        #expect(picker?.minimumDate == nil)
        #expect(picker?.maximumDate == nil)

        let future = LMKDatePicker.present(.future(title: "Schedule", excludingToday: true), from: host) { _ in }
        let futurePicker = find(UIDatePicker.self, in: future.view).first
        #expect(dayComponents(futurePicker?.minimumDate) == dayComponents(LMKDate.calendar.date(byAdding: .day, value: 1, to: LMKDate.today)))
    }

    @Test
    func `presentRange shows two compact pickers that keep start before end`() {
        let (host, window) = makeHost()
        defer { window.isHidden = true }
        let sheet = LMKDatePicker.presentRange(from: host, title: "Range") { _, _ in }
        let pickers = find(UIDatePicker.self, in: sheet.view)
        #expect(pickers.count == 2)
        #expect(pickers.allSatisfy { $0.preferredDatePickerStyle == .compact })
        #expect(find(UILabel.self, in: sheet.view).contains { $0.text == "From" })
        #expect(find(UILabel.self, in: sheet.view).contains { $0.text == "To" })
        guard pickers.count == 2 else { return }
        pickers[0].date = LMKDate.calendar.date(byAdding: .day, value: 60, to: LMKDate.today) ?? LMKDate.today
        pickers[0].sendActions(for: .valueChanged)
        #expect(pickers[1].date >= pickers[0].date)
    }

    @Test
    func `presentCalendarRange shows a calendar and confirms only with a selection`() async {
        let (host, window) = makeHost()
        defer { window.isHidden = true }
        var confirmed: (Date, Date)?
        let sheet = LMKDatePicker.presentCalendarRange(from: host, title: "Dates") { confirmed = ($0, $1) }
        let rangeView = find(LMKCalendarRangeSelectionView.self, in: sheet.view).first
        #expect(rangeView != nil)
        #expect(find(UICalendarView.self, in: sheet.view).count == 1)
        #expect(rangeView?.summaryLabel.text == "Select dates")
        sheet.confirmTapped()
        await LMKWait.until { host.children.isEmpty }
        #expect(confirmed == nil, "an empty calendar confirms nothing")
    }

    @Test
    func `presentWithTextField shows a field above the picker and hands back trimmed notes`() async {
        let (host, window) = makeHost()
        defer { window.isHidden = true }
        var result: (Date, String?)?
        let sheet = LMKDatePicker.presentWithTextField(.past(title: "Entry"), from: host, placeholder: "Note") { result = ($0, $1) }
        let field = find(LMKTextField.self, in: sheet.view).first
        #expect(field?.placeholder == "Note")
        #expect(find(UIDatePicker.self, in: sheet.view).count == 1)
        field?.text = "  hello  "
        sheet.confirmTapped()
        await LMKWait.until { result != nil }
        #expect(result?.1 == "hello")

        result = nil
        let empty = LMKDatePicker.presentWithTextField(.past(title: "Entry"), from: host) { result = ($0, $1) }
        #expect(find(LMKTextField.self, in: empty.view).first?.placeholder == "Add notes...")
        empty.confirmTapped()
        await LMKWait.until { result != nil }
        #expect(result != nil)
        #expect(result?.1 == nil)
    }

    @Test
    func `Strings defaults`() {
        let strings = LMKDatePicker.Strings()
        #expect(strings.confirm == "OK")
        #expect(strings.fromLabel == "From")
        #expect(strings.toLabel == "To")
        #expect(strings.textFieldPlaceholder == "Add notes...")
        #expect(strings.selectDatesPrompt == "Select dates")
    }
}

// MARK: - Calendar range selection

@MainActor
struct LMKCalendarRangeSelectionTests {
    private let calendar = LMKDate.calendar

    private func day(_ offset: Int) -> Date {
        calendar.date(byAdding: .day, value: offset, to: LMKDate.today) ?? LMKDate.today
    }

    private func calendarDay(_ offset: Int) -> LMKCalendarDay {
        LMKCalendarDay(day(offset), calendar: calendar)
    }

    @Test
    func `Initial selection bridges dates to calendar days`() {
        #expect(LMKCalendarRangeSelectionView().selection == .empty)
        #expect(LMKCalendarRangeSelectionView(startDate: day(10)).selection == .start(calendarDay(10)))
        #expect(LMKCalendarRangeSelectionView(startDate: day(10), endDate: day(12)).selection == .range(calendarDay(10), calendarDay(12)))
        #expect(LMKCalendarRangeSelectionView(startDate: day(10), endDate: day(5)).selection == .range(calendarDay(10), calendarDay(10)))
        #expect(LMKCalendarRangeSelectionView(startDate: day(10), endDate: day(12)).selectedDays == calendarDay(10) ... calendarDay(12))
    }

    @Test
    func `selectedRange, select, and the delegate path`() {
        let empty = LMKCalendarRangeSelectionView()
        #expect(empty.selectedRange == nil)
        var changes: [LMKCalendarSelection] = []
        empty.onSelectionChange = { changes.append($0) }
        empty.select(day(3))
        #expect(empty.selectedRange == day(3) ... day(3))
        empty.select(day(6))
        #expect(empty.selectedRange == day(3) ... day(6))
        #expect(changes == [.start(calendarDay(3)), .range(calendarDay(3), calendarDay(6))])

        let full = LMKCalendarRangeSelectionView(startDate: day(0), endDate: day(6))
        let selection = UICalendarSelectionMultiDate(delegate: nil)
        // A tap inside the range arrives as a deselect and still starts over there.
        full.multiDateSelection(selection, didDeselectDate: calendar.dateComponents([.year, .month, .day], from: day(2)))
        #expect(full.selection == .start(calendarDay(2)))
        #expect(full.summaryLabel.text != "Select dates")
    }
}
