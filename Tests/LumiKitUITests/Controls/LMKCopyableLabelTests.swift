//
//  LMKCopyableLabelTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

@MainActor
struct LMKCopyableLabelTests {
    @Test
    func `Copyable text comes from the provider, the attributed text, or the plain text`() {
        let label = LMKCopyableLabel()
        #expect(label.copyableText == nil)
        label.text = "555-0100"
        #expect(label.copyableText == "555-0100")
        label.attributedText = NSAttributedString(string: "Attributed")
        #expect(label.copyableText == "Attributed")
        label.copyTextProvider = { "raw" }
        #expect(label.copyableText == "raw")
        label.copyTextProvider = { "" }
        #expect(label.copyableText == nil)
        label.copyTextProvider = nil
        label.text = ""
        label.attributedText = nil
        #expect(label.copyableText == nil)
    }

    @Test
    func `Copying writes the pasteboard and reports the text`() {
        let label = LMKCopyableLabel()
        label.haptics = false
        var copied: [String] = []
        var written: [String] = []
        // Never touch `UIPasteboard.general` here: it blocks the main thread in the xctest host.
        label.writeToPasteboard = { written.append($0) }
        label.onCopy = { copied.append($0) }
        #expect(!label.copyToPasteboard(), "nothing to copy")
        label.text = "ABC-123"
        #expect(label.copyToPasteboard())
        #expect(written == ["ABC-123"])
        #expect(copied == ["ABC-123"])
        label.isCopyEnabled = false
        #expect(!label.copyToPasteboard())
        #expect(copied.count == 1)
    }

    @Test
    func `Interaction, menu, and VoiceOver action follow isCopyEnabled`() {
        let label = LMKCopyableLabel()
        label.text = "Value"
        #expect(label.isUserInteractionEnabled)
        #expect(label.interactions.contains { $0 is UIEditMenuInteraction })
        #expect(label.gestureRecognizers?.contains { $0 is UILongPressGestureRecognizer } == true)
        #expect(label.accessibilityCustomActions?.map(\.name) == [LMKCopyableLabel.Strings().copy])

        let interaction = UIEditMenuInteraction(delegate: nil)
        let menu = label.editMenuInteraction(interaction, menuFor: UIEditMenuConfiguration(identifier: nil, sourcePoint: .zero), suggestedActions: [])
        #expect(menu?.children.count == 1)
        #expect((menu?.children.first as? UIAction)?.title == LMKCopyableLabel.Strings().copy)

        let secondaryClick = label.gestureRecognizers?.compactMap { $0 as? UITapGestureRecognizer }.first { $0.buttonMaskRequired == .secondary }
        #expect(secondaryClick != nil, "a right click on iPad or Mac opens the menu too")
        label.frame = CGRect(x: 0, y: 0, width: 80, height: 19)
        #expect(label.point(inside: CGPoint(x: 40, y: -10), with: nil), "44pt band")

        label.isCopyEnabled = false
        #expect(label.accessibilityCustomActions == nil)
        #expect(label.editMenuInteraction(interaction, menuFor: UIEditMenuConfiguration(identifier: nil, sourcePoint: .zero), suggestedActions: []) == nil)
        #expect(label.gestureRecognizers?.first { $0 is UILongPressGestureRecognizer }?.isEnabled == false)
        #expect(secondaryClick?.isEnabled == false)
        #expect(!label.isUserInteractionEnabled, "a plain label passes touches to its row")
        #expect(!label.point(inside: CGPoint(x: 40, y: -10), with: nil))
        label.isCopyEnabled = true
        #expect(label.isUserInteractionEnabled)
        label.isHidden = true
        #expect(!label.point(inside: CGPoint(x: 40, y: 10), with: nil))
    }

    @Test
    func `The menu is not presented outside a window`() {
        let label = LMKCopyableLabel()
        label.text = "Value"
        label.presentCopyMenu(at: .zero)
        #expect(label.window == nil, "no window, no menu, no assertion from UIEditMenuInteraction")
    }

    @Test
    func `Strings rename the menu item`() {
        let label = LMKCopyableLabel()
        label.text = "x"
        label.strings = LMKCopyableLabel.Strings(copy: "Copy number")
        #expect(label.accessibilityCustomActions?.first?.name == "Copy number")
        let menu = label.editMenuInteraction(UIEditMenuInteraction(delegate: nil), menuFor: UIEditMenuConfiguration(identifier: nil, sourcePoint: .zero), suggestedActions: [])
        #expect((menu?.children.first as? UIAction)?.title == "Copy number")
    }
}
