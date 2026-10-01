//
//  AlertsExample.swift
//  LumiKitExample
//
//  Alerts & Errors: Confirmation, text input, countdown, LMKErrorHandler.
//

import LumiKitUI
import UIKit

// MARK: - Alerts & Errors

final class AlertsDetailViewController: DetailViewController {
    /// Closes the five-second countdown through its handle if nobody answers it.
    private var countdownTimeout: Task<Void, Never>?

    isolated deinit {
        countdownTimeout?.cancel()
    }

    override func setupStackContent() {
        addSectionHeader("LMKAlert")
        stackView.addArrangedSubview(UILabel.lmk_make(.caption, text: "Standardized alert and confirmation dialogs with configurable strings."))

        let confirmButton = LMKButton(title: "Show Confirmation", style: .filled(.primary), target: self, action: #selector(showConfirmation))
        stackView.addArrangedSubview(confirmButton)

        let alertButton = LMKButton(title: "Show Alert", style: .filled(.secondary), target: self, action: #selector(showAlert))
        stackView.addArrangedSubview(alertButton)

        let textInputButton = LMKButton(title: "Show Text Input", style: .outlined(.primary), target: self, action: #selector(showTextInput))
        stackView.addArrangedSubview(textInputButton)

        let secureInputButton = LMKButton(title: "Show Secure Text Input", style: .outlined(.secondary), target: self, action: #selector(showSecureTextInput))
        stackView.addArrangedSubview(secureInputButton)

        addDivider()
        addSectionHeader("Delete confirmation and typed action sheet")
        stackView.addArrangedSubview(UILabel.lmk_make(
            .caption,
            text: "presentDeleteConfirmation formats the localized title with the item name; "
                + "presentActionSheet takes typed actions with images, styles, and an iPad popover anchor."
        ))
        let deleteButton = LMKButton(title: "Delete Monstera", style: .outlined(.destructive), target: self, action: #selector(showDeleteConfirmation))
        stackView.addArrangedSubview(deleteButton)
        let typedSheetButton = LMKButton(title: "Show System Action Sheet", style: .outlined(.primary), target: self, action: #selector(showTypedActionSheet(_:)))
        stackView.addArrangedSubview(typedSheetButton)

        addDivider()
        addSectionHeader("Countdown confirmation")
        stackView.addArrangedSubview(UILabel.lmk_make(
            .caption,
            text: "Destructive confirmation with a timed countdown: the confirm button is disabled for a few seconds "
                + "to prevent accidental taps. The returned handle can dismiss it: the five-second one closes itself after 15 seconds."
        ))

        let countdown3Button = LMKButton(title: "Delete All (3s countdown)", style: .filled(.destructive), target: self, action: #selector(showCountdown3))
        stackView.addArrangedSubview(countdown3Button)

        let countdown5Button = LMKButton(title: "Reset Account (5s countdown)", style: .outlined(.destructive), target: self, action: #selector(showCountdown5))
        stackView.addArrangedSubview(countdown5Button)

        addDivider()
        addSectionHeader("LMKErrorHandler")
        stackView.addArrangedSubview(UILabel.lmk_make(
            .caption,
            text: "Severity-based error presentation through LMKErrorHandler.policy: info shows a toast, warning an alert, "
                + "error a toast (or an alert with retry), critical always an alert. Recovery suggestions append to the message."
        ))

        let infoButton = makeErrorButton(title: "Info (toast)", role: .info) { [weak self] in
            guard let self else { return }
            LMKErrorHandler.present(from: self, message: "Informational message.", severity: .info)
        }
        stackView.addArrangedSubview(infoButton)

        let warningButton = makeErrorButton(title: "Warning (alert)", role: .warning) { [weak self] in
            guard let self else { return }
            LMKErrorHandler.present(from: self, message: "Something needs attention.", severity: .warning)
        }
        stackView.addArrangedSubview(warningButton)

        let errorToastButton = makeErrorButton(title: "Error (toast, no retry)", role: .destructive) { [weak self] in
            guard let self else { return }
            LMKErrorHandler.present(from: self, message: "Transient error, no retry available.", severity: .error)
        }
        stackView.addArrangedSubview(errorToastButton)

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
        stackView.addArrangedSubview(errorRetryButton)

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
        stackView.addArrangedSubview(criticalButton)
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

    /// Takes the tapped button so the sheet anchors to it as a popover on iPad and Mac.
    @objc private func showTypedActionSheet(_ sender: UIView) {
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
            ],
            anchor: .view(sender)
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
        let handle = LMKAlert.presentCountdownConfirmation(
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
        // The handle can close the dialog as a cancel would (onCancel runs once); a second call does nothing.
        countdownTimeout?.cancel()
        countdownTimeout = Task {
            try? await Task.sleep(for: .seconds(15))
            guard !Task.isCancelled else { return }
            handle.dismiss()
        }
    }

    private func makeErrorButton(title: String, role: LMKButton.Role, action: @escaping () -> Void) -> LMKButton {
        LMKButton(title: title, style: .outlined(role), onTap: action)
    }
}
