//
//  LMKDetailCardViewTests.swift
//  LumiKit
//

import LumiKitCore
import Testing
import UIKit
@testable import LumiKitUI

@MainActor
struct LMKDetailCardViewTests {
    private func makeView(_ card: LMKDetailCard, style: LMKDetailCardView.Style = LMKDetailCardView.Style(), width: CGFloat = 375) -> LMKDetailCardView {
        let view = LMKDetailCardView(card: card, style: style)
        LMKThemeTesting.fit(view, width: width)
        return view
    }

    private func rowView<T>(_ view: LMKDetailCardView, _ id: String, as _: T.Type) throws -> T {
        try #require(view.view(forRowID: id) as? T)
    }

    // MARK: - Header

    @Test
    func `Header renders icon, title, subtitles, trailing items, loading, tap, and copy`() throws {
        var taps = 0
        var trailingTaps = 0
        let card = LMKDetailCard(id: "c", header: .init(
            icon: .symbol("leaf.fill", tint: .green),
            title: "Monstera",
            subtitles: ["Swiss cheese plant", "Araceae"],
            trailing: [.button(systemName: "book", accessibilityLabel: "Wiki") { trailingTaps += 1 }, .badge(.count(4)), .text("3 items")],
            isLoading: true,
            isCopyable: true,
            onTap: { taps += 1 }
        ))
        let view = makeView(card)
        #expect(view.headerView.isHidden == false)
        #expect(view.headerIconView.image == UIImage(systemName: "leaf.fill"))
        #expect(view.headerIconView.tintColor == UIColor.green)
        #expect(view.headerIconContainer.frame.width == LMKLayout.iconMedium)
        #expect(view.titleLabel.text == "Monstera")
        #expect(view.titleLabel.font == LMKTypography.font(for: .h3, compatibleWith: view.traitCollection))
        #expect(view.titleLabel.isCopyEnabled)
        #expect(view.titleLabel.accessibilityTraits.contains(.header) && view.titleLabel.accessibilityTraits.contains(.button))
        #expect(view.subtitleLabels.filter { !$0.isHidden }.map(\.text) == ["Swiss cheese plant", "Araceae"])
        let trailing = view.headerTrailingStack.arrangedSubviews
        #expect(trailing.count == 4, "three items plus the loading indicator")
        let wiki = try #require(trailing[0] as? LMKButton)
        #expect(wiki.accessibilityLabel == "Wiki")
        wiki.onTap?()
        #expect(trailingTaps == 1)
        #expect((trailing[1] as? LMKBadgeView)?.countLabel.text == "4")
        #expect((trailing[2] as? UILabel)?.text == "3 items")
        #expect(view.loadingIndicator.isAnimating)
        view.setHeaderLoading(false)
        #expect(!view.loadingIndicator.isAnimating)
        #expect(view.card?.header?.isLoading == false)
        view.perform(NSSelectorFromString("handleHeaderTap"))
        #expect(taps == 1)

        let plain = makeView(LMKDetailCard(id: "p", title: "Plain"))
        #expect(plain.headerIconContainer.isHidden)
        #expect(plain.headerTrailingStack.isHidden)
        #expect(plain.titleLabel.isCopyEnabled == false)
        #expect(plain.subtitleLabels.filter { !$0.isHidden }.isEmpty)
        let headless = makeView(LMKDetailCard(id: "h", rows: [.text(.init(id: "t", text: "x"))]))
        #expect(headless.headerView.isHidden)
    }

    @Test
    func `Header icon in a circle uses the icon circle size and a tinted fill`() {
        let view = makeView(LMKDetailCard(id: "c", header: .init(icon: .symbol("drop.fill"), title: "Care")), style: LMKDetailCardView.Style(headerIconInCircle: true))
        #expect(view.headerIconContainer.frame.width == LMKLayout.iconCircle)
        #expect(view.headerIconContainer.backgroundColor == LMKColor.primary.withAlphaComponent(LMKAlpha.xxs))
        #expect(view.headerIconView.frame.width == LMKLayout.iconMedium)
    }

