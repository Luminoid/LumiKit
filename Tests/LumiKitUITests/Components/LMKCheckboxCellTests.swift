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
    private func makeCell() -> LMKCheckboxCell {
        LMKCheckboxCell(style: .default, reuseIdentifier: LMKCheckboxCell.reuseIdentifier)
    }

    @Test
    func `Configure sets the title and strikes it through when done`() {
        let cell = makeCell()
        cell.configure(title: "Pack sunscreen", isDone: false)
        #expect(cell.titleLabel.text == "Pack sunscreen")
        #expect(cell.titleLabel.attributedText?.attribute(.strikethroughStyle, at: 0, effectiveRange: nil) == nil)
        #expect(!cell.checkbox.isChecked)
        #expect(cell.subtitleLabel.isHidden)

        cell.configure(title: "Book flights", subtitle: "Before Friday", isDone: true)
        let strike = cell.titleLabel.attributedText?.attribute(.strikethroughStyle, at: 0, effectiveRange: nil) as? Int
        #expect(strike == NSUnderlineStyle.single.rawValue)
        #expect(cell.checkbox.isChecked)
        #expect(!cell.subtitleLabel.isHidden)
        #expect(cell.subtitleLabel.text == "Before Friday")

        cell.configure(title: "Book flights", isDone: false)
        #expect(cell.titleLabel.attributedText?.attribute(.strikethroughStyle, at: 0, effectiveRange: nil) == nil)
    }

    @Test
    func `A checkbox tap flips the row, then reports the value; setDone is silent`() {
        let cell = makeCell()
        cell.configure(title: "Item", isDone: false)
        var values: [Bool] = []
        cell.onValueChange = { values.append($0) }
        cell.checkbox.onValueChange?(true)
        #expect(values == [true])
        #expect(cell.isDone, "the row follows the checkbox without a second configure")
        let strike = cell.titleLabel.attributedText?.attribute(.strikethroughStyle, at: 0, effectiveRange: nil) as? Int
        #expect(strike == NSUnderlineStyle.single.rawValue)
        #expect(cell.accessibilityValue == LMKCheckboxCell.Strings().doneAccessibilityValue)
        #expect(cell.accessibilityTraits.contains(.selected))

        cell.setDone(false, animated: false)
        #expect(!cell.isDone)
        #expect(!cell.checkbox.isChecked)
        #expect(cell.titleLabel.attributedText?.attribute(.strikethroughStyle, at: 0, effectiveRange: nil) == nil)
        #expect(values == [true], "the row-tap path already knows the value")

        #expect(cell.isAccessibilityElement)
        #expect(cell.accessibilityActivate(), "VoiceOver's double tap toggles the row")
        #expect(cell.isDone)
        #expect(cell.checkbox.isChecked)
        #expect(values == [true, true])

        cell.checkbox.isEnabled = false
        #expect(cell.accessibilityTraits.contains(.notEnabled))
        #expect(!cell.accessibilityActivate(), "a disabled row does not toggle")
        #expect(cell.isDone)
        #expect(values == [true, true])
        cell.checkbox.isEnabled = true
        #expect(!cell.accessibilityTraits.contains(.notEnabled))
    }

    @Test
    func `Accessibility mirrors the title, done state, and strings`() {
        let cell = makeCell()
        cell.configure(title: "Item", subtitle: "Sub", isDone: false)
        #expect(cell.accessibilityLabel == "Item. Sub")
        #expect(cell.accessibilityValue == LMKCheckboxCell.Strings().notDoneAccessibilityValue)
        #expect(!cell.accessibilityTraits.contains(.selected))
        #expect(cell.checkbox.accessibilityLabel == LMKCheckboxCell.Strings().checkboxAccessibilityLabel)
        cell.configure(title: "Item", isDone: true)
        #expect(cell.accessibilityValue == LMKCheckboxCell.Strings().doneAccessibilityValue)
        #expect(cell.accessibilityTraits.contains(.selected))
        cell.strings = LMKCheckboxCell.Strings(checkboxAccessibilityLabel: "Alternar", doneAccessibilityValue: "Hecho", notDoneAccessibilityValue: "Pendiente")
        #expect(cell.accessibilityValue == "Hecho")
        #expect(cell.checkbox.accessibilityLabel == "Alternar")
    }

    @Test
    func `Checkbox hit area meets the minimum touch target`() {
        let cell = makeCell()
        cell.frame = CGRect(x: 0, y: 0, width: 375, height: 56)
        cell.layoutIfNeeded()
        let outside = CGPoint(x: cell.checkbox.bounds.maxX + 5, y: cell.checkbox.bounds.midY)
        #expect(cell.checkbox.point(inside: outside, with: nil))
    }

    @Test
    func `prepareForReuse clears everything`() {
        let cell = makeCell()
        cell.configure(title: "Item", subtitle: "Sub", isDone: true)
        cell.onValueChange = { _ in }
        cell.checkbox.isEnabled = false
        cell.isUserInteractionEnabled = false
        cell.alpha = 0.5
        cell.prepareForReuse()
        #expect(cell.onValueChange == nil)
        #expect(cell.titleLabel.text == nil)
        #expect(cell.titleLabel.attributedText == nil)
        #expect(cell.subtitleLabel.isHidden)
        #expect(!cell.checkbox.isChecked)
        #expect(!cell.accessibilityTraits.contains(.selected))
        #expect(cell.checkbox.isEnabled, "what a host set on a disabled row does not ride along")
        #expect(cell.isUserInteractionEnabled)
        #expect(cell.alpha == 1)
    }

    @Test
    func `Style and theme defaults apply`() {
        let cell = makeCell()
        cell.style = LMKCheckboxCell.Style(background: .red, doneColor: .blue, strikesThroughWhenDone: false)
        cell.configure(title: "Item", isDone: true)
        #expect(cell.backgroundColor == UIColor.red)
        #expect(cell.titleLabel.textColor == UIColor.blue)
        #expect(cell.titleLabel.attributedText?.attribute(.strikethroughStyle, at: 0, effectiveRange: nil) == nil)

        var theme = LMKTheme()
        theme.checkboxCell = LMKCheckboxCell.Style(checkbox: LMKCheckbox.Style(offColor: .magenta))
        let themed = makeCell()
        let window = LMKThemeTesting.host(themed, theme: theme)
        defer { window.isHidden = true }
        #expect(themed.checkbox.glyphView.tintColor == UIColor.magenta)
    }

    @Test
    func `Default strings are English`() {
        let strings = LMKCheckboxCell.Strings()
        #expect(strings.checkboxAccessibilityLabel == "Toggle done")
        #expect(strings.doneAccessibilityValue == "Done")
        #expect(strings.notDoneAccessibilityValue == "Not done")
    }
}
