//
//  ProgressExample.swift
//  LumiKitExample
//
//  Progress: Determinate and indeterminate progress.
//

import LumiKitUI
import SnapKit
import UIKit

// MARK: - Progress

final class ProgressDetailViewController: DetailViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        addSectionHeader("Determinate")
        stack.addArrangedSubview(UILabel.lmk_make(.caption, text: "Shows a progress bar with percentage and current task label. Includes cancel button."))
        let determinateButton = LMKButton(title: "Show Determinate Progress", style: .filled(.primary), target: self, action: #selector(showDeterminate))
        stack.addArrangedSubview(determinateButton)

        addDivider()
        addSectionHeader("Indeterminate")
        stack.addArrangedSubview(UILabel.lmk_make(.caption, text: "Shows a spinner without a progress bar. Useful when total work is unknown."))
        let indeterminateButton = LMKButton(title: "Show Indeterminate Progress", style: .filled(.secondary), target: self, action: #selector(showIndeterminate))
        stack.addArrangedSubview(indeterminateButton)
    }

    @objc private func showDeterminate() {
        let progressVC = LMKProgressViewController(title: "Importing Data")
        progressVC.onCancel = { [weak progressVC] in
            progressVC?.dismiss()
        }
        progressVC.present(from: self)
        simulateProgress(on: progressVC)
    }

    @objc private func showIndeterminate() {
        let progressVC = LMKProgressViewController(title: "Processing...", subtitle: "This may take a moment", mode: .indeterminate)
        progressVC.onCancel = { [weak progressVC] in
            progressVC?.dismiss()
        }
        progressVC.present(from: self)
        Task { [weak progressVC] in
            try? await Task.sleep(for: .seconds(2))
            progressVC?.subtitle = "Taking longer than usual"
            try? await Task.sleep(for: .seconds(2))
            progressVC?.setState(.succeeded)
            try? await Task.sleep(for: .milliseconds(800))
            progressVC?.dismiss()
        }
    }

    private func simulateProgress(on progressVC: LMKProgressViewController) {
        let tasks = ["Reading files...", "Validating data...", "Saving records...", "Finishing up..."]
        let totalSteps = tasks.count * 3

        Task { [weak progressVC] in
            for step in 1 ... totalSteps {
                try? await Task.sleep(for: .milliseconds(600))
                guard let progressVC else { return }
                let progress = Float(step) / Float(totalSteps)
                let taskIndex = min(step / 3, tasks.count - 1)
                progressVC.updateProgress(progress, task: tasks[taskIndex])
            }
            progressVC?.setState(.succeeded, message: "Imported 12 records")
            try? await Task.sleep(for: .milliseconds(900))
            progressVC?.dismiss()
        }
    }
}