    // MARK: - Rows

    @Test
    func `Key/value rows: stacked by default, inline on request, one VoiceOver element, copy action`() throws {
        var taps = 0
        let card = LMKDetailCard(id: "c", rows: [
            .keyValue(.init(id: "phone", key: "Phone", value: "555-0100", isCopyable: true, copyText: "5550100")),
            .keyValue(.init(id: "status", key: "Status", value: "Overdue", layout: .inline, valueColor: .red, description: "Water soon", onTap: { taps += 1 })),
        ])
        let view = makeView(card)
        let stacked = try rowView(view, "phone", as: LMKDetailKeyValueRowView.self)
        #expect(stacked.pairStack.axis == .vertical)
        #expect(stacked.keyLabel.text == "Phone")
        #expect(stacked.keyLabel.font == LMKTypography.font(for: .captionMedium, compatibleWith: view.traitCollection))
        #expect(stacked.keyLabel.textColor == LMKColor.textSecondary)
        #expect(stacked.valueLabel.text == "555-0100")
        #expect(stacked.valueLabel.textColor == LMKColor.textPrimary)
        #expect(stacked.valueLabel.isCopyEnabled)
        #expect(stacked.valueLabel.copyableText == "5550100")
        #expect(stacked.isAccessibilityElement)
        #expect(stacked.accessibilityLabel == "Phone")
        #expect(stacked.accessibilityValue == "555-0100")
        #expect(stacked.accessibilityTraits == .staticText)
        #expect(stacked.accessibilityCustomActions?.count == 1)
        #expect(stacked.descriptionLabel.isHidden)

        let inline = try rowView(view, "status", as: LMKDetailKeyValueRowView.self)
        #expect(inline.pairStack.axis == .horizontal)
        #expect(inline.keyLabel.font == LMKTypography.font(for: .subbodyMedium, compatibleWith: view.traitCollection))
        #expect(inline.valueLabel.textColor == UIColor.red)
        #expect(inline.valueLabel.textAlignment == .right)
        #expect(inline.valueLabel.frame.minX > inline.keyLabel.frame.maxX)
        #expect(inline.descriptionLabel.text == "Water soon")
        #expect(inline.accessibilityValue == "Overdue, Water soon")
        #expect(inline.accessibilityTraits == .button)
        #expect(inline.accessibilityCustomActions == nil)
        inline.perform(NSSelectorFromString("handleTap"))
        #expect(taps == 1)
    }

    @Test
    func `setValue and update change a row in place without replacing its view`() throws {
        let view = makeView(LMKDetailCard(id: "c", rows: [.keyValue(.init(id: "next", key: "Next", value: "Today"))]))
        let before = try rowView(view, "next", as: LMKDetailKeyValueRowView.self)
        #expect(view.setValue("Tomorrow", color: .orange, forRowID: "next"))
        let after = try rowView(view, "next", as: LMKDetailKeyValueRowView.self)
        #expect(before === after)
        #expect(after.valueLabel.text == "Tomorrow")
        #expect(after.valueLabel.textColor == UIColor.orange)
        if case let .keyValue(model)? = view.card?.row(id: "next") {
            #expect(model.value == "Tomorrow")
        } else {
            Issue.record("row missing")
        }
        #expect(!view.setValue("x", forRowID: "missing"))
        let changed = view.update(rowID: "next") { row in row = .text(.init(id: "next", text: "Now text")) }
        #expect(changed)
        #expect(view.view(forRowID: "next") is LMKDetailTextRowView, "a kind change rebuilds the row view")
    }

