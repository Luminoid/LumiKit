//
//  LMKEnumPickerTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

private enum TestSortOption: String, CaseIterable, Hashable, LMKEnumSelectable {
    case name, date, type

    var displayName: String {
        switch self {
        case .name: "Name"
        case .date: "Date"
        case .type: "Type"
        }
    }

    var iconName: String? {
        switch self {
        case .name: "textformat.abc"
        case .date: "calendar"
        case .type: "tag"
        }
    }
}

private enum PlainOption: String, CaseIterable, Hashable, LMKEnumSelectable {
    case only

    var displayName: String { "Only Option" }
}

private enum LongOption: Int, CaseIterable, Hashable, LMKEnumSelectable {
    case first, second, third, fourth, fifth, sixth, seventh, eighth, ninth, tenth, eleventh, twelfth, thirteenth, fourteenth

    var displayName: String { "Option \(rawValue + 1)" }
}

struct LMKEnumSelectableTests {
    @Test
    func `iconName defaults to nil and conformers can provide one`() {
        #expect(PlainOption.only.iconName == nil)
        #expect(TestSortOption.date.iconName == "calendar")
        #expect(TestSortOption.allCases.allSatisfy { !$0.displayName.isEmpty })
    }
}

@MainActor
struct LMKEnumPickerTests {
    private func makeHost() -> (UIViewController, UIWindow) {
        let host = UIViewController()
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 375, height: 812))
        window.rootViewController = host
        window.makeKeyAndVisible()
        return (host, window)
    }

    private func cell(_ sheet: LMKEnumPickerViewController, row: Int) -> LMKEnumPickerCell? {
        sheet.tableView(sheet.tableView, cellForRowAt: IndexPath(row: row, section: 0)) as? LMKEnumPickerCell
    }

    @Test
    func `Single-select presents a picker with one row per option and the current selection marked`() {
        let (host, window) = makeHost()
        defer { window.isHidden = true }
        let sheet = LMKEnumPicker.present(from: host, title: "Sort By", options: TestSortOption.allCases, selection: .date) { _ in }
        #expect(host.children.first === sheet)
        #expect(LMKEnumPicker.current(in: host) === sheet)
        #expect(!sheet.isMultiSelect)
        #expect(sheet.tableView(sheet.tableView, numberOfRowsInSection: 0) == 3)
        #expect(sheet.selectedIndices == [1])
        #expect(sheet.doneButton.superview == nil)
        #expect(sheet.titleLabel.text == "Sort By")
        #expect(cell(sheet, row: 1)?.accessibilityTraits.contains(.selected) == true)
        #expect(cell(sheet, row: 0)?.accessibilityTraits.contains(.selected) == false)
        #expect(cell(sheet, row: 0)?.rowView.iconView.isHidden == false, "icons show by default")
        #expect(cell(sheet, row: 0)?.rowView.checkmarkView.isHidden == true)
        #expect(cell(sheet, row: 1)?.rowView.checkmarkView.isHidden == false)
    }

    @Test
    func `A list taller than the sheet's cap gives way and leaves the title whole`() {
        let (host, window) = makeHost()
        defer { window.isHidden = true }
        let sheet = LMKEnumPicker.present(from: host, title: "Kind", options: LongOption.allCases, selection: nil) { _ in }
        sheet.view.layoutIfNeeded()
        let lineHeight = sheet.titleLabel.font.lineHeight
        #expect(sheet.containerView.bounds.height <= 812 * 0.9 + 0.5)
        #expect(sheet.tableView.bounds.height < 56 * 14, "the fixture no longer reaches the cap: \(sheet.tableView.frame)")
        #expect(sheet.titleLabel.bounds.height >= floor(lineHeight), "the title gave up height to the list: \(sheet.titleLabel.frame)")
    }

    @Test
    func `showsIcons false and a nil selection`() {
        let (host, window) = makeHost()
        defer { window.isHidden = true }
        let sheet = LMKEnumPicker.present(from: host, title: "Sort", options: TestSortOption.allCases, selection: nil, showsIcons: false) { _ in }
        #expect(sheet.selectedIndices.isEmpty)
        #expect(cell(sheet, row: 0)?.rowView.iconView.isHidden == true)
        #expect(sheet.items.map(\.iconName) == [nil, nil, nil])
    }

    @Test
    func `A single-select tap commits after the sheet has gone`() async {
        let (host, window) = makeHost()
        defer { window.isHidden = true }
        var selected: TestSortOption?
        let sheet = LMKEnumPicker.present(from: host, title: "Sort", options: TestSortOption.allCases, selection: .name) { selected = $0 }
        sheet.tableView(sheet.tableView, didSelectRowAt: IndexPath(row: 1, section: 0))
        #expect(selected == nil, "the commit waits for the dismissal")
        await LMKWait.until { selected != nil }
        #expect(selected == .date)
        #expect(host.children.isEmpty)
    }

    @Test
    func `Multi-select toggles rows, Done commits, cancel discards`() async {
        let (host, window) = makeHost()
        defer { window.isHidden = true }
        var committed: Set<TestSortOption>?
        let sheet = LMKEnumPicker.present(from: host, title: "Filter", options: TestSortOption.allCases, selection: [.name], doneTitle: "Apply") { committed = $0 }
        #expect(sheet.isMultiSelect)
        #expect(sheet.doneButton.title == "Apply")
        #expect(sheet.doneButton.superview != nil)
        sheet.select(itemAt: 1)
        sheet.select(itemAt: 0)
        #expect(sheet.selectedIndices == [1])
        #expect(committed == nil)
        #expect(host.children.count == 1)
        sheet.doneButton.didTap()
        await LMKWait.until { committed != nil }
        #expect(committed == [.date])

        var cancelled: Set<TestSortOption>? = []
        let second = LMKEnumPicker.present(from: host, title: "Filter", options: TestSortOption.allCases, selection: []) { cancelled = $0 }
        second.select(itemAt: 2)
        second.dismiss(reason: .cancelButton)
        await LMKWait.until { host.children.isEmpty }
        #expect(cancelled == [], "cancel never commits")
        #expect(LMKEnumPicker.Strings().done == "Done")
    }

    @Test
    func `Disabled options render dimmed and cannot be selected`() {
        let (host, window) = makeHost()
        defer { window.isHidden = true }
        let sheet = LMKEnumPicker.present(from: host, title: "Filter", options: TestSortOption.allCases, selection: [], disabledOptions: [.type]) { _ in }
        #expect(cell(sheet, row: 2)?.rowView.isEnabled == false)
        #expect(cell(sheet, row: 2)?.accessibilityTraits.contains(.notEnabled) == true)
        sheet.select(itemAt: 2)
        #expect(sheet.selectedIndices.isEmpty)
    }

    @Test
    func `Search filters the visible rows by title`() {
        let (host, window) = makeHost()
        defer { window.isHidden = true }
        let sheet = LMKEnumPicker.present(from: host, title: "Sort", options: TestSortOption.allCases, selection: .name, showsSearch: true) { _ in }
        #expect(sheet.searchBar.superview != nil)
        #expect(sheet.searchBar.placeholder == "Search")
        sheet.filter(with: "da")
        #expect(sheet.visibleIndices == [1])
        #expect(sheet.tableView(sheet.tableView, numberOfRowsInSection: 0) == 1)
        #expect(cell(sheet, row: 0)?.rowView.titleLabel.text == "Date")
        sheet.filter(with: "  ")
        #expect(sheet.visibleIndices == [0, 1, 2])
        sheet.filter(with: "zzz")
        #expect(sheet.visibleIndices.isEmpty)
    }

    @Test
    func `Style and theme.enumPicker flow into the title and rows`() {
        let (host, window) = makeHost()
        defer { window.isHidden = true }
        let style = LMKEnumPicker.Style(row: LMKActionSheet.RowStyle(titleColor: .purple), titleColor: .green)
        let sheet = LMKEnumPicker.present(from: host, title: "Sort", options: [PlainOption.only], selection: nil, style: style) { _ in }
        #expect(sheet.titleLabel.textColor == UIColor.green)
        #expect(cell(sheet, row: 0)?.rowView.titleLabel.textColor == UIColor.purple)

        var theme = LMKTheme()
        theme.enumPicker = LMKEnumPicker.Style(sheet: LMKBottomSheetViewController.Style(showsDragIndicator: false))
        sheet.applyTheme(theme)
        #expect(sheet.dragIndicator.isHidden)
    }
}
