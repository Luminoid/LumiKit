//
//  FadeExample.swift
//  LumiKitExample
//
//  Fade Animations: LMKAnimation.fadeIn and fadeOut.
//

import LumiKitUI
import SnapKit
import UIKit

// MARK: - Fade Animations

final class FadeDetailViewController: DetailViewController {
    private let targetView = UIView()

    override func setupStackContent() {
        addSectionHeader("LMKAnimation.fadeIn / fadeOut")
        stackView.addArrangedSubview(UILabel.lmk_make(.caption, text: "Animated opacity transitions with configurable duration. Respects Reduce Motion."))

        targetView.backgroundColor = LMKColor.primary
        targetView.lmk_applyCornerRadius(LMKCornerRadius.medium)
        targetView.snp.makeConstraints { $0.height.equalTo(100) }

        let label = UILabel.lmk_make(.body, text: "Fade Target")
        label.textColor = LMKColor.onAccent
        label.textAlignment = .center
        targetView.addSubview(label)
        label.snp.makeConstraints { $0.center.equalToSuperview() }
        stackView.addArrangedSubview(targetView)

        let buttonRow = UIStackView(lmk_axis: .horizontal, spacing: LMKSpacing.small)
        buttonRow.distribution = .fillEqually

        let fadeOutButton = LMKButton(title: "Fade Out", style: .outlined(.destructive), target: self, action: #selector(fadeOut))
        buttonRow.addArrangedSubview(fadeOutButton)

        let fadeInButton = LMKButton(title: "Fade In", style: .outlined(.success), target: self, action: #selector(fadeIn))
        buttonRow.addArrangedSubview(fadeInButton)

        stackView.addArrangedSubview(buttonRow)
    }

    @objc private func fadeOut() {
        LMKAnimation.fadeOut(targetView)
    }

    @objc private func fadeIn() {
        LMKAnimation.fadeIn(targetView)
    }
}
