//
//  LMKErrorHandlerTests.swift
//  LumiKit
//

import Testing
import UIKit

@testable import LumiKitUI

// MARK: - LMKErrorHandler

@Suite("LMKErrorHandler")
@MainActor
struct LMKErrorHandlerTests {
    @Test("Default error handler strings are English")
    func defaultStrings() {
        let strings = LMKErrorHandler.Strings()
        #expect(strings.errorTitle == "Error")
        #expect(strings.retry == "Retry")
        #expect(strings.ok == "OK")
        #expect(strings.warningTitle == "Warning")
        #expect(strings.infoTitle == "Info")
    }

    @Test("Custom error handler strings are preserved")
    func customStrings() {
        let strings = LMKErrorHandler.Strings(errorTitle: "Oops", retry: "Again", ok: "Done")
        #expect(strings.errorTitle == "Oops")
        #expect(strings.retry == "Again")
        #expect(strings.ok == "Done")
    }

    @Test("Severity enum has all expected cases")
    func severityCases() {
        let cases: [LMKErrorHandler.Severity] = [.info, .warning, .error, .critical]
        #expect(cases.count == 4)
    }

    @Test("Static strings can be overridden")
    func overrideStaticStrings() {
        let original = LMKErrorHandler.strings
        defer { LMKErrorHandler.strings = original }

        LMKErrorHandler.strings = .init(errorTitle: "Fallo", retry: "Reintentar", ok: "Aceptar", warningTitle: "Aviso", infoTitle: "Info")
        #expect(LMKErrorHandler.strings.errorTitle == "Fallo")
        #expect(LMKErrorHandler.strings.retry == "Reintentar")
    }
}
