//
//  ExtensionExamples.swift
//  LumiKitExample
//
//  Shadow, border, fade, and layout extension examples.
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
            ("cellCard()", LMKShadow.cellCard()),
            ("card()", LMKShadow.card()),
            ("button()", LMKShadow.button()),
            ("small()", LMKShadow.small()),
        ]

        for (name, shadow) in presets {
            let container = UIView()
            container.backgroundColor = LMKColor.backgroundPrimary
            container.layer.cornerRadius = LMKCornerRadius.medium
            container.lmk_applyShadow(shadow)

            let label = LMKLabelFactory.body(text: name)
            label.textAlignment = .center
            container.addSubview(label)
            label.snp.makeConstraints { $0.edges.equalToSuperview().inset(LMKSpacing.large) }
            container.snp.makeConstraints { $0.height.equalTo(60) }
            stack.addArrangedSubview(container)
        }

        addDivider()
        addSectionHeader("Remove Shadow")
        stack.addArrangedSubview(LMKLabelFactory.caption(text: "lmk_removeShadow() clears the shadow layer."))
        let toggleView = UIView()
        toggleView.backgroundColor = LMKColor.backgroundPrimary
        toggleView.layer.cornerRadius = LMKCornerRadius.medium
        toggleView.lmk_applyShadow(LMKShadow.card())
        toggleView.snp.makeConstraints { $0.height.equalTo(60) }

        let toggleLabel = LMKLabelFactory.body(text: "Tap to toggle shadow")
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
            view.lmk_applyShadow(LMKShadow.card())
        }
    }
}

// MARK: - Border & Corner Radius

final class BorderDetailViewController: DetailViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        addSectionHeader("lmk_applyBorder")
        let borderedView = UIView()
        borderedView.backgroundColor = LMKColor.backgroundSecondary
        borderedView.lmk_applyBorder(color: LMKColor.primary, width: 2)
        borderedView.lmk_applyCornerRadius(LMKCornerRadius.medium)

        let label = LMKLabelFactory.body(text: "Primary color, 2pt width, medium radius")
        label.textAlignment = .center
        borderedView.addSubview(label)
        label.snp.makeConstraints { $0.edges.equalToSuperview().inset(LMKSpacing.large) }
        borderedView.snp.makeConstraints { $0.height.equalTo(60) }
        stack.addArrangedSubview(borderedView)

        addDivider()
        addSectionHeader("lmk_makeCircular")
        let circleSize: CGFloat = 80
        let circleView = UIView()
        circleView.backgroundColor = LMKColor.primary
        circleView.snp.makeConstraints { $0.width.height.equalTo(circleSize) }

        // Force layout so makeCircular can calculate
        circleView.frame = CGRect(x: 0, y: 0, width: circleSize, height: circleSize)
        circleView.lmk_makeCircular()

        let circleLabel = LMKLabelFactory.small(text: "Circle")
        circleLabel.textColor = LMKColor.white
        circleLabel.textAlignment = .center
        circleView.addSubview(circleLabel)
        circleLabel.snp.makeConstraints { $0.center.equalToSuperview() }

        let row = UIStackView(lmk_axis: .horizontal)
        row.addArrangedSubview(circleView)
        row.addArrangedSubview(UIView())
        stack.addArrangedSubview(row)

        addDivider()
        addSectionHeader("Corner Radius Tokens")
        let radii: [(String, CGFloat)] = [
            ("xs (4)", LMKCornerRadius.xs),
            ("small (8)", LMKCornerRadius.small),
            ("medium (12)", LMKCornerRadius.medium),
            ("large (16)", LMKCornerRadius.large),
            ("xl (20)", LMKCornerRadius.xl),
        ]
        let radiusRow = UIStackView(lmk_axis: .horizontal, spacing: LMKSpacing.small)
        radiusRow.distribution = .fillEqually
        for (name, radius) in radii {
            let box = UIView()
            box.backgroundColor = LMKColor.secondary
            box.lmk_applyCornerRadius(radius)
            box.snp.makeConstraints { $0.height.equalTo(52) }

            let lbl = LMKLabelFactory.small(text: name)
            lbl.textColor = LMKColor.white
            lbl.textAlignment = .center
            box.addSubview(lbl)
            lbl.snp.makeConstraints { $0.center.equalToSuperview() }
            radiusRow.addArrangedSubview(box)
        }
        stack.addArrangedSubview(radiusRow)
    }
}

// MARK: - Fade Animations

final class FadeDetailViewController: DetailViewController {
    private let targetView = UIView()

    override func viewDidLoad() {
        super.viewDidLoad()

        addSectionHeader("lmk_fadeIn / lmk_fadeOut")
        stack.addArrangedSubview(LMKLabelFactory.caption(text: "Animated opacity transitions with configurable duration. Respects Reduce Motion."))

        targetView.backgroundColor = LMKColor.primary
        targetView.layer.cornerRadius = LMKCornerRadius.medium
        targetView.snp.makeConstraints { $0.height.equalTo(100) }

        let label = LMKLabelFactory.body(text: "Fade Target")
        label.textColor = LMKColor.white
        label.textAlignment = .center
        targetView.addSubview(label)
        label.snp.makeConstraints { $0.center.equalToSuperview() }
        stack.addArrangedSubview(targetView)

        let buttonRow = UIStackView(lmk_axis: .horizontal, spacing: LMKSpacing.small)
        buttonRow.distribution = .fillEqually

        let fadeOutButton = LMKButtonFactory.outlined(role: .destructive, title: "Fade Out", target: self, action: #selector(fadeOut))
        buttonRow.addArrangedSubview(fadeOutButton)

        let fadeInButton = LMKButtonFactory.outlined(role: .success, title: "Fade In", target: self, action: #selector(fadeIn))
        buttonRow.addArrangedSubview(fadeInButton)

        stack.addArrangedSubview(buttonRow)
    }

    @objc private func fadeOut() {
        targetView.lmk_fadeOut()
    }

    @objc private func fadeIn() {
        targetView.lmk_fadeIn()
    }
}
