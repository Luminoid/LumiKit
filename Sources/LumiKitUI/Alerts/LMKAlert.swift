//
//  LMKAlert.swift
//  LumiKit
//
//  Alert presentation: confirmations (closure and async), a single-button
//  alert, a validated text input, a typed action sheet with a popover anchor,
//  and the delete confirmation. The countdown confirmation lives in
//  +CountdownConfirmation.
//

import LumiKitCore
import UIKit

/// Presents `UIAlertController`s consistently, with localized defaults.
///
/// ```swift
/// LMKAlert.presentConfirmation(from: self, title: "Sign out?", onConfirm: { signOut() })
/// if await LMKAlert.confirm(from: self, title: "Discard changes?", isDestructive: true) { discard() }
/// LMKAlert.presentDeleteConfirmation(from: self, itemName: plant.name) { delete(plant) }
/// ```
public enum LMKAlert {
    // MARK: - Models

    /// One action of an action sheet.
    public struct Action {
        public nonisolated enum Style: Sendable, Hashable, CaseIterable {
            case `default`
            case destructive
        }

        public var title: String
        public var image: UIImage?
        public var style: Style
        public var isEnabled: Bool
        public var handler: () -> Void

        public init(title: String, image: UIImage? = nil, style: Style = .default, isEnabled: Bool = true, handler: @escaping () -> Void) {
            self.title = title
            self.image = image
            self.style = style
            self.isEnabled = isEnabled
            self.handler = handler
        }
    }

    /// Where an action sheet's popover points on iPad and Mac.
    public enum Anchor {
        /// A view (and a rect inside it; `nil` = its bounds).
        case view(UIView, rect: CGRect? = nil)
        case barButtonItem(UIBarButtonItem)
        /// Centered on the presenter with no arrow.
        case centered
    }

    /// A single text field prompt.
    public struct TextInput {
        public var title: String
        public var message: String?
        public var placeholder: String?
        public var initialText: String?
        public var autocapitalizationType: UITextAutocapitalizationType
        public var autocorrectionType: UITextAutocorrectionType
        public var keyboardType: UIKeyboardType
        public var isSecure: Bool
        /// `nil` = `strings.save`.
        public var saveTitle: String?
        /// `nil` = `strings.cancel`.
        public var cancelTitle: String?
        /// Enables Save only while it returns `true` for the current text.
        public var validate: ((String) -> Bool)?
        /// Runs after the standard configuration, so its changes win.
        public var configureField: ((UITextField) -> Void)?

        public init(
            title: String,
            message: String? = nil,
            placeholder: String? = nil,
            initialText: String? = nil,
            autocapitalizationType: UITextAutocapitalizationType = .sentences,
            autocorrectionType: UITextAutocorrectionType = .default,
            keyboardType: UIKeyboardType = .default,
            isSecure: Bool = false,
            saveTitle: String? = nil,
            cancelTitle: String? = nil,
            validate: ((String) -> Bool)? = nil,
            configureField: ((UITextField) -> Void)? = nil
        ) {
            self.title = title
            self.message = message
            self.placeholder = placeholder
            self.initialText = initialText
            self.autocapitalizationType = autocapitalizationType
            self.autocorrectionType = autocorrectionType
            self.keyboardType = keyboardType
            self.isSecure = isSecure
            self.saveTitle = saveTitle
            self.cancelTitle = cancelTitle
            self.validate = validate
            self.configureField = configureField
        }
    }

    // MARK: - Strings

