//
//  LMKButtonFactoryTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

// MARK: - Helper

private final class DummyTarget: NSObject {
    @objc func dummyAction() {}
}

// MARK: - LMKButtonFactory (filled)

@MainActor
struct LMKButtonFactoryFilledTests {
    private let target = DummyTarget()
    private var action: Selector { #selector(DummyTarget.dummyAction) }

    @Test
    func `primary filled has primary background color`() {
        let button = LMKButtonFactory.filled(role: .primary, title: "Save", target: target, action: action)
        #expect(button.configuration?.baseBackgroundColor == LMKColor.primary)
    }

    @Test
    func `secondary filled has secondary background color`() {
        let button = LMKButtonFactory.filled(role: .secondary, title: "Cancel", target: target, action: action)
        #expect(button.configuration?.baseBackgroundColor == LMKColor.secondary)
    }

    @Test
    func `destructive filled has error background color`() {
        let button = LMKButtonFactory.filled(role: .destructive, title: "Delete", target: target, action: action)
        #expect(button.configuration?.baseBackgroundColor == LMKColor.error)
    }

    @Test
    func `warning filled has warning background color`() {
        let button = LMKButtonFactory.filled(role: .warning, title: "Warn", target: target, action: action)
        #expect(button.configuration?.baseBackgroundColor == LMKColor.warning)
    }

    @Test
    func `success filled has success background color`() {
        let button = LMKButtonFactory.filled(role: .success, title: "Done", target: target, action: action)
        #expect(button.configuration?.baseBackgroundColor == LMKColor.success)
    }

    @Test
    func `info filled has info background color`() {
        let button = LMKButtonFactory.filled(role: .info, title: "Info", target: target, action: action)
        #expect(button.configuration?.baseBackgroundColor == LMKColor.info)
    }

    @Test
    func `filled button title is set correctly`() {
        let button = LMKButtonFactory.filled(role: .primary, title: "Submit", target: target, action: action)
        #expect(button.configuration?.title == "Submit")
    }

    @Test
    func `filled button foreground color is white`() {
        let button = LMKButtonFactory.filled(role: .primary, title: "Save", target: target, action: action)
        #expect(button.configuration?.baseForegroundColor == LMKColor.white)
    }

    @Test
    func `filled button uses capsule corner style`() {
        let button = LMKButtonFactory.filled(role: .primary, title: "Save", target: target, action: action)
        #expect(button.configuration?.cornerStyle == .capsule)
    }
}

// MARK: - LMKButtonFactory (outlined)

@MainActor
struct LMKButtonFactoryOutlinedTests {
    private let target = DummyTarget()
    private var action: Selector { #selector(DummyTarget.dummyAction) }

    @Test
    func `primary outlined has primary foreground color`() {
        let button = LMKButtonFactory.outlined(role: .primary, title: "Cancel", target: target, action: action)
        #expect(button.configuration?.baseForegroundColor == LMKColor.primary)
    }

    @Test
    func `destructive outlined has error foreground color`() {
        let button = LMKButtonFactory.outlined(role: .destructive, title: "Remove", target: target, action: action)
        #expect(button.configuration?.baseForegroundColor == LMKColor.error)
    }

    @Test
    func `outlined button title is set correctly`() {
        let button = LMKButtonFactory.outlined(role: .secondary, title: "Skip", target: target, action: action)
        #expect(button.configuration?.title == "Skip")
    }

    @Test
    func `outlined button has no background color`() {
        let button = LMKButtonFactory.outlined(role: .info, title: "Details", target: target, action: action)
        #expect(button.configuration?.baseBackgroundColor == nil)
    }
}
