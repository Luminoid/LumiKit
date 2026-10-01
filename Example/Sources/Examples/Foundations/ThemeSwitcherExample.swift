//
//  ThemeSwitcherExample.swift
//  LumiKitExample
//
//  Theme Switcher: LMKTheme.apply at runtime: every component re-renders live.
//

import LumiKitCore
import LumiKitUI
import SnapKit
import UIKit

final class ThemeSwitcherDetailViewController: DetailViewController {
    private let names = ExampleThemes.names
    private let statusLabel = UILabel.lmk_make(.caption, color: LMKColor.textSecondary)

    override func setupStackContent() {
        addSectionHeader("Theme")
        let control = LMKSegmentedControl(items: names.map(\.capitalized))
        control.selectedSegmentIndex = currentThemeIndex()
        control.onValueChange = { [weak self] index in
            guard let self, let theme = names[lmk_safe: index].flatMap(ExampleThemes.theme(named:)) else { return }
            LMKTheme.apply(theme)
            statusLabel.lmk_setText("Applied \(names[index]); primary is \(LMKTheme.current.colors.primary.lmk_hexString)")
        }
        stackView.addArrangedSubview(control)
        statusLabel.lmk_setText("Tap a theme. Components below follow LMKTheme.apply without a rebuild; so does the rest of the catalog.")
        stackView.addArrangedSubview(statusLabel)

        addDivider()
        addSectionHeader("Live Components")
        let buttons = UIStackView(lmk_axis: .horizontal, spacing: LMKSpacing.small)
        buttons.lmk_addArrangedSubviews([
            LMKButton(title: "Filled", style: .filled()),
            LMKButton(title: "Outlined", style: .outlined()),
            LMKButton(title: "Ghost", style: .ghost(.secondary)),
        ])
        stackView.addArrangedSubview(buttons)

        let chips = UIStackView(lmk_axis: .horizontal, spacing: LMKSpacing.small)
        let selected = LMKChipView(text: "Selected", style: .filled)
        selected.isSelected = true
        chips.lmk_addArrangedSubviews([LMKChipView(text: "Filled", style: .filled), LMKChipView(text: "Outlined", style: .outlined), selected])
        chips.addArrangedSubview(UIView())
        stackView.addArrangedSubview(chips)

        let card = LMKCardView(style: .elevated)
        let cardLabel = UILabel.lmk_make(.body, text: "An elevated card with the theme's corner radius and shadow level.")
        cardLabel.numberOfLines = 0
        card.contentView.addSubview(cardLabel)
        cardLabel.snp.makeConstraints { $0.edges.equalToSuperview().inset(LMKSpacing.large) }
        stackView.addArrangedSubview(card)

        let controls = UIStackView(lmk_axis: .horizontal, spacing: LMKSpacing.large)
        controls.alignment = .center
        let toggle = LMKSwitch()
        toggle.isOn = true
        toggle.accessibilityLabel = "Sample switch"
        let badge = LMKBadgeView()
        badge.configure(.count(7))
        let field = LMKTextField()
        field.placeholder = "Text field"
        controls.lmk_addArrangedSubviews([toggle, badge, field])
        stackView.addArrangedSubview(controls)

        addDivider()
        addSectionHeader("System Settings To Pair With")
        stackView.addArrangedSubview(UILabel.lmk_make(
            .caption,
            text: "Increase Contrast boosts the accent roles by the theme's highContrastBoost. Dark Mode and Dynamic Type re-resolve through the same trait pass. "
                + "Launch with -lmk-theme ocean or -lmk-rtl to script it.",
            color: LMKColor.textSecondary
        ))
    }

    private func currentThemeIndex() -> Int {
        let primary = LMKTheme.current.colors.primary.lmk_hexString
        return names.firstIndex { ExampleThemes.theme(named: $0)?.colors.primary.lmk_hexString == primary } ?? 0
    }
}
