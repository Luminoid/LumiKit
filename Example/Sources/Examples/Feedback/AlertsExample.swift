//
//  AlertsExample.swift
//  LumiKitExample
//
//  Alerts & Errors: Confirmation, text input, countdown, LMKErrorHandler.
//

import LumiKitUI
import SnapKit
import UIKit

// MARK: - Alerts & Errors

final class AlertsDetailViewController: DetailViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        addSectionHeader("LMKAlert")
        stack.addArrangedSubview(UILabel.lmk_make(.caption, text: "Standardized alert and confirmation dialogs with configurable strings."))

        let confirmButton = LMKButton(title: "Show Confirmation", style: .filled(.primary), target: self, action: #selector(showConfirmation))
        stack.addArrangedSubview(confirmButton)

        let alertButton = LMKButton(title: "Show Alert", style: .filled(.secondary), target: self, action: #selector(showAlert))
        stack.addArrangedSubview(alertButton)

        let textInputButton = LMKButton(title: "Show Text Input", style: .outlined(.primary), target: self, action: #selector(showTextInput))
        stack.addArrangedSubview(textInputButton)

        let secureInputButton = LMKButton(title: "Show Secure Text Input", style: .outlined(.secondary), target: self, action: #selector(showSecureTextInput))
        stack.addArrangedSubview(secureInputButton)

        addDivider()
        addSectionHeader("Delete confirmation and typed action sheet")
        stack.addArrangedSubview(UILabel.lmk_make(
            .caption,
            text: "presentDeleteConfirmation formats the localized title with the item name; "
                + "presentActionSheet takes typed actions with images, styles, and an iPad popover anchor."
        ))
        let deleteButton = LMKButton(title: "Delete Monstera", style: .outlined(.destructive), target: self, action: #selector(showDeleteConfirmation))
        stack.addArrangedSubview(deleteButton)
        let typedSheetButton = LMKButton(title: "Show System Action Sheet", style: .outlined(.primary), target: self, action: #selector(showTypedActionSheet))
        stack.addArrangedSubview(typedSheetButton)

        addDivider()
        addSectionHeader("Countdown confirmation")
        stack.addArrangedSubview(UILabel.lmk_make(
            .caption,
            text: "Destructive confirmation with a timed countdown: the confirm button is disabled for a few seconds "
                + "to prevent accidental taps. The returned handle can dismiss it."
        ))

        let countdown3Button = LMKButton(title: "Delete All (3s countdown)", style: .filled(.destructive), target: self, action: #selector(showCountdown3))
        stack.addArrangedSubview(countdown3Button)

        let countdown5Button = LMKButton(title: "Reset Account (5s countdown)", style: .outlined(.destructive), target: self, action: #selector(showCountdown5))
        stack.addArrangedSubview(countdown5Button)

        addDivider()
        addSectionHeader("LMKErrorHandler")
        stack.addArrangedSubview(UILabel.lmk_make(
            .caption,
            text: "Severity-based error presentation through LMKErrorHandler.policy: info shows a toast, warning an alert, "
                + "error a toast (or an alert with retry), critical always an alert. Recovery suggestions append to the message."
        ))

        let infoButton = makeErrorButton(title: "Info (toast)", role: .info) { [weak self] in
            guard let self else { return }
            LMKErrorHandler.present(from: self, message: "Informational message.", severity: .info)
        }
        stack.addArrangedSubview(infoButton)

        let warningButton = makeErrorButton(title: "Warning (alert)", role: .warning) { [weak self] in
            guard let self else { return }
            LMKErrorHandler.present(from: self, message: "Something needs attention.", severity: .warning)
        }
        stack.addArrangedSubview(warningButton)

        let errorToastButton = makeErrorButton(title: "Error (toast, no retry)", role: .destructive) { [weak self] in
            guard let self else { return }
            LMKErrorHandler.present(from: self, message: "Transient error, no retry available.", severity: .error)
        }
        stack.addArrangedSubview(errorToastButton)

        let errorRetryButton = makeErrorButton(title: "Error (alert + retry)", role: .destructive) { [weak self] in
            guard let self else { return }
            LMKErrorHandler.present(
                from: self,
                message: "Recoverable error: tap retry to try again.",
                severity: .error,
                retryAction: { [weak self] in
                    guard let self else { return }
                    LMKToast.show(.success, "Retry triggered!", in: self)
                }
            )
        }
        stack.addArrangedSubview(errorRetryButton)

        let criticalButton = makeErrorButton(title: "Critical (alert + retry)", role: .destructive) { [weak self] in
            guard let self else { return }
            LMKErrorHandler.present(
                from: self,
                message: "Critical failure: always shows an alert.",
                severity: .critical,
                retryAction: { [weak self] in
                    guard let self else { return }
                    LMKToast.show(.success, "Retry triggered!", in: self)
                }
            )
        }
        stack.addArrangedSubview(criticalButton)
    }

    @objc private func showConfirmation() {
        LMKAlert.presentConfirmation(
            from: self,
            title: "Delete Item?",
            message: "This action cannot be undone.",
            confirmTitle: "Delete",
            confirmStyle: .destructive,
            onConfirm: { [weak self] in
                guard let self else { return }
                LMKToast.show(.success, "Confirmed!", in: self)
            }
        )
    }

    @objc private func showAlert() {
        LMKAlert.present(
            from: self,
            title: "Update Available",
            message: "A new version of the app is available. Please update to get the latest features."
        )
    }

    @objc private func showTextInput() {
        LMKAlert.presentTextInput(
            from: self,
            title: "Rename Collection",
            message: "Enter a new name for this collection.",
            placeholder: "Collection name",
            initialText: "Succulents",
            onSave: { [weak self] text in
                guard let self else { return }
                // The save action hands back the field's text verbatim;
                // trimming and empty checks stay with the caller.
                let name = text.trimmingCharacters(in: .whitespacesAndNewlines)
                if name.isEmpty {
                    LMKToast.show(.warning, "Name unchanged (empty input)", in: self)
                } else {
                    LMKToast.show(.success, "Renamed to \u{201C}\(name)\u{201D}", in: self)
                }
            }
        )
    }

    @objc private func showSecureTextInput() {
        LMKAlert.presentTextInput(LMKAlert.TextInput(
            title: "Enter API Key",
            message: "The key is stored securely in the Keychain. Save enables once the key has 8 characters.",
            placeholder: "API key",
            isSecure: true,
            validate: { $0.count >= 8 }
        ), from: self) { [weak self] text in
            guard let self else { return }
            LMKToast.show(.success, "Saved key (\(text.count) characters)", in: self)
        }
    }

    @objc private func showDeleteConfirmation() {
        LMKAlert.presentDeleteConfirmation(from: self, itemName: "Monstera") { [weak self] in
            guard let self else { return }
            LMKToast.show(.success, "Deleted", in: self)
        }
    }

    @objc private func showTypedActionSheet() {
        LMKAlert.presentActionSheet(
            from: self,
            title: "Photo",
            actions: [
                .init(title: "Edit", image: UIImage(systemName: "pencil")) { [weak self] in
                    guard let self else { return }
                    LMKToast.show(.info, "Edit", in: self)
                },
                .init(title: "Delete", style: .destructive) { [weak self] in
                    guard let self else { return }
                    LMKToast.show(.error, "Delete", in: self)
                },
            ]
        )
    }

    @objc private func showCountdown3() {
        LMKAlert.presentCountdownConfirmation(
            from: self,
            title: "Delete All Data?",
            message: "This will permanently remove all items. This action cannot be undone.",
            confirmTitle: "Delete All",
            countdownSeconds: 3,
            onConfirm: { [weak self] in
                guard let self else { return }
                LMKToast.show(.success, "All data deleted!", in: self)
            }
        )
    }

    @objc private func showCountdown5() {
        LMKAlert.presentCountdownConfirmation(
            from: self,
            title: "Reset Account?",
            message: "This will erase your account and all associated data.",
            confirmTitle: "Reset",
            countdownSeconds: 5,
            onConfirm: { [weak self] in
                guard let self else { return }
                LMKToast.show(.success, "Account reset!", in: self)
            },
            onCancel: { [weak self] in
                guard let self else { return }
                LMKToast.show(.info, "Cancelled", in: self)
            }
        )
    }

    private func makeErrorButton(title: String, role: LMKButton.Role, action: @escaping () -> Void) -> LMKButton {
        let button = LMKButton(title: title, style: .outlined(role), target: self, action: #selector(handleErrorButton))
        button.onTap = action
        return button
    }

    @objc private func handleErrorButton() {
        // Handled by onTap
    }
}
