//
//  CardsExample.swift
//  LumiKitExample
//
//  Cards: LMKCardView presets: cell, elevated, flat, outlined.
//

import LumiKitUI
import SnapKit
import UIKit

// MARK: - Cards

final class CardsDetailViewController: DetailViewController {
    override func setupStackContent() {
        addSectionHeader("LMKCardView")
        stackView.addArrangedSubview(UILabel.lmk_make(
            .caption,
            text: "Add content to card.contentView and pin it to the edges: the card already insets contentView by its content insets."
        ))
        addCard(LMKCardView(), text: "The default card (the .elevated preset): secondary background, medium corners, the level3 shadow.")

        addDivider()
        addSectionHeader("Presets")
        addCard(LMKCardView(style: .cell), text: ".cell: the lighter level2 lift for list rows.")
        addCard(LMKCardView(style: .elevated), text: ".elevated: the level3 shadow of a floating card.")
        addCard(LMKCardView(style: .flat), text: ".flat: no shadow; the card clips its content to the corners.")
        addCard(LMKCardView(style: .outlined), text: ".outlined: a hairline border and no shadow.")

        addDivider()
        addSectionHeader("Tappable")
        let tappable = LMKCardView(style: .outlined)
        addLabel("onTap gives the card press feedback and makes it one VoiceOver button.", to: tappable)
        tappable.onTap = { [weak self] in
            guard let self else { return }
            LMKToast.show(.info, "Card tapped", in: self)
        }
        stackView.addArrangedSubview(tappable)
    }

    private func addCard(_ card: LMKCardView, text: String) {
        addLabel(text, to: card)
        stackView.addArrangedSubview(card)
    }

    private func addLabel(_ text: String, to card: LMKCardView) {
        let label = UILabel.lmk_make(.body, text: text)
        card.contentView.addSubview(label)
        label.snp.makeConstraints { $0.edges.equalToSuperview() }
    }
}
