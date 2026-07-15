//
//  LMKAlertPresenter.swift
//  LumiKit
//
//  Centralized alert presentation helper with configurable strings.
//

import UIKit

/// Helper for presenting alerts consistently.
///
/// Configure strings at app launch:
/// ```swift
/// LMKAlertPresenter.strings = .init(ok: "OK", cancel: "Cancel")
/// ```
public enum LMKAlertPresenter {
    // MARK: - Configurable Strings

    /// Configurable button title strings.
    public nonisolated struct Strings: Sendable {
        public var ok: String
        public var cancel: String
        public var save: String

        public init(ok: String = "OK", cancel: String = "Cancel", save: String = "Save") {
            self.ok = ok
            self.cancel = cancel
            self.save = save
        }
    }

    /// Override these at app launch with localized values.
    public nonisolated(unsafe) static var strings = Strings()

    // MARK: - Presentation

    /// Present a confirmation alert with confirm and cancel buttons.
    public static func presentConfirmation(
        on viewController: UIViewController,
        title: String,
        message: String? = nil,
        confirmTitle: String? = nil,
        cancelTitle: String? = nil,
        confirmStyle: UIAlertAction.Style = .default,
        onConfirm: @escaping () -> Void,
        onCancel: (() -> Void)? = nil
    ) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: cancelTitle ?? strings.cancel, style: .cancel) { _ in onCancel?() })
        alert.addAction(UIAlertAction(title: confirmTitle ?? strings.ok, style: confirmStyle) { _ in onConfirm() })
        viewController.present(alert, animated: true)
    }

    /// Present a simple alert with a single dismiss button.
    public static func presentAlert(
        on viewController: UIViewController,
        title: String,
        message: String? = nil,
        buttonTitle: String? = nil,
        onDismiss: (() -> Void)? = nil
    ) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: buttonTitle ?? strings.ok, style: .default) { _ in onDismiss?() })
        viewController.present(alert, animated: true)
    }

    /// Present an alert with a single text field and save / cancel buttons.
    ///
    /// Covers the common name / title / identifier prompt: the save action hands back
    /// the field's text verbatim (empty string when untouched); trimming and empty
    /// checks stay with the caller.
    ///
    /// `configureField` covers anything the standard parameters don't (secure entry,
    /// content padding, delegates); it runs after the standard configuration is
    /// applied, so its changes win.
    public static func presentTextInput(
        on viewController: UIViewController,
        title: String,
        message: String? = nil,
        placeholder: String? = nil,
        initialText: String? = nil,
        autocapitalizationType: UITextAutocapitalizationType = .sentences,
        autocorrectionType: UITextAutocorrectionType = .default,
        keyboardType: UIKeyboardType = .default,
        configureField: ((UITextField) -> Void)? = nil,
        saveTitle: String? = nil,
        cancelTitle: String? = nil,
        onSave: @escaping (String) -> Void
    ) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addTextField { field in
            field.placeholder = placeholder
            field.text = initialText
            field.autocapitalizationType = autocapitalizationType
            field.autocorrectionType = autocorrectionType
            field.keyboardType = keyboardType
            configureField?(field)
        }
        alert.addAction(UIAlertAction(title: cancelTitle ?? strings.cancel, style: .cancel))
        alert.addAction(UIAlertAction(title: saveTitle ?? strings.save, style: .default) { [weak alert] _ in
            onSave(alert?.textFields?.first?.text ?? "")
        })
        viewController.present(alert, animated: true)
    }

    /// Present an action sheet with multiple actions.
    public static func presentActionSheet(
        on viewController: UIViewController,
        title: String? = nil,
        message: String? = nil,
        actions: [(title: String, style: UIAlertAction.Style, handler: () -> Void)],
        cancelTitle: String? = nil
    ) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
        for action in actions {
            alert.addAction(UIAlertAction(title: action.title, style: action.style) { _ in action.handler() })
        }
        alert.addAction(UIAlertAction(title: cancelTitle ?? strings.cancel, style: .cancel))
        viewController.lmk_configurePopoverForActionSheet(alert)
        viewController.present(alert, animated: true)
    }
}
