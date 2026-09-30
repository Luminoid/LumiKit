//
//  DividerExample.swift
//  LumiKitExample
//
//  Divider: Hairline separators, horizontal and vertical.
//

import LumiKitUI
import SnapKit
import UIKit

// MARK: - Divider

final class DividerDetailViewController: DetailViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        addSectionHeader("Horizontal")
        stack.addArrangedSubview(UILabel.lmk_make(.caption, text: "Pixel-perfect separator between content sections:"))
        stack.addArrangedSubview(LMKDividerView())
        stack.addArrangedSubview(UILabel.lmk_make(.caption, text: "Content continues here"))
    }
}
