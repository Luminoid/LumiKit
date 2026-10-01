//
//  ShadowExample.swift
//  LumiKitExample
//
//  Shadows: LMKShadow levels and lmk_applyShadow.
//

import LumiKitUI
import SnapKit
import UIKit

// MARK: - Shadow

final class ShadowDetailViewController: DetailViewController {
    private static let toggleLevel = LMKShadow.Level.level3

    override func setupStackContent() {
        addSectionHeader("LMKShadow.Level")
        stackView.addArrangedSubview(UILabel.lmk_make(
            .caption,
            text: "lmk_applyShadow(_ level:) resolves the level through the theme, so a theme with its own shadow scale restyles every card; level1 is the tightest lift, level5 the widest."
        ))
        for level in LMKShadow.Level.allCases where level != .none {
            let container = UIView()
            container.backgroundColor = LMKColor.backgroundPrimary
            container.lmk_applyCornerRadius(LMKCornerRadius.medium, masking: false)
            container.lmk_applyShadow(level)

            let label = UILabel.lmk_make(.body, text: "\(level)")
            label.textAlignment = .center
            container.addSubview(label)
            label.snp.makeConstraints { $0.edges.equalToSuperview().inset(LMKSpacing.large) }
            container.snp.makeConstraints { $0.height.greaterThanOrEqualTo(60) }
            stackView.addArrangedSubview(container)
        }

        addDivider()
        addSectionHeader("Remove Shadow")
        stackView.addArrangedSubview(UILabel.lmk_make(.caption, text: "lmk_removeShadow() clears the shadow layer."))
        let toggleView = UIView()
        toggleView.backgroundColor = LMKColor.backgroundPrimary
        toggleView.lmk_applyCornerRadius(LMKCornerRadius.medium, masking: false)
        toggleView.lmk_applyShadow(Self.toggleLevel)
        toggleView.snp.makeConstraints { $0.height.greaterThanOrEqualTo(60) }

        let toggleLabel = UILabel.lmk_make(.body, text: "Tap to toggle shadow")
        toggleLabel.textAlignment = .center
        toggleView.addSubview(toggleLabel)
        toggleLabel.snp.makeConstraints { $0.edges.equalToSuperview().inset(LMKSpacing.large) }

        let tap = UITapGestureRecognizer()
        tap.addTarget(self, action: #selector(toggleShadow(_:)))
        toggleView.addGestureRecognizer(tap)
        // The tap target is the card, so VoiceOver gets one button in place of a static label.
        toggleView.isAccessibilityElement = true
        toggleView.accessibilityTraits = .button
        toggleView.accessibilityLabel = toggleLabel.text
        stackView.addArrangedSubview(toggleView)
    }

    @objc private func toggleShadow(_ gesture: UITapGestureRecognizer) {
        guard let view = gesture.view else { return }
        if view.layer.shadowOpacity > 0 {
            view.lmk_removeShadow()
        } else {
            view.lmk_applyShadow(Self.toggleLevel)
        }
    }
}
