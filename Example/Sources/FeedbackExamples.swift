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

        let types: [(String, UIColor, Selector)] = [
            ("Show Success Toast", LMKColor.success, #selector(showSuccess)),
            ("Show Error Toast", LMKColor.error, #selector(showError)),
            ("Show Warning Toast", LMKColor.warning, #selector(showWarning)),
            ("Show Info Toast", LMKColor.info, #selector(showInfo)),
        ]

        addSectionHeader("Tap to show")
        for (title, color, action) in types {
            let button = LMKButton()
            button.setTitle(title, for: .normal)
            button.setTitleColor(color, for: .normal)
            button.titleLabel?.font = LMKTypography.bodyMedium
            button.addTarget(self, action: action, for: .touchUpInside)
            button.snp.makeConstraints { $0.height.equalTo(LMKLayout.minimumTouchTarget) }
            stack.addArrangedSubview(button)
        }
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
        let button = LMKButton()
        button.setTitle(title, for: .normal)
        button.setTitleColor(color, for: .normal)
        button.titleLabel?.font = LMKTypography.bodyMedium
        button.snp.makeConstraints { $0.height.equalTo(LMKLayout.minimumTouchTarget) }
        button.tapHandler = action
        return button
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

        let notifications: [(String, UIColor, @MainActor @Sendable () -> Void)] = [
            ("Success", LMKColor.success, { LMKHapticFeedbackHelper.success() }),
            ("Warning", LMKColor.warning, { LMKHapticFeedbackHelper.warning() }),
            ("Error", LMKColor.error, { LMKHapticFeedbackHelper.error() }),
        ]
        let notifRow = UIStackView(lmk_axis: .horizontal, spacing: LMKSpacing.small)
        notifRow.distribution = .fillEqually
        for (title, color, action) in notifications {
            let button = LMKButton()
            button.setTitle(title, for: .normal)
            button.setTitleColor(color, for: .normal)
            button.titleLabel?.font = LMKTypography.bodyMedium
            button.snp.makeConstraints { $0.height.equalTo(LMKLayout.minimumTouchTarget) }
            let tapAction = action
            button.tapHandler = tapAction
            notifRow.addArrangedSubview(button)
        }
        stack.addArrangedSubview(notifRow)

        addDivider()
        addSectionHeader("Selection Feedback")
        stack.addArrangedSubview(LMKLabelFactory.caption(text: "Subtle tick for picker changes and control selection."))
        let selectionButton = LMKButton()
        selectionButton.setTitle("Trigger Selection", for: .normal)
        selectionButton.setTitleColor(LMKColor.primary, for: .normal)
        selectionButton.titleLabel?.font = LMKTypography.bodyMedium
        selectionButton.snp.makeConstraints { $0.height.equalTo(LMKLayout.minimumTouchTarget) }
        selectionButton.tapHandler = { LMKHapticFeedbackHelper.selection() }
        stack.addArrangedSubview(selectionButton)

        addDivider()
        addSectionHeader("Impact Feedback")
        stack.addArrangedSubview(LMKLabelFactory.caption(text: "Physical impact feel — light, medium, or heavy intensity."))

        let impacts: [(String, UIImpactFeedbackGenerator.FeedbackStyle, @MainActor @Sendable () -> Void)] = [
            ("Light", .light, { LMKHapticFeedbackHelper.light() }),
            ("Medium", .medium, { LMKHapticFeedbackHelper.medium() }),
            ("Heavy", .heavy, { LMKHapticFeedbackHelper.heavy() }),
        ]
        let impactRow = UIStackView(lmk_axis: .horizontal, spacing: LMKSpacing.small)
        impactRow.distribution = .fillEqually
        for (title, style, action) in impacts {
            let button = LMKButton()
            button.setTitle(title, for: .normal)
            button.setTitleColor(LMKColor.secondary, for: .normal)
            button.titleLabel?.font = LMKTypography.bodyMedium
            button.snp.makeConstraints { $0.height.equalTo(LMKLayout.minimumTouchTarget) }
            let capturedStyle = style
            let tapAction = action
            button.tapHandler = {
                LMKHapticFeedbackHelper.prepareImpact(capturedStyle)
                tapAction()
            }
            impactRow.addArrangedSubview(button)
        }
        stack.addArrangedSubview(impactRow)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Prepare the notification generator when this screen appears
        // so the first tap has minimal latency (~1–2s window)
        LMKHapticFeedbackHelper.prepareNotification()
        LMKHapticFeedbackHelper.prepareSelection()
    }
}
