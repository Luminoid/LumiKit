//
//  FeedbackExamples.swift
//  LumiKitExample
//
//  Toast, alerts & errors, progress, and haptics examples.
//

import LumiKitUI
import SnapKit
import UIKit

// MARK: - Toast

final class ToastDetailViewController: DetailViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        addSectionHeader("Tap to show")

        let successButton = LMKButtonFactory.successOutlined(title: "Show Success Toast", target: self, action: #selector(showSuccess))
        stack.addArrangedSubview(successButton)

        let errorButton = LMKButtonFactory.destructiveOutlined(title: "Show Error Toast", target: self, action: #selector(showError))
        stack.addArrangedSubview(errorButton)

        let warningButton = LMKButtonFactory.warningOutlined(title: "Show Warning Toast", target: self, action: #selector(showWarning))
        stack.addArrangedSubview(warningButton)

        let infoButton = LMKButtonFactory.infoOutlined(title: "Show Info Toast", target: self, action: #selector(showInfo))
        stack.addArrangedSubview(infoButton)
    }

    @objc private func showSuccess() { LMKToast.showSuccess(message: "Item saved successfully!", on: self) }
    @objc private func showError() { LMKToast.showError(message: "Failed to save item", on: self) }
    @objc private func showWarning() { LMKToast.showWarning(message: "Low storage warning", on: self) }
    @objc private func showInfo() { LMKToast.showInfo(message: "Tap an item for details", on: self) }
}

// MARK: - Alerts & Errors

final class AlertsDetailViewController: DetailViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        addSectionHeader("LMKAlertPresenter")
        stack.addArrangedSubview(LMKLabelFactory.caption(text: "Standardized alert and confirmation dialogs with configurable strings."))

        let confirmButton = LMKButtonFactory.primary(title: "Show Confirmation", target: self, action: #selector(showConfirmation))
        stack.addArrangedSubview(confirmButton)

        let alertButton = LMKButtonFactory.secondary(title: "Show Alert", target: self, action: #selector(showAlert))
        stack.addArrangedSubview(alertButton)

        addDivider()
        addSectionHeader("LMKErrorHandler")
        stack.addArrangedSubview(LMKLabelFactory.caption(text: "Severity-based error presentation — info shows a toast, warning shows an alert, error shows a toast (or alert with retry), critical always shows an alert."))

        let infoButton = makeErrorButton(title: "Info (toast)", color: LMKColor.info) { [weak self] in
            guard let self else { return }
            LMKErrorHandler.present(on: self, message: "Informational message.", severity: .info)
        }
        stack.addArrangedSubview(infoButton)

        let warningButton = makeErrorButton(title: "Warning (alert)", color: LMKColor.warning) { [weak self] in
            guard let self else { return }
            LMKErrorHandler.present(on: self, message: "Something needs attention.", severity: .warning)
        }
        stack.addArrangedSubview(warningButton)

        let errorToastButton = makeErrorButton(title: "Error (toast, no retry)", color: LMKColor.error) { [weak self] in
            guard let self else { return }
            LMKErrorHandler.present(on: self, message: "Transient error — no retry available.", severity: .error)
        }
        stack.addArrangedSubview(errorToastButton)

        let errorRetryButton = makeErrorButton(title: "Error (alert + retry)", color: LMKColor.error) { [weak self] in
            guard let self else { return }
            LMKErrorHandler.present(
                on: self,
                message: "Recoverable error — tap retry to try again.",
                severity: .error,
                retryAction: { [weak self] in
                    guard let self else { return }
                    LMKToast.showSuccess(message: "Retry triggered!", on: self)
                }
            )
        }
        stack.addArrangedSubview(errorRetryButton)

        let criticalButton = makeErrorButton(title: "Critical (alert + retry)", color: LMKColor.error) { [weak self] in
            guard let self else { return }
            LMKErrorHandler.present(
                on: self,
                message: "Critical failure — always shows an alert.",
                severity: .critical,
                retryAction: { [weak self] in
                    guard let self else { return }
                    LMKToast.showSuccess(message: "Retry triggered!", on: self)
                }
            )
        }
        stack.addArrangedSubview(criticalButton)
    }

    @objc private func showConfirmation() {
        LMKAlertPresenter.presentConfirmation(
            on: self,
            title: "Delete Item?",
            message: "This action cannot be undone.",
            confirmTitle: "Delete",
            confirmStyle: .destructive,
            onConfirm: { [weak self] in
                guard let self else { return }
                LMKToast.showSuccess(message: "Confirmed!", on: self)
            }
        )
    }

    @objc private func showAlert() {
        LMKAlertPresenter.presentAlert(
            on: self,
            title: "Update Available",
            message: "A new version of the app is available. Please update to get the latest features."
        )
    }

    private func makeErrorButton(title: String, color: UIColor, action: @escaping () -> Void) -> LMKButton {
        let factoryMethod: (String, Any?, Selector) -> LMKButton
        switch color {
        case LMKColor.info: factoryMethod = LMKButtonFactory.infoOutlined
        case LMKColor.warning: factoryMethod = LMKButtonFactory.warningOutlined
        case LMKColor.error: factoryMethod = LMKButtonFactory.destructiveOutlined
        default: factoryMethod = LMKButtonFactory.primaryOutlined
        }

        let button = factoryMethod(title, self, #selector(handleErrorButton))
        button.tapHandler = action
        return button
    }

    @objc private func handleErrorButton() {
        // Handled by tapHandler
    }
}

// MARK: - Progress

final class ProgressDetailViewController: DetailViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        addSectionHeader("Determinate")
        stack.addArrangedSubview(LMKLabelFactory.caption(text: "Shows a progress bar with percentage and current task label. Includes cancel button."))
        let determinateButton = LMKButtonFactory.primary(title: "Show Determinate Progress", target: self, action: #selector(showDeterminate))
        stack.addArrangedSubview(determinateButton)

        addDivider()
        addSectionHeader("Indeterminate")
        stack.addArrangedSubview(LMKLabelFactory.caption(text: "Shows a spinner without a progress bar. Useful when total work is unknown."))
        let indeterminateButton = LMKButtonFactory.secondary(title: "Show Indeterminate Progress", target: self, action: #selector(showIndeterminate))
        stack.addArrangedSubview(indeterminateButton)
    }

    @objc private func showDeterminate() {
        let progressVC = LMKProgressViewController(title: "Importing Data")
        progressVC.modalPresentationStyle = .overFullScreen
        progressVC.modalTransitionStyle = .crossDissolve
        progressVC.onCancel = { [weak progressVC] in
            progressVC?.dismiss(animated: true)
        }
        present(progressVC, animated: true) {
            self.simulateProgress(on: progressVC)
        }
    }

    @objc private func showIndeterminate() {
        let progressVC = LMKProgressViewController(title: "Processing...", style: .indeterminate)
        progressVC.modalPresentationStyle = .overFullScreen
        progressVC.modalTransitionStyle = .crossDissolve
        progressVC.onCancel = { [weak progressVC] in
            progressVC?.dismiss(animated: true)
        }
        present(progressVC, animated: true) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak progressVC] in
                progressVC?.dismiss(animated: true)
            }
        }
    }

    private func simulateProgress(on progressVC: LMKProgressViewController) {
        let tasks = ["Reading files...", "Validating data...", "Saving records...", "Finishing up..."]
        let totalSteps = tasks.count * 3

        Task { [weak progressVC] in
            for step in 1...totalSteps {
                try? await Task.sleep(for: .milliseconds(600))
                guard let progressVC else { return }
                let progress = Float(step) / Float(totalSteps)
                let taskIndex = min(step / 3, tasks.count - 1)
                progressVC.updateProgress(progress, task: tasks[taskIndex])
            }
            try? await Task.sleep(for: .milliseconds(500))
            progressVC?.dismiss(animated: true)
        }
    }
}

