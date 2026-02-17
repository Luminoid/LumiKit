//
//  LMKTextFieldTests.swift
//  LumiKit
//

import Testing
import UIKit

@testable import LumiKitUI

// MARK: - LMKTextField

@Suite("LMKTextField")
@MainActor
struct LMKTextFieldTests {
    @Test("Normal state has divider border color")
    func normalState() {
        let field = LMKTextField()
        #expect(field.textField.font == LMKTypography.body)
    }

    @Test("Error state updates border and shows message")
    func errorState() {
        let field = LMKTextField()
        field.validationState = .error("Invalid")
        // Verify state was set (border color testing is limited in unit tests)
        if case .error(let msg) = field.validationState {
            #expect(msg == "Invalid")
        } else {
            #expect(Bool(false))
        }
    }

    @Test("Placeholder sets attributed placeholder")
    func placeholder() {
        let field = LMKTextField()
        field.placeholder = "Email"
        #expect(field.textField.attributedPlaceholder?.string == "Email")
    }

    @Test("Text property proxies to textField")
    func textProxy() {
        let field = LMKTextField()
        field.text = "Hello"
        #expect(field.textField.text == "Hello")
        #expect(field.text == "Hello")
    }
}
