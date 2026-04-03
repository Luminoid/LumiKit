//
//  LMKSearchBarTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

// MARK: - MockSearchBarDelegate

private final class MockSearchBarDelegate: LMKSearchBarDelegate {
    var lastSearchText: String?
    var searchButtonClickedCount = 0
    var beginEditingCount = 0
    var endEditingCount = 0
    var cancelClickedCount = 0

    func lmkSearchBar(_ searchBar: LMKSearchBar, textDidChange searchText: String) {
        lastSearchText = searchText
    }

    func lmkSearchBarSearchButtonClicked(_ searchBar: LMKSearchBar) {
        searchButtonClickedCount += 1
    }

    func lmkSearchBarTextDidBeginEditing(_ searchBar: LMKSearchBar) {
        beginEditingCount += 1
    }

    func lmkSearchBarTextDidEndEditing(_ searchBar: LMKSearchBar) {
        endEditingCount += 1
    }

    func lmkSearchBarCancelButtonClicked(_ searchBar: LMKSearchBar) {
        cancelClickedCount += 1
    }
}

// MARK: - LMKSearchBar

@MainActor
struct LMKSearchBarTests {
    @Test
    func `placeholder getter and setter`() {
        let searchBar = LMKSearchBar()
        searchBar.placeholder = "Search plants..."
        #expect(searchBar.placeholder == "Search plants...")
    }

    @Test
    func `text getter and setter`() {
        let searchBar = LMKSearchBar()
        searchBar.text = "Monstera"
        #expect(searchBar.text == "Monstera")
    }

    @Test
    func `showsCancelButton defaults to false`() {
        let searchBar = LMKSearchBar()
        #expect(!searchBar.showsCancelButton)
    }

    @Test
    func `showsCancelButton can be toggled`() {
        let searchBar = LMKSearchBar()
        searchBar.showsCancelButton = true
        #expect(searchBar.showsCancelButton)
        searchBar.showsCancelButton = false
        #expect(!searchBar.showsCancelButton)
    }

    @Test
    func `Setting nil placeholder clears it`() {
        let searchBar = LMKSearchBar()
        searchBar.placeholder = "Search"
        searchBar.placeholder = nil
        #expect(searchBar.placeholder == nil)
    }
}

// MARK: - LMKSearchBarStrings

@MainActor
struct LMKSearchBarStringsTests {
    @Test
    func `Default strings are English`() {
        let strings = LMKSearchBar.Strings()
        #expect(strings.cancel == "Cancel")
        #expect(strings.clearAccessibilityLabel == "Clear")
    }

    @Test
    func `Custom strings override defaults`() {
        let original = LMKSearchBar.strings
        defer { LMKSearchBar.strings = original }

        LMKSearchBar.strings = LMKSearchBar.Strings(
            cancel: "Cancelar",
            clearAccessibilityLabel: "Limpiar"
        )
        #expect(LMKSearchBar.strings.cancel == "Cancelar")
        #expect(LMKSearchBar.strings.clearAccessibilityLabel == "Limpiar")
    }
}
