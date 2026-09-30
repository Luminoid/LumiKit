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

    override func viewDidLoad() {
        super.viewDidLoad()

        addSectionHeader("LMKAnimation.fadeIn / fadeOut")
        stack.addArrangedSubview(UILabel.lmk_make(.caption, text: "Animated opacity transitions with configurable duration. Respects Reduce Motion."))

        targetView.backgroundColor = LMKColor.primary
        targetView.layer.cornerRadius = LMKCornerRadius.medium
        targetView.snp.makeConstraints { $0.height.equalTo(100) }

        let label = UILabel.lmk_make(.body, text: "Fade Target")
        label.textColor = LMKColor.onAccent
        label.textAlignment = .center
        targetView.addSubview(label)
        label.snp.makeConstraints { $0.center.equalToSuperview() }
        stack.addArrangedSubview(targetView)

        let buttonRow = UIStackView(lmk_axis: .horizontal, spacing: LMKSpacing.small)
        buttonRow.distribution = .fillEqually

        let fadeOutButton = LMKButton(title: "Fade Out", style: .outlined(.destructive), target: self, action: #selector(fadeOut))
        buttonRow.addArrangedSubview(fadeOutButton)

        let fadeInButton = LMKButton(title: "Fade In", style: .outlined(.success), target: self, action: #selector(fadeIn))
        buttonRow.addArrangedSubview(fadeInButton)

        stack.addArrangedSubview(buttonRow)
    }

    @objc private func fadeOut() {
        LMKAnimation.fadeOut(targetView)
    }

    @objc private func fadeIn() {
        LMKAnimation.fadeIn(targetView)
    }
}
