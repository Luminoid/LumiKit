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
    override func viewDidLoad() {
        super.viewDidLoad()

        addSectionHeader("LMKCardView")
        let card = LMKCardView()
        let label = UILabel.lmk_make(.body, text: "Card with shadow, corner radius, and content insets. Uses LMKShadow.style(for: .level2) and LMKCornerRadius.medium.")
        card.contentView.addSubview(label)
        label.snp.makeConstraints { $0.edges.equalToSuperview().inset(LMKSpacing.large) }
        stack.addArrangedSubview(card)

        addDivider()
        addSectionHeader("LMKCardView(style: .cell)")
        let factoryCard = LMKCardView(style: .cell)
        let factoryLabel = UILabel.lmk_make(.body, text: "Created via LMKCardView(style: .cell): secondary background with standard shadow.")
        factoryCard.addSubview(factoryLabel)
        factoryLabel.snp.makeConstraints { $0.edges.equalToSuperview().inset(LMKSpacing.large) }
        stack.addArrangedSubview(factoryCard)
    }
}
