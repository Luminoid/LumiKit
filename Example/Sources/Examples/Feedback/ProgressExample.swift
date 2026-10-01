//
//  ProgressExample.swift
//  LumiKitExample
//
//  Progress: Determinate and indeterminate progress.
//

import LumiKitUI
import UIKit

// MARK: - Progress

final class ProgressDetailViewController: DetailViewController {
    /// The simulated work; Cancel and leaving the page both stop it.
    private var demoTask: Task<Void, Never>?

    isolated deinit {
        demoTask?.cancel()
    }

    override func setupStackContent() {
        addSectionHeader("Determinate")
        stackView.addArrangedSubview(UILabel.lmk_make(.caption, text: "Shows a progress bar with percentage and current task label. Includes cancel button."))
        let determinateButton = LMKButton(title: "Show Determinate Progress", style: .filled(.primary), target: self, action: #selector(showDeterminate))
        stackView.addArrangedSubview(determinateButton)

        addDivider()
        addSectionHeader("Indeterminate")
        stackView.addArrangedSubview(UILabel.lmk_make(.caption, text: "Shows a spinner without a progress bar. Useful when total work is unknown."))
        let indeterminateButton = LMKButton(title: "Show Indeterminate Progress", style: .filled(.secondary), target: self, action: #selector(showIndeterminate))
        stackView.addArrangedSubview(indeterminateButton)
    }

    @objc private func showDeterminate() {
        let progressVC = LMKProgressViewController(title: "Importing Data")
        progressVC.onCancel = { [weak self, weak progressVC] in
            self?.demoTask?.cancel()
            progressVC?.dismiss()
        }
        progressVC.present(from: self)
        let tasks = ["Reading files...", "Validating data...", "Saving records...", "Finishing up..."]
        let totalSteps = tasks.count * 3
        demoTask?.cancel()
        demoTask = Task { [weak progressVC] in
            for step in 1 ... totalSteps {
                try? await Task.sleep(for: .milliseconds(600))
                guard !Task.isCancelled, let progressVC else { return }
                progressVC.updateProgress(Float(step) / Float(totalSteps), task: tasks[min(step / 3, tasks.count - 1)])
            }
            progressVC?.setState(.succeeded, message: "Imported 12 records")
            try? await Task.sleep(for: .milliseconds(900))
            progressVC?.dismiss()
        }
    }

    @objc private func showIndeterminate() {
        let progressVC = LMKProgressViewController(title: "Processing...", subtitle: "This may take a moment", mode: .indeterminate)
        progressVC.onCancel = { [weak self, weak progressVC] in
            self?.demoTask?.cancel()
            progressVC?.dismiss()
        }
        progressVC.present(from: self)
        demoTask?.cancel()
        demoTask = Task { [weak progressVC] in
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled else { return }
            progressVC?.subtitle = "Taking longer than usual"
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled else { return }
            progressVC?.setState(.succeeded)
            try? await Task.sleep(for: .milliseconds(800))
            progressVC?.dismiss()
        }
    }
}
