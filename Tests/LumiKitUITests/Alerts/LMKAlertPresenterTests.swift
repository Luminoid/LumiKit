//
//  LMKAlertPresenterTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

// MARK: - LMKAlertPresenter

struct LMKAlertPresenterTests {
    @Test
    func `Default strings are English`() {
        let strings = LMKAlertPresenter.Strings()
        #expect(strings.ok == "OK")
        #expect(strings.cancel == "Cancel")
    }

    @Test
    func `Custom strings are preserved`() {
        let strings = LMKAlertPresenter.Strings(ok: "Aceptar", cancel: "Cancelar")
        #expect(strings.ok == "Aceptar")
        #expect(strings.cancel == "Cancelar")
    }

    @Test
    func `Static strings can be overridden`() {
        let original = LMKAlertPresenter.strings
        LMKAlertPresenter.strings = .init(ok: "OK!", cancel: "Nah")
        #expect(LMKAlertPresenter.strings.ok == "OK!")
        #expect(LMKAlertPresenter.strings.cancel == "Nah")
        // Restore
        LMKAlertPresenter.strings = original
    }
}
