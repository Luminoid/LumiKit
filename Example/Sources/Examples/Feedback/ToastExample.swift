//
//  ToastExample.swift
//  LumiKitExample
//
//  Toast: Status toasts, actions, undo, persistent, queueing.
//

import LumiKitUI
import SnapKit
import UIKit

// MARK: - Toast

final class ToastDetailViewController: DetailViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        addSectionHeader("Tap to show")

        let successButton = LMKButton(title: "Show Success Toast", style: .outlined(.success), target: self, action: #selector(showSuccess))
        stack.addArrangedSubview(successButton)

        let errorButton = LMKButton(title: "Show Error Toast", style: .outlined(.destructive), target: self, action: #selector(showError))
        stack.addArrangedSubview(errorButton)

        let warningButton = LMKButton(title: "Show Warning Toast", style: .outlined(.warning), target: self, action: #selector(showWarning))
        stack.addArrangedSubview(warningButton)

        let infoButton = LMKButton(title: "Show Info Toast", style: .outlined(.info), target: self, action: #selector(showInfo))
        stack.addArrangedSubview(infoButton)

        addDivider()
        addSectionHeader("Actions, undo, persistence, queueing")
        stack.addArrangedSubview(UILabel.lmk_make(
            .caption,
            text: "One LMKToastConfiguration covers a trailing action, an undo countdown that commits on expiry, a persistent toast with a dismiss button, bottom placement, and the queue policy."
        ))

        let actionButton = LMKButton(title: "Toast with action", style: .outlined()) { [weak self] in
            guard let self else { return }
            LMKToast.show(LMKToastConfiguration(
                status: .error, message: "Upload failed", title: "Photos",
                action: .init(title: "Retry") { LMKToast.show(.success, "Retrying", in: self) },
                presentation: .onViewController(self)
            ))
        }
        stack.addArrangedSubview(actionButton)

        let undoButton = LMKButton(title: "Undo toast (5s commit)", style: .outlined(.destructive)) { [weak self] in
            guard let self else { return }
            statusLabel.show("Pending delete", status: .warning)
            LMKToast.showUndo(message: "Item deleted", in: self, onUndo: { [weak self] in
                self?.statusLabel.show("Restored", status: .success)
            }, onCommit: { [weak self] in
                self?.statusLabel.show("Deleted permanently", status: .neutral)
            })
        }
        stack.addArrangedSubview(undoButton)

        let persistentButton = LMKButton(title: "Persistent toast at the bottom", style: .outlined(.secondary)) { [weak self] in
            guard let self else { return }
            LMKToast.show(LMKToastConfiguration(
                status: .info, message: "Syncing in the background", duration: .persistent, position: .bottom,
                presentation: .onViewController(self)
            ))
        }
        stack.addArrangedSubview(persistentButton)

        let queueButton = LMKButton(title: "Enqueue three toasts", style: .outlined(.secondary)) { [weak self] in
            guard let self else { return }
            for index in 1 ... 3 {
                LMKToast.show(LMKToastConfiguration(
                    status: .info, message: "Toast \(index) of 3", duration: .seconds(1.2),
                    presentation: .onViewController(self), queuePolicy: .enqueue
                ))
            }
        }
        stack.addArrangedSubview(queueButton)

        addDivider()
        addSectionHeader("LMKStatusLabel")
        stack.addArrangedSubview(UILabel.lmk_make(.caption, text: "An inline readout for a form: show(_:status:) colors the line by status, clear() hides it."))
        stack.addArrangedSubview(statusLabel)
        let statusRow = UIStackView(lmk_axis: .horizontal, spacing: LMKSpacing.small)
        statusRow.addArrangedSubview(LMKButton(title: "Saved", style: .tinted(.success).size(.small)) { [weak self] in self?.statusLabel.show("Saved", status: .success) })
        statusRow.addArrangedSubview(LMKButton(title: "Warning", style: .tinted(.warning).size(.small)) { [weak self] in self?.statusLabel.show("Check the date", status: .warning) })
        statusRow.addArrangedSubview(LMKButton(title: "Clear", style: .ghost(.neutral).size(.small)) { [weak self] in self?.statusLabel.clear() })
        statusRow.addArrangedSubview(UIView())
        stack.addArrangedSubview(statusRow)
    }

    private let statusLabel = LMKStatusLabel()

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