    @Test
    func `Text, chips, progress, rating, divider, and custom rows render their content`() throws {
        let custom = UIView()
        var chipTaps = 0
        var ratings: [Int] = []
        let card = LMKDetailCard(id: "c", rows: [
            .text(.init(id: "notes", title: "Notes", content: .markdown("**Bold** note"))),
            .chips(.init(id: "tags", items: [.init(id: "a", text: "Sunny", tint: .orange) { chipTaps += 1 }, .init(id: "b", text: "Humid")])),
            .progress(.init(id: "p", title: "Next watering", value: 0.25, detail: "3 days")),
            .rating(.init(id: "r", title: "Rating", value: 3, onChange: { ratings.append($0) })),
            .divider(id: "d"),
            .custom(id: "map", custom),
        ])
        let view = makeView(card)
        let text = try rowView(view, "notes", as: LMKDetailTextRowView.self)
        #expect(text.titleLabel.text == "Notes")
        #expect(text.textLabel.attributedText?.string == "Bold note")
        let chips = try rowView(view, "tags", as: LMKDetailChipsRowView.self)
        #expect(chips.chips.map(\.text) == ["Sunny", "Humid"])
        #expect(chips.chips[0].style.tintColor == UIColor.orange)
        chips.chips[0].onTap?()
        #expect(chipTaps == 1)
        let progress = try rowView(view, "p", as: LMKDetailProgressRowView.self)
        #expect(progress.titleLabel.text == "Next watering")
        #expect(progress.detailLabel.text == "3 days")
        #expect(progress.value == 0.25)
        #expect(abs(progress.barView.frame.width - progress.trackView.frame.width * 0.25) < 1)
        #expect(progress.trackView.frame.height == LMKSpacing.small)
        #expect(progress.accessibilityLabel == "Next watering")
        #expect(progress.accessibilityValue == "3 days")
        let rating = try rowView(view, "r", as: LMKDetailRatingRowView.self)
        #expect(rating.ratingControl.value == 3)
        #expect(rating.ratingControl.isInteractive)
        rating.ratingControl.onChange?(5)
        #expect(ratings == [5])
        #expect(view.view(forRowID: "d") is LMKDetailDividerRowView)
        #expect(custom.superview === view.view(forRowID: "map"))
        #expect(view.rowsStack.arrangedSubviews.count == 6)
    }

    @Test
    func `Row dividers are inserted between rows when the style asks`() {
        let card = LMKDetailCard(id: "c", rows: [.text(.init(id: "a", text: "A")), .text(.init(id: "b", text: "B")), .text(.init(id: "c", text: "C"))])
        let view = makeView(card, style: LMKDetailCardView.Style(showsRowDividers: true))
        #expect(view.rowsStack.arrangedSubviews.count == 5)
        #expect(view.rowsStack.arrangedSubviews[1] is LMKDividerView)
        #expect(view.rowsStack.spacing == LMKSpacing.medium)
    }

    @Test
    func `Navigation and link rows: one element each, chevron forced, remove button, opening`() throws {
        var navigated = 0
        var opened = 0
        var removed = 0
        let card = LMKDetailCard(id: "c", rows: [
            .navigation(.init(id: "journal", title: "Care journal", subtitle: "12 entries", systemName: "book", detail: "12") { navigated += 1 }),
            .link(.init(id: "site", title: "Care guide", subtitle: "example.com", url: URL(string: "https://example.com"), icon: .symbol("link"), onOpen: { opened += 1 }, onRemove: { removed += 1 })),
            .link(.init(id: "plain", title: "Plain", url: URL(string: "https://example.com"))),
        ])
        let view = makeView(card, style: LMKDetailCardView.Style(navigationRowSurface: LMKSurfaceStyle(background: .solid(.yellow), corners: .fixed(6)), underlinesLinks: true))
        let navigation = try rowView(view, "journal", as: LMKDetailNavigationRowView.self)
        let content = try #require(navigation.contentView)
        #expect(content.current.title == "Care journal")
        #expect(content.current.detail == "12")
        if case .disclosure = content.current.trailing {} else { Issue.record("trailing must be a disclosure") }
        #expect(content.isAccessibilityElement)
        #expect(navigation.isAccessibilityElement == false)
        #expect(navigation.backgroundColor == UIColor.yellow)
        #expect(navigation.layer.cornerRadius == 6)
        navigation.perform(NSSelectorFromString("handleTap"))
        #expect(navigated == 1)

        let link = try rowView(view, "site", as: LMKDetailLinkRowView.self)
        #expect(link.titleLabel.attributedText?.string == "Care guide")
        #expect(link.titleLabel.attributedText?.attribute(.underlineStyle, at: 0, effectiveRange: nil) as? Int == NSUnderlineStyle.single.rawValue)
        #expect(link.subtitleLabel.text == "example.com")
        #expect(link.iconView.isHidden == false)
        #expect(link.removeButton.isHidden == false)
        #expect(link.removeButton.accessibilityLabel == "Remove link")
        #expect(link.openControl.accessibilityTraits.contains(.link))
        #expect(link.openControl.accessibilityLabel == "Care guide")
        link.perform(NSSelectorFromString("handleOpen"))
        #expect(opened == 1)
        link.removeButton.onTap?()
        #expect(removed == 1)
        let plain = try rowView(view, "plain", as: LMKDetailLinkRowView.self)
        #expect(plain.removeButton.isHidden)
        #expect(plain.iconView.isHidden)
        #expect(plain.openControl.accessibilityValue == "example.com")
    }

