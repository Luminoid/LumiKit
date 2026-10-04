//
//  GlassExample.swift
//  LumiKitExample
//
//  Glass: LMKGlassView and LMKGlassContainerView: Liquid Glass on iOS 26, material fallback before.
//

import LumiKitUI
import SnapKit
import UIKit

// MARK: - Glass

final class GlassDetailViewController: DetailViewController {
    /// Merge distances offered for the container; the middle one is selected first.
    private static let mergeDistances: [CGFloat] = [LMKSpacing.small, LMKSpacing.xxl, LMKSpacing.xxl * 2]
    /// The dots start apart, wider than the default merge distance, so dragging the gap down shows the merge.
    private static let initialGap = LMKSpacing.xxl + LMKSpacing.medium

    private var tapCount = 0
    private lazy var tapLabel = UILabel.lmk_make(.caption, text: "Taps: 0")
    private lazy var glassContainer = LMKGlassContainerView(spacing: Self.mergeDistances[1])
    private lazy var glassRow: UIStackView = {
        let row = UIStackView(lmk_axis: .horizontal, spacing: Self.initialGap)
        for symbol in ["heart", "star", "bookmark"] {
            row.addArrangedSubview(makeGlassDot(symbol: symbol))
        }
        return row
    }()

    override func setupStackContent() {
        addSectionHeader("LMKGlassView")
        let probe = LMKGlassView()
        stackView.addArrangedSubview(UILabel.lmk_make(.caption, text: probe.isGlass
                ? "This device renders Liquid Glass (UIGlassEffect, iOS 26+). No availability gate needed in app code."
                : "This device is below iOS 26, so LMKGlassView renders the systemMaterial blur fallback. Same API, no gate."))

        addSectionHeader("Variants")
        let stylesBackdrop = makeBackdrop()
        let pills = UIStackView(lmk_axis: .horizontal, spacing: LMKSpacing.medium)
        pills.distribution = .fillEqually
        pills.addArrangedSubview(makePill(LMKGlassView(variant: .regular), title: "regular"))
        pills.addArrangedSubview(makePill(LMKGlassView(variant: .clear), title: "clear"))
        pills.addArrangedSubview(makePill(LMKGlassView(variant: .regular, tintColor: LMKColor.primary), title: "tinted"))
        stylesBackdrop.addSubview(pills)
        pills.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(LMKSpacing.large)
            make.centerY.equalToSuperview()
        }
        stackView.addArrangedSubview(stylesBackdrop)

        addDivider()
        addSectionHeader("isInteractive")
        stackView.addArrangedSubview(UILabel.lmk_make(
            .caption,
            text: "Interactive glass reacts to touches, the fit for button backgrounds. usesConcentricCorners: true lets the radius follow the nearest published container corner."
        ))
        let interactiveBackdrop = makeBackdrop()
        let button = LMKGlassView(variant: .regular, isInteractive: true, cornerRadius: LMKCornerRadius.xxl, usesConcentricCorners: true)
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
        stackView.addArrangedSubview(interactiveBackdrop)
        stackView.addArrangedSubview(tapLabel)

        addDivider()
        addSectionHeader("LMKGlassContainerView")
        let containerNote = probe.isGlass
            ? "Glass views in the container's contentView blend into one shape once the gap between them closes within its spacing. "
            + "Drag the gap under the merge distance to watch them join. LMKGlassView.makeContainer(spacing:) builds the same view."
            : "Below iOS 26 the container carries no effect, so each glass view renders on its own at any gap. "
            + "Same API, no gate: on iOS 26 the views blend into one shape once the gap closes within the container's spacing."
        stackView.addArrangedSubview(UILabel.lmk_make(.caption, text: containerNote))
        let containerBackdrop = makeBackdrop()
        containerBackdrop.addSubview(glassContainer)
        glassContainer.snp.makeConstraints { $0.center.equalToSuperview() }
        glassContainer.contentView.addSubview(glassRow)
        glassRow.snp.makeConstraints { $0.edges.equalToSuperview() }
        stackView.addArrangedSubview(containerBackdrop)

        let gapSlider = LMKSlider()
        gapSlider.caption = "Gap between the views"
        gapSlider.minimumValue = 0
        gapSlider.maximumValue = Float(Self.mergeDistances[Self.mergeDistances.count - 1])
        gapSlider.value = Float(Self.initialGap)
        gapSlider.valueFormatter = { "\(Int($0)) pt" }
        gapSlider.onValueChange = { [weak self] value in
            self?.glassRow.spacing = CGFloat(value)
        }
        stackView.addArrangedSubview(gapSlider)

        stackView.addArrangedSubview(UILabel.lmk_make(.caption, text: "Merge distance (spacing)"))
        let mergeControl = LMKSegmentedControl(items: Self.mergeDistances.map { "\(Int($0)) pt" })
        mergeControl.accessibilityLabel = "Merge distance"
        mergeControl.selectedSegmentIndex = 1
        mergeControl.onValueChange = { [weak self] index in
            guard let distance = Self.mergeDistances[lmk_safe: index] else { return }
            self?.glassContainer.spacing = distance
        }
        stackView.addArrangedSubview(mergeControl)
    }

    // MARK: - Actions

    @objc private func glassTapped() {
        tapCount += 1
        tapLabel.lmk_setText("Taps: \(tapCount)")
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

    /// A circular glass view around a symbol, sized from the symbol plus a large inset on each side.
    private func makeGlassDot(symbol: String) -> LMKGlassView {
        let dot = LMKGlassView(style: LMKGlassView.Style(corners: .circle))
        let icon = UIImageView(image: UIImage(systemName: symbol))
        icon.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: LMKLayout.symbolLarge)
        icon.tintColor = LMKColor.textPrimary
        icon.contentMode = .center
        dot.contentView.addSubview(icon)
        icon.snp.makeConstraints { $0.center.equalToSuperview() }
        dot.snp.makeConstraints { $0.size.equalTo(LMKLayout.symbolLarge + LMKSpacing.large * 2) }
        return dot
    }
}
