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

struct LMKEnumSelectableProtocolTests {
    @Test
    func `Conforming enum provides displayName`() {
        #expect(TestSortOption.name.displayName == "Name")
        #expect(TestSortOption.date.displayName == "Date")
        #expect(TestSortOption.type.displayName == "Type")
    }

    @Test
    func `Conforming enum provides iconName`() {
        #expect(TestSortOption.name.iconName == "textformat.abc")
        #expect(TestSortOption.date.iconName == "calendar")
        #expect(TestSortOption.type.iconName == "tag")
    }

    @Test
    func `All cases provide non-empty displayName`() {
        for option in TestSortOption.allCases {
            #expect(!option.displayName.isEmpty)
        }
    }

    @Test
    func `All cases provide non-empty iconName`() {
        for option in TestSortOption.allCases {
            #expect(!option.iconName.isEmpty)
        }
    }
}

// MARK: - LMKEnumSelectionBottomSheet

@MainActor
struct LMKEnumSelectionBottomSheetTests {
    // MARK: - Presentation

    @Test
    func `Present adds sheet as child of parent VC`() {
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

    @Test
    func `Present with showIcons adds sheet as child`() {
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

    @Test
    func `Present with single option`() {
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

    @Test
    func `Table view has correct number of rows`() {
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

    @Test
    func `Table view cells are LMKEnumSelectionCell`() {
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

    @Test
    func `Row height uses LMKBottomSheetLayout.rowHeight`() {
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

    @Test
    func `onSelect callback receives correct option`() {
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

    @Test
    func `Sheet view is not nil after loading`() {
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

    @Test
    func `Sheet contains a table view in its hierarchy`() {
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
