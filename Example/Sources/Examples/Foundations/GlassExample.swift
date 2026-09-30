//
//  GlassExample.swift
//  LumiKitExample
//
//  Glass: LMKGlassView: Liquid Glass on iOS 26, material fallback before.
//

import LumiKitUI
import SnapKit
import UIKit

// MARK: - Glass

final class GlassDetailViewController: DetailViewController {
    private var tapCount = 0
    private lazy var tapLabel = UILabel.lmk_make(.caption, text: "Taps: 0")

    override func viewDidLoad() {
        super.viewDidLoad()

        addSectionHeader("LMKGlassView")
        let probe = LMKGlassView()
        stack.addArrangedSubview(UILabel.lmk_make(.caption, text: probe.isGlass
                ? "This device renders Liquid Glass (UIGlassEffect, iOS 26+). No availability gate needed in app code."
                : "This device is below iOS 26, so LMKGlassView renders the systemMaterial blur fallback. Same API, no gate."))

        addSectionHeader("Styles")
        let stylesBackdrop = makeBackdrop()
        let pills = UIStackView(lmk_axis: .horizontal, spacing: LMKSpacing.medium)
        pills.distribution = .fillEqually
        pills.addArrangedSubview(makePill(LMKGlassView(style: .regular), title: "regular"))
        pills.addArrangedSubview(makePill(LMKGlassView(style: .clear), title: "clear"))
        pills.addArrangedSubview(makePill(LMKGlassView(style: .regular, tintColor: LMKColor.primary), title: "tinted"))
        stylesBackdrop.addSubview(pills)
        pills.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(LMKSpacing.large)
            make.centerY.equalToSuperview()
        }
        stack.addArrangedSubview(stylesBackdrop)

        addDivider()
        addSectionHeader("isInteractive")
        stack.addArrangedSubview(UILabel.lmk_make(
            .caption,
            text: "Interactive glass reacts to touches, the fit for button backgrounds. usesConcentricCorners: true lets the radius follow the nearest published container corner."
        ))
        let interactiveBackdrop = makeBackdrop()
        let button = LMKGlassView(style: .regular, isInteractive: true, cornerRadius: LMKCornerRadius.xxl, usesConcentricCorners: true)
        let buttonLabel = UILabel.lmk_make(.bodyMedium, text: "Tap me")
        buttonLabel.textAlignment = .center
        button.contentView.addSubview(buttonLabel)
        buttonLabel.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(LMKSpacing.medium)
            make.leading.trailing.equalToSuperview().inset(LMKSpacing.xxl)
        }
        button.contentView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(glassTapped)))
        interactiveBackdrop.addSubview(button)
        button.snp.makeConstraints { $0.center.equalToSuperview() }
        stack.addArrangedSubview(interactiveBackdrop)
        stack.addArrangedSubview(tapLabel)

        addDivider()
        addSectionHeader("makeContainer(spacing:)")
        stack.addArrangedSubview(UILabel.lmk_make(
            .caption,
            text: "Glass views hosted in a container merge into one shape once they come within the spacing (iOS 26). Before iOS 26 they render on their own."
        ))
        let containerBackdrop = makeBackdrop()
        let container = LMKGlassView.makeContainer(spacing: LMKSpacing.xxl)
        containerBackdrop.addSubview(container)
        container.snp.makeConstraints { $0.center.equalToSuperview() }
        let dots = UIStackView(lmk_axis: .horizontal, spacing: LMKSpacing.small)
        for symbol in ["heart", "star", "bookmark"] {
            let dot = LMKGlassView(cornerRadius: 28, usesConcentricCorners: false)
            let icon = UIImageView(image: UIImage(systemName: symbol))
            icon.tintColor = LMKColor.textPrimary
            icon.contentMode = .center
            dot.contentView.addSubview(icon)
            icon.snp.makeConstraints { $0.edges.equalToSuperview() }
            dot.snp.makeConstraints { $0.width.height.equalTo(56) }
            dots.addArrangedSubview(dot)
        }
        container.contentView.addSubview(dots)
        dots.snp.makeConstraints { $0.edges.equalToSuperview() }
        stack.addArrangedSubview(containerBackdrop)
    }

    // MARK: - Actions

    @objc private func glassTapped() {
        tapCount += 1
        tapLabel.text = "Taps: \(tapCount)"
    }

    // MARK: - Builders

    private func makeBackdrop() -> UIView {
        let gradient = LMKGradientView(colors: [LMKColor.primary, LMKColor.secondary], direction: .topLeftToBottomRight)
        gradient.lmk_applyCornerRadius(LMKCornerRadius.large, asConcentricContainer: true)
        gradient.snp.makeConstraints { $0.height.equalTo(140) }
        return gradient
    }

    private func makePill(_ glass: LMKGlassView, title: String) -> UIView {
        let label = UILabel.lmk_make(.bodyMedium, text: title)
        label.textAlignment = .center
        glass.contentView.addSubview(label)
        label.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(LMKSpacing.medium)
            make.leading.trailing.equalToSuperview().inset(LMKSpacing.small)
        }
        return glass
    }
}
