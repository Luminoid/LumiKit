//
//  LMKAlertTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

struct LMKAlertStringsTests {
    @Test
    func `Default strings are English and overridable`() {
        let strings = LMKAlert.Strings()
        #expect(strings.ok == "OK")
        #expect(strings.cancel == "Cancel")
        #expect(strings.save == "Save")
        #expect(strings.delete == "Delete")
        #expect(strings.deleteConfirmationTitleFormat.contains("%@"))
        #expect(!strings.deleteConfirmationMessage.isEmpty)
        let custom = LMKAlert.Strings(ok: "Aceptar", cancel: "Cancelar")
        #expect(custom.ok == "Aceptar")
        #expect(custom.cancel == "Cancelar")
    }
}

@MainActor
struct LMKAlertTests {
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

    @Test
    func `Confirmation and simple alerts carry their titles and actions`() {
        let (presenter, window) = makePresenter()
        defer { window.isHidden = true }
        let alert = LMKAlert.presentConfirmation(from: presenter, title: "Sign out?", message: "M", confirmTitle: "Sign out", confirmStyle: .destructive, onConfirm: {})
        #expect(presentedAlert(presenter) === alert)
        #expect(alert.title == "Sign out?")
        #expect(alert.message == "M")
        #expect(alert.actions.map(\.title) == ["Cancel", "Sign out"])
        #expect(alert.actions.first?.style == .cancel)
        #expect(alert.actions.last?.style == .destructive)

        let other = UIViewController()
        window.rootViewController = other
        let simple = LMKAlert.present(from: other, title: "Update")
        #expect(simple.actions.map(\.title) == ["OK"])
    }

    @Test
    func `Delete confirmation formats the item name and is destructive`() {
        let (presenter, window) = makePresenter()
        defer { window.isHidden = true }
        let alert = LMKAlert.presentDeleteConfirmation(from: presenter, itemName: "Fern", onConfirm: {})
        #expect(alert.title?.contains("Fern") == true)
        #expect(alert.message == LMKAlert.strings.deleteConfirmationMessage)
        #expect(alert.actions.last?.title == "Delete")
        #expect(alert.actions.last?.style == .destructive)
    }

    @Test
    func `Text input configures the field and validates before enabling Save`() {
        let (presenter, window) = makePresenter()
        defer { window.isHidden = true }
        let alert = LMKAlert.presentTextInput(LMKAlert.TextInput(
            title: "Custom model",
            placeholder: "gemini-3.5-flash",
            initialText: "",
            autocapitalizationType: .none,
            autocorrectionType: .no,
            keyboardType: .asciiCapable,
            isSecure: true,
            saveTitle: "Create",
            cancelTitle: "Later",
            validate: { !$0.isEmpty },
            configureField: { $0.placeholder = "Overridden" }
        ), from: presenter) { _ in }
        #expect(presentedAlert(presenter) === alert)
        let field = alert.textFields?.first
        #expect(alert.textFields?.count == 1)
        #expect(field?.placeholder == "Overridden", "configureField runs last, so its changes win")
        #expect(field?.autocapitalizationType == UITextAutocapitalizationType.none)
        #expect(field?.autocorrectionType == .no)
        #expect(field?.keyboardType == .asciiCapable)
        #expect(field?.isSecureTextEntry == true)
        #expect(alert.actions.map(\.title) == ["Later", "Create"])
        #expect(alert.actions.last?.isEnabled == false, "empty text fails validation")

        let other = UIViewController()
        window.rootViewController = other
        let valid = LMKAlert.presentTextInput(LMKAlert.TextInput(title: "T", initialText: "ok", validate: { !$0.isEmpty }), from: other) { _ in }
        #expect(valid.actions.last?.isEnabled == true)

        let third = UIViewController()
        window.rootViewController = third
        let short = LMKAlert.presentTextInput(from: third, title: "Rename", placeholder: "Name", initialText: "Fern") { _ in }
        #expect(short.textFields?.first?.text == "Fern")
        #expect(short.textFields?.first?.autocapitalizationType == .sentences)
        #expect(short.actions.map(\.title) == ["Cancel", "Save"])
    }

    /// Runs an alert action's handler the way a tap would (UIKit keeps it in a private property).
    private func run(_ action: UIAlertAction) {
        typealias Handler = @convention(block) (UIAlertAction) -> Void
        guard action.responds(to: NSSelectorFromString("handler")), let block = action.value(forKey: "handler") else { return }
        unsafeBitCast(block as AnyObject, to: Handler.self)(action)
    }

