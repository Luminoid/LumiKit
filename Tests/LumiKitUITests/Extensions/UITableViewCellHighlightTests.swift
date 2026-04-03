//
//  UITableViewCellHighlightTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

// MARK: - UITableViewCell+LMKHighlight

@MainActor
struct UITableViewCellHighlightTests {
    @Test
    func `lmk_configureCustomHighlight sets selectedBackgroundView`() {
        let cell = UITableViewCell()
        cell.lmk_configureCustomHighlight()

        #expect(cell.selectedBackgroundView != nil)
        #expect(cell.selectedBackgroundView?.backgroundColor != nil)
    }

    @Test
    func `lmk_applyCustomHighlight with no containers changes contentView background`() {
        let cell = UITableViewCell()

        cell.lmk_applyCustomHighlight(highlighted: true, animated: false)
        #expect(cell.contentView.backgroundColor != nil)
        #expect(cell.contentView.backgroundColor != .clear)

        cell.lmk_applyCustomHighlight(highlighted: false, animated: false)
        #expect(cell.contentView.backgroundColor == .clear)
    }

    @Test
    func `lmk_applyCustomHighlight with container adds overlay`() {
        let cell = UITableViewCell()

        // Create a container-like subview (has background, corner radius)
        let container = UIView()
        container.backgroundColor = .systemBlue
        container.layer.cornerRadius = 12
        cell.contentView.addSubview(container)

        cell.lmk_applyCustomHighlight(highlighted: true, animated: false)

        // Container should have an overlay subview
        let overlay = container.subviews.first(where: { $0 !== container && $0.backgroundColor != nil && $0.backgroundColor != .clear })
        #expect(overlay != nil)
    }

    @Test
    func `lmk_applyCustomHighlight removes overlay on unhighlight`() {
        let cell = UITableViewCell()

        let container = UIView()
        container.backgroundColor = .systemBlue
        container.layer.cornerRadius = 12
        cell.contentView.addSubview(container)

        cell.lmk_applyCustomHighlight(highlighted: true, animated: false)
        let overlay = container.subviews.first(where: { $0.backgroundColor != nil && $0.backgroundColor != .clear })
        #expect(overlay != nil)

        cell.lmk_applyCustomHighlight(highlighted: false, animated: false)
        let overlayAfter = container.subviews.first(where: { $0.backgroundColor != nil && $0.backgroundColor != .clear })
        #expect(overlayAfter == nil)
    }

    @Test
    func `lmk_applyCustomHighlight skips labels and buttons in container detection`() {
        let cell = UITableViewCell()

        // Add a label with background — should NOT be treated as container
        let label = UILabel()
        label.backgroundColor = .systemRed
        label.layer.cornerRadius = 8
        cell.contentView.addSubview(label)

        cell.lmk_applyCustomHighlight(highlighted: true, animated: false)

        // Label should not have an overlay
        #expect(label.viewWithTag(9999) == nil)
        // Instead, contentView background should be set
        #expect(cell.contentView.backgroundColor != nil)
        #expect(cell.contentView.backgroundColor != .clear)
    }

    @Test
    func `UITableView lmk_configureCellHighlight configures the cell`() {
        let tableView = UITableView()
        let cell = UITableViewCell()
        tableView.lmk_configureCellHighlight(cell)

        #expect(cell.selectedBackgroundView != nil)
    }
}
