//
//  LMKSearchBarTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

// MARK: - LMKSearchBar

@MainActor
struct LMKSearchBarTests {
    @Test
    func `placeholder and text proxy to the field`() {
        let searchBar = LMKSearchBar()
        searchBar.placeholder = "Search plants..."
        #expect(searchBar.textField.attributedPlaceholder?.string == "Search plants...")
        searchBar.placeholder = nil
        #expect(searchBar.textField.attributedPlaceholder == nil)
        searchBar.text = "Monstera"
        #expect(searchBar.textField.text == "Monstera")
        #expect(!searchBar.clearButton.isHidden)
        searchBar.text = ""
        #expect(searchBar.textField.text == "")
        #expect(searchBar.clearButton.isHidden)
        #expect(searchBar.textField.accessibilityTraits.contains(.searchField))
    }

    @Test
    func `Cancel button follows the mode and the editing state`() {
        let searchBar = LMKSearchBar()
        #expect(!searchBar.showsCancelButton)
        searchBar.cancelButtonMode = .always
        #expect(searchBar.showsCancelButton)
        searchBar.cancelButtonMode = .never
        #expect(!searchBar.showsCancelButton)
        searchBar.cancelButtonMode = .automatic
        searchBar.textFieldDidBeginEditing(searchBar.textField)
        #expect(searchBar.showsCancelButton)
        searchBar.textFieldDidEndEditing(searchBar.textField)
        #expect(!searchBar.showsCancelButton)
    }

    @Test
    func `A shown cancel button takes its own width and a hidden one collapses`() {
        let searchBar = LMKSearchBar()
        searchBar.cancelButtonMode = .always
        LMKThemeTesting.fit(searchBar, width: 375)
        #expect(searchBar.cancelButton.frame.width > 0)
        #expect(abs(searchBar.cancelButton.frame.width - searchBar.cancelButton.intrinsicContentSize.width) < 0.5)
        #expect(searchBar.containerView.frame.maxX < 375, "the field makes room for the button")

        searchBar.cancelButtonMode = .never
        // Outside a window a constraint change does not flag layout on its own.
        searchBar.setNeedsLayout()
        LMKThemeTesting.fit(searchBar, width: 375)
        #expect(searchBar.cancelButton.frame.width == 0)
        #expect(searchBar.containerView.frame.maxX == 375)
    }

    @Test
    func `Closures fire for typing, return, clear, editing, and cancel`() {
        let searchBar = LMKSearchBar()
        var changes: [String] = []
        var searches: [String] = []
        var began = 0
        var ended = 0
        var cancels = 0
        searchBar.onTextChange = { changes.append($0) }
        searchBar.onSearch = { searches.append($0) }
        searchBar.onBeginEditing = { began += 1 }
        searchBar.onEndEditing = { ended += 1 }
        searchBar.onCancel = { cancels += 1 }

        searchBar.textFieldDidBeginEditing(searchBar.textField)
        searchBar.textField.text = "Fern"
        searchBar.textField.sendActions(for: .editingChanged)
        _ = searchBar.textFieldShouldReturn(searchBar.textField)
        searchBar.clearButton.didTap()
        searchBar.textFieldDidEndEditing(searchBar.textField)
        searchBar.cancelButton.didTap()

        #expect(changes == ["Fern", ""] || changes == [""], "editingChanged may not deliver in the host; the clear tap always does")
        #expect(searches == ["Fern"])
        #expect(began == 1)
        #expect(ended == 1)
        #expect(cancels == 1)
        #expect(searchBar.text == "")
    }

    @Test
    func `Debounced text change coalesces keystrokes`() async {
        let searchBar = LMKSearchBar()
        var debounced: [String] = []
        searchBar.debounceInterval = 0.05
        searchBar.onDebouncedTextChange = { debounced.append($0) }
        searchBar.textField.text = "a"
        searchBar.clearButton.didTap()
        searchBar.textField.text = "ab"
        searchBar.clearButton.didTap()
        // Under parallel-suite load the main actor can stall well past the interval, so wait for the
        // callback with a generous deadline and then leave room for a stray second fire to land.
        let deadline = ContinuousClock.now + .seconds(10)
        while debounced.isEmpty, ContinuousClock.now < deadline {
            try? await Task.sleep(for: .milliseconds(20))
        }
        try? await Task.sleep(for: .milliseconds(150))
        #expect(debounced == [""])
    }

