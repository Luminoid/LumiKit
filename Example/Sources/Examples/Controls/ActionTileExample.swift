//
//  ActionTileExample.swift
//  LumiKitExample
//
//  Action Tile: LMKActionTile grid with counts and accent colors.
//

import LumiKitUI
import SnapKit
import UIKit

// MARK: - Action Tile

final class ActionTileDetailViewController: DetailViewController {
    override func setupStackContent() {
        addSectionHeader("LMKActionTile")
        stackView.addArrangedSubview(UILabel.lmk_make(
            .caption,
            text: "Icon-over-label tiles for action grids. A count reads inline (\"Expenses · 3\"). "
                + "An accent tints the background lightly and the glyph fully; a locked accent (Emergency) ignores the theme accent."
        ))

        let tiles: [(String, String, Int?)] = [
            ("Health", "heart.text.square", nil),
            ("Weight", "scalemass", 12),
            ("Vet", "cross.case", 2),
            ("Photos", "photo.on.rectangle", 48),
            ("Expenses", "creditcard", 3),
            ("Emergency", "exclamationmark.triangle", nil),
        ]
        var made: [LMKActionTile] = []
        for (title, symbol, count) in tiles {
            let tile = LMKActionTile()
            tile.configure(title: title, systemName: symbol, count: count)
            tile.onTap = { [weak self] in
                guard let self else { return }
                LMKToast.show(.info, "\(title) tapped", in: self)
            }
            tile.snp.makeConstraints { make in
                make.height.greaterThanOrEqualTo(LMKLayout.rowHeightComfortable + LMKSpacing.small)
            }
            made.append(tile)
        }
        made.last?.lockedAccentColor = LMKColor.error
        made[4].isEnabled = false

        let grid = UIStackView(lmk_axis: .vertical, spacing: LMKSpacing.medium, arrangedSubviews: stride(from: 0, to: made.count, by: 3).map { start in
            UIStackView(lmk_axis: .horizontal, spacing: LMKSpacing.medium, distribution: .fillEqually, arrangedSubviews: Array(made[start ..< min(start + 3, made.count)]))
        })
        stackView.addArrangedSubview(grid)

        addDivider()
        addSectionHeader("Accent color")
        stackView.addArrangedSubview(UILabel.lmk_make(
            .caption,
            text: "Pick an accent. Light accents darken for the glyph (UIColor.lmk_glyphTint) so they stay legible; the Emergency tile keeps its locked red."
        ))
        let accents: [(String, UIColor?)] = [("Default", nil), ("Teal", UIColor(lmk_hex: 0x1E88A8)), ("Yellow", UIColor(lmk_hex: 0xF2D16B)), ("Purple", UIColor(lmk_hex: 0x6D4AB8))]
        let control = LMKSegmentedControl(items: accents.map(\.0))
        control.onValueChange = { index in
            for tile in made {
                tile.accentColor = accents[index].1
            }
        }
        stackView.addArrangedSubview(control)
    }
}
