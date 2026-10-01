//
//  LMKStatusLabelTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

@MainActor
struct LMKStatusLabelTests {
    @Test
    func `Starts hidden and shows a colored message`() {
        let label = LMKStatusLabel()
        #expect(label.isHidden)
        label.show("Saved", status: .success)
        #expect(!label.isHidden)
        #expect(label.textLabel.text == "Saved")
        #expect(label.textLabel.textColor === LMKColor.success)
        #expect(label.iconView.tintColor === LMKColor.success)
        #expect(!label.iconView.isHidden)
        #expect(label.accessibilityLabel == "Saved")
        #expect(label.status == .success)
    }

    @Test
    func `Neutral status has no icon and clear hides the view`() {
        let label = LMKStatusLabel()
        label.show("3 selected")
        #expect(label.iconView.isHidden)
        #expect(label.textLabel.textColor === LMKColor.textSecondary)
        label.clear()
        #expect(label.isHidden)
        #expect(label.message == nil)
        #expect(label.textLabel.text == nil)
    }

    @Test
    func `showsIcon hides a glyph but never shows an empty slot`() {
        let label = LMKStatusLabel(style: LMKStatusLabel.Style(showsIcon: true))
        label.show("Counting", status: .neutral)
        #expect(label.iconView.isHidden, "neutral has no glyph, so there is nothing to show")
        label.show("Saved", status: .success)
        #expect(!label.iconView.isHidden)
        label.style.showsIcon = false
        #expect(label.iconView.isHidden)
        label.style.showsIcon = nil
        #expect(!label.iconView.isHidden)
    }

    @Test
    func `Style colors override per status`() {
        let label = LMKStatusLabel(style: LMKStatusLabel.Style(colors: [.error: .purple]))
        label.show("Bad", status: .error)
        #expect(label.textLabel.textColor == UIColor.purple)
        label.show("Ok", status: .success)
        #expect(label.textLabel.textColor === LMKColor.success)
    }
}
