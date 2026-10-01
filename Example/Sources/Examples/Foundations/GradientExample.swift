//
//  GradientExample.swift
//  LumiKitExample
//
//  Gradient: LMKGradientView: linear, angled, and radial.
//

import LumiKitUI
import SnapKit
import UIKit

// MARK: - Gradient

final class GradientDetailViewController: DetailViewController {
    override func setupStackContent() {
        let directions: [(String, LMKGradientView.Direction)] = [
            ("Top \u{2192} Bottom", .topToBottom),
            ("Left \u{2192} Right", .leftToRight),
            ("Top-Left \u{2192} Bottom-Right", .topLeftToBottomRight),
            ("Top-Right \u{2192} Bottom-Left", .topRightToBottomLeft),
        ]

        for (name, direction) in directions {
            addSectionHeader(name)
            addGradient(LMKGradientView(colors: [LMKColor.primary, LMKColor.secondary], direction: direction))
        }

        addDivider()
        addSectionHeader("Angled: .angle(30)")
        stackView.addArrangedSubview(UILabel.lmk_make(.caption, text: "Any angle in degrees; the start and end points are solved so the full ramp spans the view."))
        addGradient(LMKGradientView(colors: [LMKColor.primary, LMKColor.secondary], direction: .angle(30)))

        addDivider()
        addSectionHeader("Radial: kind = .radial")
        stackView.addArrangedSubview(UILabel.lmk_make(.caption, text: "Radiates from the center to the corners; the direction is ignored."))
        addGradient(LMKGradientView(colors: [LMKColor.secondary, LMKColor.primary], kind: .radial))

        addDivider()
        addSectionHeader("Custom Colors")
        addGradient(LMKGradientView(colors: [LMKColor.warning, LMKColor.error, LMKColor.primary], direction: .leftToRight))
    }

    private func addGradient(_ gradient: LMKGradientView) {
        gradient.lmk_applyCornerRadius(LMKCornerRadius.medium)
        gradient.snp.makeConstraints { $0.height.equalTo(80) }
        stackView.addArrangedSubview(gradient)
    }
}
