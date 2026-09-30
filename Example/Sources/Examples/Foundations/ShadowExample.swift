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
    override func viewDidLoad() {
        super.viewDidLoad()

        addSectionHeader("LMKShadow Presets")
        let presets: [(String, LMKShadowStyle)] = [
            ("cellCard()", LMKShadow.style(for: .level2)),
            ("card()", LMKShadow.style(for: .level3)),
            ("button()", LMKShadow.style(for: .level2)),
            ("small()", LMKShadow.style(for: .level1)),
        ]

        for (name, shadow) in presets {
            let container = UIView()
            container.backgroundColor = LMKColor.backgroundPrimary
            container.layer.cornerRadius = LMKCornerRadius.medium
            container.lmk_applyShadow(shadow)

            let label = UILabel.lmk_make(.body, text: name)
            label.textAlignment = .center
            container.addSubview(label)
            label.snp.makeConstraints { $0.edges.equalToSuperview().inset(LMKSpacing.large) }
            container.snp.makeConstraints { $0.height.greaterThanOrEqualTo(60) }
            stack.addArrangedSubview(container)
        }

        addDivider()
        addSectionHeader("Remove Shadow")
        stack.addArrangedSubview(UILabel.lmk_make(.caption, text: "lmk_removeShadow() clears the shadow layer."))
        let toggleView = UIView()
        toggleView.backgroundColor = LMKColor.backgroundPrimary
        toggleView.layer.cornerRadius = LMKCornerRadius.medium
        toggleView.lmk_applyShadow(LMKShadow.style(for: .level3))
        toggleView.snp.makeConstraints { $0.height.greaterThanOrEqualTo(60) }

        let toggleLabel = UILabel.lmk_make(.body, text: "Tap to toggle shadow")
        toggleLabel.textAlignment = .center
        toggleView.addSubview(toggleLabel)
        toggleLabel.snp.makeConstraints { $0.edges.equalToSuperview().inset(LMKSpacing.large) }

        let tap = UITapGestureRecognizer()
        tap.addTarget(self, action: #selector(toggleShadow(_:)))
        toggleView.addGestureRecognizer(tap)
        toggleView.isUserInteractionEnabled = true
        toggleView.tag = 100
        toggleView.accessibilityLabel = "shadow on"
        stack.addArrangedSubview(toggleView)
    }

    @objc private func toggleShadow(_ gesture: UITapGestureRecognizer) {
        guard let view = gesture.view else { return }
        if view.layer.shadowOpacity > 0 {
            view.lmk_removeShadow()
        } else {
            view.lmk_applyShadow(LMKShadow.style(for: .level3))
        }
    }
}
