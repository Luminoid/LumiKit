//
//  TipViewExample.swift
//  LumiKitExample
//
//  Tip View: Centered and pointed tips with custom surfaces.
//

import LumiKitUI
import SnapKit
import UIKit

// MARK: - Tip View

final class TipViewDetailViewController: DetailViewController {
    private let targetChip = LMKChipView(text: "Target View", style: .filled)

    override func viewDidLoad() {
        super.viewDidLoad()

        addSectionHeader("Centered")
        stack.addArrangedSubview(UILabel.lmk_make(.caption, text: "A card over a dimmed screen with a dismiss button; a tap outside dismisses it too."))
        stack.addArrangedSubview(LMKButton(title: "Show Centered Tip", style: .outlined(.primary)) { [weak self] in self?.showCenteredTip() })
        stack.addArrangedSubview(LMKButton(title: "Show Message-Only Tip", style: .outlined(.info)) { [weak self] in self?.showSimpleTip() })

        addDivider()
        addSectionHeader("Pointed")
        stack.addArrangedSubview(UILabel.lmk_make(
            .caption,
            text: "A bubble with an arrow toward a source view. The bubble and its arrow are one outline, so Style.surface colors, borders, and shadows wrap both."
        ))
        // The chip keeps its own width; a full-width target would hide where the arrow points.
        stack.addArrangedSubview(UIStackView(lmk_axis: .horizontal, arrangedSubviews: [targetChip, UIView()]))
        stack.addArrangedSubview(LMKButton(title: "Default", style: .outlined(.secondary)) { [weak self] in self?.showPointedTip(style: LMKTipView.Style()) })
        stack.addArrangedSubview(LMKButton(title: "Brand color", style: .outlined(.secondary)) { [weak self] in
            self?.showPointedTip(style: LMKTipView.Style(
                surface: LMKSurfaceStyle(background: .solid(LMKColor.primary), shadow: .level(.level4)),
                titleColor: LMKColor.onAccent,
                messageColor: LMKColor.onAccent
            ))
        })
        stack.addArrangedSubview(LMKButton(title: "Outlined", style: .outlined(.secondary)) { [weak self] in
            self?.showPointedTip(style: LMKTipView.Style(surface: LMKSurfaceStyle(
                background: .solid(LMKColor.backgroundPrimary),
                corners: .fixed(LMKCornerRadius.large),
                border: .solid(LMKColor.primary, width: 1.5),
                shadow: LMKShadowSource.none
            )))
        })
        stack.addArrangedSubview(LMKButton(title: "Dashed border", style: .outlined(.secondary)) { [weak self] in
            self?.showPointedTip(style: LMKTipView.Style(surface: LMKSurfaceStyle(
                background: .solid(LMKColor.warning.lmk_composited(over: LMKColor.backgroundPrimary, alpha: LMKAlpha.xs)),
                border: .dashed([6, 3], color: LMKColor.warning, width: 1),
                shadow: LMKShadowSource.none
            )))
        })
    }

    private func showCenteredTip() {
        LMKTip.show(
            title: "Did you know?",
            message: "You can long-press any item to see more options. Try it out!",
            icon: UIImage(systemName: "lightbulb"),
            placement: .center,
            in: self
        )
    }

    private func showPointedTip(style: LMKTipView.Style) {
        LMKTip.show(
            title: "Pointed tip",
            message: "The arrow follows the target view.",
            placement: .pointed(sourceView: targetChip, arrowDirection: .up),
            style: style,
            in: self
        )
    }

    private func showSimpleTip() {
        LMKTip.show(
            message: "Swipe down to refresh the list. New items will appear at the top.",
            in: self
        )
    }
}
