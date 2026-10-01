//
//  ToastExample.swift
//  LumiKitExample
//
//  Toast: Status toasts, actions, undo, persistent, queueing.
//

import LumiKitUI
import UIKit

// MARK: - Toast

final class ToastDetailViewController: DetailViewController {
    private let statusLabel = LMKStatusLabel()
    /// The persistent toast, kept so a button can dismiss it through its handle.
    private var persistentToast: LMKToast.Handle?

    override func setupStackContent() {
        addSectionHeader("Tap to show")

        let successButton = LMKButton(title: "Show Success Toast", style: .outlined(.success), target: self, action: #selector(showSuccess))
        stackView.addArrangedSubview(successButton)

        let errorButton = LMKButton(title: "Show Error Toast", style: .outlined(.destructive), target: self, action: #selector(showError))
        stackView.addArrangedSubview(errorButton)

        let warningButton = LMKButton(title: "Show Warning Toast", style: .outlined(.warning), target: self, action: #selector(showWarning))
        stackView.addArrangedSubview(warningButton)

        let infoButton = LMKButton(title: "Show Info Toast", style: .outlined(.info), target: self, action: #selector(showInfo))
        stackView.addArrangedSubview(infoButton)

        addDivider()
        addSectionHeader("Actions, undo, persistence, queueing")
        stackView.addArrangedSubview(UILabel.lmk_make(
            .caption,
            text: "One LMKToast.Configuration covers a trailing action, an undo countdown that commits on expiry, a persistent toast with a dismiss button, bottom placement, and the queue policy."
        ))

        let actionButton = LMKButton(title: "Toast with action", style: .outlined()) { [weak self] in
            guard let self else { return }
            LMKToast.show(LMKToast.Configuration(
                status: .error, message: "Upload failed", title: "Photos",
                action: .init(title: "Retry") { LMKToast.show(.success, "Retrying", in: self) },
                presentation: .onViewController(self)
            ))
        }
        stackView.addArrangedSubview(actionButton)

        let undoButton = LMKButton(title: "Undo toast (5s commit)", style: .outlined(.destructive)) { [weak self] in
            guard let self else { return }
            statusLabel.show("Pending delete", status: .warning)
            LMKToast.showUndo(message: "Item deleted", in: self, onUndo: { [weak self] in
                self?.statusLabel.show("Restored", status: .success)
            }, onCommit: { [weak self] in
                self?.statusLabel.show("Deleted permanently", status: .neutral)
            })
        }
        stackView.addArrangedSubview(undoButton)

        let persistentButton = LMKButton(title: "Persistent toast at the bottom", style: .outlined(.secondary)) { [weak self] in
            guard let self else { return }
            persistentToast = LMKToast.show(LMKToast.Configuration(
                status: .info, message: "Syncing in the background", duration: .persistent, position: .bottom,
                presentation: .onViewController(self)
            ))
        }
        stackView.addArrangedSubview(persistentButton)
        // The returned handle updates or dismisses its toast later; both are no-ops once it is gone.
        let handleRow = UIStackView(lmk_axis: .horizontal, spacing: LMKSpacing.small)
        handleRow.addArrangedSubview(LMKButton(title: "Update message", style: .ghost(.secondary).size(.small)) { [weak self] in
            self?.persistentToast?.setMessage("Syncing 3 of 12 items")
        })
        handleRow.addArrangedSubview(LMKButton(title: "Dismiss", style: .ghost(.secondary).size(.small)) { [weak self] in
            self?.persistentToast?.dismiss()
            self?.persistentToast = nil
        })
        handleRow.addArrangedSubview(UIView())
        stackView.addArrangedSubview(handleRow)

        let queueButton = LMKButton(title: "Enqueue three toasts", style: .outlined(.secondary)) { [weak self] in
            guard let self else { return }
            for index in 1 ... 3 {
                LMKToast.show(LMKToast.Configuration(
                    status: .info, message: "Toast \(index) of 3", duration: .seconds(1.2),
                    presentation: .onViewController(self), queuePolicy: .enqueue
                ))
            }
        }
        stackView.addArrangedSubview(queueButton)

        addDivider()
        addSectionHeader("Above a sheet")
        stackView.addArrangedSubview(UILabel.lmk_make(
            .caption,
            text: "LMKToast.show(_:_:in: nil) hosts the toast on the key window, so it shows above a sheet presented over the page."
        ))
        stackView.addArrangedSubview(LMKButton(title: "Toast over a sheet", style: .outlined(.primary)) { [weak self] in
            self?.presentToastSheet()
        })

        addDivider()
        addSectionHeader("LMKStatusLabel")
        stackView.addArrangedSubview(UILabel.lmk_make(.caption, text: "An inline readout for a form: show(_:status:) colors the line by status, clear() hides it."))
        stackView.addArrangedSubview(statusLabel)
        let statusRow = UIStackView(lmk_axis: .horizontal, spacing: LMKSpacing.small)
        statusRow.addArrangedSubview(LMKButton(title: "Saved", style: .tinted(.success).size(.small)) { [weak self] in self?.statusLabel.show("Saved", status: .success) })
        statusRow.addArrangedSubview(LMKButton(title: "Warning", style: .tinted(.warning).size(.small)) { [weak self] in self?.statusLabel.show("Check the date", status: .warning) })
        statusRow.addArrangedSubview(LMKButton(title: "Clear", style: .ghost(.neutral).size(.small)) { [weak self] in self?.statusLabel.clear() })
        statusRow.addArrangedSubview(UIView())
        stackView.addArrangedSubview(statusRow)
    }

    private func presentToastSheet() {
        let sheet = ToastSheetViewController()
        sheet.modalPresentationStyle = .pageSheet
        sheet.sheetPresentationController?.detents = [.medium()]
        present(sheet, animated: true)
    }

    @objc private func showSuccess() {
        LMKToast.show(.success, "Item saved successfully!", in: self)
    }

    @objc private func showError() {
        LMKToast.show(.error, "Failed to save item", in: self)
    }

    @objc private func showWarning() {
        LMKToast.show(.warning, "Low storage warning", in: self)
    }

    @objc private func showInfo() {
        LMKToast.show(.info, "Tap an item for details", in: self)
    }
}

/// A sheet whose button shows a toast on the key window, above the sheet.
private final class ToastSheetViewController: DetailViewController {
    override func setupStackContent() {
        addSectionHeader("A sheet")
        stackView.addArrangedSubview(LMKButton(title: "Show Toast Here", style: .filled(.primary)) {
            LMKToast.show(.success, "Above the sheet", in: nil)
        })
        stackView.addArrangedSubview(LMKButton(title: "Close", style: .ghost(.neutral)) { [weak self] in
            self?.dismiss(animated: true)
        })
    }
}