    @Test
    func `Secure text input turns off autocorrection and adds actions after Save`() throws {
        let (presenter, window) = makePresenter()
        defer { window.isHidden = true }
        var removed = 0
        var saved: [String] = []
        let alert = LMKAlert.presentTextInput(LMKAlert.TextInput(
            title: "API Key",
            initialText: "sk-123",
            isSecure: true,
            additionalActions: [
                .init(title: "Remove", style: .destructive) { removed += 1 },
                .init(title: "Off", isEnabled: false) {},
            ]
        ), from: presenter) { saved.append($0) }
        let field = try #require(alert.textFields?.first)
        #expect(field.isSecureTextEntry)
        #expect(field.autocorrectionType == .no)
        #expect(field.autocapitalizationType == UITextAutocapitalizationType.none)
        #expect(field.spellCheckingType == .no)
        #expect(field.smartQuotesType == .no)
        #expect(field.smartDashesType == .no)
        #expect(alert.actions.map(\.title) == ["Cancel", "Save", "Remove", "Off"])
        #expect(alert.actions.map(\.style) == [.cancel, .default, .destructive, .default])
        #expect(alert.actions[3].isEnabled == false)
        run(alert.actions[2])
        #expect(removed == 1)
        #expect(saved.isEmpty, "an additional action does not save")
        run(alert.actions[1])
        #expect(saved == ["sk-123"])

        // The defaults keep the plain prompt: no extra actions, the field's own text settings.
        let other = UIViewController()
        window.rootViewController = other
        let plain = LMKAlert.presentTextInput(from: other, title: "Rename", initialText: "Fern") { _ in }
        #expect(plain.actions.map(\.title) == ["Cancel", "Save"])
        #expect(plain.textFields?.first?.isSecureTextEntry == false)
        #expect(plain.textFields?.first?.autocorrectionType == .default)

        let third = UIViewController()
        window.rootViewController = third
        let short = LMKAlert.presentTextInput(
            from: third,
            title: "Key",
            isSecure: true,
            additionalActions: [.init(title: "Remove", style: .destructive) {}]
        ) { _ in }
        #expect(short.textFields?.first?.isSecureTextEntry == true)
        #expect(short.actions.map(\.title) == ["Cancel", "Save", "Remove"])
    }

    @Test
    func `configureField still wins over the secure defaults`() {
        let (presenter, window) = makePresenter()
        defer { window.isHidden = true }
        let alert = LMKAlert.presentTextInput(LMKAlert.TextInput(
            title: "Code",
            isSecure: true,
            configureField: { $0.autocapitalizationType = .allCharacters }
        ), from: presenter) { _ in }
        #expect(alert.textFields?.first?.autocapitalizationType == .allCharacters)
    }

    @Test
    func `Typed action sheet maps styles, enabled state, and adds cancel`() {
        let (presenter, window) = makePresenter()
        defer { window.isHidden = true }
        let anchorView = UIView()
        presenter.view.addSubview(anchorView)
        let sheet = LMKAlert.presentActionSheet(
            from: presenter,
            title: "Photo",
            actions: [
                .init(title: "Edit", image: UIImage(systemName: "pencil")) {},
                .init(title: "Delete", style: .destructive) {},
                .init(title: "Off", isEnabled: false) {},
            ],
            anchor: .view(anchorView)
        )
        #expect(sheet.preferredStyle == .actionSheet)
        #expect(sheet.actions.map(\.title) == ["Edit", "Delete", "Off", "Cancel"])
        #expect(sheet.actions[1].style == .destructive)
        #expect(sheet.actions[2].isEnabled == false)
        #expect(sheet.actions.last?.style == .cancel)
        #expect(sheet.popoverPresentationController?.sourceView === anchorView)
    }

    @Test
    func `Text input and action sheet cancel actions carry an onCancel`() {
        let (presenter, window) = makePresenter()
        defer { window.isHidden = true }
        var cancels = 0
        let alert = LMKAlert.presentTextInput(LMKAlert.TextInput(title: "T"), from: presenter, onSave: { _ in }, onCancel: { cancels += 1 })
        #expect(alert.actions.first?.style == .cancel)

        let other = UIViewController()
        window.rootViewController = other
        let sheet = LMKAlert.presentActionSheet(from: other, actions: [.init(title: "A") {}], onCancel: { cancels += 1 })
        #expect(sheet.actions.last?.style == .cancel)
        #expect(cancels == 0)
    }

    // MARK: - Awaited confirmation

    @Test
    func `confirm resolves false when the host is already presenting or off screen`() async {
        let (presenter, window) = makePresenter()
        defer { window.isHidden = true }
        LMKAlert.present(from: presenter, title: "First")
        #expect(presenter.presentedViewController != nil)
        let busy = await LMKAlert.confirm(from: presenter, title: "Second?")
        #expect(!busy)
        #expect((presenter.presentedViewController as? UIAlertController)?.title == "First", "nothing else was presented")

        let detached = UIViewController()
        let offScreen = await LMKAlert.confirm(from: detached, title: "Nowhere?")
        #expect(!offScreen)
        #expect(detached.presentedViewController == nil)
    }
}

// MARK: - LMKOnceContinuation

@MainActor
struct LMKOnceContinuationTests {
    @Test
    func `Resolves once and falls back to the default when released`() async {
        let resolved = await withCheckedContinuation { continuation in
            let once = LMKOnceContinuation(continuation, fallback: false)
            once.resolve(true)
            once.resolve(false)
        }
        #expect(resolved)

        let released = await withCheckedContinuation { continuation in
            _ = LMKOnceContinuation(continuation, fallback: false)
        }
        #expect(!released)
    }
}
