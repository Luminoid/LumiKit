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
    private static func content(_ message: String = "Nothing here", icon: String? = "tray", primary: LMKEmptyStateView.Action? = nil) -> LMKEmptyStateView.Content {
        LMKEmptyStateView.Content(message: message, icon: icon.map { .system($0) }, primaryAction: primary)
    }

    @Test
    func `isHorizontal is true only for inline`() {
        #expect(!LMKEmptyStateView.Layout.fullScreen.isHorizontal)
        #expect(!LMKEmptyStateView.Layout.card.isHorizontal)
        #expect(LMKEmptyStateView.Layout.inline.isHorizontal)
    }

    @Test
    func `configure sets text, icon, and the layout's fonts`() {
        let view = LMKEmptyStateView()
        view.configure(LMKEmptyStateView.Content(title: "Empty", message: "Nothing here", icon: .system("tray")))
        #expect(view.layout == .fullScreen)
        #expect(view.titleLabel.text == "Empty")
        #expect(!view.titleLabel.isHidden)
        #expect(view.messageLabel.text == "Nothing here")
        #expect(view.iconView.image != nil)
        #expect(!view.iconView.isHidden)
        #expect(view.titleLabel.lmk_textStyle == .h3)
        #expect(view.messageLabel.lmk_textStyle == .body)
        #expect(view.messageLabel.textColor === LMKColor.textSecondary, "message is secondary under a title")

        let card = LMKEmptyStateView(style: .card)
        card.configure(Self.content(icon: nil))
        #expect(card.iconView.isHidden)
        #expect(card.titleLabel.isHidden)
        #expect(card.messageLabel.lmk_textStyle == .caption)
        #expect(card.messageLabel.textColor === LMKColor.textPrimary)
    }

    @Test
    func `Icons accept images too and the layout picks the icon size`() {
        let view = LMKEmptyStateView(style: .inline)
        view.configure(LMKEmptyStateView.Content(message: "x", icon: .image(UIImage())))
        #expect(view.iconView.image != nil)
        #expect(view.layout == .inline)
        view.style.iconSize = 33
        view.frame = CGRect(x: 0, y: 0, width: 300, height: 60)
        view.layoutIfNeeded()
        #expect(view.iconView.bounds.width == 33)
    }

    @Test
    func `Accessibility is one static element without actions`() {
        let view = LMKEmptyStateView()
        view.configure(LMKEmptyStateView.Content(title: "Empty", message: "Nothing here"))
        #expect(view.isAccessibilityElement)
        #expect(view.accessibilityTraits.contains(.staticText))
        #expect(view.accessibilityLabel == "Empty. Nothing here")
    }
}

// MARK: - LMKEmptyStateView (actions)

@MainActor
struct LMKEmptyStateViewActionTests {
    @Test
    func `A primary action renders a button below the message`() {
        let view = LMKEmptyStateView()
        view.configure(LMKEmptyStateView.Content(message: "Nothing here", icon: .system("tray"), primaryAction: .init(title: "Add") {}))
        #expect(view.actionButton != nil)
        #expect(view.actionButton?.isDescendant(of: view) == true)
        #expect(view.actionButton?.title == "Add")
        #expect(view.secondaryActionButton == nil)
    }

    @Test
    func `Card layout shows both actions and the inline layout shows only the primary`() {
        let card = LMKEmptyStateView(style: .card)
        card.configure(LMKEmptyStateView.Content(message: "x", primaryAction: .init(title: "Add") {}, secondaryAction: .init(title: "Import") {}))
        #expect(card.actionButton != nil)
        #expect(card.secondaryActionButton?.title == "Import")

        let inline = LMKEmptyStateView(style: .inline)
        inline.configure(LMKEmptyStateView.Content(message: "x", primaryAction: .init(title: "Clear") {}, secondaryAction: .init(title: "More") {}))
        #expect(inline.actionButton?.title == "Clear")
        #expect(inline.actionButton?.style.size == .small)
        #expect(inline.secondaryActionButton?.isHidden == true)
        #expect(inline.accessibilityElements?.count == 2, "the hidden secondary is not exposed")

        inline.style.layout = .card
        #expect(inline.secondaryActionButton?.isHidden == false, "a layout change shows it again")
        #expect(inline.actionButton?.style.size == nil)
    }

