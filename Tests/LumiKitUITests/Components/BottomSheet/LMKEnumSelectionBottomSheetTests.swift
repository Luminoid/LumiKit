//
//  LMKEnumSelectionBottomSheetTests.swift
//  LumiKit
//
//  Tests for LMKEnumSelectionBottomSheet — protocol conformance,
//  cell configuration, presentation, and table view data source.
//

import Testing
import UIKit
@testable import LumiKitUI

// MARK: - Test Enum

private enum TestSortOption: String, CaseIterable, Equatable, LMKEnumSelectable {
    case name
    case date
    case type

    var displayName: String {
        switch self {
        case .name: "Name"
        case .date: "Date"
        case .type: "Type"
        }
    }

    var iconName: String {
        switch self {
        case .name: "textformat.abc"
        case .date: "calendar"
        case .type: "tag"
        }
    }
}

private enum SingleOption: Equatable, LMKEnumSelectable {
    case only

    var displayName: String { "Only Option" }
    var iconName: String { "star" }
}

// MARK: - LMKEnumSelectable Protocol

@Suite("LMKEnumSelectable Protocol")
struct LMKEnumSelectableProtocolTests {
    @Test("Conforming enum provides displayName")
    func displayNameFromEnum() {
        #expect(TestSortOption.name.displayName == "Name")
        #expect(TestSortOption.date.displayName == "Date")
        #expect(TestSortOption.type.displayName == "Type")
    }

    @Test("Conforming enum provides iconName")
    func iconNameFromEnum() {
        #expect(TestSortOption.name.iconName == "textformat.abc")
        #expect(TestSortOption.date.iconName == "calendar")
        #expect(TestSortOption.type.iconName == "tag")
    }

    @Test("All cases provide non-empty displayName")
    func allCasesHaveDisplayName() {
        for option in TestSortOption.allCases {
            #expect(!option.displayName.isEmpty)
        }
    }

    @Test("All cases provide non-empty iconName")
    func allCasesHaveIconName() {
        for option in TestSortOption.allCases {
            #expect(!option.iconName.isEmpty)
        }
    }
}

// MARK: - LMKEnumSelectionBottomSheet

@Suite("LMKEnumSelectionBottomSheet")
@MainActor
struct LMKEnumSelectionBottomSheetTests {
    // MARK: - Presentation

