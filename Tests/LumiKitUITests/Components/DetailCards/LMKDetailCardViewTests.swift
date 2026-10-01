//
//  LMKDetailCardViewTests.swift
//  LumiKit
//

import LumiKitCore
import Testing
import UIKit
@testable import LumiKitUI

/// Holds an image load open until the test lets it land.
@MainActor
private final class LoadGate {
    private var isOpen = false
    private var continuations: [CheckedContinuation<Void, Never>] = []

    func wait() async {
        if isOpen { return }
        await withCheckedContinuation { continuations.append($0) }
    }

    func open() {
        isOpen = true
        continuations.forEach { $0.resume() }
        continuations.removeAll()
    }
}

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
        // The spinner shows on a header without trailing items too.
        plain.setHeaderLoading(true)
        #expect(plain.headerTrailingStack.isHidden == false)
        #expect(plain.loadingIndicator.isAnimating)
        plain.setHeaderLoading(false)
        #expect(plain.headerTrailingStack.isHidden)
        let headless = makeView(LMKDetailCard(id: "h", rows: [.text(.init(id: "t", text: "x"))]))
        #expect(headless.headerView.isHidden)
    }

    @Test
    func `Header trailing controls are updated in place across reconfigures and a host view stays whose it is`() throws {
        let hosted = UIView()
        var taps: [String] = []
        func card(count: Int, label: String) -> LMKDetailCard {
            LMKDetailCard(id: "c", header: .init(title: "T", trailing: [
                .button(systemName: "book", accessibilityLabel: label) { taps.append(label) },
                .badge(.count(count)),
                .view(hosted),
                .text("\(count) items"),
            ]))
        }
        let view = makeView(card(count: 1, label: "One"))
        let before = view.headerTrailingStack.arrangedSubviews
        let button = try #require(before[0] as? LMKButton)
        view.configure(card(count: 2, label: "Two"))
        let after = view.headerTrailingStack.arrangedSubviews
        #expect(after.count == 5, "four items plus the loading indicator")
        #expect(after[0] === button, "the same button, updated")
        #expect(button.accessibilityLabel == "Two")
        button.onTap?()
        #expect(taps == ["Two"])
        #expect(after[1] === before[1])
        #expect((after[1] as? LMKBadgeView)?.countLabel.text == "2")
        #expect(after[2] === hosted)
        #expect((after[3] as? UILabel)?.text == "2 items")
        #expect(after[4] === view.loadingIndicator)
        // Another card takes the host's view; this card no longer removes it on its next pass.
        let other = makeView(LMKDetailCard(id: "o", header: .init(title: "O", trailing: [.view(hosted)])))
        #expect(hosted.superview === other.headerTrailingStack)
        view.configure(LMKDetailCard(id: "c", header: .init(title: "T", trailing: [.text("none")])))
        #expect(hosted.superview === other.headerTrailingStack)
        #expect(view.headerTrailingStack.arrangedSubviews.count == 2)
        // A shape change at a position rebuilds that control only.
        other.configure(LMKDetailCard(id: "o", header: .init(title: "O", trailing: [.text("x"), .view(hosted)])))
        #expect(other.headerTrailingStack.arrangedSubviews[0] is UILabel)
        #expect(other.headerTrailingStack.arrangedSubviews[1] === hosted)
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
        // The inline value sits against the trailing edge, which is the left one in RTL.
        inline.semanticContentAttribute = .forceRightToLeft
        view.configure(card)
        #expect(inline.valueLabel.textAlignment == .left)
        view.configure(LMKDetailCard(id: "c", rows: [.keyValue(.init(id: "status", key: "Status", value: "Overdue", layout: .inline))], style: LMKDetailCardView.Style(inlineValueAlignment: .center)))
        #expect(inline.valueLabel.textAlignment == .center)
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
            .rating(.init(id: "r", title: "Rating", value: 3, onValueChange: { ratings.append($0) })),
            .divider(id: "d"),
            .custom(id: "map", custom),
        ])
        let view = makeView(card)
        let text = try rowView(view, "notes", as: LMKDetailTextRowView.self)
        #expect(text.titleLabel.text == "Notes")
        #expect(text.richTextLabel.attributedText?.string == "Bold note")
        #expect(text.textLabel.isHidden && !text.richTextLabel.isHidden)
        let chips = try rowView(view, "tags", as: LMKDetailChipsRowView.self)
        #expect(chips.chips.map(\.text) == ["Sunny", "Humid"])
        #expect(chips.chips[0].style.tintColor == UIColor.orange)
        chips.chips[0].onTap?()
        #expect(chipTaps == 1)
        // Chips are reused by id: a reconfigure restyles the same views and drops the missing ones.
        let sunny = chips.chips[0]
        view.update(rowID: "tags") { row in row = .chips(.init(id: "tags", items: [.init(id: "b", text: "Humid"), .init(id: "a", text: "Sunny!", tint: .red), .init(id: "c", text: "New")])) }
        #expect(chips.chips.map(\.text) == ["Humid", "Sunny!", "New"])
        #expect(chips.chips[1] === sunny)
        #expect(sunny.style.tintColor == UIColor.red)
        #expect(chips.stack.arrangedSubviews.map { ($0 as? LMKChipView)?.text } == ["Humid", "Sunny!", "New"])
        view.update(rowID: "tags") { row in row = .chips(.init(id: "tags", items: [.init(id: "c", text: "New")])) }
        #expect(chips.chips.count == 1)
        #expect(sunny.superview == nil)
        #expect(chips.stack.arrangedSubviews.count == 1)
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
        rating.ratingControl.onValueChange?(5)
        #expect(ratings == [5])
        #expect(view.view(forRowID: "d") is LMKDetailDividerRowView)
        #expect(custom.superview === view.view(forRowID: "map"))
        #expect(view.rowsStack.arrangedSubviews.count == 6)
    }

    @Test
    func `Attributed text keeps its runs, also across a Dynamic Type change`() throws {
        let bold = UIFont.boldSystemFont(ofSize: 20)
        let attributed = NSMutableAttributedString(string: "Plain bold", attributes: [.foregroundColor: UIColor.red])
        attributed.addAttribute(.font, value: bold, range: NSRange(location: 6, length: 4))
        let card = LMKDetailCard(id: "c", rows: [
            .text(.init(id: "attributed", content: .attributed(attributed))),
            .text(.init(id: "markdown", content: .markdown("**Bold** note"))),
            .keyValue(.init(id: "kv", key: "K", value: "V", layout: .inline)),
        ])
        let view = LMKDetailCardView(card: card)
        let window = LMKThemeTesting.host(view)
        defer { window.isHidden = true }
        LMKThemeTesting.fit(view)
        let attributedRow = try rowView(view, "attributed", as: LMKDetailTextRowView.self)
        #expect(attributedRow.richTextLabel.attributedText?.attribute(.font, at: 6, effectiveRange: nil) as? UIFont == bold)
        #expect(attributedRow.richTextLabel.attributedText?.attribute(.foregroundColor, at: 0, effectiveRange: nil) as? UIColor == UIColor.red)
        let markdownRow = try rowView(view, "markdown", as: LMKDetailTextRowView.self)
        func boldFont() -> UIFont? {
            markdownRow.richTextLabel.attributedText?.attribute(.font, at: 0, effectiveRange: nil) as? UIFont
        }
        let regularSize = try #require(boldFont()).pointSize
        #expect(try #require(boldFont()).fontDescriptor.symbolicTraits.contains(.traitBold))
        let pair = try rowView(view, "kv", as: LMKDetailKeyValueRowView.self)
        #expect(pair.pairStack.axis == .horizontal)

        window.traitOverrides.preferredContentSizeCategory = .accessibilityExtraLarge
        view.updateTraitsIfNeeded()
        markdownRow.updateTraitsIfNeeded()
        attributedRow.updateTraitsIfNeeded()
        window.layoutIfNeeded()
        let grown = try #require(boldFont())
        #expect(grown.pointSize > regularSize, "the markdown font follows the size category")
        #expect(grown.fontDescriptor.symbolicTraits.contains(.traitBold), "no label handler flattens the bold run")
        #expect(attributedRow.richTextLabel.attributedText?.attribute(.font, at: 6, effectiveRange: nil) as? UIFont == bold, "host attributes survive")
        #expect(pair.pairStack.axis == .vertical, "an inline pair stacks at accessibility sizes, judged by the card's new traits")
    }

    @Test
    func `A progress value that is not a number never reaches Auto Layout`() throws {
        var progress = LMKDetailCard.Progress(id: "p", title: "Done", value: Float(0) / Float(0))
        #expect(progress.value == 0, "0 / 0 is NaN")
        progress.value = 1.5
        #expect(progress.value == 1)
        progress.value = -0.5
        #expect(progress.value == 0)
        progress.value = .infinity
        #expect(progress.value == 0)
        progress.value = -.infinity
        #expect(progress.value == 0)
        progress.value = 0.4
        #expect(progress.value == 0.4)
        let view = makeView(LMKDetailCard(id: "c", rows: [
            .progress(.init(id: "nan", title: "NaN", value: .nan)),
            .progress(.init(id: "inf", title: "Inf", value: .infinity)),
            .progress(.init(id: "big", title: "Big", value: 7)),
            .progress(.init(id: "neg", title: "Neg", value: -3)),
        ]))
        let nan = try rowView(view, "nan", as: LMKDetailProgressRowView.self)
        #expect(nan.value == 0)
        #expect(nan.barView.frame.width == 0)
        #expect(nan.accessibilityValue == LMKFormat.progressPercent(0))
        #expect(try rowView(view, "inf", as: LMKDetailProgressRowView.self).value == 0)
        let big = try rowView(view, "big", as: LMKDetailProgressRowView.self)
        #expect(big.value == 1)
        #expect(abs(big.barView.frame.width - big.trackView.frame.width) < 1)
        #expect(try rowView(view, "neg", as: LMKDetailProgressRowView.self).value == 0)
    }

    @Test
    func `A custom row removes only the view it still owns, so two rows can swap views`() throws {
        let a = UIView()
        let b = UIView()
        let view = makeView(LMKDetailCard(id: "c", rows: [.custom(id: "x", a), .custom(id: "y", b)]))
        let x = try rowView(view, "x", as: LMKDetailCustomRowView.self)
        let y = try rowView(view, "y", as: LMKDetailCustomRowView.self)
        view.configure(LMKDetailCard(id: "c", rows: [.custom(id: "x", b), .custom(id: "y", a)]))
        #expect(b.superview === x)
        #expect(a.superview === y)
        #expect(x.subviews == [b])
        #expect(y.subviews == [a])
        view.configure(LMKDetailCard(id: "c", rows: [.custom(id: "x", b), .custom(id: "y", a)]))
        #expect(b.superview === x && a.superview === y, "the same views stay put")
    }

    @Test
    func `A navigation row shows a pressed fill that follows its corners and drops the highlight on release`() throws {
        let view = makeView(
            LMKDetailCard(id: "c", rows: [.navigation(.init(id: "n", title: "Journal") {})]),
            style: LMKDetailCardView.Style(navigationRowSurface: LMKSurfaceStyle(background: .solid(.yellow), corners: .fixed(7)))
        )
        let navigation = try rowView(view, "n", as: LMKDetailNavigationRowView.self)
        let content = try #require(navigation.contentView)
        #expect(content.stateBackgroundView.isHidden)
        navigation.isHighlighted = true
        #expect(content.current.isHighlighted)
        #expect(content.stateBackgroundView.isHidden == false)
        #expect(content.stateBackgroundView.backgroundColor == LMKColor.pressedOverlay)
        #expect(content.stateBackgroundView.layer.cornerRadius == 7)
        navigation.isHighlighted = false
        #expect(content.current.isHighlighted == false)
        #expect(content.stateBackgroundView.isHidden)
        // The style's own highlighted look wins over the built-in fill.
        let pressed = LMKListRowConfiguration.Style(highlighted: LMKControlStateStyle(background: .solid(.green), foregroundColor: .white))
        view.configure(LMKDetailCard(id: "c", rows: [.navigation(.init(id: "n", title: "Journal") {})], style: LMKDetailCardView.Style(navigationRow: pressed)))
        navigation.isHighlighted = true
        #expect(content.stateBackgroundView.backgroundColor == UIColor.green)
        #expect(content.titleLabel.textColor == UIColor.white)
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
        view.strings = LMKDetailCardView.Strings(removeLinkAccessibilityLabel: "Drop")
        #expect(link.removeButton.accessibilityLabel == "Drop", "new strings reach a reused row")
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
        // A reconfigure keeps the loaded image up while the next load runs.
        let gate = LoadGate()
        view.configure(LMKDetailCard(id: "c", rows: [.image(.init(id: "async", load: { await gate.wait(); return tall }))]))
        #expect(async.isHidden == false)
        #expect(async.imageView.image === wide)
        gate.open()
        await LMKWait.until { async.imageView.image === tall }
        #expect(async.imageView.image === tall)
        // A load that returns nothing hides the row.
        view.configure(LMKDetailCard(id: "c", rows: [.image(.init(id: "async", load: { nil }))]))
        await LMKWait.until { async.isHidden }
        #expect(async.isHidden)
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

        // A reconfigure with the same count keeps the strip view and its loaded tiles: no
        // reload, no image request; captions and selection are restyled in place.
        var requests = 0
        let same = LMKDetailCard(id: "c", rows: [
            .photoStrip(.init(id: "photos", count: 3, image: { _ in requests += 1; return image }, caption: { "Shot \($0)" }, isSelected: { $0 == 2 }, onTap: { taps.append($0) })),
        ])
        view.configure(same)
        #expect(view.view(forRowID: "photos") === strip)
        #expect(strip.collectionView.cellForItem(at: IndexPath(item: 1, section: 0)) === cell, "the tile was not reloaded")
        #expect(cell.imageView.image === image)
        #expect(cell.captionLabel.text == "Shot 1")
        #expect(cell.checkmarkView.isHidden)
        #expect(badged.checkmarkView.isHidden == false)
        #expect(cell.accessibilityLabel == "Photo 2 of 3, Shot 1")
        #expect(requests == 0)
        // A count change reloads; the explicit reload refetches.
        view.configure(LMKDetailCard(id: "c", rows: [
            .photoStrip(.init(id: "photos", count: 4, image: { _ in requests += 1; return image }, caption: { "Shot \($0)" })),
        ]))
        strip.collectionView.layoutIfNeeded()
        #expect(strip.collectionView.numberOfItems(inSection: 0) == 4)
        await LMKWait.until { requests >= 4 }
        let before = requests
        view.reloadPhotoStrip(rowID: "photos")
        strip.collectionView.layoutIfNeeded()
        await LMKWait.until { requests >= before + 4 }
        #expect(requests >= before + 4)
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
        #expect(LMKDetailCardView.Style(haptics: false).merging(LMKDetailCardView.Style()).haptics == false)
        #expect(LMKDetailCardView.Style().merging(LMKDetailCardView.Style(haptics: true)).haptics == true)
    }

    @Test
    func `Every style field reaches the card`() throws {
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let image = UIGraphicsImageRenderer(size: CGSize(width: 400, height: 100), format: format).image { _ in }
        let style = LMKDetailCardView.Style(
            card: LMKCardView.Style(surface: LMKSurfaceStyle(background: .solid(.yellow))),
            headerIconSize: 31,
            headerIconTint: .brown,
            headerIconInCircle: false,
            headerTitleTextStyle: .h1,
            headerTitleColor: .purple,
            headerSubtitleTextStyle: .small,
            headerSubtitleColor: .orange,
            headerSpacing: 3,
            headerButton: LMKButton.Style(tintColor: .cyan),
            headerBottomSpacing: 5,
            rowSpacing: 7,
            showsRowDividers: true,
            inlineKeyTextStyle: .h4,
            stackedKeyTextStyle: .bodyBold,
            keyColor: .red,
            valueTextStyle: .caption,
            valueColor: .blue,
            inlineValueAlignment: .center,
            keyValueSpacing: 9,
            descriptionTextStyle: .smallMedium,
            descriptionColor: .magenta,
            textStyle: .italicBody,
            textColor: .systemIndigo,
            textTitleTextStyle: .h2,
            chip: LMKChipView.Style(tintColor: .systemTeal),
            chipSpacing: 11,
            photoTileHeight: 60,
            photoTileCorners: .fixed(2),
            photoSpacing: 13,
            photoCaptionTextStyle: .extraSmall,
            photoCaptionColor: .systemPink,
            photoPlaceholderColor: .systemMint,
            progressHeight: 15,
            progressTint: .systemGreen,
            progressTrackColor: .systemGray,
            navigationRow: LMKListRowConfiguration.Style(titleColor: .systemBrown),
            navigationRowSurface: LMKSurfaceStyle(background: .solid(.systemYellow), corners: .fixed(4)),
            linkColor: .systemRed,
            linkTextStyle: .h3,
            underlinesLinks: true,
            rating: LMKRatingControl.Style(filledColor: .systemOrange),
            imageMaxHeight: 50,
            imageCorners: .fixed(6),
            imageBackgroundColor: .systemCyan,
            actionsTopSpacing: 17,
            actionSpacing: 19,
            actionButtons: [.secondary: LMKButton.Style(variant: .outlined)],
            haptics: false
        )
        let card = LMKDetailCard(id: "c", header: .init(icon: .symbol("leaf"), title: "T", subtitles: ["S"], trailing: [.button(systemName: "book", accessibilityLabel: "B") {}]), rows: [
            .keyValue(.init(id: "inline", key: "K", value: "V", layout: .inline, description: "D")),
            .keyValue(.init(id: "stacked", key: "K", value: "V")),
            .text(.init(id: "text", title: "Title", text: "Body")),
            .chips(.init(id: "chips", items: [.init(id: "a", text: "A"), .init(id: "b", text: "B")])),
            .photoStrip(.init(id: "photos", count: 1, image: { _ in nil }, caption: { _ in "c" })),
            .progress(.init(id: "progress", title: "P", value: 0.5)),
            .navigation(.init(id: "nav", title: "N") {}),
            .link(.init(id: "link", title: "L", url: URL(string: "https://example.com"))),
            .rating(.init(id: "rating", title: "R", value: 2)),
            .image(.init(id: "image", image: image)),
        ], actions: [.init(id: "a", title: "A", role: .secondary) {}, .init(id: "b", title: "B") {}], actionsLayout: .stacked)
        let view = makeView(card, style: style)
        let traits = view.traitCollection
        #expect(view.cardView.backgroundColor == UIColor.yellow)
        #expect(view.headerIconContainer.bounds.width == 31)
        #expect(view.headerIconView.tintColor == UIColor.brown)
        #expect(view.headerIconContainer.backgroundColor == UIColor.clear)
        #expect(view.titleLabel.font == LMKTypography.font(for: .h1, compatibleWith: traits))
        #expect(view.titleLabel.textColor == UIColor.purple)
        #expect(view.subtitleLabels[0].font == LMKTypography.font(for: .small, compatibleWith: traits))
        #expect(view.subtitleLabels[0].textColor == UIColor.orange)
        #expect(view.headerStack.spacing == 3)
        #expect((view.headerTrailingStack.arrangedSubviews[0] as? LMKButton)?.style.tintColor == UIColor.cyan)
        #expect(view.contentStack.customSpacing(after: view.headerView) == 5)
        #expect(view.rowsStack.spacing == 7)
        #expect(view.rowsStack.arrangedSubviews.count == 19, "ten rows and nine dividers")
        let inline = try rowView(view, "inline", as: LMKDetailKeyValueRowView.self)
        #expect(inline.keyLabel.font == LMKTypography.font(for: .h4, compatibleWith: traits))
        #expect(inline.keyLabel.textColor == UIColor.red)
        #expect(inline.valueLabel.font == LMKTypography.font(for: .caption, compatibleWith: traits))
        #expect(inline.valueLabel.textColor == UIColor.blue)
        #expect(inline.valueLabel.textAlignment == .center)
        #expect(inline.pairStack.spacing == 9)
        #expect(inline.descriptionLabel.font == LMKTypography.font(for: .smallMedium, compatibleWith: traits))
        #expect(inline.descriptionLabel.textColor == UIColor.magenta)
        let stacked = try rowView(view, "stacked", as: LMKDetailKeyValueRowView.self)
        #expect(stacked.keyLabel.font == LMKTypography.font(for: .bodyBold, compatibleWith: traits))
        let text = try rowView(view, "text", as: LMKDetailTextRowView.self)
        #expect(text.richTextLabel.isHidden && !text.textLabel.isHidden)
        #expect(text.textLabel.font == LMKTypography.font(for: .italicBody, compatibleWith: traits))
        #expect(text.textLabel.textColor == UIColor.systemIndigo)
        #expect(text.titleLabel.font == LMKTypography.font(for: .h2, compatibleWith: traits))
        let chips = try rowView(view, "chips", as: LMKDetailChipsRowView.self)
        #expect(chips.chips[0].style.tintColor == UIColor.systemTeal)
        #expect(chips.stack.spacing == 11)
        let strip = try rowView(view, "photos", as: LMKDetailPhotoStripRowView.self)
        #expect(strip.tileSide == 60)
        strip.collectionView.layoutIfNeeded()
        let tile = try #require(strip.collectionView.cellForItem(at: IndexPath(item: 0, section: 0)) as? LMKDetailPhotoTileCell)
        #expect(tile.imageView.layer.cornerRadius == 2)
        #expect(tile.imageView.backgroundColor == UIColor.systemMint)
        #expect(tile.captionLabel.font == LMKTypography.font(for: .extraSmall, compatibleWith: traits))
        #expect(tile.captionLabel.textColor == UIColor.systemPink)
        #expect((strip.collectionView.collectionViewLayout as? UICollectionViewFlowLayout)?.minimumLineSpacing == 13)
        let progress = try rowView(view, "progress", as: LMKDetailProgressRowView.self)
        #expect(progress.trackView.frame.height == 15)
        #expect(progress.barView.backgroundColor == UIColor.systemGreen)
        #expect(progress.trackView.backgroundColor == UIColor.systemGray)
        let navigation = try rowView(view, "nav", as: LMKDetailNavigationRowView.self)
        #expect(navigation.contentView?.titleLabel.textColor == UIColor.systemBrown)
        #expect(navigation.backgroundColor == UIColor.systemYellow)
        #expect(navigation.layer.cornerRadius == 4)
        let link = try rowView(view, "link", as: LMKDetailLinkRowView.self)
        #expect(link.titleLabel.textColor == UIColor.systemRed)
        #expect(link.titleLabel.attributedText?.attribute(.font, at: 0, effectiveRange: nil) as? UIFont == LMKTypography.font(for: .h3, compatibleWith: traits))
        let rating = try rowView(view, "rating", as: LMKDetailRatingRowView.self)
        #expect(rating.ratingControl.style.filledColor == UIColor.systemOrange)
        let hero = try rowView(view, "image", as: LMKDetailImageRowView.self)
        #expect(hero.frame.height == 50)
        #expect(hero.imageView.layer.cornerRadius == 6)
        #expect(hero.imageView.backgroundColor == UIColor.systemCyan)
        #expect(view.contentStack.customSpacing(after: view.rowsStack) == 17)
        #expect(view.actionsStack.spacing == 19)
        #expect(view.actionButtons["a"]?.style.variant == LMKButton.Variant.outlined)
        #expect(view.actionButtons["b"]?.style.variant == LMKButton.Variant.filled)
        #expect(view.resolvedStyle.haptics == false)
        #expect(LMKDetailCardView.Style().merging(style) == style, "merging over an empty style keeps every field")
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
