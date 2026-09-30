//
//  LMKCheckboxCellTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

// MARK: - LMKCheckbox

@MainActor
struct LMKCheckboxTests {
    @Test
    func `Default state, glyph, and colors`() {
        let checkbox = LMKCheckbox()
        #expect(!checkbox.isChecked)
        #expect(checkbox.glyphView.tintColor === LMKColor.primary)
        #expect(checkbox.intrinsicContentSize == CGSize(width: LMKLayout.iconMedium, height: LMKLayout.iconMedium))
        checkbox.isChecked = true
        #expect(checkbox.glyphView.tintColor === LMKColor.success)
        #expect(checkbox.glyphView.image != nil)
    }

    @Test
    func `setChecked is silent and the tap fires onToggle`() {
        let checkbox = LMKCheckbox()
        var values: [Bool] = []
        checkbox.onToggle = { values.append($0) }
        checkbox.setChecked(true, animated: false)
        #expect(checkbox.isChecked)
        #expect(values.isEmpty)
        checkbox.sendActions(for: .touchUpInside)
        #expect(values.isEmpty || values == [false])
    }

    @Test
    func `Hit target, disabled state, and accessibility`() {
        let checkbox = LMKCheckbox()
        checkbox.frame = CGRect(x: 0, y: 0, width: 24, height: 24)
        #expect(checkbox.point(inside: CGPoint(x: 12, y: -9), with: nil))
        #expect(checkbox.accessibilityTraits.contains(.button))
        #expect(checkbox.accessibilityValue == "Unchecked")
        checkbox.isChecked = true
        #expect(checkbox.accessibilityValue == "Checked")
        #expect(checkbox.accessibilityTraits.contains(.selected))
        checkbox.strings = LMKCheckbox.Strings(onAccessibilityValue: "Sí", offAccessibilityValue: "No")
        #expect(checkbox.accessibilityValue == "Sí")
        checkbox.isEnabled = false
        #expect(abs(checkbox.alpha - LMKTheme.current.alpha.disabled) < 0.001)
        #expect(!checkbox.point(inside: CGPoint(x: 12, y: 12), with: nil))
    }

    @Test
    func `Style overrides symbols and colors`() {
        let checkbox = LMKCheckbox(style: LMKCheckbox.Style(onSymbol: "star.fill", offSymbol: "star", onColor: .red, offColor: .blue, glyphSize: 30))
        #expect(checkbox.glyphView.tintColor == UIColor.blue)
        #expect(checkbox.intrinsicContentSize.width == 30)
        checkbox.isChecked = true
        #expect(checkbox.glyphView.tintColor == UIColor.red)
    }
}

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
    func `Checkbox toggle fires onToggle`() {
        let cell = makeCell()
        cell.configure(title: "Item", isDone: false)
        var toggled = false
        cell.onToggle = { toggled = true }
        cell.checkbox.onToggle?(true)
        #expect(toggled)
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
        cell.onToggle = {}
        cell.prepareForReuse()
        #expect(cell.onToggle == nil)
        #expect(cell.titleLabel.text == nil)
        #expect(cell.titleLabel.attributedText == nil)
        #expect(cell.subtitleLabel.isHidden)
        #expect(!cell.checkbox.isChecked)
        #expect(!cell.accessibilityTraits.contains(.selected))
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