    public nonisolated struct Strings: Sendable, Equatable {
        public var ok: String
        public var cancel: String
        public var save: String
        public var delete: String
        /// Format with the item name (`%@`).
        public var deleteConfirmationTitleFormat: String
        public var deleteConfirmationMessage: String
        /// The countdown confirmation's button while it counts: format with the confirm title
        /// (`%1$@`) and the seconds left (`%2$lld`).
        public var countdownConfirmTitleFormat: String

        public init(
            ok: String = LMKLocalized("alert.ok"),
            cancel: String = LMKLocalized("alert.cancel"),
            save: String = LMKLocalized("alert.save"),
            delete: String = LMKLocalized("alert.delete"),
            deleteConfirmationTitleFormat: String = LMKLocalized("alert.deleteConfirmation.title"),
            deleteConfirmationMessage: String = LMKLocalized("alert.deleteConfirmation.message"),
            countdownConfirmTitleFormat: String = LMKLocalized("alert.countdownConfirmation.confirmTitleFormat")
        ) {
            self.ok = ok
            self.cancel = cancel
            self.save = save
            self.delete = delete
            self.deleteConfirmationTitleFormat = deleteConfirmationTitleFormat
            self.deleteConfirmationMessage = deleteConfirmationMessage
            self.countdownConfirmTitleFormat = countdownConfirmTitleFormat
        }
    }

    /// Process-wide defaults; set at app launch to override.
    public nonisolated(unsafe) static var strings = Strings()

    // MARK: - Confirmation

