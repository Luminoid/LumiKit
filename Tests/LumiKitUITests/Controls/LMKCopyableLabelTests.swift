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
        label.onCopied = { copied.append($0) }
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

        label.isCopyEnabled = false
        #expect(label.accessibilityCustomActions == nil)
        #expect(label.editMenuInteraction(interaction, menuFor: UIEditMenuConfiguration(identifier: nil, sourcePoint: .zero), suggestedActions: []) == nil)
        #expect(label.gestureRecognizers?.first { $0 is UILongPressGestureRecognizer }?.isEnabled == false)
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