    @Test
    func `The action buttons survive a theme or style pass with the state the host set`() throws {
        let view = LMKEmptyStateView()
        view.configure(LMKEmptyStateView.Content(message: "x", primaryAction: .init(title: "Add") {}, secondaryAction: .init(title: "Import") {}))
        let button = try #require(view.actionButton)
        let secondary = try #require(view.secondaryActionButton)
        button.isLoading = true
        secondary.isEnabled = false
        view.style.spacing = 20
        view.applyTheme(LMKThemeTesting.distinct)
        #expect(view.actionButton === button, "the same instance, so VoiceOver focus and state hold")
        #expect(view.secondaryActionButton === secondary)
        #expect(button.isLoading)
        #expect(!secondary.isEnabled)
        #expect(button.style.variant == .filled)

        view.configure(LMKEmptyStateView.Content(message: "y", primaryAction: .init(title: "Retry") {}), animated: false)
        #expect(view.actionButton !== button, "configure rebuilds the actions")
        #expect(view.secondaryActionButton == nil)
    }

    @Test
    func `Action handlers fire and icons apply`() {
        var fired = false
        let view = LMKEmptyStateView()
        view.configure(LMKEmptyStateView.Content(message: "x", primaryAction: .init(title: "Add", icon: "plus") { fired = true }))
        view.actionButton?.didTap()
        #expect(fired)
        #expect(view.actionButton?.configuration?.image != nil)
    }

    @Test
    func `Action styles come from the action, then the empty state style`() {
        let view = LMKEmptyStateView(style: LMKEmptyStateView.Style(primaryButton: .outlined(.info)))
        view.configure(LMKEmptyStateView.Content(message: "x", primaryAction: .init(title: "A") {}, secondaryAction: .init(title: "B", style: .tinted(.warning)) {}))
        #expect(view.actionButton?.style.variant == .outlined)
        #expect(view.actionButton?.style.role == .info)
        #expect(view.secondaryActionButton?.style.variant == .tinted)
        #expect(view.secondaryActionButton?.style.role == .warning)
    }

    @Test
    func `The view becomes an accessibility container while an action is present`() {
        let view = LMKEmptyStateView()
        view.configure(LMKEmptyStateView.Content(message: "Nothing here", primaryAction: .init(title: "Add") {}))
        #expect(!view.isAccessibilityElement)
        #expect(view.accessibilityElements?.count == 2)

        view.setAction(nil)
        #expect(view.actionButton == nil)
        #expect(view.isAccessibilityElement)
        #expect(view.accessibilityLabel == "Nothing here")
    }

    @Test
    func `setAction adds and replaces the button post-configure`() {
        let view = LMKEmptyStateView()
        view.configure(LMKEmptyStateView.Content(message: "Nothing here"))
        #expect(view.actionButton == nil)
        view.setAction(.init(title: "Retry") {})
        #expect(view.actionButton?.title == "Retry")
        view.setAction(.init(title: "Add") {})
        #expect(view.actionButton?.title == "Add")
    }

    @Test
    func `asContentUnavailableConfiguration mirrors the content`() {
        let view = LMKEmptyStateView()
        view.configure(LMKEmptyStateView.Content(title: "Empty", message: "Nothing here", icon: .system("tray"), primaryAction: .init(title: "Add") {}, secondaryAction: .init(title: "Import") {}))
        let configuration = view.asContentUnavailableConfiguration()
        #expect(configuration.text == "Empty")
        #expect(configuration.secondaryText == "Nothing here")
        #expect(configuration.image != nil)
        #expect(configuration.button.title == "Add")
        #expect(configuration.secondaryButton.title == "Import")
    }
}

// MARK: - LMKEmptyStateView (sizing)