    @Test
    func `Image rows bind to the aspect ratio, cap the height, and hide without an image`() async throws {
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let tall = UIGraphicsImageRenderer(size: CGSize(width: 100, height: 400), format: format).image { _ in }
        let wide = UIGraphicsImageRenderer(size: CGSize(width: 400, height: 100), format: format).image { _ in }
        let card = LMKDetailCard(id: "c", rows: [
            .image(.init(id: "hero", image: wide, accessibilityLabel: "Photo")),
            .image(.init(id: "tall", image: tall, maxHeight: 150)),
            .image(.init(id: "async", load: { wide })),
            .image(.init(id: "none")),
        ])
        let view = makeView(card, width: 300)
        let hero = try rowView(view, "hero", as: LMKDetailImageRowView.self)
        #expect(hero.isHidden == false)
        #expect(hero.imageView.image === wide)
        #expect(hero.accessibilityLabel == "Photo")
        #expect(abs(hero.frame.height - hero.frame.width / 4) < 1, "wide image keeps its aspect ratio")
        let capped = try rowView(view, "tall", as: LMKDetailImageRowView.self)
        #expect(capped.frame.height == 150)
        #expect(view.view(forRowID: "none")?.isHidden == true)
        let async = try rowView(view, "async", as: LMKDetailImageRowView.self)
        await LMKWait.until { async.imageView.image === wide }
        #expect(async.imageView.image === wide)
    }

