//
//  TypographyExample.swift
//  LumiKitExample
//
//  Typography: LMKTextStyle headings, body, captions, Dynamic Type.
//

import LumiKitUI
import UIKit

// MARK: - Typography

final class TypographyDetailViewController: DetailViewController {
    override func setupStackContent() {
        addSectionHeader("Headings")
        stackView.addArrangedSubview(UILabel.lmk_make(.h1, text: "Heading 1"))
        stackView.addArrangedSubview(UILabel.lmk_make(.h2, text: "Heading 2"))
        stackView.addArrangedSubview(UILabel.lmk_make(.h3, text: "Heading 3"))
        stackView.addArrangedSubview(UILabel.lmk_make(.h4, text: "Heading 4"))

        addDivider()
        addSectionHeader("Body Styles")
        stackView.addArrangedSubview(UILabel.lmk_make(.body, text: "Body: the quick brown fox jumps over the lazy dog. This is the default paragraph style used for content."))
        stackView.addArrangedSubview(UILabel.lmk_make(.caption, text: "Caption: used for secondary information and metadata"))
        stackView.addArrangedSubview(UILabel.lmk_make(.small, text: "Small: fine print and tertiary details"))

        addDivider()
        addSectionHeader("Special")
        stackView.addArrangedSubview(UILabel.lmk_make(.italicBody, text: "Monstera deliciosa", color: LMKColor.info))
        stackView.addArrangedSubview(UILabel.lmk_make(.italicBody, text: "Epipremnum aureum", color: LMKColor.info))
    }
}
