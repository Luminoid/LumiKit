//
//  LMKDetailCardHeaderLayoutTests.swift
//  LumiKit
//
//  The header title once wrapped in a narrow column beside free space and, at
//  accessibility sizes, got a single line of height (found by the Example sweep).
//

import LumiKitCore
import Testing
import UIKit
@testable import LumiKitUI

@MainActor
struct LMKDetailCardHeaderLayoutTests {
    private func makeCard() -> LMKDetailCard {
        LMKDetailCard(id: "c", header: .init(
            icon: .symbol("leaf.fill", tint: .green),
            title: "Monstera deliciosa",
            subtitles: ["Swiss cheese plant", "Araceae"],
            trailing: [.button(systemName: "book", accessibilityLabel: "Wikipedia") {}],
            isCopyable: true
        ))
    }

    @Test
    func `The title column takes the width the trailing items leave`() {
        let view = LMKDetailCardView(card: makeCard())
        LMKThemeTesting.fit(view, width: 352)
        let trailing = view.headerTrailingStack.bounds.width
        let column = view.titleLabel.bounds.width
        let members = view.headerTrailingStack.arrangedSubviews.map { "\(type(of: $0)) \($0.bounds.width) hidden=\($0.isHidden)" }
        #expect(trailing < 60, "one glyph button: \(trailing), members \(members), spacing \(view.headerTrailingStack.spacing)")
        #expect(column > 200, "the title column is \(column), trailing \(trailing)")
        #expect(view.titleLabel.bounds.height < view.titleLabel.font.lineHeight * 1.5, "one line at the default size")
    }

    @Test
    func `At accessibility sizes the title wraps instead of truncating`() {
        let view = LMKDetailCardView(card: makeCard())
        view.traitOverrides.preferredContentSizeCategory = .accessibilityExtraExtraExtraLarge
        LMKThemeTesting.fit(view, width: 352)
        let label = view.titleLabel
        let needed = label.sizeThatFits(CGSize(width: label.bounds.width, height: .greatestFiniteMagnitude)).height
        #expect(label.bounds.height >= needed - 1, "needs \(needed), has \(label.bounds.height)")
    }
}
