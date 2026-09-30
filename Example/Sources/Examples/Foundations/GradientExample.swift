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
    override func viewDidLoad() {
        super.viewDidLoad()

        let directions: [(String, LMKGradientView.Direction)] = [
            ("Top \u{2192} Bottom", .topToBottom),
            ("Left \u{2192} Right", .leftToRight),
            ("Top-Left \u{2192} Bottom-Right", .topLeftToBottomRight),
            ("Top-Right \u{2192} Bottom-Left", .topRightToBottomLeft),
        ]

        for (name, direction) in directions {
            addSectionHeader(name)
            let gradient = LMKGradientView(
                colors: [LMKColor.primary, LMKColor.secondary],
                direction: direction
            )
            gradient.layer.cornerRadius = LMKCornerRadius.medium
            gradient.clipsToBounds = true
            gradient.snp.makeConstraints { $0.height.equalTo(80) }
            stack.addArrangedSubview(gradient)
        }

        addDivider()
        addSectionHeader("Custom Colors")
        let sunset = LMKGradientView(
            colors: [LMKColor.warning, LMKColor.error, LMKColor.primary],
            direction: .leftToRight
        )
        sunset.layer.cornerRadius = LMKCornerRadius.medium
        sunset.clipsToBounds = true
        sunset.snp.makeConstraints { $0.height.equalTo(80) }
        stack.addArrangedSubview(sunset)
    }
}
