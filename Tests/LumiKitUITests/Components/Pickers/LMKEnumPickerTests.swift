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
    func `A single-select tap commits after the sheet has gone; leaving without a tap cancels`() async {
        let (host, window) = makeHost()
        defer { window.isHidden = true }
        var selected: TestSortOption?
        var cancels = 0
        let sheet = LMKEnumPicker.present(from: host, title: "Sort", options: TestSortOption.allCases, selection: .name, onSelect: { selected = $0 }, onCancel: { cancels += 1 })
        sheet.tableView(sheet.tableView, didSelectRowAt: IndexPath(row: 1, section: 0))
        #expect(selected == nil, "the commit waits for the dismissal")
        await LMKWait.until { selected != nil }
        #expect(selected == .date)
        #expect(host.children.isEmpty)
        #expect(cancels == 0)

        let second = LMKEnumPicker.present(from: host, title: "Sort", options: TestSortOption.allCases, selection: .name, onSelect: { selected = $0 }, onCancel: { cancels += 1 })
        second.dismiss(reason: .dimmingTap)
        await LMKWait.until { cancels == 1 }
        #expect(selected == .date, "nothing new was committed")
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
        var cancels = 0
        let second = LMKEnumPicker.present(from: host, title: "Filter", options: TestSortOption.allCases, selection: [], onSelect: { cancelled = $0 }, onCancel: { cancels += 1 })
        second.select(itemAt: 2)
        second.dismiss(reason: .cancelButton)
        await LMKWait.until { host.children.isEmpty }
        #expect(cancelled == [], "cancel never commits")
        #expect(cancels == 1)
        #expect(LMKEnumPicker.Strings().done == "Done")
    }

    @Test
    func `The table is as tall as its rows and keeps that height while a search narrows the list`() async {
        let (host, window) = makeHost()
        defer { window.isHidden = true }
        let sheet = LMKEnumPicker.present(from: host, title: "Sort", options: TestSortOption.allCases, selection: nil, showsSearch: true) { _ in }
        await LMKWait.until {
            sheet.view.layoutIfNeeded()
            return abs(sheet.tableView.bounds.height - sheet.tableView.contentSize.height) < 0.5
        }
        let contentHeight = sheet.tableView.contentSize.height
        #expect(contentHeight > 0)
        #expect(contentHeight < 56 * 3, "rows are shorter than the estimate, and the table no longer reserves the estimate")
        #expect(abs(sheet.tableView.bounds.height - contentHeight) < 0.5, "\(sheet.tableView.bounds.height) vs \(contentHeight)")
        sheet.filter(with: "da")
        sheet.view.layoutIfNeeded()
        #expect(abs(sheet.tableView.bounds.height - contentHeight) < 0.5, "a filtered list does not shrink the sheet")
    }

    @Test
    func `Disabled options render dimmed, never highlight, and cannot be selected`() {
        let (host, window) = makeHost()
        defer { window.isHidden = true }
        let sheet = LMKEnumPicker.present(from: host, title: "Filter", options: TestSortOption.allCases, selection: [], disabledOptions: [.type]) { _ in }
        #expect(cell(sheet, row: 2)?.rowView.isEnabled == false)
        #expect(cell(sheet, row: 2)?.accessibilityTraits.contains(.notEnabled) == true)
        #expect(!sheet.tableView(sheet.tableView, shouldHighlightRowAt: IndexPath(row: 2, section: 0)))
        #expect(sheet.tableView(sheet.tableView, shouldHighlightRowAt: IndexPath(row: 0, section: 0)))
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
    func `Style and theme.enumPicker flow into the title, rows, and insets`() {
        let (host, window) = makeHost()
        defer { window.isHidden = true }
        let style = LMKEnumPicker.Style(
            sheet: LMKBottomSheetViewController.Style(surface: LMKSurfaceStyle(contentInsets: .lmk_all(30))),
            row: LMKActionSheet.RowStyle(titleColor: .purple),
            titleColor: .green,
            doneButton: LMKButton.Style(minimumHeight: 64),
            searchBar: LMKSearchBar.Style(placeholderColor: .orange),
            rowSpacing: 10
        )
        let sheet = LMKEnumPicker.present(from: host, title: "Sort", options: TestSortOption.allCases, selection: [], showsSearch: true, style: style) { _ in }
        sheet.view.layoutIfNeeded()
        #expect(sheet.titleLabel.textColor == UIColor.green)
        #expect(cell(sheet, row: 0)?.rowView.titleLabel.textColor == UIColor.purple)
        #expect(sheet.doneButton.style.minimumHeight == 64)
        #expect(sheet.searchBar.style.placeholderColor == UIColor.orange)
        #expect(abs(sheet.titleLabel.frame.minX - 30) < 0.5, "the sheet's content inset places the title")
        #expect(abs(sheet.searchBar.frame.minX - 30) < 0.5)
        #expect(abs(sheet.doneButton.frame.minX - 30) < 0.5)
        let firstRow = sheet.tableView.visibleCells.compactMap { $0 as? LMKEnumPickerCell }.first
        #expect(firstRow.map { abs($0.rowView.frame.minX - 30) < 0.5 } == true, "and the rows")
        #expect(firstRow.map { abs($0.rowView.frame.minY - 5) < 0.5 } == true, "half the row spacing above each row")

        var theme = LMKTheme()
        theme.enumPicker = LMKEnumPicker.Style(sheet: LMKBottomSheetViewController.Style(showsDragIndicator: false))
        sheet.applyTheme(theme)
        #expect(sheet.dragIndicator.isHidden)
        sheet.style.showsCancelButton = false
        #expect(sheet.cancelButton.isHidden, "the instance style layers on top of the picker style")
    }
}
