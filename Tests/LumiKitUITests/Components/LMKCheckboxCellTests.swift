//
//  LMKCheckboxCellTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

// MARK: - LMKCheckboxCell

@MainActor
struct LMKCheckboxCellTests {
    // MARK: - Helpers

    private func makeCell() -> LMKCheckboxCell {
        LMKCheckboxCell(style: .default, reuseIdentifier: LMKCheckboxCell.reuseIdentifier)
    }

    private func titleLabel(in cell: LMKCheckboxCell) -> UILabel? {
        cell.contentView.subviews.compactMap { $0 as? UILabel }.first
    }

    private func checkbox(in cell: LMKCheckboxCell) -> UIButton? {
        cell.contentView.subviews.compactMap { $0 as? UIButton }.first
    }

    // MARK: - Configuration

    @Test
    func `Configure sets plain title when not done`() {
        let cell = makeCell()
        cell.configure(title: "Pack sunscreen", isDone: false)

        let label = titleLabel(in: cell)
        #expect(label?.text == "Pack sunscreen")
        #expect(label?.attributedText?.attribute(.strikethroughStyle, at: 0, effectiveRange: nil) == nil)
    }

    @Test
    func `Configure strikes through the title when done`() {
        let cell = makeCell()
        cell.configure(title: "Book flights", isDone: true)

        let attributed = titleLabel(in: cell)?.attributedText
        #expect(attributed?.string == "Book flights")
        let strike = attributed?.attribute(.strikethroughStyle, at: 0, effectiveRange: nil) as? Int
        #expect(strike == NSUnderlineStyle.single.rawValue)
    }

    @Test
    func `Reconfiguring from done back to not done clears the strikethrough`() {
        let cell = makeCell()
        cell.configure(title: "Book flights", isDone: true)
        cell.configure(title: "Book flights", isDone: false)

        let label = titleLabel(in: cell)
        #expect(label?.text == "Book flights")
        #expect(label?.attributedText?.attribute(.strikethroughStyle, at: 0, effectiveRange: nil) == nil)
    }

    // MARK: - Toggle

    @Test
    func `Checkbox tap fires onToggle`() {
        let cell = makeCell()
        cell.configure(title: "Item", isDone: false)
        var toggled = false
        cell.onToggle = { toggled = true }

        // Invoke the wired target-action directly: `sendActions(for:)` routes
        // through UIApplication, which doesn't dispatch in a non-hosted test bundle.
        guard let button = checkbox(in: cell),
              let actionName = button.actions(forTarget: cell, forControlEvent: .touchUpInside)?.first else {
            Issue.record("Missing checkbox action wiring")
            return
        }
        _ = cell.perform(NSSelectorFromString(actionName))

        #expect(toggled)
    }

    // MARK: - Accessibility

    @Test
    func `Accessibility label mirrors the title`() {
        let cell = makeCell()
        cell.configure(title: "Pack sunscreen", isDone: false)
        #expect(cell.accessibilityLabel == "Pack sunscreen")
    }

    @Test
    func `Accessibility value and selected trait track done state`() {
        let cell = makeCell()

        cell.configure(title: "Item", isDone: false)
        #expect(cell.accessibilityValue == lmkCheckboxCellStrings.notDoneAccessibilityValue)
        #expect(!cell.accessibilityTraits.contains(.selected))

        cell.configure(title: "Item", isDone: true)
        #expect(cell.accessibilityValue == lmkCheckboxCellStrings.doneAccessibilityValue)
        #expect(cell.accessibilityTraits.contains(.selected))
    }

    @Test
    func `Checkbox button has an accessibility label`() {
        let cell = makeCell()
        #expect(checkbox(in: cell)?.accessibilityLabel == lmkCheckboxCellStrings.checkboxAccessibilityLabel)
    }

    @Test
    func `Checkbox hit area meets the minimum touch target`() {
        let cell = makeCell()
        cell.frame = CGRect(x: 0, y: 0, width: 375, height: 56)
        cell.layoutIfNeeded()

        guard let button = checkbox(in: cell) else {
            Issue.record("Missing checkbox button")
            return
        }
        let insets = button.lmk_touchAreaEdgeInsets
        let effectiveWidth = button.bounds.width - insets.left - insets.right
        let effectiveHeight = button.bounds.height - insets.top - insets.bottom
        #expect(effectiveWidth >= LMKLayout.minimumTouchTarget)
        #expect(effectiveHeight >= LMKLayout.minimumTouchTarget)
        // A point outside the glyph but inside the expanded area still hits.
        let outside = CGPoint(x: button.bounds.maxX + 5, y: button.bounds.midY)
        #expect(button.point(inside: outside, with: nil))
    }

    // MARK: - Reuse

    @Test
    func `prepareForReuse clears the toggle callback and title`() {
        let cell = makeCell()
        cell.configure(title: "Item", isDone: true)
        cell.onToggle = {}

        cell.prepareForReuse()

        #expect(cell.onToggle == nil)
        let label = titleLabel(in: cell)
        #expect(label?.text == nil)
        #expect(label?.attributedText == nil)
    }

    // MARK: - Strings

    @Test
    func `Default strings are English`() {
        let strings = LMKCheckboxCellStrings()
        #expect(strings.checkboxAccessibilityLabel == "Toggle done")
        #expect(strings.doneAccessibilityValue == "Done")
        #expect(strings.notDoneAccessibilityValue == "Not done")
    }

    @Test
    func `Custom strings are preserved`() {
        let strings = LMKCheckboxCellStrings(
            checkboxAccessibilityLabel: "Alternar",
            doneAccessibilityValue: "Hecho",
            notDoneAccessibilityValue: "Pendiente"
        )
        #expect(strings.checkboxAccessibilityLabel == "Alternar")
        #expect(strings.doneAccessibilityValue == "Hecho")
        #expect(strings.notDoneAccessibilityValue == "Pendiente")
    }
}