@MainActor
struct LMKEmptyStateViewSizingTests {
    @Test
    func `The view sizes itself to its content when the host imposes no height`() throws {
        let host = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 600))
        let view = LMKEmptyStateView(style: .card)
        view.translatesAutoresizingMaskIntoConstraints = false
        host.addSubview(view)
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: host.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: host.trailingAnchor),
            view.topAnchor.constraint(equalTo: host.topAnchor),
        ])
        view.configure(LMKEmptyStateView.Content(message: "Nothing here", icon: .system("tray"), primaryAction: .init(title: "Add") {}))
        host.setNeedsLayout()
        host.layoutIfNeeded()

        let button = try #require(view.actionButton)
        let buttonFrame = button.convert(button.bounds, to: view)
        let labelFrame = view.messageLabel.convert(view.messageLabel.bounds, to: view)
        #expect(view.bounds.height > 0)
        #expect(view.bounds.height >= 40, "at least the card icon")
        #expect(buttonFrame.maxY <= view.bounds.height + 0.5)
        #expect(buttonFrame.minY >= labelFrame.maxY)
    }

    @Test
    func `A host-imposed height wins and the content stays centered inside it`() throws {
        let hostHeight: CGFloat = 400
        let host = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: hostHeight))
        let view = LMKEmptyStateView(style: .card)
        view.translatesAutoresizingMaskIntoConstraints = false
        host.addSubview(view)
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: host.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: host.trailingAnchor),
            view.topAnchor.constraint(equalTo: host.topAnchor),
            view.bottomAnchor.constraint(equalTo: host.bottomAnchor),
        ])
        view.configure(LMKEmptyStateView.Content(message: "Nothing here", icon: .system("tray"), primaryAction: .init(title: "Add") {}))
        host.setNeedsLayout()
        host.layoutIfNeeded()

        let button = try #require(view.actionButton)
        let container = try #require(button.superview?.superview)
        #expect(abs(view.bounds.height - hostHeight) < 0.5)
        #expect(container.bounds.height < hostHeight)
        let topGap = container.frame.minY
        let bottomGap = view.bounds.height - container.frame.maxY
        #expect(abs(topGap - bottomGap) < 1)
        #expect(topGap > 0)
    }

    @Test
    func `Content insets hold when the message wraps`() {
        let view = LMKEmptyStateView(style: .card)
        view.frame = CGRect(x: 0, y: 0, width: 220, height: 400)
        let message = String(repeating: "A long message that wraps onto several lines. ", count: 3)
        view.configure(LMKEmptyStateView.Content(message: message, icon: .system("tray")), animated: false)
        view.setNeedsLayout()
        view.layoutIfNeeded()
        let inset = LMKSpacing.large
        let labelFrame = view.messageLabel.convert(view.messageLabel.bounds, to: view)
        #expect(labelFrame.height > view.messageLabel.font.lineHeight * 2, "the message wraps")
        #expect(labelFrame.minX >= inset - 0.5, "the wrapped label keeps the card's leading inset")
        #expect(labelFrame.maxX <= 220 - inset + 0.5, "and the trailing one")

        view.style.surface.contentInsets = NSDirectionalEdgeInsets(top: 4, leading: 30, bottom: 4, trailing: 10)
        view.setNeedsLayout()
        view.layoutIfNeeded()
        let asymmetric = view.messageLabel.convert(view.messageLabel.bounds, to: view)
        #expect(asymmetric.minX >= 30 - 0.5)
        #expect(asymmetric.maxX <= 220 - 10 + 0.5)
    }

    @Test
    func `wrappedForTableBackground fills a container in the background color`() {
        let view = LMKEmptyStateView(style: .card)
        view.configure(LMKEmptyStateView.Content(message: "Nothing"), animated: false)
        let container = view.wrappedForTableBackground(backgroundColor: .red)
        container.frame = CGRect(x: 0, y: 0, width: 300, height: 500)
        container.layoutIfNeeded()
        #expect(view.superview === container)
        #expect(container.backgroundColor == UIColor.red)
        #expect(view.frame == container.bounds)
        #expect(LMKEmptyStateView().wrappedForTableBackground().backgroundColor === LMKColor.backgroundPrimary)
    }

    @Test
    func `A long message never overlaps the action button`() throws {
        let view = LMKEmptyStateView(frame: CGRect(x: 0, y: 0, width: 320, height: 600))
        let message = String(repeating: "A fairly long empty state explanation sentence. ", count: 6)
        view.configure(LMKEmptyStateView.Content(message: message, icon: .system("tray"), primaryAction: .init(title: "Add something") {}))
        view.setNeedsLayout()
        view.layoutIfNeeded()

        let button = try #require(view.actionButton)
        let buttonFrame = button.convert(button.bounds, to: view)
        let labelFrame = view.messageLabel.convert(view.messageLabel.bounds, to: view)
        #expect(labelFrame.height > 0)
        #expect(buttonFrame.minY >= labelFrame.maxY)
    }
}
