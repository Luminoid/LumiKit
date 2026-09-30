//
//  LMKListRowContentViewSizingTests.swift
//  LumiKit
//
//  A table asks a content view for its fitting size with an expanded target;
//  the row once answered with an unbounded height, which UIKit's content-view
//  assertion turns into a crash (found by the Example sweep).
//

import Testing
import UIKit
@testable import LumiKitUI

@MainActor
struct LMKListRowContentViewSizingTests {
    @Test
    func `Fitting sizes are finite for compressed and expanded targets and floor at the row height`() {
        let view = LMKListRowContentView(configuration: LMKListRowConfiguration(title: "General", subtitle: "Two lines of text", trailing: .disclosure))
        let expanded = view.systemLayoutSizeFitting(
            CGSize(width: 330, height: UIView.layoutFittingExpandedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
        #expect(expanded.height.isFinite)
        #expect(expanded.height < 1000)
        #expect(expanded.height >= LMKTheme.default.layout.rowHeightCompact)

        let compressed = view.systemLayoutSizeFitting(
            CGSize(width: 330, height: 0),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
        #expect(abs(compressed.height - expanded.height) < 0.5, "the same answer for either target")

        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        cell.lmk_applyListRow(LMKListRowConfiguration(title: "Cell", trailing: .checkmark))
        let cellSize = cell.systemLayoutSizeFitting(
            CGSize(width: 330, height: UIView.layoutFittingExpandedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
        #expect(cellSize.height.isFinite)
        #expect(cellSize.height >= LMKTheme.default.layout.rowHeightCompact)
    }

    private static func fittingHeight(_ configuration: LMKListRowConfiguration, width: CGFloat = 330) -> CGFloat {
        LMKListRowContentView(configuration: configuration).systemLayoutSizeFitting(
            CGSize(width: width, height: UIView.layoutFittingExpandedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        ).height
    }

    @Test
    func `The vertical insets pad the content: an icon or two text lines never touch the row edges`() {
        let theme = LMKTheme.default
        let padding = theme.spacing.small * 2

        // A title alone fits the compact row.
        #expect(Self.fittingHeight(LMKListRowConfiguration(title: "General")) == theme.layout.rowHeightCompact)

        // The symbol circle keeps the insets above and below it.
        let symbol = Self.fittingHeight(LMKListRowConfiguration(title: "General", leading: .symbol("gearshape")))
        #expect(symbol == theme.layout.iconCircle + padding)

        // So do a title and a subtitle.
        let view = LMKListRowContentView(configuration: LMKListRowConfiguration(title: "General", subtitle: "Language, appearance, units"))
        LMKThemeTesting.fit(view, width: 330)
        #expect(abs(view.textStack.frame.minY - theme.spacing.small) < 0.5)
        #expect(abs(view.bounds.maxY - view.textStack.frame.maxY - theme.spacing.small) < 0.5)
    }

    @Test
    func `Custom insets and a zero minimum height size the row to its content`() {
        let style = LMKListRowConfiguration.Style(contentInsets: .lmk_all(0), minimumHeight: 0)
        let bare = Self.fittingHeight(LMKListRowConfiguration(title: "General", leading: .symbol("gearshape"), style: style))
        #expect(bare == LMKTheme.default.layout.iconCircle)

        let uneven = LMKListRowConfiguration.Style(contentInsets: NSDirectionalEdgeInsets(top: 4, leading: 16, bottom: 20, trailing: 16), minimumHeight: 0)
        let view = LMKListRowContentView(configuration: LMKListRowConfiguration(title: "General", leading: .symbol("gearshape"), style: uneven))
        LMKThemeTesting.fit(view, width: 330)
        #expect(abs(view.leadingContainer.frame.minY - 4) < 0.5)
        #expect(abs(view.bounds.maxY - view.leadingContainer.frame.maxY - 20) < 0.5)
    }
}
