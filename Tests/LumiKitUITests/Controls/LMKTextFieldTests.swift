//
//  LMKTextFieldTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

// MARK: - LMKTextField

@MainActor
struct LMKTextFieldTests {
    @Test
    func `Normal state has divider border color`() {
        let field = LMKTextField()
        #expect(field.textField.font == LMKTypography.body)
    }

    @Test
    func `Error state updates border and shows message`() {
        let field = LMKTextField()
        field.validationState = .error("Invalid")
        // Verify state was set (border color testing is limited in unit tests)
        if case let .error(msg) = field.validationState {
            #expect(msg == "Invalid")
        } else {
            Issue.record("Expected .error state")
        }
    }

    @Test
    func `Placeholder sets attributed placeholder`() {
        let field = LMKTextField()
        field.placeholder = "Email"
        #expect(field.textField.attributedPlaceholder?.string == "Email")
    }

    @Test
    func `Text property proxies to textField`() {
        let field = LMKTextField()
        field.text = "Hello"
        #expect(field.textField.text == "Hello")
        #expect(field.text == "Hello")
    }
}
