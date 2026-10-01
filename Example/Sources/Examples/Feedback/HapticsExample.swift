//
//  HapticsExample.swift
//  LumiKitExample
//
//  Haptics: Notification, impact, and selection feedback.
//

import LumiKitUI
import UIKit

// MARK: - Haptics

final class HapticsDetailViewController: DetailViewController {
    override func setupStackContent() {
        addSectionHeader("Notification Feedback")
        stackView.addArrangedSubview(UILabel.lmk_make(
            .caption,
            text: "Triggered for task outcomes: success, warning, or error. The Taptic Engine is prepared when this screen appears for lower latency."
        ))

        let notifRow = UIStackView(lmk_axis: .horizontal, spacing: LMKSpacing.small)
        notifRow.distribution = .fillEqually

        let successNotif = LMKButton(title: "Success", style: .outlined(.success), target: self, action: #selector(hapticSuccess))
        notifRow.addArrangedSubview(successNotif)

        let warningNotif = LMKButton(title: "Warning", style: .outlined(.warning), target: self, action: #selector(hapticWarning))
        notifRow.addArrangedSubview(warningNotif)

        let errorNotif = LMKButton(title: "Error", style: .outlined(.destructive), target: self, action: #selector(hapticError))
        notifRow.addArrangedSubview(errorNotif)

        stackView.addArrangedSubview(notifRow)

        addDivider()
        addSectionHeader("Selection Feedback")
        stackView.addArrangedSubview(UILabel.lmk_make(.caption, text: "Subtle tick for picker changes and control selection."))
        let selectionButton = LMKButton(title: "Trigger Selection", style: .outlined(.primary), target: self, action: #selector(hapticSelection))
        stackView.addArrangedSubview(selectionButton)

        addDivider()
        addSectionHeader("Impact Feedback")
        stackView.addArrangedSubview(UILabel.lmk_make(.caption, text: "Physical impact feel: light, medium, heavy, soft (cushioned), or rigid (sharp)."))

        let impactRow1 = UIStackView(lmk_axis: .horizontal, spacing: LMKSpacing.small)
        impactRow1.distribution = .fillEqually

        let lightImpact = LMKButton(title: "Light", style: .outlined(.secondary), target: self, action: #selector(hapticLight))
        impactRow1.addArrangedSubview(lightImpact)

        let mediumImpact = LMKButton(title: "Medium", style: .outlined(.secondary), target: self, action: #selector(hapticMedium))
        impactRow1.addArrangedSubview(mediumImpact)

        let heavyImpact = LMKButton(title: "Heavy", style: .outlined(.secondary), target: self, action: #selector(hapticHeavy))
        impactRow1.addArrangedSubview(heavyImpact)

        stackView.addArrangedSubview(impactRow1)

        let impactRow2 = UIStackView(lmk_axis: .horizontal, spacing: LMKSpacing.small)
        impactRow2.distribution = .fillEqually

        let softImpact = LMKButton(title: "Soft", style: .outlined(.secondary), target: self, action: #selector(hapticSoft))
        impactRow2.addArrangedSubview(softImpact)

        let rigidImpact = LMKButton(title: "Rigid", style: .outlined(.secondary), target: self, action: #selector(hapticRigid))
        impactRow2.addArrangedSubview(rigidImpact)

        stackView.addArrangedSubview(impactRow2)
    }

    @objc private func hapticSuccess() {
        LMKHaptics.success()
    }

    @objc private func hapticWarning() {
        LMKHaptics.warning()
    }

    @objc private func hapticError() {
        LMKHaptics.error()
    }

    @objc private func hapticSelection() {
        LMKHaptics.selection()
    }

    @objc private func hapticLight() {
        LMKHaptics.light()
    }

    @objc private func hapticMedium() {
        LMKHaptics.medium()
    }

    @objc private func hapticHeavy() {
        LMKHaptics.heavy()
    }

    @objc private func hapticSoft() {
        LMKHaptics.soft()
    }

    @objc private func hapticRigid() {
        LMKHaptics.rigid()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Prepare when a haptic is anticipated (this screen appearing), not right before it plays:
        // the generators stay warm for a second or two, so the first tap has minimal latency.
        LMKHaptics.prepareNotification()
        LMKHaptics.prepareSelection()
        LMKHaptics.prepareImpact(.medium)
    }
}
