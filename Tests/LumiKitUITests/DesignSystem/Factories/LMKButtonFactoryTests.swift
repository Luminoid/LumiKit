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

@Suite("LMKButtonFactory (filled)")
@MainActor
struct LMKButtonFactoryFilledTests {
    private let target = DummyTarget()
    private var action: Selector { #selector(DummyTarget.dummyAction) }

    @Test("primary filled has primary background color")
    func primaryBackground() {
        let button = LMKButtonFactory.filled(role: .primary, title: "Save", target: target, action: action)
        #expect(button.configuration?.baseBackgroundColor == LMKColor.primary)
    }

    @Test("secondary filled has secondary background color")
    func secondaryBackground() {
        let button = LMKButtonFactory.filled(role: .secondary, title: "Cancel", target: target, action: action)
        #expect(button.configuration?.baseBackgroundColor == LMKColor.secondary)
    }

    @Test("destructive filled has error background color")
    func destructiveBackground() {
        let button = LMKButtonFactory.filled(role: .destructive, title: "Delete", target: target, action: action)
        #expect(button.configuration?.baseBackgroundColor == LMKColor.error)
    }

    @Test("warning filled has warning background color")
    func warningBackground() {
        let button = LMKButtonFactory.filled(role: .warning, title: "Warn", target: target, action: action)
        #expect(button.configuration?.baseBackgroundColor == LMKColor.warning)
    }

    @Test("success filled has success background color")
    func successBackground() {
        let button = LMKButtonFactory.filled(role: .success, title: "Done", target: target, action: action)
        #expect(button.configuration?.baseBackgroundColor == LMKColor.success)
    }

    @Test("info filled has info background color")
    func infoBackground() {
        let button = LMKButtonFactory.filled(role: .info, title: "Info", target: target, action: action)
        #expect(button.configuration?.baseBackgroundColor == LMKColor.info)
    }

    @Test("filled button title is set correctly")
    func buttonTitle() {
        let button = LMKButtonFactory.filled(role: .primary, title: "Submit", target: target, action: action)
        #expect(button.configuration?.title == "Submit")
    }

    @Test("filled button foreground color is white")
    func buttonForeground() {
        let button = LMKButtonFactory.filled(role: .primary, title: "Save", target: target, action: action)
        #expect(button.configuration?.baseForegroundColor == LMKColor.white)
    }

    @Test("filled button corner radius uses LMKCornerRadius.small")
    func buttonCornerRadius() {
        let button = LMKButtonFactory.filled(role: .primary, title: "Save", target: target, action: action)
        #expect(button.configuration?.background.cornerRadius == LMKCornerRadius.small)
    }
}

// MARK: - LMKButtonFactory (outlined)

@Suite("LMKButtonFactory (outlined)")
@MainActor
struct LMKButtonFactoryOutlinedTests {
    private let target = DummyTarget()
    private var action: Selector { #selector(DummyTarget.dummyAction) }

    @Test("primary outlined has primary foreground color")
    func primaryForeground() {
        let button = LMKButtonFactory.outlined(role: .primary, title: "Cancel", target: target, action: action)
        #expect(button.configuration?.baseForegroundColor == LMKColor.primary)
    }

    @Test("destructive outlined has error foreground color")
    func destructiveForeground() {
        let button = LMKButtonFactory.outlined(role: .destructive, title: "Remove", target: target, action: action)
        #expect(button.configuration?.baseForegroundColor == LMKColor.error)
    }

    @Test("outlined button title is set correctly")
    func buttonTitle() {
        let button = LMKButtonFactory.outlined(role: .secondary, title: "Skip", target: target, action: action)
        #expect(button.configuration?.title == "Skip")
    }

    @Test("outlined button has no background color")
    func clearBackground() {
        let button = LMKButtonFactory.outlined(role: .info, title: "Details", target: target, action: action)
        #expect(button.configuration?.baseBackgroundColor == nil)
    }
}
