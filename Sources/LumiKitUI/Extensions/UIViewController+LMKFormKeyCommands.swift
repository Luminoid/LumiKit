//
//  UIViewController+LMKFormKeyCommands.swift
//  LumiKit
//
//  Standard hardware-keyboard shortcuts for form and confirmation screens
//  (iPad and Mac Catalyst): Command-Return saves, Escape cancels.
//

import UIKit

/// Localized titles for the form key commands (they double as the discoverability HUD labels).
public enum LMKFormKeyCommands {
    public nonisolated struct Strings: Sendable, Equatable {
        public var save: String
        public var cancel: String

        public init(
            save: String = LMKLocalized("formKeyCommands.save"),
            cancel: String = LMKLocalized("formKeyCommands.cancel")
        ) {
            self.save = save
            self.cancel = cancel
        }
    }

    /// Process-wide defaults; set at app launch to override.
    public nonisolated(unsafe) static var strings = Strings()
}

public extension UIViewController {
    /// Key commands for a screen with a Save (or Done) and a Cancel action:
    /// Command-Return runs `save`, Escape runs `cancel`.
    ///
    /// Return them from a `keyCommands` override. Pass `nil` for either selector to omit that
    /// command; `cancel` defaults to `lmk_cancelFromKeyCommand()`, which dismisses the view
    /// controller (or pops it when it sits in a navigation stack).
    /// ```swift
    /// override var keyCommands: [UIKeyCommand]? {
    ///     lmk_formKeyCommands(save: #selector(saveTapped), cancel: #selector(cancelTapped))
    /// }
    /// ```
    func lmk_formKeyCommands(
        save: Selector?,
        cancel: Selector? = #selector(UIViewController.lmk_cancelFromKeyCommand),
        strings: LMKFormKeyCommands.Strings = LMKFormKeyCommands.strings
    ) -> [UIKeyCommand] {
        var commands: [UIKeyCommand] = []
        if let save {
            commands.append(UIKeyCommand(title: strings.save, action: save, input: "\r", modifierFlags: .command))
        }
        if let cancel {
            commands.append(UIKeyCommand(title: strings.cancel, action: cancel, input: UIKeyCommand.inputEscape, modifierFlags: []))
        }
        return commands
    }

    /// The default Escape action: dismisses a presented view controller, or pops one that was
    /// pushed. Override in a subclass to confirm unsaved changes first.
    @objc func lmk_cancelFromKeyCommand() {
        if let navigationController, navigationController.viewControllers.count > 1, navigationController.topViewController === self {
            navigationController.popViewController(animated: true)
        } else if presentingViewController != nil {
            dismiss(animated: true)
        }
    }
}
