//
//  UICollectionViewCellHighlightTests.swift
//  LumiKit
//
//  Mirrors UITableViewCellHighlightTests for the UICollectionViewCell path
//  added when `lmk_applyCustomHighlight` was lifted onto the
//  `LMKHighlightable` protocol.
//

import Testing
import UIKit
@testable import LumiKitUI

@MainActor
struct UICollectionViewCellHighlightTests {
    private func makeCell() -> UICollectionViewCell {
        // Lay out the cell so contentView has a non-zero frame — the overlay
        // SnapKit constraints need a parent size to attach to.
        let cell = UICollectionViewCell(frame: CGRect(x: 0, y: 0, width: 100, height: 44))
        cell.layoutIfNeeded()
        return cell
    }

    @Test
    func `lmk_applyCustomHighlight with no containers changes contentView background`() {
        let cell = makeCell()

        cell.lmk_applyCustomHighlight(highlighted: true, animated: false)
        #expect(cell.contentView.backgroundColor != nil)
        #expect(cell.contentView.backgroundColor != .clear)

        cell.lmk_applyCustomHighlight(highlighted: false, animated: false)
        #expect(cell.contentView.backgroundColor == .clear)
    }

    @Test
    func `lmk_applyCustomHighlight with container adds overlay`() {
        let cell = makeCell()

        let container = UIView()
        container.backgroundColor = .systemBlue
        container.layer.cornerRadius = 12
        cell.contentView.addSubview(container)

        cell.lmk_applyCustomHighlight(highlighted: true, animated: false)

        let overlay = container.subviews.first { $0.backgroundColor != nil && $0.backgroundColor != .clear }
        #expect(overlay != nil)
    }

    @Test
    func `lmk_applyCustomHighlight removes overlay on unhighlight`() {
        let cell = makeCell()

        let container = UIView()
        container.backgroundColor = .systemBlue
        container.layer.cornerRadius = 12
        cell.contentView.addSubview(container)

        cell.lmk_applyCustomHighlight(highlighted: true, animated: false)
        #expect(container.subviews.contains { $0.backgroundColor != nil && $0.backgroundColor != .clear })

        cell.lmk_applyCustomHighlight(highlighted: false, animated: false)
        #expect(!container.subviews.contains { $0.backgroundColor != nil && $0.backgroundColor != .clear })
    }
}