    @Test
    func `Photo strips size their tiles, load images, show captions and selection, and fall back to an empty state`() async throws {
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let image = UIGraphicsImageRenderer(size: CGSize(width: 10, height: 10), format: format).image { _ in }
        var taps: [Int] = []
        let card = LMKDetailCard(id: "c", rows: [
            .photoStrip(.init(id: "photos", count: 3, image: { _ in image }, caption: { "Day \($0)" }, isSelected: { $0 == 1 }, badgeSymbol: { $0 == 2 ? "leaf" : nil }, onTap: { taps.append($0) })),
            .photoStrip(.init(id: "empty", count: 0, image: { _ in nil }, emptyState: .init(message: "No photos yet", icon: .system("photo")))),
            .photoStrip(.init(id: "bare", count: 0, image: { _ in nil })),
        ])
        let view = makeView(card)
        let strip = try rowView(view, "photos", as: LMKDetailPhotoStripRowView.self)
        #expect(strip.collectionView.isHidden == false)
        #expect(strip.emptyStateView.isHidden)
        #expect(strip.tileSide == 100)
        #expect(strip.collectionView.numberOfItems(inSection: 0) == 3)
        let captionHeight = LMKSpacing.xs + ceil(LMKTextMeasurement.lineHeight(of: .smallMedium, traits: view.traitCollection))
        #expect(strip.frame.height == 100 + captionHeight)
        strip.collectionView.layoutIfNeeded()
        let cell = try #require(strip.collectionView.cellForItem(at: IndexPath(item: 1, section: 0)) as? LMKDetailPhotoTileCell)
        #expect(cell.captionLabel.text == "Day 1")
        #expect(cell.checkmarkView.isHidden == false)
        #expect(cell.accessibilityLabel == "Photo 2 of 3, Day 1")
        #expect(cell.accessibilityValue == "Selected")
        #expect(cell.accessibilityTraits.contains(.button))
        await LMKWait.until { cell.imageView.image === image }
        #expect(cell.imageView.image === image)
        let badged = try #require(strip.collectionView.cellForItem(at: IndexPath(item: 2, section: 0)) as? LMKDetailPhotoTileCell)
        #expect(badged.badgeView.isHidden == false)
        #expect(badged.checkmarkView.isHidden)
        strip.collectionView(strip.collectionView, didSelectItemAt: IndexPath(item: 2, section: 0))
        #expect(taps == [2])

        let empty = try rowView(view, "empty", as: LMKDetailPhotoStripRowView.self)
        #expect(empty.emptyStateView.isHidden == false)
        #expect(empty.collectionView.isHidden)
        let bare = try rowView(view, "bare", as: LMKDetailPhotoStripRowView.self)
        #expect(bare.collectionView.isHidden)
        #expect(bare.emptyStateView.isHidden)
        #expect(bare.frame.height == 0)

        // A reconfigure with the same row id keeps the strip view (no reload flash).
        view.configure(card)
        #expect(view.view(forRowID: "photos") === strip)
        view.reloadPhotoStrip(rowID: "photos")
    }

    // MARK: - Actions

    @Test
    func `Actions lay out stacked, in pairs, leading-primary, or inline, with roles, enablement, and long press`() throws {
        var taps: [String] = []
        var longPresses = 0
        let actions: [LMKDetailCard.Action] = [
            .init(id: "water", title: "Mark Watered", role: .primary, onLongPress: { longPresses += 1 }, onTap: { taps.append("water") }),
            .init(id: "log", title: "Log Past", role: .secondary) { taps.append("log") },
            .init(id: "delete", title: "Delete", role: .destructive, isEnabled: false) { taps.append("delete") },
        ]
        let stacked = makeView(LMKDetailCard(id: "s", rows: [], actions: actions, actionsLayout: .stacked))
        #expect(stacked.actionsStack.arrangedSubviews.count == 3)
        #expect(stacked.actionsStack.arrangedSubviews.allSatisfy { $0 is LMKButton })
        let water = try #require(stacked.actionButtons["water"])
        #expect(water.title == "Mark Watered")
        #expect(water.style.role == .primary && water.style.variant == .filled)
        #expect(water.gestureRecognizers?.contains { $0 is UILongPressGestureRecognizer } == true)
        water.onTap?()
        #expect(taps == ["water"])
        let delete = try #require(stacked.actionButtons["delete"])
        #expect(delete.isEnabled == false)
        #expect(delete.style.variant == .ghost && delete.style.role == .destructive)
        #expect(stacked.setAction("delete", enabled: true))
        #expect(delete.isEnabled)
        #expect(stacked.card?.actions[2].isEnabled == true)
        #expect(!stacked.setAction("missing", enabled: true))
        #expect(stacked.contentStack.customSpacing(after: stacked.rowsStack) == LMKSpacing.large)

        let pairs = makeView(LMKDetailCard(id: "p", rows: [], actions: actions, actionsLayout: .pairs))
        #expect(pairs.actionsStack.arrangedSubviews.count == 2)
        #expect((pairs.actionsStack.arrangedSubviews[0] as? UIStackView)?.arrangedSubviews.count == 2)
        #expect(pairs.actionsStack.arrangedSubviews[1] is LMKButton)

        let leading = makeView(LMKDetailCard(id: "l", rows: [], actions: actions, actionsLayout: .leadingPrimary))
        #expect(leading.actionsStack.arrangedSubviews[0] is LMKButton)
        #expect((leading.actionsStack.arrangedSubviews[1] as? UIStackView)?.arrangedSubviews.count == 2)

        let inline = makeView(LMKDetailCard(id: "i", rows: [], actions: actions, actionsLayout: .inline))
        #expect(inline.actionsStack.arrangedSubviews.count == 1)
        #expect((inline.actionsStack.arrangedSubviews[0] as? UIStackView)?.arrangedSubviews.count == 3)

        let none = makeView(LMKDetailCard(id: "n", title: "T"))
        #expect(none.actionsStack.isHidden)
        #expect(none.actionButtons.isEmpty)
    }

