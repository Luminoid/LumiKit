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
        #expect(strings.save == "Save")
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

// MARK: - LMKAlertPresenter (presentTextInput)

@MainActor
struct LMKAlertPresenterTextInputTests {
    // MARK: - Helpers

    private func makePresenter() -> (UIViewController, UIWindow) {
        let presenter = UIViewController()
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 375, height: 812))
        window.rootViewController = presenter
        window.makeKeyAndVisible()
        return (presenter, window)
    }

    private func presentedAlert(_ presenter: UIViewController) -> UIAlertController? {
        presenter.presentedViewController as? UIAlertController
    }

    // MARK: - Tests

    @Test
    func `Presents an alert with a single text field`() {
        let (presenter, window) = makePresenter()
        _ = window

        LMKAlertPresenter.presentTextInput(on: presenter, title: "Rename", onSave: { _ in })

        let alert = presentedAlert(presenter)
        #expect(alert != nil)
        #expect(alert?.preferredStyle == .alert)
        #expect(alert?.title == "Rename")
        #expect(alert?.textFields?.count == 1)
    }

    @Test
    func `Configures the text field from parameters`() {
        let (presenter, window) = makePresenter()
        _ = window

        LMKAlertPresenter.presentTextInput(
            on: presenter,
            title: "Custom model",
            placeholder: "gemini-2.5-flash",
            initialText: "my-model",
            autocapitalizationType: .none,
            autocorrectionType: .no,
            keyboardType: .asciiCapable,
            onSave: { _ in }
        )

        let field = presentedAlert(presenter)?.textFields?.first
        #expect(field?.placeholder == "gemini-2.5-flash")
        #expect(field?.text == "my-model")
        #expect(field?.autocapitalizationType == UITextAutocapitalizationType.none)
        #expect(field?.autocorrectionType == .no)
        #expect(field?.keyboardType == .asciiCapable)
    }

    @Test
    func `Defaults to sentences capitalization and save plus cancel actions`() {
        let (presenter, window) = makePresenter()
        _ = window

        LMKAlertPresenter.presentTextInput(on: presenter, title: "Add item", onSave: { _ in })

        let alert = presentedAlert(presenter)
        #expect(alert?.textFields?.first?.autocapitalizationType == .sentences)
        #expect(alert?.actions.count == 2)
        #expect(alert?.actions.first?.style == .cancel)
        #expect(alert?.actions.first?.title == LMKAlertPresenter.strings.cancel)
        #expect(alert?.actions.last?.style == UIAlertAction.Style.default)
        #expect(alert?.actions.last?.title == LMKAlertPresenter.strings.save)
    }

    @Test
    func `Custom button titles override the defaults`() {
        let (presenter, window) = makePresenter()
        _ = window

        LMKAlertPresenter.presentTextInput(
            on: presenter,
            title: "Add",
            saveTitle: "Create",
            cancelTitle: "Later",
            onSave: { _ in }
        )

        let alert = presentedAlert(presenter)
        #expect(alert?.actions.first?.title == "Later")
        #expect(alert?.actions.last?.title == "Create")
    }
}
