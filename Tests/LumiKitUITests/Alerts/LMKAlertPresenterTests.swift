//
//  LMKAlertPresenterTests.swift
//  LumiKit
//

import Testing
import UIKit

@testable import LumiKitUI

// MARK: - LMKAlertPresenter

@Suite("LMKAlertPresenter")
struct LMKAlertPresenterTests {
    @Test("Default strings are English")
    func defaultStrings() {
        let strings = LMKAlertPresenter.Strings()
        #expect(strings.ok == "OK")
        #expect(strings.cancel == "Cancel")
    }

    @Test("Custom strings are preserved")
    func customStrings() {
        let strings = LMKAlertPresenter.Strings(ok: "Aceptar", cancel: "Cancelar")
        #expect(strings.ok == "Aceptar")
        #expect(strings.cancel == "Cancelar")
    }

    @Test("Static strings can be overridden")
    func overrideStaticStrings() {
        let original = LMKAlertPresenter.strings
        LMKAlertPresenter.strings = .init(ok: "OK!", cancel: "Nah")
        #expect(LMKAlertPresenter.strings.ok == "OK!")
        #expect(LMKAlertPresenter.strings.cancel == "Nah")
        // Restore
        LMKAlertPresenter.strings = original
    }
}