    @Test("Present adds sheet as child of parent VC")
    func presentAddsChild() {
        let parent = UIViewController()
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 375, height: 812))
        window.rootViewController = parent
        window.makeKeyAndVisible()

        LMKEnumSelectionBottomSheet.present(
            in: parent,
            title: "Sort By",
            options: TestSortOption.allCases,
            currentSelection: .name,
            onSelect: { _ in }
        )

        #expect(parent.children.count == 1)
        #expect(parent.children.first is LMKEnumSelectionBottomSheet)
    }

    @Test("Present with showIcons adds sheet as child")
    func presentWithIcons() {
        let parent = UIViewController()
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 375, height: 812))
        window.rootViewController = parent
        window.makeKeyAndVisible()

        LMKEnumSelectionBottomSheet.present(
            in: parent,
            title: "Sort By",
            options: TestSortOption.allCases,
            currentSelection: .date,
            showIcons: true,
            onSelect: { _ in }
        )

        #expect(parent.children.count == 1)
    }

    @Test("Present with single option")
    func presentSingleOption() {
        let parent = UIViewController()
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 375, height: 812))
        window.rootViewController = parent
        window.makeKeyAndVisible()

        LMKEnumSelectionBottomSheet.present(
            in: parent,
            title: "Choose",
            options: [SingleOption.only],
            currentSelection: .only,
            onSelect: { _ in }
        )

        #expect(parent.children.count == 1)
    }

    // MARK: - Table View Data Source

    @Test("Table view has correct number of rows")
    func tableViewRowCount() {
        let parent = UIViewController()
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 375, height: 812))
        window.rootViewController = parent
        window.makeKeyAndVisible()

        LMKEnumSelectionBottomSheet.present(
            in: parent,
            title: "Sort By",
            options: TestSortOption.allCases,
            currentSelection: .name,
            onSelect: { _ in }
        )

        guard let sheet = parent.children.first as? LMKEnumSelectionBottomSheet else {
            Issue.record("Expected LMKEnumSelectionBottomSheet as child")
            return
        }
        sheet.loadViewIfNeeded()

        let tableView = findTableView(in: sheet.view)
        #expect(tableView != nil)

        if let tableView {
            let rows = sheet.tableView(tableView, numberOfRowsInSection: 0)
            #expect(rows == 3)
        }
    }

    @Test("Table view cells are LMKEnumSelectionCell")
    func tableViewCellType() {
        let parent = UIViewController()
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 375, height: 812))
        window.rootViewController = parent
        window.makeKeyAndVisible()

        LMKEnumSelectionBottomSheet.present(
            in: parent,
            title: "Sort By",
            options: TestSortOption.allCases,
            currentSelection: .name,
            onSelect: { _ in }
        )

        guard let sheet = parent.children.first as? LMKEnumSelectionBottomSheet else {
            Issue.record("Expected LMKEnumSelectionBottomSheet as child")
            return
        }
        sheet.loadViewIfNeeded()

        if let tableView = findTableView(in: sheet.view) {
            let cell = sheet.tableView(tableView, cellForRowAt: IndexPath(row: 0, section: 0))
            #expect(cell is LMKEnumSelectionCell)
        }
    }

    @Test("Row height uses LMKBottomSheetLayout.rowHeight")
    func tableViewRowHeight() {
        let parent = UIViewController()
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 375, height: 812))
        window.rootViewController = parent
        window.makeKeyAndVisible()

        LMKEnumSelectionBottomSheet.present(
            in: parent,
            title: "Sort By",
            options: TestSortOption.allCases,
            currentSelection: .name,
            onSelect: { _ in }
        )

        guard let sheet = parent.children.first as? LMKEnumSelectionBottomSheet else {
            Issue.record("Expected LMKEnumSelectionBottomSheet as child")
            return
        }
        sheet.loadViewIfNeeded()

        if let tableView = findTableView(in: sheet.view) {
            let height = sheet.tableView(tableView, heightForRowAt: IndexPath(row: 0, section: 0))
            #expect(height == LMKBottomSheetLayout.rowHeight)
        }
    }

    // MARK: - Selection Callback

    @Test("onSelect callback receives correct option")
    func onSelectCallback() {
        var selectedOption: TestSortOption?
        let parent = UIViewController()
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 375, height: 812))
        window.rootViewController = parent
        window.makeKeyAndVisible()

        LMKEnumSelectionBottomSheet.present(
            in: parent,
            title: "Sort By",
            options: TestSortOption.allCases,
            currentSelection: .name,
            onSelect: { option in selectedOption = option }
        )

        guard let sheet = parent.children.first as? LMKEnumSelectionBottomSheet else {
            Issue.record("Expected LMKEnumSelectionBottomSheet as child")
            return
        }
        sheet.loadViewIfNeeded()

        if let tableView = findTableView(in: sheet.view) {
            // Simulate selecting the second row ("Date")
            sheet.tableView(tableView, didSelectRowAt: IndexPath(row: 1, section: 0))
            #expect(selectedOption == .date)
        }
    }

    // MARK: - View Hierarchy

    @Test("Sheet view is not nil after loading")
    func sheetViewNotNil() {
        let parent = UIViewController()
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 375, height: 812))
        window.rootViewController = parent
        window.makeKeyAndVisible()

        LMKEnumSelectionBottomSheet.present(
            in: parent,
            title: "Sort By",
            options: TestSortOption.allCases,
            currentSelection: .name,
            onSelect: { _ in }
        )

        guard let sheet = parent.children.first as? LMKEnumSelectionBottomSheet else {
            Issue.record("Expected LMKEnumSelectionBottomSheet as child")
            return
        }
        sheet.loadViewIfNeeded()

        #expect(sheet.view != nil)
    }

    @Test("Sheet contains a table view in its hierarchy")
    func sheetContainsTableView() {
        let parent = UIViewController()
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 375, height: 812))
        window.rootViewController = parent
        window.makeKeyAndVisible()

        LMKEnumSelectionBottomSheet.present(
            in: parent,
            title: "Sort By",
            options: TestSortOption.allCases,
            currentSelection: .name,
            onSelect: { _ in }
        )

        guard let sheet = parent.children.first as? LMKEnumSelectionBottomSheet else {
            Issue.record("Expected LMKEnumSelectionBottomSheet as child")
            return
        }
        sheet.loadViewIfNeeded()

        #expect(findTableView(in: sheet.view) != nil)
    }

    // MARK: - Helpers

    private func findTableView(in view: UIView) -> UITableView? {
        if let tableView = view as? UITableView {
            return tableView
        }
        for subview in view.subviews {
            if let found = findTableView(in: subview) {
                return found
            }
        }
        return nil
    }
}