    @Test
    func `A pending debounce is dropped by Cancel, by Return, and by setting the text`() async {
        let searchBar = LMKSearchBar()
        var debounced: [String] = []
        var searches: [String] = []
        searchBar.debounceInterval = 0.05
        searchBar.onDebouncedTextChange = { debounced.append($0) }
        searchBar.onSearch = { searches.append($0) }

        searchBar.textField.text = "abc"
        searchBar.clearButton.didTap()
        #expect(searchBar.isDebouncePending)
        searchBar.cancelButton.didTap()
        #expect(!searchBar.isDebouncePending, "Cancel drops the search for text no longer in the field")

        searchBar.clearButton.didTap()
        #expect(searchBar.isDebouncePending)
        searchBar.text = "fern"
        #expect(!searchBar.isDebouncePending, "a programmatic text change is not a keystroke")

        searchBar.clearButton.didTap()
        #expect(searchBar.isDebouncePending)
        _ = searchBar.textFieldShouldReturn(searchBar.textField)
        #expect(!searchBar.isDebouncePending, "Return reports through onSearch, once")
        #expect(searches == [""])

        try? await Task.sleep(for: .milliseconds(150))
        #expect(debounced.isEmpty)
    }

    @Test
    func `Default surface, height floor, and strings`() {
        let searchBar = LMKSearchBar()
        #expect(searchBar.containerView.backgroundColor === LMKColor.backgroundTertiary)
        #expect(searchBar.containerView.layer.cornerRadius == LMKCornerRadius.medium)
        LMKThemeTesting.fit(searchBar, width: 300)
        #expect(searchBar.containerView.bounds.height >= 36)
        #expect(searchBar.iconView.tintColor === LMKColor.textTertiary)
        #expect(searchBar.cancelButton.title == "Cancel")
        #expect(searchBar.clearButton.accessibilityLabel == "Clear")
        searchBar.strings = LMKSearchBar.Strings(cancel: "Cancelar", clearAccessibilityLabel: "Limpiar")
        #expect(searchBar.cancelButton.title == "Cancelar")
        #expect(searchBar.clearButton.accessibilityLabel == "Limpiar")
    }

    @Test
    func `Style overrides apply per instance and through the theme`() {
        let searchBar = LMKSearchBar(style: LMKSearchBar.Style(surface: LMKSurfaceStyle(background: .solid(.red)), iconTint: .blue, height: 50))
        #expect(searchBar.containerView.backgroundColor == UIColor.red)
        #expect(searchBar.iconView.tintColor == UIColor.blue)
        LMKThemeTesting.fit(searchBar, width: 300)
        #expect(searchBar.containerView.bounds.height >= 50)

        let sized = LMKSearchBar(style: LMKSearchBar.Style(
            surface: LMKSurfaceStyle(contentInsets: NSDirectionalEdgeInsets(top: 6, leading: 20, bottom: 6, trailing: 4)),
            clearButtonTint: .green,
            clearButtonSize: 30
        ))
        sized.text = "x"
        LMKThemeTesting.fit(sized, width: 300)
        #expect(sized.clearButton.bounds.width == 30)
        #expect(sized.clearButton.style.tintColor == UIColor.green)
        #expect(sized.textField.frame.minY == 6, "vertical insets reach the field")
        #expect(sized.containerView.bounds.height >= sized.textField.bounds.height + 12)
        #expect(sized.iconView.frame.minX == 20)

        var theme = LMKTheme()
        theme.searchBar = LMKSearchBar.Style(placeholderColor: .purple)
        let themed = LMKSearchBar()
        themed.placeholder = "x"
        let window = LMKThemeTesting.host(themed, theme: theme)
        defer { window.isHidden = true }
        let color = themed.textField.attributedPlaceholder?.attribute(.foregroundColor, at: 0, effectiveRange: nil) as? UIColor
        #expect(color == UIColor.purple)
    }
}
