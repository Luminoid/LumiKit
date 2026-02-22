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

// MARK: - LMKButtonFactory

@Suite("LMKButtonFactory")
@MainActor
struct LMKButtonFactoryTests {
    private let target = DummyTarget()
    private var action: Selector { #selector(DummyTarget.dummyAction) }

    @Test("primary button has primary background color")
    func primaryBackground() {
        let button = LMKButtonFactory.primary(title: "Save", target: target, action: action)
        #expect(button.configuration?.baseBackgroundColor == LMKColor.primary)
    }

    @Test("secondary button has secondary background color")
    func secondaryBackground() {
        let button = LMKButtonFactory.secondary(title: "Cancel", target: target, action: action)
        #expect(button.configuration?.baseBackgroundColor == LMKColor.secondary)
    }

    @Test("destructive button has error background color")
    func destructiveBackground() {
        let button = LMKButtonFactory.destructive(title: "Delete", target: target, action: action)
        #expect(button.configuration?.baseBackgroundColor == LMKColor.error)
    }

    @Test("warning button has warning background color")
    func warningBackground() {
        let button = LMKButtonFactory.warning(title: "Warn", target: target, action: action)
        #expect(button.configuration?.baseBackgroundColor == LMKColor.warning)
    }

    @Test("Button title is set correctly")
    func buttonTitle() {
        let button = LMKButtonFactory.primary(title: "Submit", target: target, action: action)
        #expect(button.configuration?.title == "Submit")
    }

    @Test("Button foreground color is white")
    func buttonForeground() {
        let button = LMKButtonFactory.primary(title: "Save", target: target, action: action)
        #expect(button.configuration?.baseForegroundColor == LMKColor.white)
    }

    @Test("Button corner radius uses LMKCornerRadius.small")
    func buttonCornerRadius() {
        let button = LMKButtonFactory.primary(title: "Save", target: target, action: action)
        #expect(button.configuration?.background.cornerRadius == LMKCornerRadius.small)
    }
}
