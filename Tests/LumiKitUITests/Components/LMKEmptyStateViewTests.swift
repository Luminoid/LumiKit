//
//  LMKEmptyStateViewTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

// MARK: - LMKEmptyStateView

@MainActor
struct LMKEmptyStateViewTests {
    @Test
    func `font property returns correct font per style`() {
        #expect(LMKEmptyStateStyle.fullScreen.font == LMKTypography.h3)
        #expect(LMKEmptyStateStyle.card.font == LMKTypography.body)
        #expect(LMKEmptyStateStyle.inline.font == LMKTypography.caption)
    }

    @Test
    func `isHorizontal is true only for inline`() {
        #expect(!LMKEmptyStateStyle.fullScreen.isHorizontal)
        #expect(!LMKEmptyStateStyle.card.isHorizontal)
        #expect(LMKEmptyStateStyle.inline.isHorizontal)
    }

    @Test
    func `iconSize is positive and ordered by style`() {
        #expect(LMKEmptyStateStyle.inline.iconSize < LMKEmptyStateStyle.card.iconSize)
        #expect(LMKEmptyStateStyle.card.iconSize < LMKEmptyStateStyle.fullScreen.iconSize)
    }
}

// MARK: - LMKEmptyStateView (action button)

@MainActor
struct LMKEmptyStateViewActionTests {
    @Test
    func `configure with action renders a button below the message`() {
        let view = LMKEmptyStateView()
        view.configure(message: "Nothing here", icon: "tray", style: .fullScreen, action: .init(title: "Add") {})

        #expect(view.actionButton != nil)
        #expect(view.actionButton?.isDescendant(of: view) == true)
        #expect(view.actionButton?.configuration?.title == "Add")
    }

    @Test
    func `card style shows the action too`() {
        let view = LMKEmptyStateView()
        view.configure(message: "Nothing here", style: .card, action: .init(title: "Add") {})

        #expect(view.actionButton != nil)
    }

    @Test
    func `action handler fires on tap`() {
        var fired = false
        let view = LMKEmptyStateView()
        view.configure(message: "Nothing here", action: .init(title: "Add") { fired = true })

        view.actionButton?.didTap()

        #expect(fired)
    }

    @Test
    func `action icon is applied as a leading image`() {
        let view = LMKEmptyStateView()
        view.configure(message: "Nothing here", action: .init(title: "Add", icon: "plus") {})

        #expect(view.actionButton?.configuration?.image != nil)
        #expect(view.actionButton?.configuration?.imagePlacement == .leading)
    }

    @Test
    func `view becomes an accessibility container while an action is present`() {
        let view = LMKEmptyStateView()
        view.configure(message: "Nothing here", action: .init(title: "Add") {})

        #expect(!view.isAccessibilityElement)

        view.setAction(nil)

        #expect(view.actionButton == nil)
        #expect(view.isAccessibilityElement)
        #expect(view.accessibilityTraits.contains(.staticText))
        #expect(view.accessibilityLabel == "Nothing here")
    }

    @Test
    func `setAction adds and replaces the button post-configure`() {
        let view = LMKEmptyStateView()
        view.configure(message: "Nothing here")
        #expect(view.actionButton == nil)

        view.setAction(.init(title: "Retry") {})
        #expect(view.actionButton?.configuration?.title == "Retry")

        view.setAction(.init(title: "Add") {})
        #expect(view.actionButton?.configuration?.title == "Add")
    }

    @Test
    func `inline style ignores the action`() {
        let view = LMKEmptyStateView()
        view.configure(message: "Nothing", icon: "tray", style: .inline, action: .init(title: "Add") {})

        #expect(view.actionButton == nil)
        #expect(view.isAccessibilityElement)
    }

    @Test
    func `view sizes itself to its content when the host imposes no height`() throws {
        let host = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 600))
        let view = LMKEmptyStateView()
        view.translatesAutoresizingMaskIntoConstraints = false
        host.addSubview(view)
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: host.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: host.trailingAnchor),
            view.topAnchor.constraint(equalTo: host.topAnchor),
        ])
        view.configure(message: "Nothing here", icon: "tray", style: .card, action: .init(title: "Add") {})
        host.setNeedsLayout()
        host.layoutIfNeeded()

        let button = try #require(view.actionButton)
        let container = try #require(button.superview)

        // Without a host height the edge-hugging constraints give the view its
        // container's content height — a zero-height view here means the
        // centered content spills over whatever sits next to it.
        #expect(container.bounds.height > 0)
        #expect(abs(view.bounds.height - container.bounds.height) < 0.5)
        #expect(view.bounds.height >= LMKEmptyStateStyle.card.iconSize)
    }

    @Test
    func `host-imposed height wins and the content stays centered inside it`() throws {
        let hostHeight: CGFloat = 400
        let host = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: hostHeight))
        let view = LMKEmptyStateView()
        view.translatesAutoresizingMaskIntoConstraints = false
        host.addSubview(view)
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: host.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: host.trailingAnchor),
            view.topAnchor.constraint(equalTo: host.topAnchor),
            view.bottomAnchor.constraint(equalTo: host.bottomAnchor),
        ])
        view.configure(message: "Nothing here", icon: "tray", style: .card, action: .init(title: "Add") {})
        host.setNeedsLayout()
        host.layoutIfNeeded()

        let button = try #require(view.actionButton)
        let container = try #require(button.superview)

        #expect(abs(view.bounds.height - hostHeight) < 0.5)
        #expect(container.bounds.height < hostHeight)
        // Centered: equal free space above and below the content container.
        let topGap = container.frame.minY
        let bottomGap = view.bounds.height - container.frame.maxY
        #expect(abs(topGap - bottomGap) < 1)
        #expect(topGap > 0)
    }

    @Test
    func `long multi-line message never overlaps the action button`() throws {
        let view = LMKEmptyStateView(frame: CGRect(x: 0, y: 0, width: 320, height: 600))
        let message = String(repeating: "A fairly long empty state explanation sentence. ", count: 6)
        view.configure(message: message, icon: "tray", style: .fullScreen, action: .init(title: "Add something") {})
        view.setNeedsLayout()
        view.layoutIfNeeded()

        let button = try #require(view.actionButton)
        let container = try #require(button.superview)
        let label = try #require(container.subviews.compactMap { $0 as? UILabel }.first)

        // The button sits strictly below the message at every content size —
        // both are members of one vertical constraint chain.
        #expect(label.frame.height > 0)
        #expect(button.frame.minY >= label.frame.maxY)
        // The button's bottom closes the container, so the container's height
        // is content-driven and grows with the message.
        #expect(abs(container.bounds.height - button.frame.maxY) < 0.5)
    }
}