    /// A confirm / cancel alert.
    @discardableResult
    public static func presentConfirmation(
        from host: UIViewController,
        title: String,
        message: String? = nil,
        confirmTitle: String? = nil,
        cancelTitle: String? = nil,
        confirmStyle: UIAlertAction.Style = .default,
        onConfirm: @escaping () -> Void,
        onCancel: (() -> Void)? = nil
    ) -> UIAlertController {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: cancelTitle ?? strings.cancel, style: .cancel) { _ in onCancel?() })
        alert.addAction(UIAlertAction(title: confirmTitle ?? strings.ok, style: confirmStyle) { _ in onConfirm() })
        host.present(alert, animated: true)
        return alert
    }

    /// A confirm / cancel alert awaited as a `Bool` (`true` when confirmed).
    ///
    /// Resolves `false` without presenting when `host` cannot present (it is off screen or
    /// already presenting), and when the alert goes away without an action.
    public static func confirm(
        from host: UIViewController,
        title: String,
        message: String? = nil,
        confirmTitle: String? = nil,
        cancelTitle: String? = nil,
        isDestructive: Bool = false
    ) async -> Bool {
        guard host.lmk_canPresentAlert else {
            LMKLogger.warning("LMKAlert: \(type(of: host)) cannot present “\(title)”: off screen or already presenting", category: .ui)
            return false
        }
        return await withCheckedContinuation { continuation in
            let resolution = LMKOnceContinuation(continuation, fallback: false)
            presentConfirmation(
                from: host,
                title: title,
                message: message,
                confirmTitle: confirmTitle,
                cancelTitle: cancelTitle,
                confirmStyle: isDestructive ? .destructive : .default,
                onConfirm: { resolution.resolve(true) },
                onCancel: { resolution.resolve(false) }
            )
        }
    }

    /// The delete confirmation: "Delete “name”?" with a destructive Delete.
    @discardableResult
    public static func presentDeleteConfirmation(
        from host: UIViewController,
        itemName: String,
        message: String? = nil,
        onConfirm: @escaping () -> Void,
        onCancel: (() -> Void)? = nil
    ) -> UIAlertController {
        presentConfirmation(
            from: host,
            title: String(format: strings.deleteConfirmationTitleFormat, itemName),
            message: message ?? strings.deleteConfirmationMessage,
            confirmTitle: strings.delete,
            confirmStyle: .destructive,
            onConfirm: onConfirm,
            onCancel: onCancel
        )
    }

    // MARK: - Simple alert

    /// A single-button alert.
    @discardableResult
    public static func present(
        from host: UIViewController,
        title: String,
        message: String? = nil,
        buttonTitle: String? = nil,
        onDismiss: (() -> Void)? = nil
    ) -> UIAlertController {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: buttonTitle ?? strings.ok, style: .default) { _ in onDismiss?() })
        host.present(alert, animated: true)
        return alert
    }

    // MARK: - Text input

    /// A prompt with one text field and save / cancel. The save action hands back the field's
    /// text verbatim (empty when untouched); `input.validate` keeps Save disabled until the
    /// text passes.
    @discardableResult
    public static func presentTextInput(
        _ input: TextInput,
        from host: UIViewController,
        onSave: @escaping (String) -> Void,
        onCancel: (() -> Void)? = nil
    ) -> UIAlertController {
        let alert = UIAlertController(title: input.title, message: input.message, preferredStyle: .alert)
        let save = UIAlertAction(title: input.saveTitle ?? strings.save, style: .default) { [weak alert] _ in
            onSave(alert?.textFields?.first?.text ?? "")
        }
        // `save` is weak in both closures: the alert owns the action once it is added below.
        alert.addTextField { [weak save] field in
            field.placeholder = input.placeholder
            field.text = input.initialText
            field.autocapitalizationType = input.autocapitalizationType
            field.autocorrectionType = input.autocorrectionType
            field.keyboardType = input.keyboardType
            field.isSecureTextEntry = input.isSecure
            input.configureField?(field)
            if let validate = input.validate {
                save?.isEnabled = validate(field.text ?? "")
                field.addAction(UIAction { [weak field, weak save] _ in
                    save?.isEnabled = validate(field?.text ?? "")
                }, for: .editingChanged)
            }
        }
        alert.addAction(UIAlertAction(title: input.cancelTitle ?? strings.cancel, style: .cancel) { _ in onCancel?() })
        alert.addAction(save)
        host.present(alert, animated: true)
        return alert
    }

    /// A prompt with one text field; see `presentTextInput(_:from:onSave:onCancel:)` for the full configuration.
    @discardableResult
    public static func presentTextInput(
        from host: UIViewController,
        title: String,
        message: String? = nil,
        placeholder: String? = nil,
        initialText: String? = nil,
        onSave: @escaping (String) -> Void,
        onCancel: (() -> Void)? = nil
    ) -> UIAlertController {
        presentTextInput(
            TextInput(title: title, message: message, placeholder: placeholder, initialText: initialText),
            from: host,
            onSave: onSave,
            onCancel: onCancel
        )
    }

    // MARK: - Action sheet

    /// A system action sheet with typed actions and a cancel button, anchored for popovers.
    /// An action's `image` shows when the running UIKit supports images on alert actions.
    @discardableResult
    public static func presentActionSheet(
        from host: UIViewController,
        title: String? = nil,
        message: String? = nil,
        actions: [Action],
        cancelTitle: String? = nil,
        anchor: Anchor = .centered,
        onCancel: (() -> Void)? = nil
    ) -> UIAlertController {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
        for action in actions {
            let alertAction = UIAlertAction(title: action.title, style: action.style == .destructive ? .destructive : .default) { _ in action.handler() }
            alertAction.isEnabled = action.isEnabled
            // `image` is not public API on `UIAlertAction`; the setter check keeps the key from ever raising.
            if let image = action.image, alertAction.responds(to: NSSelectorFromString("setImage:")) {
                alertAction.setValue(image, forKey: "image")
            }
            alert.addAction(alertAction)
        }
        alert.addAction(UIAlertAction(title: cancelTitle ?? strings.cancel, style: .cancel) { _ in onCancel?() })
        switch anchor {
        case let .view(view, rect):
            alert.popoverPresentationController?.sourceView = view
            alert.popoverPresentationController?.sourceRect = rect ?? view.bounds
        case let .barButtonItem(item):
            alert.popoverPresentationController?.barButtonItem = item
        case .centered:
            host.lmk_configurePopoverForActionSheet(alert)
        }
        host.present(alert, animated: true)
        return alert
    }
}

extension UIViewController {
    /// Whether UIKit would honor a `present` from this controller: it is on screen and not
    /// already presenting. The awaited alerts check it so a refused presentation still resolves.
    var lmk_canPresentAlert: Bool {
        viewIfLoaded?.window != nil && presentedViewController == nil
    }
}
