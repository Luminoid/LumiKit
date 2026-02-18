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

@Suite("LMKSearchBar")
@MainActor
struct LMKSearchBarTests {
    @Test("placeholder getter and setter")
    func placeholderGetterSetter() {
        let searchBar = LMKSearchBar()
        searchBar.placeholder = "Search plants..."
        #expect(searchBar.placeholder == "Search plants...")
    }

    @Test("text getter and setter")
    func textGetterSetter() {
        let searchBar = LMKSearchBar()
        searchBar.text = "Monstera"
        #expect(searchBar.text == "Monstera")
    }

    @Test("showsCancelButton defaults to false")
    func cancelButtonHiddenByDefault() {
        let searchBar = LMKSearchBar()
        #expect(!searchBar.showsCancelButton)
    }

    @Test("showsCancelButton can be toggled")
    func cancelButtonToggle() {
        let searchBar = LMKSearchBar()
        searchBar.showsCancelButton = true
        #expect(searchBar.showsCancelButton)
        searchBar.showsCancelButton = false
        #expect(!searchBar.showsCancelButton)
    }

    @Test("Setting nil placeholder clears it")
    func nilPlaceholder() {
        let searchBar = LMKSearchBar()
        searchBar.placeholder = "Search"
        searchBar.placeholder = nil
        #expect(searchBar.placeholder == nil)
    }
}

// MARK: - LMKSearchBarStrings

@Suite("LMKSearchBarStrings")
@MainActor
struct LMKSearchBarStringsTests {
    @Test("Default strings are English")
    func defaultStrings() {
        let strings = LMKSearchBar.Strings()
        #expect(strings.cancel == "Cancel")
        #expect(strings.clearAccessibilityLabel == "Clear")
    }

    @Test("Custom strings override defaults")
    func customStrings() {
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