// MARK: - Haptics

final class HapticsDetailViewController: DetailViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        addSectionHeader("Notification Feedback")
        stack.addArrangedSubview(LMKLabelFactory.caption(text: "Triggered for task outcomes — success, warning, or error. The Taptic Engine is prepared when this screen appears for lower latency."))

        let notifRow = UIStackView(lmk_axis: .horizontal, spacing: LMKSpacing.small)
        notifRow.distribution = .fillEqually

        let successNotif = LMKButtonFactory.successOutlined(title: "Success", target: self, action: #selector(hapticSuccess))
        notifRow.addArrangedSubview(successNotif)

        let warningNotif = LMKButtonFactory.warningOutlined(title: "Warning", target: self, action: #selector(hapticWarning))
        notifRow.addArrangedSubview(warningNotif)

        let errorNotif = LMKButtonFactory.destructiveOutlined(title: "Error", target: self, action: #selector(hapticError))
        notifRow.addArrangedSubview(errorNotif)

        stack.addArrangedSubview(notifRow)

        addDivider()
        addSectionHeader("Selection Feedback")
        stack.addArrangedSubview(LMKLabelFactory.caption(text: "Subtle tick for picker changes and control selection."))
        let selectionButton = LMKButtonFactory.primaryOutlined(title: "Trigger Selection", target: self, action: #selector(hapticSelection))
        stack.addArrangedSubview(selectionButton)

        addDivider()
        addSectionHeader("Impact Feedback")
        stack.addArrangedSubview(LMKLabelFactory.caption(text: "Physical impact feel — light, medium, or heavy intensity."))

        let impactRow = UIStackView(lmk_axis: .horizontal, spacing: LMKSpacing.small)
        impactRow.distribution = .fillEqually

        let lightImpact = LMKButtonFactory.secondaryOutlined(title: "Light", target: self, action: #selector(hapticLight))
        impactRow.addArrangedSubview(lightImpact)

        let mediumImpact = LMKButtonFactory.secondaryOutlined(title: "Medium", target: self, action: #selector(hapticMedium))
        impactRow.addArrangedSubview(mediumImpact)

        let heavyImpact = LMKButtonFactory.secondaryOutlined(title: "Heavy", target: self, action: #selector(hapticHeavy))
        impactRow.addArrangedSubview(heavyImpact)

        stack.addArrangedSubview(impactRow)
    }

    @objc private func hapticSuccess() { LMKHapticFeedbackHelper.success() }
    @objc private func hapticWarning() { LMKHapticFeedbackHelper.warning() }
    @objc private func hapticError() { LMKHapticFeedbackHelper.error() }
    @objc private func hapticSelection() { LMKHapticFeedbackHelper.selection() }

    @objc private func hapticLight() {
        LMKHapticFeedbackHelper.prepareImpact(.light)
        LMKHapticFeedbackHelper.light()
    }

    @objc private func hapticMedium() {
        LMKHapticFeedbackHelper.prepareImpact(.medium)
        LMKHapticFeedbackHelper.medium()
    }

    @objc private func hapticHeavy() {
        LMKHapticFeedbackHelper.prepareImpact(.heavy)
        LMKHapticFeedbackHelper.heavy()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Prepare the notification generator when this screen appears
        // so the first tap has minimal latency (~1–2s window)
        LMKHapticFeedbackHelper.prepareNotification()
        LMKHapticFeedbackHelper.prepareSelection()
    }
}
