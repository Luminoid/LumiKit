//
//  BorderExample.swift
//  LumiKitExample
//
//  Borders & Radius: Hairline borders, corner styles, concentric corners, circles.
//

import LumiKitUI
import SnapKit
import UIKit

// MARK: - Border & Corner Radius

final class BorderDetailViewController: DetailViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        addSectionHeader("lmk_applyBorder")
        let borderedView = UIView()
        borderedView.backgroundColor = LMKColor.backgroundSecondary
        borderedView.lmk_applyBorder(color: LMKColor.primary, width: 2)
        borderedView.lmk_applyCornerRadius(LMKCornerRadius.medium)

        let label = UILabel.lmk_make(.body, text: "Primary color, 2pt width, medium radius")
        label.textAlignment = .center
        borderedView.addSubview(label)
        label.snp.makeConstraints { $0.edges.equalToSuperview().inset(LMKSpacing.large) }
        borderedView.snp.makeConstraints { $0.height.greaterThanOrEqualTo(60) }
        stack.addArrangedSubview(borderedView)

        addDivider()
        addSectionHeader("Hairline Default (LMKLayout.hairline)")
        let hairlineView = UIView()
        hairlineView.backgroundColor = LMKColor.backgroundSecondary
        hairlineView.lmk_applyBorder(color: LMKColor.outline)
        hairlineView.lmk_applyCornerRadius(LMKCornerRadius.medium)

        let hairlineLabel = UILabel.lmk_make(.body, text: String(
            format: "Omitting width uses LMKLayout.hairline: one physical pixel on any display scale (%.2fpt at this screen's scale)",
            LMKLayout.hairline
        ))
        hairlineLabel.textAlignment = .center
        hairlineView.addSubview(hairlineLabel)
        hairlineLabel.snp.makeConstraints { $0.edges.equalToSuperview().inset(LMKSpacing.large) }
        stack.addArrangedSubview(hairlineView)

        addDivider()
        addSectionHeader("Bordered Capsules")
        stack.addArrangedSubview(UILabel.lmk_make(
            .caption,
            text: "A capsule follows its view's size on its own. Border widths snap to whole pixels, so the line keeps one thickness along the edges and around the ends."
        ))
        let capsuleRow = UIStackView(lmk_axis: .horizontal, spacing: LMKSpacing.medium, alignment: .center)
        for (title, width) in [("Hairline", nil), ("1.5pt", 1.5), ("2pt", 2)] as [(String, CGFloat?)] {
            let capsule = UIView()
            capsule.backgroundColor = LMKColor.backgroundPrimary
            capsule.lmk_applyBorder(color: LMKColor.primary, width: width)
            capsule.lmk_applyCornerStyle(.capsule)
            let capsuleLabel = UILabel.lmk_make(.captionMedium, text: title, color: LMKColor.primary)
            capsule.addSubview(capsuleLabel)
            capsuleLabel.snp.makeConstraints { make in
                make.top.bottom.equalToSuperview().inset(LMKSpacing.small)
                make.leading.trailing.equalToSuperview().inset(LMKSpacing.large)
            }
            capsuleRow.addArrangedSubview(capsule)
        }
        capsuleRow.addArrangedSubview(UIView())
        stack.addArrangedSubview(capsuleRow)

        addDivider()
        addSectionHeader("lmk_makeCircular")
        let circleSize: CGFloat = 80
        let circleView = UIView()
        circleView.backgroundColor = LMKColor.primary
        circleView.snp.makeConstraints { $0.width.height.equalTo(circleSize) }

        // Force layout so makeCircular can calculate
        circleView.frame = CGRect(x: 0, y: 0, width: circleSize, height: circleSize)
        circleView.lmk_makeCircular()

        let circleLabel = UILabel.lmk_make(.small, text: "Circle")
        circleLabel.textColor = LMKColor.onAccent
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

            let lbl = UILabel.lmk_make(.small, text: name)
            lbl.textColor = LMKColor.onAccent
            lbl.textAlignment = .center
            box.addSubview(lbl)
            lbl.snp.makeConstraints { $0.center.equalToSuperview() }
            radiusRow.addArrangedSubview(box)
        }
        stack.addArrangedSubview(radiusRow)

        addDivider()
        addSectionHeader("lmk_applyConcentricCorners (iOS 26)")
        stack.addArrangedSubview(UILabel.lmk_make(.caption, text: "The outer card publishes its radius (asConcentricContainer: true); the inner view asks UIKit for a "
                + "container-concentric radius: the outer corner minus the inset, floored at the minimum. "
                + "Before iOS 26 it falls back to the fixed minimum radius."))
        let outer = UIView()
        outer.backgroundColor = LMKColor.backgroundSecondary
        outer.lmk_applyCornerRadius(LMKCornerRadius.xxl, asConcentricContainer: true)
        outer.snp.makeConstraints { $0.height.equalTo(120) }
        let inner = UIView()
        inner.backgroundColor = LMKColor.primary
        inner.lmk_applyConcentricCorners(minimumRadius: LMKCornerRadius.small)
        outer.addSubview(inner)
        inner.snp.makeConstraints { $0.edges.equalToSuperview().inset(LMKSpacing.medium) }
        let innerLabel = UILabel.lmk_make(.small, text: "concentric with the outer card")
        innerLabel.textColor = LMKColor.onAccent
        innerLabel.textAlignment = .center
        inner.addSubview(innerLabel)
        innerLabel.snp.makeConstraints { $0.center.equalToSuperview() }
        stack.addArrangedSubview(outer)
    }
}