    // MARK: - Style and theme

    @Test
    func `Style, theme.detailCard, and the card's own style layer in that order`() {
        var theme = LMKTheme()
        theme.detailCard = LMKDetailCardView.Style(rowSpacing: 30, keyColor: .purple, actionButtons: [.primary: LMKButton.Style(variant: .outlined)])
        let card = LMKDetailCard(
            id: "c",
            rows: [.keyValue(.init(id: "k", key: "K", value: "V"))],
            actions: [.init(id: "a", title: "A") {}],
            style: LMKDetailCardView.Style(rowSpacing: 5)
        )
        let view = LMKDetailCardView(card: card, style: LMKDetailCardView.Style(card: LMKCardView.Style(surface: LMKSurfaceStyle(corners: .fixed(3))), valueColor: .brown))
        view.applyTheme(theme)
        LMKThemeTesting.fit(view)
        #expect(view.resolvedStyle.keyColor == UIColor.purple)
        #expect(view.resolvedStyle.valueColor == UIColor.brown)
        #expect(view.rowsStack.spacing == 5, "the card's own style wins")
        #expect(view.cardView.layer.cornerRadius == 3)
        #expect((view.view(forRowID: "k") as? LMKDetailKeyValueRowView)?.keyLabel.textColor == UIColor.purple)
        #expect(view.actionButtons["a"]?.style.variant == .outlined)
        #expect(LMKDetailCardView.Style().actionButtonStyle(for: .destructive).variant == .ghost)
        #expect(LMKDetailCardView.Style().actionButtonStyle(for: .secondary) == .filled(.secondary))
        let merged = LMKDetailCardView.Style(rowSpacing: 1, keyColor: .red).merging(LMKDetailCardView.Style(rowSpacing: 2))
        #expect(merged.rowSpacing == 2 && merged.keyColor == UIColor.red)
        #expect(LMKDetailCardView.Style.defaultValue == LMKDetailCardView.Style())
        #expect(view.isHidden == false)
        view.configure(LMKDetailCard(id: "c", isHidden: true))
        #expect(view.isHidden)
    }

    @Test
    func `Model helpers: row ids, kinds, divider factory, title convenience, clamped progress`() {
        let rows: [LMKDetailCard.Row] = [
            .keyValue(.init(id: "1", key: "k", value: "v")), .text(.init(id: "2", text: "t")), .chips(.init(id: "3", items: [])),
            .photoStrip(.init(id: "4", count: 0, image: { _ in nil })), .progress(.init(id: "5", title: "p", value: 2)),
            .navigation(.init(id: "6", title: "n") {}), .link(.init(id: "7", title: "l")), .rating(.init(id: "8", title: "r", value: 1)),
            .image(.init(id: "9")), .divider(id: "10"), .custom(id: "11", UIView()),
        ]
        #expect(rows.map(\.id) == (1 ... 11).map(String.init))
        #expect(Set(rows.map(\.kind)).count == 11)
        #expect(LMKDetailCard.Row.divider().id.isEmpty == false)
        if case let .progress(progress) = rows[4] { #expect(progress.value == 1) }
        let card = LMKDetailCard(id: "c", title: "Title", rows: rows)
        #expect(card.header?.title == "Title")
        #expect(card.row(id: "7") != nil)
        #expect(card.row(id: "x") == nil)
        #expect(LMKDetailCardView.Strings().photoAccessibilityLabelFormat.contains("%lld"))
    }
}
